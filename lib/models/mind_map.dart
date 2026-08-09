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

/// Default colors offered for nodes (ARGB): soft, modern pastels.
/// Text contrast is derived from the color's luminance, so maps using
/// darker saturated colors keep readable white text.
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

/// Selectable color themes. Each has 9 colors at matching palette positions,
/// so switching themes can remap node colors index-by-index.
const Map<String, List<int>> kColorThemes = <String, List<int>>{
  'vivid': kNodePalette,
  'pastel': <int>[
    0xFFAEC6FF, // soft periwinkle blue
    0xFF9EE7D8, // mint
    0xFFBBE5A6, // soft green
    0xFFFFD9A0, // apricot
    0xFFFFB3A7, // soft coral
    0xFFF8B8D0, // rose
    0xFFD5C4F9, // lavender
    0xFFA9E4EF, // sky
    0xFFD3DAE6, // mist grey
  ],
  'earth': <int>[
    0xFF8A9B8E, // sage
    0xFFC2B280, // sand
    0xFF97A97C, // moss
    0xFFD4A373, // amber tan
    0xFFB08968, // clay
    0xFFC98D83, // terracotta rose
    0xFFA58FAA, // dried lavender
    0xFF8FAAB3, // slate blue grey
    0xFFA9927D, // taupe
  ],
};

/// Progress marker shown on a node. [none] means no icon.
enum NodeStatus {
  none,
  inProgress,
  done;

  static NodeStatus fromName(String? name) => NodeStatus.values
      .firstWhere((e) => e.name == name, orElse: () => NodeStatus.none);

  String get label => switch (this) {
        NodeStatus.none => 'No status',
        NodeStatus.inProgress => 'In progress',
        NodeStatus.done => 'Done',
      };
}

class MindMapNode {
  MindMapNode({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.parentId,
    this.layout,
    this.status = NodeStatus.none,
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

  /// Optional progress status shown as an icon badge on the node.
  NodeStatus status;

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
        status: NodeStatus.fromName(json['status'] as String?),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'x': x,
        'y': y,
        'color': color,
        'parentId': parentId,
        if (layout != null) 'layout': layout!.name,
        if (status != NodeStatus.none) 'status': status.name,
      };

  MindMapNode copy() => MindMapNode(
      id: id,
      text: text,
      x: x,
      y: y,
      color: color,
      parentId: parentId,
      layout: layout,
      status: status);
}

/// Display name of the built-in default category. Maps with a null/empty
/// [MindMap.category] belong here.
const String kHomeCategory = 'Home';

/// Offer to create categories once the user has more maps than this.
const int kCategoryOfferThreshold = 17;

class MindMap {
  MindMap({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.nodes,
    this.layout = MindMapLayout.map,
    this.nodePadding = kDefaultNodePadding,
    this.colorTheme = 'pastel',
    this.category,
  });

  final String id;
  String title;
  DateTime updatedAt;
  final List<MindMapNode> nodes;

  /// Template mode for the whole map (nodes may override per subtree).
  MindMapLayout layout;

  /// Padding between node text and the node box, in canvas pixels.
  double nodePadding;

  /// Key into [kColorThemes]; determines the palette offered for new nodes.
  String colorTheme;

  /// Custom category name. Null or empty means [kHomeCategory].
  String? category;

  /// Effective category label for display and filtering.
  String get categoryOrHome {
    final c = category?.trim();
    if (c == null || c.isEmpty) return kHomeCategory;
    return c;
  }

  bool get isInHome => categoryOrHome == kHomeCategory;

  /// The active palette for this map.
  List<int> get palette => kColorThemes[colorTheme] ?? kNodePalette;

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
    String? category,
  }) {
    final cat = category?.trim();
    return MindMap(
      id: newId(),
      title: title,
      updatedAt: DateTime.now(),
      layout: layout,
      nodePadding: nodePadding,
      category: (cat == null || cat.isEmpty || cat == kHomeCategory) ? null : cat,
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

  factory MindMap.fromJson(Map<String, dynamic> json) {
    final rawCat = (json['category'] as String?)?.trim();
    return MindMap(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      layout: MindMapLayout.fromName(json['layout'] as String?),
      nodePadding:
          ((json['nodePadding'] as num?)?.toDouble() ?? kDefaultNodePadding)
              .clamp(kMinNodePadding, kMaxNodePadding),
      colorTheme: kColorThemes.containsKey(json['colorTheme'])
          ? json['colorTheme'] as String
          : 'pastel',
      category: (rawCat == null ||
              rawCat.isEmpty ||
              rawCat == kHomeCategory)
          ? null
          : rawCat,
      nodes: (json['nodes'] as List<dynamic>? ?? const [])
          .map((e) => MindMapNode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'layout': layout.name,
        'nodePadding': nodePadding,
        'colorTheme': colorTheme,
        if (category != null &&
            category!.trim().isNotEmpty &&
            category != kHomeCategory)
          'category': category,
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
        colorTheme: colorTheme,
        category: category,
        nodes: nodes.map((n) => n.copy()).toList(),
      );

  /// Assigns this map to [name]. Pass null or [kHomeCategory] for Home.
  void setCategory(String? name) {
    final c = name?.trim();
    category =
        (c == null || c.isEmpty || c == kHomeCategory) ? null : c;
  }
}
