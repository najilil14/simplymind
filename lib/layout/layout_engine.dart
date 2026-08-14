import 'dart:math';

import 'package:flutter/painting.dart';

import '../models/mind_map.dart';

/// Shared canvas size used by the editor and spawn placement.
const double kCanvasSize = 6000;

const double _listIndent = 44;
const double _listGapY = 16;
const double _stepGapX = 48;
const double _stepLevelGap = 72;
const double _graphRadius = 250;

/// Text sizing limits: a node box hugs its text between these bounds, then
/// the text wraps. The root node gets a wider box and more lines so long
/// central topics stay fully readable.
const double kMinNodeTextWidth = 56;
const double kMaxNodeTextWidth = 220;
const double kMaxRootTextWidth = 320;
const double kMinNodeTextHeight = 24;
const int kMaxNodeTextLines = 10;
const int kMaxRootTextLines = 14;

/// Max text lines used for rendering a node (must match measurement).
int nodeMaxLines(bool isRoot) => isRoot ? kMaxRootTextLines : kMaxNodeTextLines;

/// The text style nodes are both measured and rendered with (color is
/// applied separately by the card widget).
TextStyle nodeTextStyle(bool isRoot) => TextStyle(
      fontSize: isRoot ? 15 : 13,
      fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
      height: 1.3,
    );

/// Extra pixels added to measured text width so the rendered [Text] widget
/// never wraps one word earlier than [TextPainter] predicted (a common
/// CanvasKit / font-metrics mismatch on web).
const double kTextWidthFudge = 14;

/// Measures the text content of [node], clamped to the sizing limits.
Size _measureNodeText(MindMapNode node) {
  final isRoot = node.parentId == null;
  final maxWidth = isRoot ? kMaxRootTextWidth : kMaxNodeTextWidth;
  final painter = TextPainter(
    text: TextSpan(text: node.text, style: nodeTextStyle(isRoot)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: nodeMaxLines(isRoot),
  );

  // Prefer a single-line width when the label fits under the max. Measuring
  // only at [maxWidth] can report the width of the longest *wrapped* line
  // ("New") while the box height stays one-line tall - which clips "idea".
  painter.layout(maxWidth: double.infinity);
  final oneLineWidth = painter.width + kTextWidthFudge;

  final double w;
  if (oneLineWidth <= maxWidth) {
    w = oneLineWidth.ceilToDouble().clamp(kMinNodeTextWidth, maxWidth);
    painter.layout(maxWidth: w);
  } else {
    // Label must wrap: size to the max width and measure the wrapped height.
    w = maxWidth;
    painter.layout(maxWidth: w);
  }

  final h = max(painter.height.ceilToDouble() + 1, kMinNodeTextHeight);
  painter.dispose();
  return Size(w, h);
}

/// Result of laying out a whole mind map.
class LayoutResult {
  LayoutResult({
    required this.positions,
    required this.sizes,
    required this.placedBy,
    required this.childrenModeOf,
    required this.stepNumber,
  });

  /// Absolute canvas position (center) of every node.
  final Map<String, Offset> positions;

  /// Box size of every node: measured text plus the map's node padding.
  final Map<String, Size> sizes;

  /// The mode that positioned each node (its parent's effective mode).
  /// The root is always [MindMapLayout.map] so it stays draggable.
  final Map<String, MindMapLayout> placedBy;

  /// Effective mode each node uses to lay out its own children.
  final Map<String, MindMapLayout> childrenModeOf;

  /// 1-based sequence number for nodes placed by [MindMapLayout.step].
  final Map<String, int> stepNumber;
}

/// Relative layout of one subtree: offsets of every descendant (including the
/// subtree root itself, always at Offset.zero) and the bounding rect, both
/// relative to the subtree root's center.
class _Subtree {
  _Subtree(this.offsets, this.bounds);

  final Map<String, Offset> offsets;
  final Rect bounds;
}

const double kTextSpare = 2;
/// Computes sizes and positions for every node of [map] according to its
/// template mode and any per-node overrides.
LayoutResult computeLayout(MindMap map) {
  final result = LayoutResult(
    positions: {},
    sizes: {},
    placedBy: {},
    childrenModeOf: {},
    stepNumber: {},
  );
  // Node boxes hug their text: measured content plus padding on all sides.
  for (final n in map.nodes) {
    final content = _measureNodeText(n);
    result.sizes[n.id] = Size(
      content.width + kTextSpare * map.nodePadding,
      content.height + kTextSpare * map.nodePadding,
    );
  }
  final root = map.root;
  if (root == null) return result;

  final rootMode = root.layout ?? map.layout;
  final subtree = _computeSubtree(map, root, rootMode, 0, 2 * pi, result);
  // The root is anchored at its stored position and always drag-movable.
  result.placedBy[root.id] = MindMapLayout.map;
  final anchor = Offset(root.x, root.y);
  for (final entry in subtree.offsets.entries) {
    result.positions[entry.key] = anchor + entry.value;
  }
  // Any orphaned nodes (shouldn't happen) fall back to stored positions.
  for (final n in map.nodes) {
    result.positions.putIfAbsent(n.id, () => Offset(n.x, n.y));
    result.placedBy.putIfAbsent(n.id, () => MindMapLayout.map);
  }
  return result;
}

int _leafCount(MindMap map, MindMapNode node) {
  final children = map.childrenOf(node.id);
  if (children.isEmpty) return 1;
  var sum = 0;
  for (final c in children) {
    sum += _leafCount(map, c);
  }
  return sum;
}

/// [childrenMode] is the effective template this node uses for its children.
/// [angleStart]/[angleEnd] are only meaningful inside graph chains.
_Subtree _computeSubtree(
  MindMap map,
  MindMapNode node,
  MindMapLayout childrenMode,
  double angleStart,
  double angleEnd,
  LayoutResult out,
) {
  out.childrenModeOf[node.id] = childrenMode;
  final size = out.sizes[node.id]!;
  final children = map.childrenOf(node.id);
  final offsets = <String, Offset>{node.id: Offset.zero};
  var bounds = Rect.fromCenter(
      center: Offset.zero, width: size.width, height: size.height);
  if (children.isEmpty) return _Subtree(offsets, bounds);

  // Pre-compute every child subtree with its own effective mode.
  final childModes = <MindMapLayout>[
    for (final c in children) c.layout ?? childrenMode,
  ];

  void merge(MindMapNode child, _Subtree st, Offset at) {
    for (final e in st.offsets.entries) {
      offsets[e.key] = at + e.value;
    }
    bounds = bounds.expandToInclude(st.bounds.shift(at));
  }

  switch (childrenMode) {
    case MindMapLayout.map:
      // Manual positions, stored relative to this node's stored position so
      // that map-mode subtrees stay intact when nested inside auto layouts.
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final st = _computeSubtree(
            map, child, childModes[i], angleStart, angleEnd, out);
        out.placedBy[child.id] = MindMapLayout.map;
        merge(child, st, Offset(child.x - node.x, child.y - node.y));
      }

    case MindMapLayout.list:
      // Outline: children's LEFT edges align, indented from the parent's
      // left edge, so variable-width boxes read as a clean list.
      var cursorY = size.height / 2 + _listGapY;
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final st = _computeSubtree(map, child, childModes[i], 0, 2 * pi, out);
        out.placedBy[child.id] = MindMapLayout.list;
        final childWidth = out.sizes[child.id]!.width;
        final at = Offset(
          -size.width / 2 + _listIndent + childWidth / 2,
          cursorY - st.bounds.top,
        );
        merge(child, st, at);
        cursorY += st.bounds.height + _listGapY;
      }

    case MindMapLayout.step:
      // One horizontal row of numbered steps below the parent, each step
      // centered over its own subtree.
      final subtrees = <_Subtree>[];
      for (var i = 0; i < children.length; i++) {
        subtrees.add(
            _computeSubtree(map, children[i], childModes[i], 0, 2 * pi, out));
      }
      var totalW = 0.0;
      for (final st in subtrees) {
        totalW += st.bounds.width;
      }
      totalW += _stepGapX * (children.length - 1);
      var cursorX = -totalW / 2;
      final rowTop = size.height / 2 + _stepLevelGap;
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final st = subtrees[i];
        out.placedBy[child.id] = MindMapLayout.step;
        out.stepNumber[child.id] = i + 1;
        final at = Offset(cursorX - st.bounds.left, rowTop - st.bounds.top);
        merge(child, st, at);
        cursorX += st.bounds.width + _stepGapX;
      }

    case MindMapLayout.graph:
      // Divide the available angular window proportionally to leaf counts.
      final window = angleEnd - angleStart;
      final weights = [for (final c in children) _leafCount(map, c)];
      final totalWeight = weights.fold<int>(0, (a, b) => a + b);
      var cursor = angleStart;
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final span = window * weights[i] / totalWeight;
        final mid = cursor + span / 2;
        final st = _computeSubtree(
            map, child, childModes[i], cursor, cursor + span, out);
        out.placedBy[child.id] = MindMapLayout.graph;
        merge(child, st, Offset(cos(mid), sin(mid)) * _graphRadius);
        cursor += span;
      }
  }
  return _Subtree(offsets, bounds);
}
