import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/mind_map.dart';
import '../storage/mind_map_storage.dart';

/// Canvas dimensions shared by the editor widgets.
const double kCanvasSize = 6000;

class EditorController extends ChangeNotifier {
  EditorController({required this.map, required this.storage});

  final MindMap map;
  final MindMapStorage storage;

  String? selectedId;

  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  static const int _maxHistory = 100;

  Timer? _saveTimer;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void select(String? id) {
    if (selectedId == id) return;
    selectedId = id;
    notifyListeners();
  }

  /// Call before a mutation to make it undoable.
  void _checkpoint() {
    _undoStack.add(map.encode());
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _restore(String snapshot) {
    final restored = MindMap.decode(snapshot);
    map.layout = restored.layout;
    map.nodePadding = restored.nodePadding;
    map.nodes
      ..clear()
      ..addAll(restored.nodes);
    if (selectedId != null && map.nodeById(selectedId!) == null) {
      selectedId = null;
    }
    _touch();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(map.encode());
    _restore(_undoStack.removeLast());
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(map.encode());
    _restore(_redoStack.removeLast());
  }

  MindMapNode addChild(String parentId) {
    final parent = map.nodeById(parentId);
    if (parent == null) throw StateError('Unknown parent $parentId');
    _checkpoint();

    final siblings = map.childrenOf(parentId).length;
    // Fan children out to the right of the parent, alternating up and down.
    final vertical = siblings.isEven
        ? -(siblings ~/ 2) * (map.nodeHeight + 36)
        : ((siblings + 1) ~/ 2) * (map.nodeHeight + 36);
    final child = MindMapNode(
      id: newId(),
      text: 'New idea',
      x: (parent.x + map.nodeWidth + 90).clamp(0, kCanvasSize),
      y: (parent.y + vertical).clamp(0, kCanvasSize),
      color: kNodePalette[
          (kNodePalette.indexOf(parent.color) + 1) % kNodePalette.length],
      parentId: parentId,
    );
    map.nodes.add(child);
    selectedId = child.id;
    _touch();
    return child;
  }

  void updateText(String id, String text) {
    final node = map.nodeById(id);
    if (node == null || node.text == text) return;
    _checkpoint();
    node.text = text;
    _touch();
  }

  void setColor(String id, int color) {
    final node = map.nodeById(id);
    if (node == null || node.color == color) return;
    _checkpoint();
    node.color = color;
    _touch();
  }

  /// Deletes a node together with its whole subtree. The root cannot be
  /// deleted.
  void deleteSubtree(String id) {
    final node = map.nodeById(id);
    if (node == null || node.parentId == null) return;
    _checkpoint();
    final doomed = map.subtreeIds(id);
    map.nodes.removeWhere((n) => doomed.contains(n.id));
    if (selectedId != null && doomed.contains(selectedId)) selectedId = null;
    _touch();
  }

  /// Live-updates the node padding, e.g. while a settings slider moves.
  /// Wrap the gesture in [beginMove]/[endMove] to get a single undo step.
  void setNodePadding(double value) {
    final v = value.clamp(kMinNodePadding, kMaxNodePadding).toDouble();
    if (map.nodePadding == v) return;
    map.nodePadding = v;
    _touch();
  }

  /// Sets the template mode for the whole map.
  void setMapLayout(MindMapLayout layout) {
    if (map.layout == layout) return;
    _checkpoint();
    map.layout = layout;
    _touch();
  }

  /// Sets (or clears, with null) the template override for one subtree.
  void setNodeLayout(String id, MindMapLayout? layout) {
    final node = map.nodeById(id);
    if (node == null || node.layout == layout) return;
    _checkpoint();
    node.layout = layout;
    _touch();
  }

  /// Moves a node up (-1) or down (+1) among its siblings. Sibling order is
  /// the order nodes appear in the nodes array, which auto layouts follow.
  void reorderSibling(String id, int delta) {
    final node = map.nodeById(id);
    if (node == null || node.parentId == null) return;
    final siblingIndexes = <int>[];
    for (var i = 0; i < map.nodes.length; i++) {
      if (map.nodes[i].parentId == node.parentId) siblingIndexes.add(i);
    }
    final pos = siblingIndexes.indexWhere((i) => map.nodes[i].id == id);
    final newPos = pos + delta;
    if (newPos < 0 || newPos >= siblingIndexes.length) return;
    _checkpoint();
    final a = siblingIndexes[pos];
    final b = siblingIndexes[newPos];
    final tmp = map.nodes[a];
    map.nodes[a] = map.nodes[b];
    map.nodes[b] = tmp;
    _touch();
  }

  /// True while a node is being dragged; layout animations are suppressed so
  /// the node follows the pointer without lag.
  bool isDragging = false;

  /// Called once when a drag starts so the whole gesture is one undo step.
  void beginMove() {
    isDragging = true;
    _checkpoint();
  }

  void endMove() {
    isDragging = false;
    notifyListeners();
  }

  /// Moves a node and all of its descendants by a canvas-space delta.
  void moveBy(String id, double dx, double dy) {
    final ids = map.subtreeIds(id);
    for (final n in map.nodes) {
      if (ids.contains(n.id)) {
        n.x = (n.x + dx).clamp(0, kCanvasSize);
        n.y = (n.y + dy).clamp(0, kCanvasSize);
      }
    }
    _touch();
  }

  void _touch() {
    map.updatedAt = DateTime.now();
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      storage.save(map);
    });
  }

  /// Flushes any pending save immediately (used when leaving the editor).
  Future<void> flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await storage.save(map);
    }
  }

  @override
  void dispose() {
    // Persist any change still waiting on the debounce timer.
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      storage.save(map);
    }
    super.dispose();
  }
}
