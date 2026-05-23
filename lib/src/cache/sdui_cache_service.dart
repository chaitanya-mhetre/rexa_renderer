import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sdui_cached_screen.dart';

class SduiCacheService {
  static SharedPreferences? _prefs;
  static const _prefix = 'sdui_cache_';

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String _key(String routeName) => '$_prefix$routeName';

  static Future<SduiCachedScreen?> get(String routeName) async {
    await initialize();
    final s = _prefs!.getString(_key(routeName));
    if (s == null) return null;
    try {
      return SduiCachedScreen.fromJsonString(s);
    } catch (_) {
      return null;
    }
  }

  static Future<void> put(String routeName, String json, int version) async {
    await initialize();
    final entry = SduiCachedScreen(
      routeName: routeName,
      json: json,
      version: version,
      cachedAt: DateTime.now(),
    );
    await _prefs!.setString(_key(routeName), entry.toJsonString());
  }

  static Future<void> remove(String routeName) async {
    await initialize();
    await _prefs!.remove(_key(routeName));
  }

  static Future<void> clear() async {
    await initialize();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await _prefs!.remove(k);
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _prefs = null;
  }
}
