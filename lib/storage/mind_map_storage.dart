import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/mind_map.dart';

/// Persists mind maps as JSON strings.
///
/// Uses shared_preferences, which maps to platform-native local storage:
/// SharedPreferences on Android, NSUserDefaults on iOS and localStorage in
/// web browsers. Everything stays on the device - no network involved.
class MindMapStorage {
  static const String _keyPrefix = 'simplymind.map.';
  static const String _categoriesKey = 'simplymind.categories';
  static const String _categoryBannerDismissedKey =
      'simplymind.categoryBannerDismissed';

  Future<List<MindMap>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final maps = <MindMap>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_keyPrefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        maps.add(MindMap.decode(raw));
      } catch (_) {
        // Skip unreadable entries instead of breaking the whole list.
      }
    }
    maps.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return maps;
  }

  Future<void> save(MindMap map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix${map.id}', map.encode());
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$id');
  }

  /// Custom category names (never includes [kHomeCategory]).
  Future<List<String>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoriesKey);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty && e != kHomeCategory)
          .toList();
      // Preserve order, drop duplicates.
      final seen = <String>{};
      return list.where((c) => seen.add(c)).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = <String>[];
    final seen = <String>{};
    for (final c in categories) {
      final name = c.trim();
      if (name.isEmpty || name == kHomeCategory) continue;
      if (seen.add(name)) cleaned.add(name);
    }
    await prefs.setString(_categoriesKey, jsonEncode(cleaned));
  }

  /// Ensures [name] is in the saved category list. Returns the trimmed name,
  /// or null if it is empty / Home.
  Future<String?> ensureCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == kHomeCategory) return null;
    final cats = await loadCategories();
    if (!cats.contains(trimmed)) {
      cats.add(trimmed);
      await saveCategories(cats);
    }
    return trimmed;
  }

  Future<bool> isCategoryBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_categoryBannerDismissedKey) ?? false;
  }

  Future<void> setCategoryBannerDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_categoryBannerDismissedKey, value);
  }
}
