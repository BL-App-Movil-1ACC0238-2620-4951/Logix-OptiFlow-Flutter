import 'package:sqflite/sqflite.dart';

/// Última respuesta descargada de una consulta (en JSON), para mostrarla sin conexión.
class CachedResponse {
  const CachedResponse({required this.key, required this.json, required this.savedAtMillis});

  final String key;
  final String json;
  final int savedAtMillis;
}

/// Base de datos local (sqflite): caché de solo lectura de lo último consultado.
class AppDatabase {
  static const _name = 'optiflow.db';
  static const cachedResponses = 'cached_responses';

  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    try {
      return await openDatabase(
        '${await getDatabasesPath()}/$_name',
        version: 1,
        onCreate: (db, _) => db.execute(
          'CREATE TABLE $cachedResponses (key TEXT PRIMARY KEY, json TEXT NOT NULL, saved_at_millis INTEGER NOT NULL)',
        ),
      );
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  CachedResponseDao get cachedResponseDao => CachedResponseDao(this);
}

class CachedResponseDao {
  const CachedResponseDao(this._db);

  final AppDatabase _db;

  Future<CachedResponse?> get(String key) async {
    final rows = await (await _db.database).query(AppDatabase.cachedResponses, where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return CachedResponse(key: row['key'] as String, json: row['json'] as String, savedAtMillis: row['saved_at_millis'] as int);
  }

  Future<void> save(CachedResponse response) async => (await _db.database).insert(
        AppDatabase.cachedResponses,
        {'key': response.key, 'json': response.json, 'saved_at_millis': response.savedAtMillis},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> clear() async => (await _db.database).delete(AppDatabase.cachedResponses);
}
