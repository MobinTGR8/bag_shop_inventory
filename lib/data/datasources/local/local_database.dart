import '../../local/shared_prefs.dart';

class LocalDatabase {
  static const String _prefix = 'bag_shop_inventory.local_db.';

  Future<void> init() async {
    await Future<void>.value();
  }

  Future<String?> readString(String key) {
    return SharedPrefs.getString('$_prefix$key');
  }

  Future<bool> writeString(String key, String value) {
    return SharedPrefs.setString('$_prefix$key', value);
  }

  Future<Map<String, dynamic>?> readMap(String key) {
    return SharedPrefs.getJsonMap('$_prefix$key');
  }

  Future<bool> writeMap(String key, Map<String, dynamic> value) {
    return SharedPrefs.setJson('$_prefix$key', value);
  }

  Future<List<dynamic>?> readList(String key) {
    return SharedPrefs.getJsonList('$_prefix$key');
  }

  Future<bool> writeList(String key, List<dynamic> value) {
    return SharedPrefs.setJson('$_prefix$key', value);
  }

  Future<bool> remove(String key) {
    return SharedPrefs.remove('$_prefix$key');
  }

  Future<bool> clear() {
    return SharedPrefs.clear();
  }
}
