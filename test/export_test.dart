import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/models/mind_map.dart';
import 'package:simplymind/utils/map_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MindMap sampleMap() {
    final map = MindMap.create(
      title: 'Export demo',
      centerX: 3000,
      centerY: 3000,
      layout: MindMapLayout.map,
    );
    final rootId = map.root!.id;
    final a = MindMapNode(
      id: newId(),
      text: 'Branch A',
      x: 3260,
      y: 2900,
      color: kNodePalette[1],
      parentId: rootId,
      status: NodeStatus.done,
    );
    final b = MindMapNode(
      id: newId(),
      text: 'Branch B',
      x: 3260,
      y: 3100,
      color: kNodePalette[2],
      parentId: rootId,
      status: NodeStatus.inProgress,
    );
    map.nodes.addAll([a, b]);
    map.links.add(
      MindMapLink(
        id: newId(),
        fromId: a.id,
        toId: b.id,
        label: 'depends on',
        cardinality: 'N:1',
      ),
    );
    return map;
  }

  test('renderPng returns a non-empty PNG for a sample map', () async {
    final bytes = await MapExporter.renderPng(sampleMap());
    expect(bytes.length, greaterThan(100));
    // PNG magic number
    expect(bytes.sublist(0, 8),
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]));
  });

  test('renderPdf returns a non-empty PDF for a sample map', () async {
    final bytes = await MapExporter.renderPdf(sampleMap());
    expect(bytes.length, greaterThan(100));
    // PDF header
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
