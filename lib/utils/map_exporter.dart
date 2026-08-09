import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../layout/layout_engine.dart';
import '../models/mind_map.dart';

/// Renders a mind map to PNG / PDF and saves via the system picker.
///
/// Draws the full layout offscreen (not a screenshot), so the export includes
/// every node at crisp resolution without chrome, zoom, or selection UI.
class MapExporter {
  MapExporter._();

  static const double _padding = 48;
  static const double _pixelRatio = 2;
  static const double _maxImageEdge = 4096;

  /// PNG bytes of the full map at [pixelRatio] scale (capped for memory).
  static Future<Uint8List> renderPng(
    MindMap map, {
    double pixelRatio = _pixelRatio,
  }) async {
    final layout = computeLayout(map);
    final bounds = _contentBounds(layout);
    if (bounds == null || bounds.isEmpty) {
      throw StateError('Mind map has no nodes to export');
    }

    final logicalW = bounds.width;
    final logicalH = bounds.height;
    var scale = pixelRatio;
    final maxEdge = max(logicalW, logicalH) * scale;
    if (maxEdge > _maxImageEdge) {
      scale = _maxImageEdge / max(logicalW, logicalH);
    }

    final imageW = max(1, (logicalW * scale).ceil());
    final imageH = max(1, (logicalH * scale).ceil());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    // Soft light background so pastel nodes stay readable.
    canvas.drawRect(
      Rect.fromLTWH(bounds.left, bounds.top, logicalW, logicalH),
      Paint()..color = const Color(0xFFF7F8FC),
    );

    _paintEdges(canvas, map, layout);
    _paintNodes(canvas, map, layout);

    final picture = recorder.endRecording();
    final image = await picture.toImage(imageW, imageH);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) {
      throw StateError('Failed to encode PNG');
    }
    return bytes.buffer.asUint8List();
  }

  /// Single-page PDF wrapping a high-res PNG of the map.
  static Future<Uint8List> renderPdf(MindMap map) async {
    final png = await renderPng(map);
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width.toDouble();
    final h = img.height.toDouble();
    img.dispose();
    codec.dispose();

    // PDF points ≈ image pixels at 72dpi feel; keep aspect, cap page size.
    const maxPt = 1440.0;
    var pageW = w;
    var pageH = h;
    final longest = max(pageW, pageH);
    if (longest > maxPt) {
      final s = maxPt / longest;
      pageW *= s;
      pageH *= s;
    }

    final doc = pw.Document(title: map.title, creator: 'SimplyMind');
    final memory = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageW, pageH, marginAll: 0),
        build: (_) => pw.Center(
          child: pw.Image(memory, fit: pw.BoxFit.contain),
        ),
      ),
    );
    return Uint8List.fromList(await doc.save());
  }

  /// Saves PNG via the platform picker / browser download.
  static Future<bool> exportPng(MindMap map) async {
    final bytes = await renderPng(map);
    return _saveBytes(
      bytes: bytes,
      fileName: '${_safeFileName(map)}.png',
      dialogTitle: 'Export image',
      extension: 'png',
    );
  }

  /// Saves PDF via the platform picker / browser download.
  static Future<bool> exportPdf(MindMap map) async {
    final bytes = await renderPdf(map);
    return _saveBytes(
      bytes: bytes,
      fileName: '${_safeFileName(map)}.pdf',
      dialogTitle: 'Export PDF',
      extension: 'pdf',
    );
  }

  static Future<bool> _saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String dialogTitle,
    required String extension,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
    return kIsWeb || path != null;
  }

  static String _safeFileName(MindMap map) {
    final safe = map.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return safe.isEmpty ? 'mindmap' : safe;
  }

  static Rect? _contentBounds(LayoutResult layout) {
    Rect? bounds;
    for (final entry in layout.positions.entries) {
      final size = layout.sizes[entry.key];
      if (size == null) continue;
      final rect = Rect.fromCenter(
        center: entry.value,
        width: size.width,
        height: size.height,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    return bounds?.inflate(_padding);
  }

  static Color _inkFor(Color background) =>
      background.computeLuminance() > 0.45
          ? const Color(0xFF273043)
          : Colors.white;

  static void _paintEdges(Canvas canvas, MindMap map, LayoutResult layout) {
    final positions = layout.positions;
    final sizes = layout.sizes;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final parent in map.nodes) {
      final children = map.childrenOf(parent.id);
      if (children.isEmpty) continue;
      final p = positions[parent.id];
      final ps = sizes[parent.id];
      if (p == null || ps == null) continue;
      final mode = layout.childrenModeOf[parent.id] ?? MindMapLayout.map;

      switch (mode) {
        case MindMapLayout.map:
          for (final child in children) {
            final c = positions[child.id];
            if (c == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            final midX = p.dx + (c.dx - p.dx) / 2;
            final path = Path()
              ..moveTo(p.dx, p.dy)
              ..cubicTo(midX, p.dy, midX, c.dy, c.dx, c.dy);
            canvas.drawPath(path, paint);
          }
        case MindMapLayout.graph:
          for (final child in children) {
            final c = positions[child.id];
            if (c == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            canvas.drawLine(p, c, paint);
          }
        case MindMapLayout.list:
          final trunkX = p.dx - ps.width / 2 + 20;
          for (final child in children) {
            final c = positions[child.id];
            final cs = sizes[child.id];
            if (c == null || cs == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            final path = Path()
              ..moveTo(trunkX, p.dy + ps.height / 2)
              ..lineTo(trunkX, c.dy)
              ..lineTo(c.dx - cs.width / 2, c.dy);
            canvas.drawPath(path, paint);
          }
        case MindMapLayout.step:
          final first = positions[children.first.id];
          final firstSize = sizes[children.first.id];
          if (first != null && firstSize != null) {
            paint.color = Color(children.first.color).withValues(alpha: 0.8);
            _arrow(
              canvas,
              Offset(p.dx, p.dy + ps.height / 2),
              Offset(first.dx, first.dy - firstSize.height / 2),
              paint,
            );
          }
          for (var i = 0; i < children.length - 1; i++) {
            final a = positions[children[i].id];
            final b = positions[children[i + 1].id];
            final sa = sizes[children[i].id];
            final sb = sizes[children[i + 1].id];
            if (a == null || b == null || sa == null || sb == null) continue;
            paint.color = Color(children[i + 1].color).withValues(alpha: 0.8);
            _arrow(
              canvas,
              Offset(a.dx + sa.width / 2, a.dy),
              Offset(b.dx - sb.width / 2, b.dy),
              paint,
            );
          }
      }
    }
  }

  static void _arrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const size = 9.0;
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - size * cos(angle - 0.45),
        to.dy - size * sin(angle - 0.45),
      )
      ..lineTo(
        to.dx - size * cos(angle + 0.45),
        to.dy - size * sin(angle + 0.45),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  static void _paintNodes(Canvas canvas, MindMap map, LayoutResult layout) {
    for (final node in map.nodes) {
      final center = layout.positions[node.id];
      final size = layout.sizes[node.id];
      if (center == null || size == null) continue;

      final isRoot = node.parentId == null;
      final color = Color(node.color);
      final ink = _inkFor(color);
      final rect = Rect.fromCenter(
        center: center,
        width: size.width,
        height: size.height,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(isRoot ? 24 : 14),
      );

      // Soft shadow
      canvas.drawRRect(
        rrect.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.10),
      );
      canvas.drawRRect(rrect, Paint()..color = color);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = ink.withValues(alpha: 0.18),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: nodeTextStyle(isRoot).copyWith(color: ink),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: nodeMaxLines(isRoot),
        ellipsis: '…',
      );
      final maxTextW = max(8.0, size.width - 2 * map.nodePadding);
      textPainter.layout(maxWidth: maxTextW);
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
      textPainter.dispose();

      final step = layout.stepNumber[node.id];
      if (step != null) {
        _paintStepBadge(canvas, rect.topLeft + const Offset(-8, -8), step, color);
      }

      if (node.status != NodeStatus.none) {
        _paintStatusMark(
          canvas,
          Offset(rect.right - 6, rect.bottom - 6),
          node.status,
        );
      }
    }
  }

  static void _paintStepBadge(
    Canvas canvas,
    Offset topLeft,
    int step,
    Color accent,
  ) {
    const d = 22.0;
    final center = topLeft + const Offset(d / 2, d / 2);
    canvas.drawCircle(center, d / 2, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      d / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '$step',
        style: const TextStyle(
          color: Color(0xFF273043),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    tp.dispose();
  }

  static void _paintStatusMark(Canvas canvas, Offset bottomRight, NodeStatus status) {
    const r = 10.0;
    final center = bottomRight;
    final fill = status == NodeStatus.done
        ? const Color(0xFF2E7D4F)
        : const Color(0xFF3B6FE0);
    canvas.drawCircle(center, r, Paint()..color = Colors.white);
    canvas.drawCircle(center, r, Paint()..color = fill);

    if (status == NodeStatus.done) {
      final check = Path()
        ..moveTo(center.dx - 4, center.dy)
        ..lineTo(center.dx - 1, center.dy + 3.5)
        ..lineTo(center.dx + 5, center.dy - 3.5);
      canvas.drawPath(
        check,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      // Simple "in progress" arc.
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 5),
        -pi / 2,
        pi * 1.4,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
