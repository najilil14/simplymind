import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:simplymind/layout/layout_engine.dart';
import 'package:simplymind/models/mind_map.dart';
import 'package:simplymind/state/editor_controller.dart';
import 'package:simplymind/storage/mind_map_storage.dart';

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

Rect _rectOf(LayoutResult result, String id) => Rect.fromCenter(
    center: result.positions[id]!,
    width: result.sizes[id]!.width,
    height: result.sizes[id]!.height);

double _leftEdge(LayoutResult result, String id) =>
    result.positions[id]!.dx - result.sizes[id]!.width / 2;

void _expectNoOverlaps(LayoutResult result, MindMap map) {
  final ids = result.positions.keys.toList();
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      final a = _rectOf(result, ids[i]).deflate(1);
      final b = _rectOf(result, ids[j]).deflate(1);
      expect(a.overlaps(b), isFalse,
          reason: '${ids[i]} overlaps ${ids[j]}');
    }
  }
}

void main() {
  // Text measurement (node auto-sizing) needs the test rendering bindings.
  TestWidgetsFlutterBinding.ensureInitialized();

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
    final rootId = map.root!.id;

    // Children's left edges align, indented 44 from the parent's left edge.
    for (final id in ['a', 'b', 'c']) {
      expect(_leftEdge(result, id) - _leftEdge(result, rootId), 44,
          reason: 'children indent right of the root');
    }
    expect(result.positions['a']!.dy, lessThan(result.positions['b']!.dy));
    expect(result.positions['b']!.dy, lessThan(result.positions['c']!.dy));
    // Grandchild indents one level further.
    expect(_leftEdge(result, 'a1') - _leftEdge(result, 'a'), 44);
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
    final before = computeLayout(map).sizes['a']!;

    map.nodePadding = 20;
    final after = computeLayout(map).sizes['a']!;
    expect(after.width, before.width + 2 * (20 - kDefaultNodePadding));
    expect(after.height, before.height + 2 * (20 - kDefaultNodePadding));

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

  test('node box grows with its text, capped at the max width', () {
    final map = _tree(MindMapLayout.map);
    final short = computeLayout(map).sizes['a']!;

    map.nodeById('a')!.text =
        'a much longer node label that should wrap onto several lines';
    final long = computeLayout(map).sizes['a']!;

    expect(long.width, greaterThan(short.width));
    expect(long.width,
        lessThanOrEqualTo(
            kMaxNodeTextWidth + kTextWidthFudge + 2 * map.nodePadding + 1));
    expect(long.height, greaterThan(short.height),
        reason: 'wrapped text should make the box taller');
    // Layouts still resolve without overlaps with mixed box sizes.
    map.layout = MindMapLayout.list;
    _expectNoOverlaps(computeLayout(map), map);
    map.layout = MindMapLayout.step;
    _expectNoOverlaps(computeLayout(map), map);
  });

  test('"New idea" fits on one line without clipping', () {
    final map = _tree(MindMapLayout.map);
    map.nodeById('a')!.text = 'New idea';
    final size = computeLayout(map).sizes['a']!;
    final textWidth = size.width - 2 * map.nodePadding;

    // Must be wider than a single short word; otherwise "idea" would wrap
    // out of a one-line-tall box and disappear.
    expect(textWidth, greaterThan(56));
    expect(size.height, lessThan(kMinNodeTextHeight + 20),
        reason: 'short two-word labels should stay on one line');
  });

  test('long root text gets a wider box and is never cut by width', () {
    final map = _tree(MindMapLayout.map);
    map.root!.text = List.filled(20, 'topic').join(' '); // ~119 chars
    final sizes = computeLayout(map).sizes;
    final rootWidth = sizes[map.root!.id]!.width;

    expect(rootWidth, greaterThan(kMaxNodeTextWidth),
        reason: 'the root may grow wider than regular nodes');
    expect(rootWidth,
        lessThanOrEqualTo(
            kMaxRootTextWidth + kTextWidthFudge + 2 * map.nodePadding + 1));
    expect(sizes[map.root!.id]!.height,
        greaterThan(sizes['a']!.height * 2),
        reason: 'long root text wraps onto multiple lines');
  });

  test('reparent attaches under a new parent; cannot create cycles', () {
    SharedPreferences.setMockInitialValues({});
    final map = _tree(MindMapLayout.list);
    final controller = EditorController(map: map, storage: MindMapStorage());
    final rootId = map.root!.id;

    // a1 is under a; reparent onto b → sibling of a under different branch.
    expect(controller.canReparent('a1', 'b'), isTrue);
    controller.reparent('a1', 'b');
    expect(map.nodeById('a1')!.parentId, 'b');

    // Cannot attach a under its own descendant.
    expect(controller.canReparent('b', 'a1'), isFalse);

    // Promote a1 (now under b) to root → sibling of b.
    expect(controller.canPromote('a1'), isTrue);
    controller.promote('a1');
    expect(map.nodeById('a1')!.parentId, rootId);

    // Root's children cannot promote further.
    expect(controller.canPromote('a'), isFalse);
    final before = map.nodeById('a')!.parentId;
    controller.promote('a');
    expect(map.nodeById('a')!.parentId, before);

    controller.dispose();
  });

  test('node status round-trips through JSON; missing means none', () {
    final map = _tree(MindMapLayout.map);
    map.nodeById('a')!.status = NodeStatus.done;
    map.nodeById('b')!.status = NodeStatus.inProgress;

    final restored = MindMap.decode(map.encode());
    expect(restored.nodeById('a')!.status, NodeStatus.done);
    expect(restored.nodeById('b')!.status, NodeStatus.inProgress);
    expect(restored.nodeById('c')!.status, NodeStatus.none);

    final legacy = MindMap.decode(
        '{"id":"m","title":"t","nodes":[{"id":"r","text":"r","x":1,"y":2}]}');
    expect(legacy.root!.status, NodeStatus.none);
  });

  test('colorTheme round-trips through JSON, unknown values fall back', () {
    final map = _tree(MindMapLayout.map);
    map.colorTheme = 'earth';
    expect(MindMap.decode(map.encode()).colorTheme, 'earth');

    final bad = MindMap.decode(
        '{"id":"m","title":"t","colorTheme":"neon","nodes":[]}');
    expect(bad.colorTheme, 'pastel');
  });

  test('switching color theme remaps node colors by palette position', () {
    SharedPreferences.setMockInitialValues({});
    final map = _tree(MindMapLayout.map);
    final controller = EditorController(map: map, storage: MindMapStorage());
    map.root!.color = kColorThemes['pastel']![0];
    map.nodeById('a')!.color = kColorThemes['pastel']![3];
    map.nodeById('b')!.color = 0xFF123456; // custom color

    controller.setColorTheme('vivid');
    expect(map.colorTheme, 'vivid');
    expect(map.root!.color, kColorThemes['vivid']![0]);
    expect(map.nodeById('a')!.color, kColorThemes['vivid']![3]);
    expect(map.nodeById('b')!.color, 0xFF123456,
        reason: 'custom colors survive theme switches');

    controller.undo();
    expect(map.colorTheme, 'pastel');
    expect(map.nodeById('a')!.color, kColorThemes['pastel']![3]);
    controller.dispose();
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
