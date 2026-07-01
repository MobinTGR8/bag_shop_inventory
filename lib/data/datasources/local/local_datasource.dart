import 'local_database.dart';

class LocalDatasource {
  final LocalDatabase _database;

  LocalDatasource({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  Future<void> init() => _database.init();

  Future<String?> readString(String key) => _database.readString(key);

  Future<bool> writeString(String key, String value) =>
      _database.writeString(key, value);

  Future<Map<String, dynamic>?> readMap(String key) => _database.readMap(key);

  Future<bool> writeMap(String key, Map<String, dynamic> value) =>
      _database.writeMap(key, value);

  Future<List<dynamic>?> readList(String key) => _database.readList(key);

  Future<bool> writeList(String key, List<dynamic> value) =>
      _database.writeList(key, value);

  Future<bool> remove(String key) => _database.remove(key);

  Future<bool> clear() => _database.clear();
}
