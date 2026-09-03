import '../l10n/app_localizations.dart';
import '../layout/child_placement.dart';
import '../models/mind_map.dart';

/// Content starter applied when creating a map. Independent of [MindMapLayout].
enum MapStarter {
  /// Root node only.
  blank,

  /// Product requirements outline under the root.
  prd,

  /// Sample entities with attributes (relational sketch, still a tree).
  entities,
}

/// Suggested layout when the user first picks a starter (they can still change it).
MindMapLayout suggestedLayoutFor(MapStarter starter) => switch (starter) {
      MapStarter.blank => MindMapLayout.map,
      MapStarter.prd => MindMapLayout.list,
      MapStarter.entities => MindMapLayout.graph,
    };

/// Seeds [map] with starter nodes. [blank] is a no-op.
///
/// Children get free positions via [findChildSpawnPosition] so map mode does
/// not stack them. Auto layouts ignore those coordinates.
void applyMapStarter(MindMap map, MapStarter starter, AppLocalizations l10n) {
  final root = map.root;
  if (root == null || starter == MapStarter.blank) return;

  switch (starter) {
    case MapStarter.blank:
      return;
    case MapStarter.prd:
      _seedPrd(map, root, l10n);
    case MapStarter.entities:
      _seedEntities(map, root, l10n);
  }
}

void _seedPrd(MindMap map, MindMapNode root, AppLocalizations l10n) {
  _add(map, root.id, l10n.prdProblem);
  final goals = _add(map, root.id, l10n.prdGoals);
  _add(map, goals.id, l10n.prdGoalExample);
  final users = _add(map, root.id, l10n.prdUsers);
  _add(map, users.id, l10n.prdPersona);
  final reqs = _add(map, root.id, l10n.prdRequirements);
  _add(map, reqs.id, l10n.prdMustHave);
  _add(map, reqs.id, l10n.prdNiceToHave);
  final scope = _add(map, root.id, l10n.prdScope);
  _add(map, scope.id, l10n.prdInScope);
  _add(map, scope.id, l10n.prdOutOfScope);
  _add(map, root.id, l10n.prdMetrics);
  _add(map, root.id, l10n.prdQuestions);
}

void _seedEntities(MindMap map, MindMapNode root, AppLocalizations l10n) {
  final user = _add(
    map,
    root.id,
    l10n.entityUser,
    subtreeLayout: MindMapLayout.list,
  );
  _add(map, user.id, l10n.attrId);
  _add(map, user.id, l10n.attrName);
  _add(map, user.id, l10n.attrEmail);

  final account = _add(
    map,
    root.id,
    l10n.entityAccount,
    subtreeLayout: MindMapLayout.list,
  );
  _add(map, account.id, l10n.attrId);
  _add(map, account.id, l10n.attrUserId);
  _add(map, account.id, l10n.attrStatus);

  final order = _add(
    map,
    root.id,
    l10n.entityOrder,
    subtreeLayout: MindMapLayout.list,
  );
  _add(map, order.id, l10n.attrId);
  _add(map, order.id, l10n.attrAccountId);
  _add(map, order.id, l10n.attrTotal);
  _add(map, order.id, l10n.attrStatus);

  final product = _add(
    map,
    root.id,
    l10n.entityProduct,
    subtreeLayout: MindMapLayout.list,
  );
  _add(map, product.id, l10n.attrId);
  _add(map, product.id, l10n.attrName);
  _add(map, product.id, l10n.attrSku);
  _add(map, product.id, l10n.attrPrice);

  map.links.addAll([
    MindMapLink(
      id: newId(),
      fromId: account.id,
      toId: user.id,
      label: l10n.relationBelongsTo,
      cardinality: 'N:1',
    ),
    MindMapLink(
      id: newId(),
      fromId: order.id,
      toId: account.id,
      label: l10n.relationBelongsTo,
      cardinality: 'N:1',
    ),
    MindMapLink(
      id: newId(),
      fromId: order.id,
      toId: product.id,
      label: l10n.relationContains,
      cardinality: 'N:N',
    ),
  ]);
}

MindMapNode _add(
  MindMap map,
  String parentId,
  String text, {
  MindMapLayout? subtreeLayout,
}) {
  final parent = map.nodeById(parentId)!;
  final spawn = findChildSpawnPosition(map, parentId);
  final siblingCount = map.childrenOf(parentId).length;
  final palette = map.palette;
  var colorIndex = palette.indexOf(parent.color);
  if (colorIndex < 0) colorIndex = 0;
  final color = palette[(colorIndex + 1 + siblingCount) % palette.length];
  final node = MindMapNode(
    id: newId(),
    text: text,
    x: spawn.dx,
    y: spawn.dy,
    color: color,
    parentId: parentId,
    layout: subtreeLayout,
  );
  map.nodes.add(node);
  return node;
}
