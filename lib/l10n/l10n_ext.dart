import '../l10n/app_localizations.dart';
import '../models/mind_map.dart';
import '../templates/map_starters.dart';

extension L10nLabels on AppLocalizations {
  String layoutLabel(MindMapLayout layout) => switch (layout) {
        MindMapLayout.map => layoutMap,
        MindMapLayout.list => layoutList,
        MindMapLayout.step => layoutStep,
        MindMapLayout.graph => layoutGraph,
      };

  String layoutDescription(MindMapLayout layout) => switch (layout) {
        MindMapLayout.map => layoutMapDesc,
        MindMapLayout.list => layoutListDesc,
        MindMapLayout.step => layoutStepDesc,
        MindMapLayout.graph => layoutGraphDesc,
      };

  String statusLabel(NodeStatus status) => switch (status) {
        NodeStatus.none => statusNone,
        NodeStatus.inProgress => statusInProgress,
        NodeStatus.done => statusDone,
      };

  String themeLabel(String key) => switch (key) {
        'vivid' => themeVivid,
        'pastel' => themePastel,
        'earth' => themeEarth,
        _ => key,
      };

  String nodesLabel(int count) =>
      count == 1 ? nodeCount(count) : nodeCountPlural(count);

  String starterLabel(MapStarter starter) => switch (starter) {
        MapStarter.blank => starterBlank,
        MapStarter.prd => starterPrd,
        MapStarter.entities => starterEntities,
      };

  String starterDescription(MapStarter starter) => switch (starter) {
        MapStarter.blank => starterBlankDesc,
        MapStarter.prd => starterPrdDesc,
        MapStarter.entities => starterEntitiesDesc,
      };
}
