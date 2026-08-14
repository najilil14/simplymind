import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../layout/child_placement.dart';
import '../layout/layout_engine.dart' show kCanvasSize;
import '../models/mind_map.dart';
import '../storage/mind_map_storage.dart';

export '../layout/layout_engine.dart' show kCanvasSize;

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
    map.colorTheme = restored.colorTheme;
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

    final spawn = findChildSpawnPosition(map, parentId);
    final child = MindMapNode(
      id: newId(),
      text: 'New idea',
      x: spawn.dx,
      y: spawn.dy,
      color: map.palette[
          (map.palette.indexOf(parent.color) + 1) % map.palette.length],
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

  void setStatus(String id, NodeStatus status) {
    final node = map.nodeById(id);
    if (node == null || node.status == status) return;
    _checkpoint();
    node.status = status;
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

  /// Switches the color theme. Node colors that belong to a known theme are
  /// remapped to the same position in the new palette; custom colors are
  /// left untouched.
  void setColorTheme(String theme) {
    final newPalette = kColorThemes[theme];
    if (newPalette == null || map.colorTheme == theme) return;
    _checkpoint();
    for (final node in map.nodes) {
      for (final palette in kColorThemes.values) {
        final index = palette.indexOf(node.color);
        if (index >= 0) {
          node.color = newPalette[index];
          break;
        }
      }
    }
    map.colorTheme = theme;
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

  /// True if [nodeId] can become a child of [newParentId] without creating a
  /// cycle or a second root.
  bool canReparent(String nodeId, String newParentId) {
    final node = map.nodeById(nodeId);
    if (node == null || node.parentId == null) return false;
    if (node.parentId == newParentId) return false;
    if (map.nodeById(newParentId) == null) return false;
    // Cannot attach under yourself or any of your descendants.
    if (map.subtreeIds(nodeId).contains(newParentId)) return false;
    return true;
  }

  /// Attaches [nodeId] under [newParentId]. The whole subtree moves with it.
  void reparent(String nodeId, String newParentId, {bool checkpoint = true}) {
    if (!canReparent(nodeId, newParentId)) return;
    if (checkpoint) _checkpoint();
    final node = map.nodeById(nodeId)!;
    final parent = map.nodeById(newParentId)!;

    final dx = (parent.x + 140) - node.x;
    final dy = parent.y - node.y;
    for (final id in map.subtreeIds(nodeId)) {
      final n = map.nodeById(id)!;
      n.x = (n.x + dx).clamp(0, kCanvasSize);
      n.y = (n.y + dy).clamp(0, kCanvasSize);
    }
    node.parentId = newParentId;

    // Keep sibling order sensible: place after the new parent's last child.
    map.nodes.remove(node);
    final lastChild = map.nodes.lastIndexWhere((n) => n.parentId == newParentId);
    if (lastChild >= 0) {
      map.nodes.insert(lastChild + 1, node);
    } else {
      final parentIndex = map.nodes.indexWhere((n) => n.id == newParentId);
      map.nodes.insert(parentIndex + 1, node);
    }
    _touch();
  }

  /// Makes [id] a sibling of its current parent (child of the grandparent).
  void promote(String id) {
    final node = map.nodeById(id);
    if (node?.parentId == null) return;
    final parent = map.nodeById(node!.parentId!);
    final grandparentId = parent?.parentId;
    if (grandparentId == null) return;
    reparent(id, grandparentId);
  }

  bool canPromote(String id) {
    final node = map.nodeById(id);
    if (node?.parentId == null) return false;
    return map.nodeById(node!.parentId!)?.parentId != null;
  }

  /// True while a node is being dragged; layout animations are suppressed so
  /// the node follows the pointer without lag.
  bool isDragging = false;

  /// Node currently being dragged (for reparent / visual offset).
  String? draggingId;

  /// Valid drop target under the pointer, or null.
  String? dropTargetId;

  /// Extra canvas offset applied while dragging auto-laid-out nodes (their
  /// stored x/y are ignored by the layout engine until drop).
  Offset dragVisualOffset = Offset.zero;

  /// Called once when a gesture starts so the whole gesture is one undo step.
  /// Pass [id] when dragging a node (enables drop-to-reparent).
  void beginMove([String? id]) {
    if (id != null) {
      isDragging = true;
      draggingId = id;
      dropTargetId = null;
      dragVisualOffset = Offset.zero;
    }
    _checkpoint();
    notifyListeners();
  }

  /// Updates drag position and highlights a drop-to-reparent target if any.
  void updateDrag({
    required String id,
    required double dx,
    required double dy,
    required bool freeMove,
    required Map<String, Offset> positions,
    required Map<String, Size> sizes,
  }) {
    if (freeMove) {
      moveBy(id, dx, dy);
    } else {
      dragVisualOffset += Offset(dx, dy);
    }

    // After freeMove, stored coords are current; during auto-layout drag the
    // layout positions are static and we add [dragVisualOffset].
    final node = map.nodeById(id);
    final base = positions[id];
    if (node == null || base == null) return;
    final tip =
        freeMove ? Offset(node.x, node.y) : base + dragVisualOffset;
    _resolveDropTarget(id, tip, positions, sizes);
    if (!freeMove) notifyListeners();
  }

  void _resolveDropTarget(
    String draggedId,
    Offset tip,
    Map<String, Offset> positions,
    Map<String, Size> sizes,
  ) {
    String? hit;
    var bestArea = double.infinity;
    final doomed = map.subtreeIds(draggedId);
    for (final n in map.nodes) {
      if (doomed.contains(n.id)) continue;
      if (!canReparent(draggedId, n.id)) continue;
      final p = positions[n.id];
      final s = sizes[n.id];
      if (p == null || s == null) continue;
      const pad = 12.0;
      final rect = Rect.fromCenter(
        center: p,
        width: s.width + pad,
        height: s.height + pad,
      );
      if (!rect.contains(tip)) continue;
      final area = s.width * s.height;
      // Prefer the smallest node under the tip (deepest / most specific).
      if (area < bestArea) {
        bestArea = area;
        hit = n.id;
      }
    }
    if (dropTargetId != hit) {
      dropTargetId = hit;
      notifyListeners();
    }
  }

  void endMove() {
    final dragged = draggingId;
    final target = dropTargetId;
    if (dragged != null && target != null && canReparent(dragged, target)) {
      // Checkpoint already taken in beginMove.
      reparent(dragged, target, checkpoint: false);
    }
    isDragging = false;
    draggingId = null;
    dropTargetId = null;
    dragVisualOffset = Offset.zero;
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
