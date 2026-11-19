import 'package:flutter/material.dart';

import '../core/storage/local_prefs.dart';

/// Alterna e persiste o modo claro/escuro de todo o app.
class TemaViewModel extends ChangeNotifier {
  TemaViewModel({ThemeMode initialMode = ThemeMode.light})
    : _mode = initialMode;

  static const _storageKey = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final saved = await LocalPrefs.getString(_storageKey);
    if (saved != 'dark' && saved != 'light') return;
    final loaded = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (loaded == _mode) return;
    _mode = loaded;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await LocalPrefs.setString(_storageKey, isDark ? 'dark' : 'light');
  }
}
