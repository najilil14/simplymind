import 'dart:convert';
import 'dart:math';

final Random _rand = Random();

/// Compact unique id: microsecond timestamp + random salt, base36.
String newId() {
  final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = _rand.nextInt(1 << 30).toRadixString(36);
  return '$ts-$salt';
}

/// Template modes controlling how a map (or a subtree) is laid out.
enum MindMapLayout {
  /// Free-form canvas: nodes keep their manually dragged x/y positions.
  map,

  /// Outline: children stacked vertically, indented by depth.
  list,

  /// Sequential flow: siblings are numbered steps connected by arrows.
  step,

  /// Radial auto-layout: branches spread in a circle around the parent.
  graph;

  static MindMapLayout fromName(String? name) => MindMapLayout.values
      .firstWhere((e) => e.name == name, orElse: () => MindMapLayout.map);

  String get label => switch (this) {
        MindMapLayout.map => 'Map',
        MindMapLayout.list => 'List',
        MindMapLayout.step => 'Step',
        MindMapLayout.graph => 'Graph',
      };
}

/// Text content area of a node card, excluding the padding around it.
const double kNodeContentWidth = 154;
const double kNodeContentHeight = 48;

/// Padding between the node text and the box border, user-adjustable per map.
const double kDefaultNodePadding = 8;
const double kMinNodePadding = 2;
const double kMaxNodePadding = 28;

/// Default colors offered for nodes (ARGB).
const List<int> kNodePalette = <int>[
  0xFF4F6DF5, // indigo
  0xFF00A896, // teal
  0xFF6A994E, // green
  0xFFF4A261, // orange
  0xFFE76F51, // coral
  0xFFEF476F, // pink
  0xFF9B5DE5, // purple
  0xFF0096C7, // blue
  0xFF5C677D, // slate
];

class MindMapNode {
  MindMapNode({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.parentId,
    this.layout,
  });

  final String id;
  String text;

  /// Center position of the node in canvas coordinates.
  double x;
  double y;

  /// ARGB color value.
  int color;

  /// Null for the root node.
  String? parentId;

  /// Optional template override for this node's subtree. When null the mode
  /// is inherited from the nearest ancestor override, or the map itself.
  MindMapLayout? layout;

  factory MindMapNode.fromJson(Map<String, dynamic> json) => MindMapNode(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        color: json['color'] as int? ?? kNodePalette.first,
        parentId: json['parentId'] as String?,
        layout: json['layout'] == null
            ? null
            : MindMapLayout.fromName(json['layout'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'color': color,
        'parentId': parentId,
        if (layout != null) 'layout': layout!.name,
      };

  MindMapNode copy() => MindMapNode(
      id: id,
      text: text,
      x: x,
      y: y,
      color: color,
      parentId: parentId,
      layout: layout);
}

class MindMap {
  MindMap({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.nodes,
    this.layout = MindMapLayout.map,
    this.nodePadding = kDefaultNodePadding,
  });

  final String id;
  String title;
  DateTime updatedAt;
  final List<MindMapNode> nodes;

  /// Template mode for the whole map (nodes may override per subtree).
  MindMapLayout layout;

  /// Padding between node text and the node box, in canvas pixels.
  double nodePadding;

  /// Node box dimensions derived from the padding setting.
  double get nodeWidth => kNodeContentWidth + 2 * nodePadding;
  double get nodeHeight => kNodeContentHeight + 2 * nodePadding;

  /// Creates a new map with a single root node at the canvas center.
  factory MindMap.create({
    required String title,
    required double centerX,
    required double centerY,
    MindMapLayout layout = MindMapLayout.map,
    double nodePadding = kDefaultNodePadding,
  }) {
    return MindMap(
      id: newId(),
      title: title,
      updatedAt: DateTime.now(),
      layout: layout,
      nodePadding: nodePadding,
      nodes: <MindMapNode>[
        MindMapNode(
          id: newId(),
          text: title,
          x: centerX,
          y: centerY,
          color: kNodePalette.first,
        ),
      ],
    );
  }

  factory MindMap.fromJson(Map<String, dynamic> json) => MindMap(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Untitled',
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        layout: MindMapLayout.fromName(json['layout'] as String?),
        nodePadding:
            ((json['nodePadding'] as num?)?.toDouble() ?? kDefaultNodePadding)
                .clamp(kMinNodePadding, kMaxNodePadding),
        nodes: (json['nodes'] as List<dynamic>? ?? const [])
            .map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'layout': layout.name,
        'nodePadding': nodePadding,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };

  String encode({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  static MindMap decode(String source) =>
      MindMap.fromJson(jsonDecode(source) as Map<String, dynamic>);

  MindMapNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  MindMapNode? get root {
    for (final n in nodes) {
      if (n.parentId == null) return n;
    }
    return null;
  }

  List<MindMapNode> childrenOf(String id) =>
      nodes.where((n) => n.parentId == id).toList();

  /// Ids of [id] and all of its descendants.
  Set<String> subtreeIds(String id) {
    final result = <String>{id};
    var added = true;
    while (added) {
      added = false;
      for (final n in nodes) {
        if (n.parentId != null &&
            result.contains(n.parentId) &&
            result.add(n.id)) {
          added = true;
        }
      }
    }
    return result;
  }

  MindMap copy({String? newMapId}) => MindMap(
        id: newMapId ?? id,
        title: title,
        updatedAt: updatedAt,
        layout: layout,
        nodePadding: nodePadding,
        nodes: nodes.map((n) => n.copy()).toList(),
      );
}
