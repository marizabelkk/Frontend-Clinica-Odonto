import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais (tema, "lembrar-me"). Nunca lança: se o armazenamento
/// não estiver disponível (ex.: testes), simplesmente não persiste.
abstract final class LocalPrefs {
  static Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
