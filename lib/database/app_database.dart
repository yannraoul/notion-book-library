import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the single `sqflite` connection + schema for the app's local
/// database (`app.db`) — currently just `BooksCache`'s offline read cache.
/// All `AppDatabase` instances share one underlying [Database] via the
/// static [_db] cache, so constructing `AppDatabase()` wherever it's
/// needed never opens a second connection to the same file.
class AppDatabase {
  static const _dbName = 'app.db';
  static const _version = 2;

  static Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      join(dir, _dbName),
      version: _version,
      onCreate: (db, version) async {
        await _createBooksTable(db);
        await _createSettingsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createSettingsTable(db);
      },
    );
    _db = db;
    return db;
  }

  /// Non-secret app preferences (theme, language) as key/value rows —
  /// see `SettingsStorage`. Not for secrets, the Notion token stays in
  /// `flutter_secure_storage` via `NotionTokenStorage`.
  Future<void> _createSettingsTable(Database db) async {
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }

  /// Full-replace cache mirroring `NotionApi.queryBooks`'s read surface —
  /// see `BooksCache`. `authors`/`genres` are stored as display-name
  /// strings already resolved from the `Authors*`/`Genres*` relations
  /// (joined with `, `), not raw Notion ids.
  Future<void> _createBooksTable(Database db) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        authors TEXT,
        isbn TEXT,
        pages INTEGER,
        published_date TEXT,
        cover_url TEXT,
        api_categories TEXT,
        genres TEXT,
        status TEXT,
        current_page REAL,
        date_started TEXT,
        date_finished TEXT,
        rating INTEGER
      )
    ''');
  }
}
