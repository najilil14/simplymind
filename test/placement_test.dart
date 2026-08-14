import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/layout/child_placement.dart';
import 'package:simplymind/layout/layout_engine.dart';
import 'package:simplymind/models/mind_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first child spawns to the right of the parent without overlap', () {
    final map = MindMap.create(title: 'Root', centerX: 3000, centerY: 3000);
    final root = map.root!;
    final spawn = findChildSpawnPosition(map, root.id);
    final layout = computeLayout(map);
    final parentBox = Rect.fromCenter(
      center: layout.positions[root.id]!,
      width: layout.sizes[root.id]!.width,
      height: layout.sizes[root.id]!.height,
    );

    expect(spawn.dx, greaterThan(root.x));
    final childBox = Rect.fromCenter(
      center: spawn,
      width: 80,
      height: 40,
    );
    expect(
      childBox.inflate(kChildSpawnGap / 2).overlaps(parentBox.inflate(kChildSpawnGap / 2)),
      isFalse,
    );
  });

  test('second child avoids overlapping the first sibling', () {
    final map = MindMap.create(title: 'Root', centerX: 3000, centerY: 3000);
    final root = map.root!;
    final first = MindMapNode(
      id: 'a',
      text: 'Sibling',
      x: 3300,
      y: 3000,
      color: kNodePalette[1],
      parentId: root.id,
    );
    map.nodes.add(first);

    final spawn = findChildSpawnPosition(map, root.id);
    final layout = computeLayout(map);
    final siblingBox = Rect.fromCenter(
      center: layout.positions['a']!,
      width: layout.sizes['a']!.width,
      height: layout.sizes['a']!.height,
    );
    final parentBox = Rect.fromCenter(
      center: layout.positions[root.id]!,
      width: layout.sizes[root.id]!.width,
      height: layout.sizes[root.id]!.height,
    );
    final childBox = Rect.fromCenter(center: spawn, width: 90, height: 44);

    expect(
      childBox.inflate(kChildSpawnGap / 2).overlaps(siblingBox.inflate(kChildSpawnGap / 2)),
      isFalse,
    );
    expect(
      childBox.inflate(kChildSpawnGap / 2).overlaps(parentBox.inflate(kChildSpawnGap / 2)),
      isFalse,
    );
    // Stays in the family neighborhood, not across the canvas.
    expect((spawn - Offset(root.x, root.y)).distance, lessThan(500));
  });

  test('wide parent uses live width so child clears the box', () {
    final map = MindMap.create(
      title: 'A very long root title that stretches the box',
      centerX: 3000,
      centerY: 3000,
    );
    final root = map.root!;
    final layout = computeLayout(map);
    final parentW = layout.sizes[root.id]!.width;
    expect(parentW, greaterThan(map.nodeWidth));

    final spawn = findChildSpawnPosition(map, root.id);
    final parentRight = root.x + parentW / 2;
    expect(spawn.dx, greaterThan(parentRight));
  });
}
