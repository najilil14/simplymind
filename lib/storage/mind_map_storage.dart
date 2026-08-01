import 'package:shared_preferences/shared_preferences.dart';

import '../models/mind_map.dart';

/// Persists mind maps as JSON strings.
///
/// Uses shared_preferences, which maps to platform-native local storage:
/// SharedPreferences on Android, NSUserDefaults on iOS and localStorage in
/// web browsers. Everything stays on the device - no network involved.
class MindMapStorage {
  static const String _keyPrefix = 'simplymind.map.';

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
}
