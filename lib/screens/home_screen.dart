import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/mind_map.dart';
import '../state/editor_controller.dart';
import '../state/locale_controller.dart';
import '../storage/json_transfer.dart';
import '../storage/mind_map_storage.dart';
import '../templates/map_starters.dart';
import '../utils/feedback_launcher.dart';
import 'editor_screen.dart';
import 'help_screen.dart';
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
    required String label,
    String hint = '',
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
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
            child: Text(l10n.cancel),
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
    final l10n = AppLocalizations.of(context);
    final name = await _promptForName(
      dialogTitle: l10n.newCategory,
      label: l10n.categoryName,
      hint: l10n.categoryHint,
      confirmLabel: l10n.create,
    );
    if (name == null) return;
    if (name == kHomeCategory) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeReserved)),
      );
      return;
    }
    if (_categories.any((c) => c.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.categoryExists(name))),
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
    final l10n = AppLocalizations.of(context);
    final name = await _promptForName(
      dialogTitle: l10n.renameCategory,
      initial: oldName,
      label: l10n.categoryName,
      confirmLabel: l10n.rename,
    );
    if (name == null || name == oldName) return;
    if (name == kHomeCategory) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.homeReservedShort)),
      );
      return;
    }
    if (_categories.any(
        (c) => c != oldName && c.toLowerCase() == name.toLowerCase())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.categoryExists(name))),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle(name)),
        content: Text(l10n.deleteCategoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
    final options = <String>[kHomeCategory, ..._categories];
    final current = map.categoryOrHome;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.moveToCategory),
        children: [
          for (final c in options)
            ListTile(
              title: Text(
                c == kHomeCategory ? l10n.categoryHome : c,
              ),
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
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    var layout = MindMapLayout.map;
    var starter = MapStarter.blank;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.newMindMap),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.titleLabel,
                    hintText: l10n.titleHint,
                  ),
                  onSubmitted: (_) => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 20),
                Text(l10n.starterSection,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in MapStarter.values)
                      ChoiceChip(
                        avatar: Icon(_starterIcon(s), size: 18),
                        label: Text(l10n.starterLabel(s)),
                        selected: starter == s,
                        tooltip: l10n.starterDescription(s),
                        onSelected: (_) => setDialogState(() {
                          starter = s;
                          if (s != MapStarter.blank) {
                            layout = suggestedLayoutFor(s);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.starterDescription(starter),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Text(l10n.layoutSection,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in MindMapLayout.values)
                      ChoiceChip(
                        avatar: Icon(layoutIcon(l), size: 18),
                        label: Text(l10n.layoutLabel(l)),
                        selected: layout == l,
                        onSelected: (_) => setDialogState(() => layout = l),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.create),
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
    applyMapStarter(map, starter, l10n);
    await _storage.save(map);
    await _reload();
    if (mounted) await _openEditor(map);
  }

  IconData _starterIcon(MapStarter starter) => switch (starter) {
        MapStarter.blank => Icons.notes_outlined,
        MapStarter.prd => Icons.article_outlined,
        MapStarter.entities => Icons.schema_outlined,
      };

  Future<void> _renameMap(MindMap map) async {
    final l10n = AppLocalizations.of(context);
    final title = await _promptForName(
      dialogTitle: l10n.renameMindMap,
      initial: map.title,
      label: l10n.titleLabel,
      hint: l10n.titleHint,
      confirmLabel: l10n.rename,
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMindMapTitle(map.title)),
        content: Text(l10n.deleteCannotUndo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _storage.delete(map.id);
    await _reload();
  }

  Future<void> _importMap() async {
    final l10n = AppLocalizations.of(context);
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
        SnackBar(content: Text(l10n.importedMap(imported.title))),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importInvalid)),
      );
    }
  }

  Future<void> _showCategoryActions(String name) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l10n.renameCategoryItem(name)),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text(l10n.deleteCategoryItem(name),
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

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context);
    final localeController = context.read<LocaleController>();
    await showDialog<void>(
      context: context,
      builder: (context) {
        final current = localeController.overrideLocale;
        Widget option(Locale? locale) {
          final label = LocaleController.labelFor(
            locale,
            system: l10n.languageSystem,
            en: l10n.languageEnglish,
            id: l10n.languageIndonesian,
          );
          final selected = locale == null
              ? current == null
              : current?.languageCode == locale.languageCode;
          return ListTile(
            title: Text(label),
            trailing: selected
                ? Icon(Icons.check,
                    color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              Navigator.of(context).pop();
              localeController.setLocale(locale);
            },
          );
        }

        return SimpleDialog(
          title: Text(l10n.language),
          children: [
            option(null),
            option(const Locale('en')),
            option(const Locale('id')),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (day == today) return l10n.todayAt(hm);
    if (day == today.subtract(const Duration(days: 1))) {
      return l10n.yesterdayAt(hm);
    }
    return '${dt.day}/${dt.month}/${dt.year} $hm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maps = _maps;
    final filtered = _filteredMaps;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.howToUse,
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HelpScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n.importJson,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: _importMap,
          ),
          PopupMenuButton<String>(
            tooltip: l10n.more,
            onSelected: (value) {
              switch (value) {
                case 'new_category':
                  _createCategory();
                case 'language':
                  _pickLanguage();
                case 'help':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpScreen(),
                    ),
                  );
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
              PopupMenuItem(
                value: 'new_category',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: Text(l10n.newCategory),
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'help',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: Text(l10n.howToUse),
                ),
              ),
              PopupMenuItem(
                value: 'feedback',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(l10n.sendFeedback),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'privacy',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyPolicy),
                ),
              ),
              PopupMenuItem(
                value: 'dmca',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gavel_outlined),
                  title: Text(l10n.dmca),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMap,
        icon: const Icon(Icons.add),
        label: Text(l10n.newMindMap),
      ),
      body: maps == null
          ? const Center(child: CircularProgressIndicator())
          : maps.isEmpty
              ? _EmptyState(
                  onCreate: _createMap,
                  onHelp: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpScreen(),
                    ),
                  ),
                )
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
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.categoryAll),
              selected: _selectedFilter == _kFilterAll,
              onSelected: (_) =>
                  setState(() => _selectedFilter = _kFilterAll),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(l10n.categoryHome),
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
            label: Text(l10n.categoryNew),
            onPressed: _createCategory,
          ),
        ],
      ),
    );
  }

  Widget _buildOfferBanner() {
    final l10n = AppLocalizations.of(context);
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
                    l10n.organizeMapsTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.organizeMapsBody(kCategoryOfferThreshold),
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
                        child: Text(l10n.createCategory),
                      ),
                      TextButton(
                        onPressed: _dismissBanner,
                        child: Text(l10n.notNow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.dismiss,
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
    final l10n = AppLocalizations.of(context);
    final variant = Theme.of(context).colorScheme.onSurfaceVariant;
    final categoryLabel = map.categoryOrHome == kHomeCategory
        ? l10n.categoryHome
        : map.categoryOrHome;
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
                  if (showCategory) categoryLabel,
                  l10n.layoutLabel(map.layout),
                  l10n.nodesLabel(map.nodes.length),
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
          itemBuilder: (context) => [
            PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
            PopupMenuItem(value: 'duplicate', child: Text(l10n.duplicate)),
            PopupMenuItem(
                value: 'move', child: Text(l10n.moveToCategory)),
            PopupMenuItem(value: 'export', child: Text(l10n.exportJson)),
            PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onHelp});

  final VoidCallback onCreate;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart_outlined, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text(l10n.noMindMapsYet,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.noMindMapsHint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.createMindMap),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onHelp,
            icon: const Icon(Icons.help_outline),
            label: Text(l10n.howToUse),
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = category == null
        ? l10n.categoryAll
        : (category == kHomeCategory ? l10n.categoryHome : category!);
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
              l10n.noMapsInCategory(label),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noMapsInCategoryHint,
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
              label: Text(l10n.newMindMap),
            ),
          ],
        ),
      ),
    );
  }
}
