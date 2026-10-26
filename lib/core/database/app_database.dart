import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String dbName = 'doxivo_library.db';
  static const int dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  Future<Database> initDatabase({String? customPath}) async {
    final String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, dbName);
      await Directory(databasesPath).create(recursive: true);
    }

    _db = await openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        page_count INTEGER NOT NULL,
        byte_size INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_docs_created ON documents(created_at DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_docs_fav ON documents(is_favorite)');
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
