import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/app_database.dart';

/// Persists non-secret app preferences (theme, language) as key/value rows
/// in the shared [AppDatabase]'s `settings` table. Not for secrets — see
/// `notion_token_storage.dart` for that (platform keychain/keystore).
///
/// Deliberately generic key/value strings (not typed to `AppTheme`/
/// `AppLanguage`) — those enums live in their own provider files, and this
/// class staying decoupled from them avoids a circular import.
class SettingsStorage {
  final AppDatabase _appDb;

  SettingsStorage({AppDatabase? appDatabase}) : _appDb = appDatabase ?? AppDatabase();

  Future<String?> read(String key) async {
    final db = await _appDb.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> write(String key, String value) async {
    final db = await _appDb.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String key) async {
    final db = await _appDb.database;
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
