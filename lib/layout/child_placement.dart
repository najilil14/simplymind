import 'dart:math';

import 'package:flutter/painting.dart';

import '../models/mind_map.dart';
import 'layout_engine.dart';

/// Gap kept between the new child box and existing family boxes (edge-to-edge).
const double kChildSpawnGap = 28;

/// Finds a free spawn center for a new child of [parentId] in map mode.
///
/// Prefers spots near the parent and existing siblings, avoids overlapping
/// their boxes (using live layout sizes), and falls back to nudging outward.
Offset findChildSpawnPosition(MindMap map, String parentId) {
  final parent = map.nodeById(parentId);
  if (parent == null) {
    return Offset(kCanvasSize / 2, kCanvasSize / 2);
  }

  final layout = computeLayout(map);
  final parentCenter = layout.positions[parentId] ?? Offset(parent.x, parent.y);
  final parentSize = layout.sizes[parentId] ??
      Size(map.nodeWidth, map.nodeHeight);

  final childSize = _estimateNewIdeaSize(map);
  final siblings = map.childrenOf(parentId);

  final obstacles = <Rect>[
    Rect.fromCenter(
      center: parentCenter,
      width: parentSize.width,
      height: parentSize.height,
    ),
    for (final s in siblings)
      if (layout.positions[s.id] != null && layout.sizes[s.id] != null)
        Rect.fromCenter(
          center: layout.positions[s.id]!,
          width: layout.sizes[s.id]!.width,
          height: layout.sizes[s.id]!.height,
        ),
  ];

  final candidates = <Offset>[
    // Default: to the right of the parent.
    Offset(
      parentCenter.dx + parentSize.width / 2 + kChildSpawnGap + childSize.width / 2,
      parentCenter.dy,
    ),
    // Near each sibling: right, above, below.
    for (final s in siblings) ..._siblingCandidates(
      layout.positions[s.id],
      layout.sizes[s.id],
      childSize,
    ),
    // Arc around the parent in the open gaps.
    ..._arcCandidates(parentCenter, parentSize, childSize, siblings, layout),
  ];

  Offset? best;
  var bestScore = double.negativeInfinity;

  for (final raw in candidates) {
    final center = _clampCenter(raw, childSize);
    final score = _score(center, childSize, parentCenter, obstacles);
    if (score > bestScore) {
      bestScore = score;
      best = center;
    }
  }

  var chosen = best ??
      Offset(
        parentCenter.dx + parentSize.width / 2 + kChildSpawnGap + childSize.width / 2,
        parentCenter.dy,
      );

  // If still overlapping, push outward from the parent until clear.
  chosen = _nudgeUntilClear(chosen, childSize, parentCenter, obstacles);
  return _clampCenter(chosen, childSize);
}

List<Offset> _siblingCandidates(Offset? center, Size? size, Size childSize) {
  if (center == null || size == null) return const [];
  final gap = kChildSpawnGap;
  return [
    Offset(
      center.dx + size.width / 2 + gap + childSize.width / 2,
      center.dy,
    ),
    Offset(
      center.dx,
      center.dy - size.height / 2 - gap - childSize.height / 2,
    ),
    Offset(
      center.dx,
      center.dy + size.height / 2 + gap + childSize.height / 2,
    ),
  ];
}

List<Offset> _arcCandidates(
  Offset parentCenter,
  Size parentSize,
  Size childSize,
  List<MindMapNode> siblings,
  LayoutResult layout,
) {
  final radius = parentSize.longestSide / 2 +
      kChildSpawnGap +
      childSize.longestSide / 2 +
      8;

  // Prefer right hemisphere; fill largest angular gaps between siblings.
  final angles = <double>[0, -0.4, 0.4, -0.8, 0.8, -1.2, 1.2, pi / 2, -pi / 2];
  if (siblings.isNotEmpty) {
    final siblingAngles = <double>[];
    for (final s in siblings) {
      final p = layout.positions[s.id];
      if (p == null) continue;
      siblingAngles.add(atan2(p.dy - parentCenter.dy, p.dx - parentCenter.dx));
    }
    siblingAngles.sort();
    if (siblingAngles.length >= 2) {
      for (var i = 0; i < siblingAngles.length; i++) {
        final a = siblingAngles[i];
        final b = siblingAngles[(i + 1) % siblingAngles.length];
        var gap = b - a;
        if (gap <= 0) gap += 2 * pi;
        angles.add(a + gap / 2);
      }
    } else if (siblingAngles.length == 1) {
      angles.add(siblingAngles.first + 0.9);
      angles.add(siblingAngles.first - 0.9);
    }
  }

  return [
    for (final a in angles)
      Offset(
        parentCenter.dx + cos(a) * radius,
        parentCenter.dy + sin(a) * radius,
      ),
  ];
}

double _score(
  Offset center,
  Size childSize,
  Offset parentCenter,
  List<Rect> obstacles,
) {
  final box = Rect.fromCenter(
    center: center,
    width: childSize.width,
    height: childSize.height,
  );

  for (final o in obstacles) {
    if (box.inflate(kChildSpawnGap / 2).overlaps(o.inflate(kChildSpawnGap / 2))) {
      return -1e9;
    }
  }

  final distParent = (center - parentCenter).distance;
  // Prefer being roughly one box away, not on top and not too far.
  final ideal = 120.0;
  final parentScore = -((distParent - ideal).abs());

  var nearSibling = 0.0;
  if (obstacles.length > 1) {
    var minD = double.infinity;
    for (var i = 1; i < obstacles.length; i++) {
      final d = (center - obstacles[i].center).distance;
      if (d < minD) minD = d;
    }
    // Prefer clustering with siblings without requiring exact distance.
    nearSibling = -min(minD, 400) * 0.35;
  }

  // Mild bias to the right of the parent (classic mind-map growth).
  final rightBias = (center.dx - parentCenter.dx).clamp(-80.0, 160.0) * 0.15;

  return parentScore + nearSibling + rightBias;
}

Offset _nudgeUntilClear(
  Offset start,
  Size childSize,
  Offset parentCenter,
  List<Rect> obstacles,
) {
  var center = start;
  final dir = center - parentCenter;
  final step = dir.distance < 1
      ? const Offset(24, 0)
      : Offset.fromDirection(dir.direction, 24);

  for (var i = 0; i < 40; i++) {
    final box = Rect.fromCenter(
      center: center,
      width: childSize.width,
      height: childSize.height,
    );
    final hits = obstacles.any(
      (o) =>
          box.inflate(kChildSpawnGap / 2).overlaps(o.inflate(kChildSpawnGap / 2)),
    );
    if (!hits) return center;
    center += step;
  }
  return center;
}

Offset _clampCenter(Offset center, Size childSize) {
  final halfW = childSize.width / 2;
  final halfH = childSize.height / 2;
  return Offset(
    center.dx.clamp(halfW, kCanvasSize - halfW),
    center.dy.clamp(halfH, kCanvasSize - halfH),
  );
}

Size _estimateNewIdeaSize(MindMap map) {
  final painter = TextPainter(
    text: TextSpan(text: 'New idea', style: nodeTextStyle(false)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: nodeMaxLines(false),
  )..layout(maxWidth: double.infinity);
  final w = (painter.width + kTextWidthFudge)
      .ceilToDouble()
      .clamp(kMinNodeTextWidth, kMaxNodeTextWidth);
  final h = max(painter.height.ceilToDouble() + 1, kMinNodeTextHeight);
  painter.dispose();
  return Size(
    w + kTextSpare * map.nodePadding,
    h + kTextSpare * map.nodePadding,
  );
}
