import 'package:flutter/material.dart';

import '../models/mind_map.dart';
import '../state/editor_controller.dart';
import '../storage/json_transfer.dart';
import '../storage/mind_map_storage.dart';
import 'editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MindMapStorage _storage = MindMapStorage();
  List<MindMap>? _maps;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final maps = await _storage.loadAll();
    if (mounted) setState(() => _maps = maps);
  }

  Future<void> _openEditor(MindMap map) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(map: map, storage: _storage),
      ),
    );
    await _reload();
  }

  Future<String?> _promptForTitle({
    required String dialogTitle,
    String initial = '',
    String confirmLabel = 'Create',
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Project brainstorm',
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _createMap() async {
    final controller = TextEditingController();
    var layout = MindMapLayout.map;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New mind map'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Project brainstorm',
                ),
                onSubmitted: (_) => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 20),
              Text('Template',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in MindMapLayout.values)
                    ChoiceChip(
                      avatar: Icon(layoutIcon(l), size: 18),
                      label: Text(l.label),
                      selected: layout == l,
                      onSelected: (_) => setDialogState(() => layout = l),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    final title = controller.text.trim();
    if (confirmed != true || title.isEmpty) return;
    final map = MindMap.create(
      title: title,
      centerX: kCanvasSize / 2,
      centerY: kCanvasSize / 2,
      layout: layout,
    );
    await _storage.save(map);
    await _reload();
    if (mounted) await _openEditor(map);
  }

  Future<void> _renameMap(MindMap map) async {
    final title = await _promptForTitle(
      dialogTitle: 'Rename mind map',
      initial: map.title,
      confirmLabel: 'Rename',
    );
    if (title == null) return;
    map.title = title;
    map.updatedAt = DateTime.now();
    await _storage.save(map);
    await _reload();
  }

  Future<void> _duplicateMap(MindMap map) async {
    final copy = map.copy(newMapId: newId());
    copy.title = '${map.title} (copy)';
    copy.updatedAt = DateTime.now();
    await _storage.save(copy);
    await _reload();
  }

  Future<void> _deleteMap(MindMap map) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${map.title}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.delete(map.id);
    await _reload();
  }

  Future<void> _importMap() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported = await JsonTransfer.importMap();
      if (imported == null) return;
      await _storage.save(imported);
      await _reload();
      messenger.showSnackBar(
        SnackBar(content: Text('Imported "${imported.title}"')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('That file is not a valid mind map.')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Today $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $hm';
    return '${dt.day}/${dt.month}/${dt.year} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final maps = _maps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimplyMind'),
        actions: [
          IconButton(
            tooltip: 'Import JSON',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _importMap,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMap,
        icon: const Icon(Icons.add),
        label: const Text('New mind map'),
      ),
      body: maps == null
          ? const Center(child: CircularProgressIndicator())
          : maps.isEmpty
              ? _EmptyState(onCreate: _createMap)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: maps.length,
                  itemBuilder: (context, index) {
                    final map = maps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Color(map.root?.color ?? kNodePalette.first),
                          child: const Icon(Icons.account_tree,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(map.title),
                        subtitle: Row(
                          children: [
                            Icon(layoutIcon(map.layout),
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${map.layout.label}'
                                ' · ${map.nodes.length} node${map.nodes.length == 1 ? '' : 's'}'
                                ' · ${_formatDate(map.updatedAt)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _openEditor(map),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _renameMap(map);
                              case 'duplicate':
                                _duplicateMap(map);
                              case 'export':
                                JsonTransfer.exportMap(map);
                              case 'delete':
                                _deleteMap(map);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                                value: 'rename', child: Text('Rename')),
                            PopupMenuItem(
                                value: 'duplicate', child: Text('Duplicate')),
                            PopupMenuItem(
                                value: 'export', child: Text('Export JSON')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart_outlined, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text('No mind maps yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create your first map and start branching ideas.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create mind map'),
          ),
        ],
      ),
    );
  }
}
