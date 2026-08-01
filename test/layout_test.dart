import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:simplymind/layout/layout_engine.dart';
import 'package:simplymind/models/mind_map.dart';

MindMap _tree(MindMapLayout layout) {
  final map = MindMap.create(
      title: 'Root', centerX: 3000, centerY: 3000, layout: layout);
  final rootId = map.root!.id;
  map.nodes.addAll([
    MindMapNode(id: 'a', text: 'a', x: 0, y: 0, color: 1, parentId: rootId),
    MindMapNode(id: 'b', text: 'b', x: 0, y: 0, color: 1, parentId: rootId),
    MindMapNode(id: 'c', text: 'c', x: 0, y: 0, color: 1, parentId: rootId),
    MindMapNode(id: 'a1', text: 'a1', x: 0, y: 0, color: 1, parentId: 'a'),
  ]);
  return map;
}

Rect _rectAt(Offset center, MindMap map) => Rect.fromCenter(
    center: center, width: map.nodeWidth, height: map.nodeHeight);

void _expectNoOverlaps(LayoutResult result, MindMap map) {
  final entries = result.positions.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = _rectAt(entries[i].value, map).deflate(1);
      final b = _rectAt(entries[j].value, map).deflate(1);
      expect(a.overlaps(b), isFalse,
          reason: '${entries[i].key} overlaps ${entries[j].key}');
    }
  }
}

void main() {
  test('layout serializes to JSON and back, including node overrides', () {
    final map = _tree(MindMapLayout.step);
    map.nodeById('a')!.layout = MindMapLayout.list;

    final restored = MindMap.decode(map.encode());

    expect(restored.layout, MindMapLayout.step);
    expect(restored.nodeById('a')!.layout, MindMapLayout.list);
    expect(restored.nodeById('b')!.layout, isNull);
  });

  test('maps without a layout field default to map mode', () {
    final restored = MindMap.decode(
        '{"id":"m","title":"t","nodes":[{"id":"r","text":"r","x":1,"y":2}]}');
    expect(restored.layout, MindMapLayout.map);
    expect(restored.root!.layout, isNull);
  });

  test('list mode stacks children top to bottom in sibling order', () {
    final map = _tree(MindMapLayout.list);
    final result = computeLayout(map);
    final root = map.root!;

    for (final id in ['a', 'b', 'c']) {
      expect(result.positions[id]!.dx, root.x + 56,
          reason: 'children indent right of the root');
    }
    expect(result.positions['a']!.dy, lessThan(result.positions['b']!.dy));
    expect(result.positions['b']!.dy, lessThan(result.positions['c']!.dy));
    // Grandchild indents one level further.
    expect(result.positions['a1']!.dx, root.x + 112);
    _expectNoOverlaps(result, map);
  });

  test('step mode numbers siblings and lays them out left to right', () {
    final map = _tree(MindMapLayout.step);
    final result = computeLayout(map);
    final root = map.root!;

    expect(result.stepNumber['a'], 1);
    expect(result.stepNumber['b'], 2);
    expect(result.stepNumber['c'], 3);
    expect(result.positions['a']!.dx, lessThan(result.positions['b']!.dx));
    expect(result.positions['b']!.dx, lessThan(result.positions['c']!.dx));
    for (final id in ['a', 'b', 'c']) {
      expect(result.positions[id]!.dy, greaterThan(root.y),
          reason: 'steps flow below the parent');
    }
    _expectNoOverlaps(result, map);
  });

  test('graph mode places children on a circle around the parent', () {
    final map = _tree(MindMapLayout.graph);
    final result = computeLayout(map);
    final rootPos = result.positions[map.root!.id]!;

    for (final id in ['a', 'b', 'c']) {
      final d = (result.positions[id]! - rootPos).distance;
      expect(d, closeTo(250, 0.01));
    }
    _expectNoOverlaps(result, map);
  });

  test('auto modes reposition while map mode keeps stored coordinates', () {
    final map = _tree(MindMapLayout.map);
    map.nodeById('a')!
      ..x = 3200
      ..y = 2900;
    final result = computeLayout(map);
    expect(result.positions['a'], const Offset(3200, 2900));
    expect(result.placedBy['a'], MindMapLayout.map);

    map.layout = MindMapLayout.list;
    final auto = computeLayout(map);
    expect(auto.placedBy['a'], MindMapLayout.list);
    expect(auto.positions['a'], isNot(const Offset(3200, 2900)));
  });

  test('a node override changes layout for its subtree only', () {
    final map = _tree(MindMapLayout.list);
    map.nodeById('a')!.layout = MindMapLayout.step;
    final result = computeLayout(map);

    expect(result.childrenModeOf[map.root!.id], MindMapLayout.list);
    expect(result.childrenModeOf['a'], MindMapLayout.step);
    expect(result.stepNumber['a1'], 1);
    expect(result.placedBy['a'], MindMapLayout.list);
    expect(result.placedBy['a1'], MindMapLayout.step);
  });

  test('nodePadding round-trips through JSON and resizes nodes', () {
    final map = _tree(MindMapLayout.map);
    expect(map.nodeWidth, 170);
    expect(map.nodeHeight, 64);

    map.nodePadding = 20;
    expect(map.nodeWidth, kNodeContentWidth + 40);
    expect(map.nodeHeight, kNodeContentHeight + 40);

    final restored = MindMap.decode(map.encode());
    expect(restored.nodePadding, 20);

    // Legacy JSON without the field falls back to the default.
    final legacy = MindMap.decode(
        '{"id":"m","title":"t","nodes":[{"id":"r","text":"r","x":1,"y":2}]}');
    expect(legacy.nodePadding, kDefaultNodePadding);
  });

  test('larger padding spreads auto layouts apart without overlaps', () {
    final map = _tree(MindMapLayout.list);
    final before = computeLayout(map);
    final gapBefore =
        before.positions['b']!.dy - before.positions['a']!.dy;

    map.nodePadding = kMaxNodePadding;
    final after = computeLayout(map);
    final gapAfter = after.positions['b']!.dy - after.positions['a']!.dy;

    expect(gapAfter, greaterThan(gapBefore));
    _expectNoOverlaps(after, map);
  });

  test('sibling order in the nodes array drives list order', () {
    final map = _tree(MindMapLayout.list);
    final before = computeLayout(map);
    expect(before.positions['a']!.dy, lessThan(before.positions['b']!.dy));

    // Swap a and b in the nodes array, as EditorController.reorderSibling does.
    final ia = map.nodes.indexWhere((n) => n.id == 'a');
    final ib = map.nodes.indexWhere((n) => n.id == 'b');
    final tmp = map.nodes[ia];
    map.nodes[ia] = map.nodes[ib];
    map.nodes[ib] = tmp;

    final after = computeLayout(map);
    expect(after.positions['b']!.dy, lessThan(after.positions['a']!.dy));
  });
}
