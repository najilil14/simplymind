import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/layout_engine.dart';
import '../models/mind_map.dart';
import '../state/editor_controller.dart';
import '../storage/json_transfer.dart';
import '../storage/mind_map_storage.dart';

IconData layoutIcon(MindMapLayout layout) => switch (layout) {
      MindMapLayout.map => Icons.open_with,
      MindMapLayout.list => Icons.format_list_bulleted,
      MindMapLayout.step => Icons.format_list_numbered,
      MindMapLayout.graph => Icons.hub_outlined,
    };

IconData? statusIcon(NodeStatus status) => switch (status) {
      NodeStatus.none => null,
      NodeStatus.inProgress => Icons.timelapse,
      NodeStatus.done => Icons.check_circle,
    };

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.map, required this.storage});

  final MindMap map;
  final MindMapStorage storage;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller;
  final TransformationController _transform = TransformationController();
  bool _centeredOnce = false;

  @override
  void initState() {
    super.initState();
    _controller =
        EditorController(map: widget.map, storage: widget.storage);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _centerOnRoot(Size viewport, {double scale = 1}) {
    final root = widget.map.root;
    if (root == null) return;
    _transform.value = Matrix4.identity()
      ..translateByDouble(viewport.width / 2 - root.x * scale,
          viewport.height / 2 - root.y * scale, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _zoomBy(double factor, Size viewport) {
    final current = _transform.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(0.2, 3.0);
    final applied = target / current;
    final cx = viewport.width / 2;
    final cy = viewport.height / 2;
    _transform.value = (Matrix4.identity()
          ..translateByDouble(cx, cy, 0, 1)
          ..scaleByDouble(applied, applied, 1, 1)
          ..translateByDouble(-cx, -cy, 0, 1))
        .multiplied(_transform.value);
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Map settings'),
        content: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Node padding: ${_controller.map.nodePadding.round()} px',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Space between the text and the node box. The change is '
                'previewed live and saved with this mind map.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Slider(
                value: _controller.map.nodePadding,
                min: kMinNodePadding,
                max: kMaxNodePadding,
                divisions: (kMaxNodePadding - kMinNodePadding).round(),
                label: '${_controller.map.nodePadding.round()} px',
                onChangeStart: (_) => _controller.beginMove(),
                onChanged: _controller.setNodePadding,
                onChangeEnd: (_) => _controller.endMove(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.beginMove();
              _controller.setNodePadding(kDefaultNodePadding);
              _controller.endMove();
            },
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    await _controller.flush();
    final saved = await JsonTransfer.exportMap(widget.map);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mind map exported as JSON')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditorController>.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.map.title),
          actions: [
            Consumer<EditorController>(
              builder: (context, c, _) => Row(
                children: [
                  IconButton(
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo),
                    onPressed: c.canUndo ? c.undo : null,
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    icon: const Icon(Icons.redo),
                    onPressed: c.canRedo ? c.redo : null,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Map settings',
              icon: const Icon(Icons.tune),
              onPressed: _openSettings,
            ),
            IconButton(
              tooltip: 'Export JSON',
              icon: const Icon(Icons.ios_share),
              onPressed: _exportJson,
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.biggest;
            if (!_centeredOnce) {
              _centeredOnce = true;
              _centerOnRoot(viewport);
            }
            return Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(1200),
                  minScale: 0.2,
                  maxScale: 3,
                  child: SizedBox(
                    width: kCanvasSize,
                    height: kCanvasSize,
                    child: Consumer<EditorController>(
                      builder: (context, c, _) => _AnimatedLayout(
                        controller: c,
                        layout: computeLayout(c.map),
                        transform: _transform,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(child: _TemplateSwitcher()),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _ZoomControls(
                    onZoomIn: () => _zoomBy(1.25, viewport),
                    onZoomOut: () => _zoomBy(1 / 1.25, viewport),
                    onCenter: () => _centerOnRoot(viewport),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: _HintBanner(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TemplateSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, c, _) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SegmentedButton<MindMapLayout>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              for (final l in MindMapLayout.values)
                ButtonSegment(
                  value: l,
                  icon: Icon(layoutIcon(l), size: 18),
                  label: Text(l.label),
                ),
            ],
            selected: {c.map.layout},
            onSelectionChanged: (s) => c.setMapLayout(s.first),
          ),
        ),
      ),
    );
  }
}

/// Smoothly animates every node from its previous position to the newly
/// computed one whenever the layout changes (mode switch, add, reorder,
/// undo...). While a node is being dragged updates are applied instantly.
class _AnimatedLayout extends StatefulWidget {
  const _AnimatedLayout({
    required this.controller,
    required this.layout,
    required this.transform,
  });

  final EditorController controller;
  final LayoutResult layout;
  final TransformationController transform;

  @override
  State<_AnimatedLayout> createState() => _AnimatedLayoutState();
}

class _AnimatedLayoutState extends State<_AnimatedLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  Map<String, Offset> _from = {};
  Map<String, Offset> _to = {};

  @override
  void initState() {
    super.initState();
    _to = widget.layout.positions;
    _from = Map.of(_to);
    _anim.value = 1;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static bool _same(Map<String, Offset> a, Map<String, Offset> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final other = b[e.key];
      if (other == null || (other - e.value).distance > 0.5) return false;
    }
    return true;
  }

  Offset _startFor(String id) {
    final from = _from[id];
    if (from != null) return from;
    // New nodes grow out of their parent's previous position.
    final parentId = widget.controller.map.nodeById(id)?.parentId;
    return (parentId != null ? _from[parentId] : null) ?? _to[id]!;
  }

  Map<String, Offset> _currentPositions() {
    final t = Curves.easeInOutCubic.transform(_anim.value);
    return {
      for (final e in _to.entries)
        e.key: Offset.lerp(_startFor(e.key), e.value, t)!,
    };
  }

  @override
  void didUpdateWidget(covariant _AnimatedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.layout.positions;
    if (_same(target, _to)) {
      _to = target;
      return;
    }
    if (widget.controller.isDragging) {
      _from = Map.of(target);
      _to = target;
      _anim.value = 1;
    } else {
      _from = _currentPositions();
      _to = target;
      _anim.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => _MindMapCanvas(
        controller: widget.controller,
        layout: widget.layout,
        positions: _currentPositions(),
        transform: widget.transform,
      ),
    );
  }
}

class _MindMapCanvas extends StatelessWidget {
  const _MindMapCanvas({
    required this.controller,
    required this.layout,
    required this.positions,
    required this.transform,
  });

  final EditorController controller;
  final LayoutResult layout;
  final Map<String, Offset> positions;
  final TransformationController transform;

  @override
  Widget build(BuildContext context) {
    final map = controller.map;
    final selected =
        controller.selectedId == null ? null : map.nodeById(controller.selectedId!);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tap on empty canvas clears the selection.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.select(null),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _EdgePainter(
                map,
                {
                  for (final e in positions.entries)
                    e.key: _displayPosition(controller, e.key, e.value),
                },
                layout.sizes,
                layout.childrenModeOf,
              ),
            ),
          ),
        ),
        for (final node in map.nodes)
          if (positions.containsKey(node.id))
            _NodeCard(
              key: ValueKey(node.id),
              node: node,
              position: _displayPosition(
                  controller, node.id, positions[node.id]!),
              size: layout.sizes[node.id]!,
              isRoot: node.parentId == null,
              isSelected: node.id == controller.selectedId,
              isDropTarget: node.id == controller.dropTargetId,
              freeMove: layout.placedBy[node.id] == MindMapLayout.map,
              stepNumber: layout.stepNumber[node.id],
              positions: positions,
              sizes: layout.sizes,
              controller: controller,
              transform: transform,
            ),
        if (selected != null &&
            positions.containsKey(selected.id) &&
            !controller.isDragging)
          _NodeToolbar(
            node: selected,
            position: _displayPosition(
                controller, selected.id, positions[selected.id]!),
            nodeHeight: layout.sizes[selected.id]!.height,
            placedBy: layout.placedBy[selected.id] ?? MindMapLayout.map,
            controller: controller,
          ),
      ],
    );
  }
}

Offset _displayPosition(
  EditorController controller,
  String id,
  Offset base,
) {
  final dragged = controller.draggingId;
  if (dragged == null || controller.dragVisualOffset == Offset.zero) {
    return base;
  }
  if (controller.map.subtreeIds(dragged).contains(id)) {
    return base + controller.dragVisualOffset;
  }
  return base;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.map, this.positions, this.sizes, this.childrenModeOf);

  final MindMap map;
  final Map<String, Offset> positions;
  final Map<String, Size> sizes;
  final Map<String, MindMapLayout> childrenModeOf;

  void _arrowhead(Canvas canvas, Offset tip, double angle, Paint paint) {
    const size = 9.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - size * cos(angle - 0.45), tip.dy - size * sin(angle - 0.45))
      ..lineTo(tip.dx - size * cos(angle + 0.45), tip.dy - size * sin(angle + 0.45))
      ..close();
    canvas.drawPath(path, Paint()..color = paint.color);
  }

  void _arrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    _arrowhead(canvas, to, atan2(to.dy - from.dy, to.dx - from.dx), paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final parent in map.nodes) {
      final children = map.childrenOf(parent.id);
      if (children.isEmpty) continue;
      final p = positions[parent.id];
      final ps = sizes[parent.id];
      if (p == null || ps == null) continue;
      final mode = childrenModeOf[parent.id] ?? MindMapLayout.map;

      switch (mode) {
        case MindMapLayout.map:
          for (final child in children) {
            final c = positions[child.id];
            if (c == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            final midX = p.dx + (c.dx - p.dx) / 2;
            final path = Path()
              ..moveTo(p.dx, p.dy)
              ..cubicTo(midX, p.dy, midX, c.dy, c.dx, c.dy);
            canvas.drawPath(path, paint);
          }

        case MindMapLayout.graph:
          for (final child in children) {
            final c = positions[child.id];
            if (c == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            canvas.drawLine(p, c, paint);
          }

        case MindMapLayout.list:
          // Elbow lines hanging from below the parent's left side.
          final trunkX = p.dx - ps.width / 2 + 20;
          for (final child in children) {
            final c = positions[child.id];
            final cs = sizes[child.id];
            if (c == null || cs == null) continue;
            paint.color = Color(child.color).withValues(alpha: 0.75);
            final path = Path()
              ..moveTo(trunkX, p.dy + ps.height / 2)
              ..lineTo(trunkX, c.dy)
              ..lineTo(c.dx - cs.width / 2, c.dy);
            canvas.drawPath(path, paint);
          }

        case MindMapLayout.step:
          // Parent points to step 1, then each step points to the next.
          final first = positions[children.first.id];
          final firstSize = sizes[children.first.id];
          if (first != null && firstSize != null) {
            paint.color = Color(children.first.color).withValues(alpha: 0.8);
            _arrow(canvas, Offset(p.dx, p.dy + ps.height / 2),
                Offset(first.dx, first.dy - firstSize.height / 2), paint);
          }
          for (var i = 0; i < children.length - 1; i++) {
            final a = positions[children[i].id];
            final b = positions[children[i + 1].id];
            final sa = sizes[children[i].id];
            final sb = sizes[children[i + 1].id];
            if (a == null || b == null || sa == null || sb == null) continue;
            paint.color = Color(children[i + 1].color).withValues(alpha: 0.8);
            _arrow(canvas, Offset(a.dx + sa.width / 2, a.dy),
                Offset(b.dx - sb.width / 2, b.dy), paint);
          }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) => true;
}

/// Opens the node text editor with the current text pre-selected, so typing
/// immediately replaces it. Saves on submit; keeps the old text on cancel.
Future<void> _showNodeTextDialog(
  BuildContext context,
  EditorController controller,
  MindMapNode node, {
  String title = 'Edit node',
}) async {
  final textController = TextEditingController(text: node.text);
  textController.selection = TextSelection(
      baseOffset: 0, extentOffset: textController.text.length);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: textController,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(textController.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  final text = result?.trim();
  if (text != null && text.isNotEmpty) {
    controller.updateText(node.id, text);
  }
}

/// Text color that stays readable on both the new pastel palette (dark ink)
/// and legacy saturated node colors (white).
Color _inkFor(Color background) =>
    background.computeLuminance() > 0.45 ? const Color(0xFF273043) : Colors.white;

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    super.key,
    required this.node,
    required this.position,
    required this.size,
    required this.isRoot,
    required this.isSelected,
    required this.isDropTarget,
    required this.freeMove,
    required this.stepNumber,
    required this.positions,
    required this.sizes,
    required this.controller,
    required this.transform,
  });

  final MindMapNode node;
  final Offset position;
  final Size size;
  final bool isRoot;
  final bool isSelected;
  final bool isDropTarget;
  final bool freeMove;
  final int? stepNumber;
  final Map<String, Offset> positions;
  final Map<String, Size> sizes;
  final EditorController controller;
  final TransformationController transform;

  @override
  Widget build(BuildContext context) {
    final color = Color(node.color);
    final ink = _inkFor(color);
    final scheme = Theme.of(context).colorScheme;
    final map = controller.map;
    final canDrag = !isRoot;
    return Positioned(
      left: position.dx - size.width / 2,
      top: position.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: GestureDetector(
        onTap: () => controller.select(node.id),
        onDoubleTap: () {
          controller.select(node.id);
          _showNodeTextDialog(context, controller, node);
        },
        onPanStart: !canDrag
            ? null
            : (_) {
                controller.select(node.id);
                controller.beginMove(node.id);
              },
        onPanUpdate: !canDrag
            ? null
            : (details) {
                final scale = transform.value.getMaxScaleOnAxis();
                controller.updateDrag(
                  id: node.id,
                  dx: details.delta.dx / scale,
                  dy: details.delta.dy / scale,
                  freeMove: freeMove,
                  positions: positions,
                  sizes: sizes,
                );
              },
        onPanEnd: !canDrag ? null : (_) => controller.endMove(),
        onPanCancel: !canDrag ? null : controller.endMove,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(isRoot ? 24 : 14),
                border: Border.all(
                  color: isDropTarget
                      ? scheme.primary
                      : isSelected
                          ? scheme.onSurface
                          : ink.withValues(alpha: 0.18),
                  width: isDropTarget || isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: isSelected ? 0.25 : 0.10),
                    blurRadius: isSelected ? 12 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.all(map.nodePadding),
              alignment: Alignment.center,
              child: Text(
                node.text,
                textAlign: TextAlign.center,
                maxLines: nodeMaxLines(isRoot),
                overflow: TextOverflow.ellipsis,
                style: nodeTextStyle(isRoot).copyWith(color: ink),
              ),
            ),
            if (stepNumber != null)
              Positioned(
                left: -8,
                top: -8,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (node.layout != null)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(layoutIcon(node.layout!),
                      size: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            if (node.status != NodeStatus.none)
              Positioned(
                left: -6,
                bottom: -6,
                child: _StatusBadge(status: node.status),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatefulWidget {
  const _StatusBadge({required this.status});

  final NodeStatus status;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.status == NodeStatus.inProgress) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant _StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == NodeStatus.inProgress) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
      _spin.reset();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = widget.status == NodeStatus.done;
    final bg = isDone ? const Color(0xFF2E7D4F) : scheme.surface;
    final fg = isDone ? Colors.white : const Color(0xFF3B6FE0);

    Widget icon;
    if (widget.status == NodeStatus.inProgress) {
      icon = RotationTransition(
        turns: _spin,
        child: Icon(Icons.autorenew, size: 14, color: fg),
      );
    } else {
      icon = Icon(Icons.check, size: 14, color: fg);
    }

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone ? bg : scheme.outlineVariant,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: icon,
    );
  }
}

class _NodeToolbar extends StatelessWidget {
  const _NodeToolbar({
    required this.node,
    required this.position,
    required this.nodeHeight,
    required this.placedBy,
    required this.controller,
  });

  final MindMapNode node;
  final Offset position;
  final double nodeHeight;
  final MindMapLayout placedBy;
  final EditorController controller;

  static String _themeLabel(String key) =>
      key[0].toUpperCase() + key.substring(1);

  Future<void> _pickColor(BuildContext context) async {
    var custom = HSVColor.fromColor(Color(node.color));
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final scheme = Theme.of(context).colorScheme;
          Widget sliderRow(String label, double value, double max,
              ValueChanged<double> onChanged) {
            return Row(
              children: [
                SizedBox(width: 16, child: Text(label)),
                Expanded(
                  child: Slider(
                    value: value,
                    max: max,
                    onChanged: (v) => setState(() => onChanged(v)),
                  ),
                ),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Node color'),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                        visualDensity: VisualDensity.compact),
                    segments: [
                      for (final key in kColorThemes.keys)
                        ButtonSegment(
                            value: key, label: Text(_themeLabel(key))),
                    ],
                    selected: {controller.map.colorTheme},
                    onSelectionChanged: (s) =>
                        setState(() => controller.setColorTheme(s.first)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in controller.map.palette)
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(dialogContext).pop(c),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c == node.color
                                    ? scheme.onSurface
                                    : scheme.outlineVariant,
                                width: c == node.color ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Text('Custom color',
                          style: Theme.of(context).textTheme.labelLarge),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: custom.toColor(),
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                      ),
                    ],
                  ),
                  sliderRow('H', custom.hue, 360,
                      (v) => custom = custom.withHue(v)),
                  sliderRow('S', custom.saturation, 1,
                      (v) => custom = custom.withSaturation(v)),
                  sliderRow('B', custom.value, 1,
                      (v) => custom = custom.withValue(v)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext)
                          .pop(custom.toColor().toARGB32()),
                      child: const Text('Use custom color'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked != null) controller.setColor(node.id, picked);
  }

  Future<void> _pickStatus(BuildContext context) async {
    final picked = await showDialog<NodeStatus>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Node status'),
        children: [
          for (final s in NodeStatus.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(s),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  statusIcon(s) ?? Icons.remove_circle_outline,
                  color: s == NodeStatus.done
                      ? const Color(0xFF2E7D4F)
                      : s == NodeStatus.inProgress
                          ? const Color(0xFF3B6FE0)
                          : null,
                ),
                title: Text(s.label),
                trailing:
                    node.status == s ? const Icon(Icons.check) : null,
              ),
            ),
        ],
      ),
    );
    if (picked != null) controller.setStatus(node.id, picked);
  }

  Future<void> _pickLayout(BuildContext context) async {
    final picked = await showDialog<_LayoutChoice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Branch template'),
        children: [
          _layoutOption(context, null, 'Inherit',
              'Follow the map template', node.layout == null),
          for (final l in MindMapLayout.values)
            _layoutOption(context, l, l.label, _describe(l), node.layout == l),
        ],
      ),
    );
    if (picked != null) controller.setNodeLayout(node.id, picked.layout);
  }

  static String _describe(MindMapLayout l) => switch (l) {
        MindMapLayout.map => 'Free positioning by dragging',
        MindMapLayout.list => 'Indented outline, top to bottom',
        MindMapLayout.step => 'Numbered sequence with arrows',
        MindMapLayout.graph => 'Radial branches around the node',
      };

  Widget _layoutOption(BuildContext context, MindMapLayout? l, String title,
      String subtitle, bool selected) {
    return SimpleDialogOption(
      onPressed: () => Navigator.of(context).pop(_LayoutChoice(l)),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(l == null ? Icons.settings_backup_restore : layoutIcon(l)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: selected ? const Icon(Icons.check) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = node.parentId == null;
    final autoPlaced = placedBy != MindMapLayout.map;
    final horizontal = placedBy == MindMapLayout.step;
    return Positioned(
      left: position.dx,
      top: position.dy + nodeHeight / 2 + 8,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Add child',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    final child = controller.addChild(node.id);
                    _showNodeTextDialog(context, controller, child,
                        title: 'New node');
                  },
                ),
                if (autoPlaced) ...[
                  IconButton(
                    tooltip: horizontal ? 'Move left' : 'Move up',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                        horizontal
                            ? Icons.keyboard_arrow_left
                            : Icons.keyboard_arrow_up,
                        size: 20),
                    onPressed: () => controller.reorderSibling(node.id, -1),
                  ),
                  IconButton(
                    tooltip: horizontal ? 'Move right' : 'Move down',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                        horizontal
                            ? Icons.keyboard_arrow_right
                            : Icons.keyboard_arrow_down,
                        size: 20),
                    onPressed: () => controller.reorderSibling(node.id, 1),
                  ),
                ],
                if (controller.canPromote(node.id))
                  IconButton(
                    tooltip: 'Promote (sibling of parent)',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.keyboard_double_arrow_up, size: 20),
                    onPressed: () => controller.promote(node.id),
                  ),
                IconButton(
                  tooltip: 'Branch template',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.account_tree_outlined, size: 20),
                  onPressed: () => _pickLayout(context),
                ),
                IconButton(
                  tooltip: 'Status',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    statusIcon(node.status) ?? Icons.flag_outlined,
                    size: 20,
                  ),
                  onPressed: () => _pickStatus(context),
                ),
                IconButton(
                  tooltip: 'Color',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.palette_outlined, size: 20),
                  onPressed: () => _pickColor(context),
                ),
                if (!isRoot)
                  IconButton(
                    tooltip: 'Delete branch',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => controller.deleteSubtree(node.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wrapper so the layout dialog can distinguish "Inherit" (null layout)
/// from "dialog cancelled" (null result).
class _LayoutChoice {
  const _LayoutChoice(this.layout);

  final MindMapLayout? layout;
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenter,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              tooltip: 'Zoom in',
              icon: const Icon(Icons.add),
              onPressed: onZoomIn),
          IconButton(
              tooltip: 'Center on root',
              icon: const Icon(Icons.filter_center_focus),
              onPressed: onCenter),
          IconButton(
              tooltip: 'Zoom out',
              icon: const Icon(Icons.remove),
              onPressed: onZoomOut),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Drag onto a node to attach · Promote: ⇈ · Double-tap: edit',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
