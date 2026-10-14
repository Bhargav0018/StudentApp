import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart' as p;

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  // ============================================================
  // DATABASE NAME / VERSION
  // ============================================================

  static const String _databaseName = 'student_help_community.db';

  // Version 5:
  // V1 -> Base database
  // V2 -> Saved resources
  // V3 -> Settings
  // V4 -> User reputation points
  // V5 -> File resources
  static const int _databaseVersion = 5;

  // ============================================================
  // GET DATABASE
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // --------------------------------------------------------
      // WEB / CHROME
      // --------------------------------------------------------

      databaseFactory = databaseFactoryFfiWeb;

      return await databaseFactory.openDatabase(
        _databaseName,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    // ----------------------------------------------------------
    // ANDROID / MOBILE
    // ----------------------------------------------------------

    final databasesPath = await getDatabasesPath();

    final path = p.join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _onCreate(Database db, int version) async {
    // ==========================================================
    // USERS
    // ==========================================================

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        course TEXT NOT NULL,
        college TEXT NOT NULL,
        points INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // ==========================================================
    // QUESTIONS
    // ==========================================================

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // ANSWERS
    // ==========================================================

    await db.execute('''
      CREATE TABLE answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        answer TEXT NOT NULL,
        is_helpful INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (question_id)
          REFERENCES questions(id)
          ON DELETE CASCADE,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // RESOURCES
    // ==========================================================

    // Supports:
    // - Links
    // - Images
    // - PDFs
    // - Documents
    // - Videos
    // - Other files
    //
    // file_data stores the actual file bytes inside SQLite.
    // ==========================================================

    await db.execute('''
      CREATE TABLE resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,

        resource_url TEXT,

        category TEXT NOT NULL,

        resource_type TEXT DEFAULT 'link',

        file_name TEXT,

        mime_type TEXT,

        file_data BLOB,

        created_at TEXT NOT NULL,

        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // NOTIFICATIONS
    // ==========================================================

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT,
        reference_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // SAVED QUESTIONS
    // ==========================================================

    await db.execute('''
      CREATE TABLE saved_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, question_id),
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (question_id)
          REFERENCES questions(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // SAVED RESOURCES
    // ==========================================================

    await db.execute('''
      CREATE TABLE saved_resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        resource_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, resource_id),
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE,
        FOREIGN KEY (resource_id)
          REFERENCES resources(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // SETTINGS
    // ==========================================================

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL UNIQUE,
        dark_mode INTEGER DEFAULT 0,
        notifications_enabled INTEGER DEFAULT 1,
        FOREIGN KEY (user_id)
          REFERENCES users(id)
          ON DELETE CASCADE
      )
    ''');

    // ==========================================================
    // INDEXES
    // ==========================================================

    await db.execute('''
      CREATE INDEX idx_questions_user
      ON questions(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_answers_question
      ON answers(question_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_answers_user
      ON answers(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_resources_user
      ON resources(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_user
      ON notifications(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_saved_resources_user
      ON saved_resources(user_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_saved_questions_user
      ON saved_questions(user_id)
    ''');
  }

  // ============================================================
  // DATABASE UPGRADES
  // ============================================================

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ==========================================================
    // VERSION 2
    // SAVED RESOURCES
    // ==========================================================

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS saved_resources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          resource_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(user_id, resource_id),
          FOREIGN KEY (user_id)
            REFERENCES users(id)
            ON DELETE CASCADE,
          FOREIGN KEY (resource_id)
            REFERENCES resources(id)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_saved_resources_user
        ON saved_resources(user_id)
      ''');
    }

    // ==========================================================
    // VERSION 3
    // SETTINGS
    // ==========================================================

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL UNIQUE,
          dark_mode INTEGER DEFAULT 0,
          notifications_enabled INTEGER DEFAULT 1,
          FOREIGN KEY (user_id)
            REFERENCES users(id)
            ON DELETE CASCADE
        )
      ''');
    }

    // ==========================================================
    // VERSION 4
    // USER REPUTATION POINTS
    // ==========================================================

    if (oldVersion < 4) {
      // Check whether points column already exists.
      final columns = await db.rawQuery('PRAGMA table_info(users)');

      final hasPointsColumn = columns.any(
        (column) => column['name'] == 'points',
      );

      if (!hasPointsColumn) {
        await db.execute('''
          ALTER TABLE users
          ADD COLUMN points INTEGER DEFAULT 0
          ''');
      }
    }

    // ==========================================================
    // VERSION 5
    // FILE RESOURCES
    // ==========================================================

    if (oldVersion < 5) {
      // --------------------------------------------------------
      // RESOURCE TYPE
      // --------------------------------------------------------

      final resourceColumns = await db.rawQuery('PRAGMA table_info(resources)');

      final hasResourceType = resourceColumns.any(
        (column) => column['name'] == 'resource_type',
      );

      if (!hasResourceType) {
        await db.execute('''
          ALTER TABLE resources
          ADD COLUMN resource_type TEXT DEFAULT 'link'
          ''');
      }

      // --------------------------------------------------------
      // FILE NAME
      // --------------------------------------------------------

      final hasFileName = resourceColumns.any(
        (column) => column['name'] == 'file_name',
      );

      if (!hasFileName) {
        await db.execute('''
          ALTER TABLE resources
          ADD COLUMN file_name TEXT
          ''');
      }

      // --------------------------------------------------------
      // MIME TYPE
      // --------------------------------------------------------

      final hasMimeType = resourceColumns.any(
        (column) => column['name'] == 'mime_type',
      );

      if (!hasMimeType) {
        await db.execute('''
          ALTER TABLE resources
          ADD COLUMN mime_type TEXT
          ''');
      }

      // --------------------------------------------------------
      // FILE DATA
      // --------------------------------------------------------

      final hasFileData = resourceColumns.any(
        (column) => column['name'] == 'file_data',
      );

      if (!hasFileData) {
        await db.execute('''
          ALTER TABLE resources
          ADD COLUMN file_data BLOB
          ''');
      }
    }
  }

  // ============================================================
  // INSERT
  // ============================================================

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;

    return await db.insert(table, values);
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> update(
    String table,
    Map<String, dynamic> values,
    String where,
    List<Object?> whereArgs,
  ) async {
    final db = await database;

    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> delete(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {
    final db = await database;

    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // ============================================================
  // QUERY WHERE
  // ============================================================

  Future<List<Map<String, dynamic>>> queryWhere(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {
    final db = await database;

    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  // ============================================================
  // QUERY ALL
  // ============================================================

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;

    return await db.query(table);
  }

  // ============================================================
  // RAW QUERY
  // ============================================================

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;

    return await db.rawQuery(sql, arguments);
  }

  // ============================================================
  // RAW INSERT / UPDATE / DELETE
  // ============================================================

  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final db = await database;

    return await db.rawUpdate(sql, arguments);
  }

  // ============================================================
  // EXECUTE RAW SQL
  // ============================================================

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;

    await db.execute(sql, arguments);
  }

  // ============================================================
  // TRANSACTION
  // ============================================================

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;

    return await db.transaction(action);
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }
}
