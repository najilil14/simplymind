import 'package:flutter_test/flutter_test.dart';

import 'package:simplymind/models/mind_map.dart';

void main() {
  test('mind map serializes to JSON and back losslessly', () {
    final map = MindMap.create(title: 'Test', centerX: 100, centerY: 200);
    final child = MindMapNode(
      id: newId(),
      text: 'Child idea',
      x: 300,
      y: 250,
      color: kNodePalette[2],
      parentId: map.root!.id,
    );
    map.nodes.add(child);
    map.links.add(
      MindMapLink(
        id: 'link-1',
        fromId: map.root!.id,
        toId: child.id,
        label: 'relates to',
        cardinality: '1:N',
      ),
    );

    final restored = MindMap.decode(map.encode(pretty: true));

    expect(restored.id, map.id);
    expect(restored.title, 'Test');
    expect(restored.nodes.length, 2);
    expect(restored.root!.text, 'Test');
    expect(restored.childrenOf(map.root!.id).single.text, 'Child idea');
    expect(restored.nodeById(child.id)!.color, kNodePalette[2]);
    expect(restored.links, hasLength(1));
    expect(restored.links.single.label, 'relates to');
    expect(restored.links.single.cardinality, '1:N');
    expect(restored.linksFor(child.id).single.id, 'link-1');
  });

  test('old JSON without links defaults to an empty relation list', () {
    final map = MindMap.create(title: 'Old', centerX: 0, centerY: 0);
    final json = map.toJson()..remove('links');
    final restored = MindMap.fromJson(json);
    expect(restored.links, isEmpty);
  });

  test('subtreeIds returns node and all descendants', () {
    final map = MindMap.create(title: 'Root', centerX: 0, centerY: 0);
    final rootId = map.root!.id;
    final a = MindMapNode(
        id: 'a', text: 'a', x: 0, y: 0, color: 0, parentId: rootId);
    final b = MindMapNode(id: 'b', text: 'b', x: 0, y: 0, color: 0, parentId: 'a');
    final c = MindMapNode(id: 'c', text: 'c', x: 0, y: 0, color: 0, parentId: 'b');
    final other = MindMapNode(
        id: 'x', text: 'x', x: 0, y: 0, color: 0, parentId: rootId);
    map.nodes.addAll([a, b, c, other]);

    expect(map.subtreeIds('a'), {'a', 'b', 'c'});
    expect(map.subtreeIds(rootId), {rootId, 'a', 'b', 'c', 'x'});
  });
}
