import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/l10n/app_localizations.dart';
import 'package:simplymind/models/mind_map.dart';
import 'package:simplymind/templates/map_starters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  MindMap blank({MindMapLayout layout = MindMapLayout.map}) => MindMap.create(
        title: 'Checkout',
        centerX: 3000,
        centerY: 3000,
        layout: layout,
      );

  test('blank starter leaves a single root', () {
    final map = blank();
    applyMapStarter(map, MapStarter.blank, l10n);
    expect(map.nodes, hasLength(1));
    expect(map.root!.text, 'Checkout');
  });

  test('PRD starter seeds outline sections under the root', () {
    final map = blank(layout: MindMapLayout.list);
    applyMapStarter(map, MapStarter.prd, l10n);
    final root = map.root!;
    final top = map.childrenOf(root.id).map((n) => n.text).toList();
    expect(top, containsAll([
      l10n.prdProblem,
      l10n.prdGoals,
      l10n.prdUsers,
      l10n.prdRequirements,
      l10n.prdScope,
      l10n.prdMetrics,
      l10n.prdQuestions,
    ]));
    final goals = map.childrenOf(root.id).firstWhere((n) => n.text == l10n.prdGoals);
    expect(map.childrenOf(goals.id).single.text, l10n.prdGoalExample);
    expect(map.nodes.length, greaterThan(10));
  });

  test('entities starter uses list layout on entity nodes', () {
    final map = blank(layout: MindMapLayout.graph);
    applyMapStarter(map, MapStarter.entities, l10n);
    final root = map.root!;
    final entities = map.childrenOf(root.id);
    expect(entities.map((n) => n.text), containsAll([
      l10n.entityUser,
      l10n.entityAccount,
      l10n.entityOrder,
      l10n.entityProduct,
    ]));
    for (final e in entities) {
      expect(e.layout, MindMapLayout.list);
      expect(map.childrenOf(e.id), isNotEmpty);
    }
    final user = entities.firstWhere((n) => n.text == l10n.entityUser);
    expect(
      map.childrenOf(user.id).map((n) => n.text),
      containsAll([l10n.attrId, l10n.attrName, l10n.attrEmail]),
    );
    expect(map.links, hasLength(3));
    expect(
      map.links.map((l) => l.cardinality),
      containsAll(<String>['N:1', 'N:1', 'N:N']),
    );
  });

  test('suggested layouts match starter intent', () {
    expect(suggestedLayoutFor(MapStarter.blank), MindMapLayout.map);
    expect(suggestedLayoutFor(MapStarter.prd), MindMapLayout.list);
    expect(suggestedLayoutFor(MapStarter.entities), MindMapLayout.graph);
  });
}
