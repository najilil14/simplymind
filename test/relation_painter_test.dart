import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/layout/relation_painter.dart';
import 'package:simplymind/models/mind_map.dart';

void main() {
  test('relation joins box edges and bends away from center line', () {
    const from = Rect.fromLTWH(0, 0, 100, 60);
    const to = Rect.fromLTWH(300, 40, 120, 80);
    final geometry = computeRelationGeometry(from, to)!;

    expect(
      (geometry.from.dx - from.left).abs() < 0.001 ||
          (geometry.from.dx - from.right).abs() < 0.001 ||
          (geometry.from.dy - from.top).abs() < 0.001 ||
          (geometry.from.dy - from.bottom).abs() < 0.001,
      isTrue,
    );
    expect(
      (geometry.to.dx - to.left).abs() < 0.001 ||
          (geometry.to.dx - to.right).abs() < 0.001 ||
          (geometry.to.dy - to.top).abs() < 0.001 ||
          (geometry.to.dy - to.bottom).abs() < 0.001,
      isTrue,
    );
    expect(
      geometry.control,
      isNot(Offset.lerp(geometry.from, geometry.to, 0.5)),
    );
  });

  test('parent-child relation is redundant with the solid tree edge', () {
    final map = MindMap.create(title: 'Root', centerX: 0, centerY: 0);
    final child = MindMapNode(
      id: 'child',
      text: 'Child',
      x: 100,
      y: 0,
      color: 0,
      parentId: map.root!.id,
    );
    final other = MindMapNode(
      id: 'other',
      text: 'Other',
      x: 200,
      y: 0,
      color: 0,
      parentId: map.root!.id,
    );
    map.nodes.addAll([child, other]);

    expect(
      isTreeRelationPair(
        map,
        MindMapLink(
          id: 'tree',
          fromId: map.root!.id,
          toId: child.id,
        ),
      ),
      isTrue,
    );
    expect(
      isTreeRelationPair(
        map,
        MindMapLink(id: 'extra', fromId: child.id, toId: other.id),
      ),
      isFalse,
    );
  });
}
