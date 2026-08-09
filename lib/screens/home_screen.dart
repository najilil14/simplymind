import 'package:flutter/material.dart';

import '../models/mind_map.dart';
import '../state/editor_controller.dart';
import '../storage/json_transfer.dart';
import '../storage/mind_map_storage.dart';
import '../utils/feedback_launcher.dart';
import 'editor_screen.dart';
import 'legal/dmca_screen.dart';
import 'legal/privacy_policy_screen.dart';

/// Sentinel for the "All" filter chip (not a real category).
const String _kFilterAll = '__all__';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MindMapStorage _storage = MindMapStorage();
  List<MindMap>? _maps;
  List<String> _categories = <String>[];
  bool _bannerDismissed = false;
  String _selectedFilter = _kFilterAll;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final maps = await _storage.loadAll();
    final categories = await _storage.loadCategories();
    final dismissed = await _storage.isCategoryBannerDismissed();

    // Auto-register categories referenced by imported/old maps.
    var cats = List<String>.from(categories);
    var changed = false;
    for (final m in maps) {
      final c = m.category?.trim();
      if (c != null &&
          c.isNotEmpty &&
          c != kHomeCategory &&
          !cats.contains(c)) {
        cats.add(c);
        changed = true;
      }
    }
    if (changed) await _storage.saveCategories(cats);

    if (!mounted) return;
    setState(() {
      _maps = maps;
      _categories = cats;
      _bannerDismissed = dismissed;
      // Drop selection if the category was deleted.
      if (_selectedFilter != _kFilterAll &&
          _selectedFilter != kHomeCategory &&
          !_categories.contains(_selectedFilter)) {
        _selectedFilter = _kFilterAll;
      }
    });
  }

  List<MindMap> get _filteredMaps {
    final maps = _maps ?? const <MindMap>[];
    if (_selectedFilter == _kFilterAll) return maps;
    return maps
        .where((m) => m.categoryOrHome == _selectedFilter)
        .toList();
  }

  bool get _showCategoryOffer {
    final maps = _maps;
    if (maps == null) return false;
    return maps.length > kCategoryOfferThreshold &&
        _categories.isEmpty &&
        !_bannerDismissed;
  }

  bool get _showChips => _categories.isNotEmpty;

  String? get _defaultCategoryForNew {
    if (_selectedFilter == _kFilterAll ||
        _selectedFilter == kHomeCategory) {
      return null;
    }
    return _selectedFilter;
  }

  Future<void> _openEditor(MindMap map) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(map: map, storage: _storage),
      ),
    );
    await _reload();
  }

  Future<String?> _promptForName({
    required String dialogTitle,
    String initial = '',
    String label = 'Name',
    String hint = '',
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
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
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

  Future<void> _createCategory() async {
    final name = await _promptForName(
      dialogTitle: 'New category',
      label: 'Category name',
      hint: 'e.g. Work, Personal',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    if (name == kHomeCategory) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"Home" is reserved for uncategorized maps')),
      );
      return;
    }
    if (_categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" already exists')),
      );
      return;
    }
    final cats = List<String>.from(_categories)..add(name);
    await _storage.saveCategories(cats);
    await _storage.setCategoryBannerDismissed(true);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _bannerDismissed = true;
      _selectedFilter = name;
    });
  }

  Future<void> _renameCategory(String oldName) async {
    final name = await _promptForName(
      dialogTitle: 'Rename category',
      initial: oldName,
      label: 'Category name',
      confirmLabel: 'Rename',
    );
    if (name == null || name == oldName) return;
    if (name == kHomeCategory) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('"Home" is reserved')),
      );
      return;
    }
    if (_categories.any(
        (c) => c != oldName && c.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" already exists')),
      );
      return;
    }

    final cats = _categories.map((c) => c == oldName ? name : c).toList();
    await _storage.saveCategories(cats);
    final maps = _maps ?? const <MindMap>[];
    for (final m in maps) {
      if (m.category == oldName) {
        m.setCategory(name);
        m.updatedAt = DateTime.now();
        await _storage.save(m);
      }
    }
    if (_selectedFilter == oldName) _selectedFilter = name;
    await _reload();
  }

  Future<void> _deleteCategory(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text(
          'Maps in this category move back to Home. The maps themselves are not deleted.',
        ),
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

    final cats = List<String>.from(_categories)..remove(name);
    await _storage.saveCategories(cats);
    final maps = _maps ?? const <MindMap>[];
    for (final m in maps) {
      if (m.category == name) {
        m.setCategory(null);
        m.updatedAt = DateTime.now();
        await _storage.save(m);
      }
    }
    if (_selectedFilter == name) _selectedFilter = _kFilterAll;
    await _reload();
  }

  Future<void> _dismissBanner() async {
    await _storage.setCategoryBannerDismissed(true);
    if (mounted) setState(() => _bannerDismissed = true);
  }

  Future<void> _moveToCategory(MindMap map) async {
    final options = <String>[kHomeCategory, ..._categories];
    final current = map.categoryOrHome;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Move to category'),
        children: [
          for (final c in options)
            ListTile(
              title: Text(c),
              trailing: c == current
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(c),
            ),
        ],
      ),
    );
    if (chosen == null || chosen == map.categoryOrHome) return;
    map.setCategory(chosen == kHomeCategory ? null : chosen);
    map.updatedAt = DateTime.now();
    await _storage.save(map);
    await _reload();
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
      category: _defaultCategoryForNew,
    );
    await _storage.save(map);
    await _reload();
    if (mounted) await _openEditor(map);
  }

  Future<void> _renameMap(MindMap map) async {
    final title = await _promptForName(
      dialogTitle: 'Rename mind map',
      initial: map.title,
      label: 'Title',
      hint: 'e.g. Project brainstorm',
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
      final cat = imported.category?.trim();
      if (cat != null && cat.isNotEmpty && cat != kHomeCategory) {
        await _storage.ensureCategory(cat);
      }
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

  Future<void> _showCategoryActions(String name) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text('Rename "$name"'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete "$name"',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'rename') await _renameCategory(name);
    if (action == 'delete') await _deleteCategory(name);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Today $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday $hm';
    return '${dt.day}/${dt.month}/${dt.year} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final maps = _maps;
    final filtered = _filteredMaps;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimplyMind'),
        actions: [
          IconButton(
            tooltip: 'Import JSON',
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _importMap,
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              switch (value) {
                case 'new_category':
                  _createCategory();
                case 'feedback':
                  openWhatsAppFeedback(context);
                case 'privacy':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                case 'dmca':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DmcaScreen(),
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_category',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.create_new_folder_outlined),
                  title: Text('New category'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'feedback',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.chat_outlined),
                  title: Text('Send feedback'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy Policy'),
                ),
              ),
              const PopupMenuItem(
                value: 'dmca',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.gavel_outlined),
                  title: Text('DMCA'),
                ),
              ),
            ],
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showChips) _buildChipRow(),
                    if (_showCategoryOffer) _buildOfferBanner(),
                    Expanded(
                      child: filtered.isEmpty
                          ? _FilteredEmpty(
                              category: _selectedFilter == _kFilterAll
                                  ? null
                                  : _selectedFilter,
                              onCreate: _createMap,
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 8, 12, 96),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final map = filtered[index];
                                return _MapTile(
                                  map: map,
                                  showCategory: _selectedFilter == _kFilterAll &&
                                      _categories.isNotEmpty,
                                  dateLabel: _formatDate(map.updatedAt),
                                  onOpen: () => _openEditor(map),
                                  onRename: () => _renameMap(map),
                                  onDuplicate: () => _duplicateMap(map),
                                  onMove: () => _moveToCategory(map),
                                  onExport: () => JsonTransfer.exportMap(map),
                                  onDelete: () => _deleteMap(map),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildChipRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedFilter == _kFilterAll,
              onSelected: (_) =>
                  setState(() => _selectedFilter = _kFilterAll),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(kHomeCategory),
              selected: _selectedFilter == kHomeCategory,
              onSelected: (_) =>
                  setState(() => _selectedFilter = kHomeCategory),
            ),
          ),
          for (final c in _categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c),
                selected: _selectedFilter == c,
                onSelected: (_) => setState(() => _selectedFilter = c),
                onDeleted: () => _showCategoryActions(c),
                deleteIcon: const Icon(Icons.more_horiz, size: 18),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('New'),
            onPressed: _createCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBanner() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organize your maps?',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You have more than $kCategoryOfferThreshold mind maps. '
                    'Create categories to keep them tidy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _createCategory,
                        child: const Text('Create category'),
                      ),
                      TextButton(
                        onPressed: _dismissBanner,
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, color: scheme.onSecondaryContainer),
              onPressed: _dismissBanner,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile({
    required this.map,
    required this.showCategory,
    required this.dateLabel,
    required this.onOpen,
    required this.onRename,
    required this.onDuplicate,
    required this.onMove,
    required this.onExport,
    required this.onDelete,
  });

  final MindMap map;
  final bool showCategory;
  final String dateLabel;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onMove;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(map.root?.color ?? kNodePalette.first),
          child: const Icon(Icons.account_tree,
              color: Colors.white, size: 20),
        ),
        title: Text(map.title),
        subtitle: Row(
          children: [
            Icon(layoutIcon(map.layout), size: 14, color: variant),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                [
                  if (showCategory) map.categoryOrHome,
                  map.layout.label,
                  '${map.nodes.length} node${map.nodes.length == 1 ? '' : 's'}',
                  dateLabel,
                ].join(' · '),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: onOpen,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'rename':
                onRename();
              case 'duplicate':
                onDuplicate();
              case 'move':
                onMove();
              case 'export':
                onExport();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(
                value: 'move', child: Text('Move to category')),
            PopupMenuItem(value: 'export', child: Text('Export JSON')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
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

class _FilteredEmpty extends StatelessWidget {
  const _FilteredEmpty({required this.category, required this.onCreate});

  final String? category;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = category ?? 'this filter';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No maps in $label',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new mind map here, or move an existing one into this category.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New mind map'),
            ),
          ],
        ),
      ),
    );
  }
}
