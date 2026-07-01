import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  SharedPrefs._();

  static Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  static Future<bool> setString(String key, String value) async {
    final prefs = await _prefs;
    return prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<bool> setStringList(String key, List<String> values) async {
    final prefs = await _prefs;
    return prefs.setStringList(key, values);
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList(key);
  }

  static Future<bool> setJson(String key, Object value) async {
    return setString(key, jsonEncode(value));
  }

  static Future<dynamic> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    return jsonDecode(raw);
  }

  static Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final value = await getJson(key);
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  static Future<List<dynamic>?> getJsonList(String key) async {
    final value = await getJson(key);
    return value is List ? value : null;
  }

  static Future<bool> remove(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }

  static Future<bool> clear() async {
    final prefs = await _prefs;
    return prefs.clear();
  }
}
