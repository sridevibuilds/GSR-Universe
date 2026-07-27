// Core Offline Caching Utility
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  final SharedPreferences _prefs;

  OfflineCache(this._prefs);

  /// Caches response structures
  Future<void> cacheData(String key, dynamic data) async {
    final rawString = json.encode(data);
    await _prefs.setString(key, rawString);
  }

  /// Retrieves cached structures
  dynamic getCachedData(String key) {
    final rawString = _prefs.getString(key);
    if (rawString != null) {
      try {
        return json.decode(rawString);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Clears cache for a specific key
  Future<void> clearCache(String key) async {
    await _prefs.remove(key);
  }

  /// Purges all local cached data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
