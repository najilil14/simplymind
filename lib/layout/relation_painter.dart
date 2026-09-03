import 'dart:math';

import 'package:flutter/painting.dart';

import '../models/mind_map.dart';

/// Geometry for a curved relation joining the visible edges of two boxes.
class RelationGeometry {
  const RelationGeometry({
    required this.from,
    required this.control,
    required this.to,
  });

  final Offset from;
  final Offset control;
  final Offset to;

  Offset pointAt(double t) {
    final u = 1 - t;
    return from * (u * u) + control * (2 * u * t) + to * (t * t);
  }

  double get endAngle =>
      atan2(to.dy - control.dy, to.dx - control.dx);
}

/// Computes edge-to-edge relation geometry with a small deterministic bend.
RelationGeometry? computeRelationGeometry(
  Rect fromBox,
  Rect toBox, {
  int bendDirection = 1,
}) {
  final delta = toBox.center - fromBox.center;
  if (delta.distance < 0.001) return null;
  final from = _boxIntersection(fromBox, delta);
  final to = _boxIntersection(toBox, -delta);
  final chord = to - from;
  final length = chord.distance;
  if (length < 0.001) return null;

  final perpendicular = Offset(-chord.dy / length, chord.dx / length);
  final bend = min(40.0, max(18.0, length * 0.10));
  final control =
      Offset.lerp(from, to, 0.5)! +
          perpendicular * bend * bendDirection.toDouble();
  return RelationGeometry(from: from, control: control, to: to);
}

Offset _boxIntersection(Rect box, Offset direction) {
  final dx = direction.dx.abs();
  final dy = direction.dy.abs();
  final xScale = dx < 0.001 ? double.infinity : box.width / 2 / dx;
  final yScale = dy < 0.001 ? double.infinity : box.height / 2 / dy;
  return box.center + direction * min(xScale, yScale);
}

/// True when the solid tree branch already connects the same two nodes.
bool isTreeRelationPair(MindMap map, MindMapLink link) {
  final fromNode = map.nodeById(link.fromId);
  final toNode = map.nodeById(link.toId);
  if (fromNode == null || toNode == null) return false;
  return fromNode.parentId == toNode.id || toNode.parentId == fromNode.id;
}

/// Draws all non-tree relations as curved dashed arrows with labels.
///
/// A relation that duplicates an existing parent-child pair is skipped:
/// the solid tree edge already communicates that connection.
void paintMindMapRelations(
  Canvas canvas,
  MindMap map,
  Map<String, Offset> positions,
  Map<String, Size> sizes, {
  Color lineColor = const Color(0xFF6B7280),
  Color labelColor = const Color(0xFF374151),
  Color labelBackground = const Color(0xFFFFFFFF),
}) {
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..color = lineColor.withValues(alpha: 0.88);

  for (final link in map.links) {
    final fromNode = map.nodeById(link.fromId);
    final toNode = map.nodeById(link.toId);
    if (fromNode == null || toNode == null) continue;
    if (isTreeRelationPair(map, link)) continue;
    final fromCenter = positions[link.fromId];
    final toCenter = positions[link.toId];
    final fromSize = sizes[link.fromId];
    final toSize = sizes[link.toId];
    if (fromCenter == null ||
        toCenter == null ||
        fromSize == null ||
        toSize == null) {
      continue;
    }

    final direction = _stableBendDirection(link.id);
    final geometry = computeRelationGeometry(
      Rect.fromCenter(
        center: fromCenter,
        width: fromSize.width,
        height: fromSize.height,
      ),
      Rect.fromCenter(
        center: toCenter,
        width: toSize.width,
        height: toSize.height,
      ),
      bendDirection: direction,
    );
    if (geometry == null) continue;

    final path = Path()
      ..moveTo(geometry.from.dx, geometry.from.dy)
      ..quadraticBezierTo(
        geometry.control.dx,
        geometry.control.dy,
        geometry.to.dx,
        geometry.to.dy,
      );
    _drawDashedPath(canvas, path, paint);
    _drawArrowhead(canvas, geometry.to, geometry.endAngle, paint.color);

    final parts = <String>[
      if (link.label.trim().isNotEmpty) link.label.trim(),
      if (link.cardinality.trim().isNotEmpty) link.cardinality.trim(),
    ];
    if (parts.isEmpty) continue;
    final textPainter = TextPainter(
      text: TextSpan(
        text: parts.join(' · '),
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final center = geometry.pointAt(0.5);
    final rect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 12,
      height: textPainter.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = labelBackground.withValues(alpha: 0.94),
    );
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
    textPainter.dispose();
  }
}

int _stableBendDirection(String id) {
  var sum = 0;
  for (final code in id.codeUnits) {
    sum += code;
  }
  return sum.isEven ? 1 : -1;
}

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  const dash = 10.0;
  const gap = 7.0;
  for (final metric in path.computeMetrics()) {
    for (var at = 0.0; at < metric.length; at += dash + gap) {
      canvas.drawPath(
        metric.extractPath(at, min(at + dash, metric.length)),
        paint,
      );
    }
  }
}

void _drawArrowhead(Canvas canvas, Offset tip, double angle, Color color) {
  const size = 9.0;
  final path = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(
      tip.dx - size * cos(angle - 0.45),
      tip.dy - size * sin(angle - 0.45),
    )
    ..lineTo(
      tip.dx - size * cos(angle + 0.45),
      tip.dy - size * sin(angle + 0.45),
    )
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}
