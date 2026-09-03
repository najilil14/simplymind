import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and notifies the app's UI locale override.
///
/// `null` means follow the device/system locale.
class LocaleController extends ChangeNotifier {
  LocaleController();

  static const _prefsKey = 'simplymind.locale';

  /// Supported app locales (must match ARB files).
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  Locale? _override;
  bool _ready = false;

  Locale? get overrideLocale => _override;
  bool get isReady => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty && code != 'system') {
      _override = Locale(code);
    } else {
      _override = null;
    }
    _ready = true;
    notifyListeners();
  }

  /// Pass `null` for system default.
  Future<void> setLocale(Locale? locale) async {
    _override = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_prefsKey, 'system');
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    notifyListeners();
  }

  static String labelFor(Locale? locale, {required String system, required String en, required String id}) {
    if (locale == null) return system;
    return switch (locale.languageCode) {
      'id' => id,
      _ => en,
    };
  }
}
