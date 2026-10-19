import 'package:shared_preferences/shared_preferences.dart';

/// Configuration management for Supabase credentials and URLs.
/// Supports both compile-time `--dart-define` and runtime local persistence.
class SupabaseConfig {
  static const String envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String envWebBaseUrl = String.fromEnvironment('PLAYER_WEB_URL', defaultValue: 'http://localhost:8080');

  static String _url = envUrl;
  static String _anonKey = envAnonKey;
  static String _webBaseUrl = envWebBaseUrl;

  static String get url => _url;
  static String get anonKey => _anonKey;
  static String get webBaseUrl => _webBaseUrl;

  static bool get isConfigured => _url.trim().isNotEmpty && _anonKey.trim().isNotEmpty;

  static Future<void> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('supabase_url');
      final savedKey = prefs.getString('supabase_anon_key');
      final savedWebUrl = prefs.getString('player_web_url');

      if (savedUrl != null && savedUrl.isNotEmpty) _url = savedUrl;
      if (savedKey != null && savedKey.isNotEmpty) _anonKey = savedKey;
      if (savedWebUrl != null && savedWebUrl.isNotEmpty) _webBaseUrl = savedWebUrl;
    } catch (_) {
      // In tests or if SharedPreferences is unavailable, fall back to environment variables
    }
  }

  static Future<void> saveConfig({
    required String url,
    required String anonKey,
    String? webBaseUrl,
  }) async {
    _url = url.trim();
    _anonKey = anonKey.trim();
    if (webBaseUrl != null && webBaseUrl.trim().isNotEmpty) {
      _webBaseUrl = webBaseUrl.trim();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', _url);
      await prefs.setString('supabase_anon_key', _anonKey);
      await prefs.setString('player_web_url', _webBaseUrl);
    } catch (_) {}
  }
}
