import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kai_local.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations(
            id TEXT PRIMARY KEY,
            title TEXT,
            model_id TEXT,
            pinned INTEGER DEFAULT 0,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id TEXT,
            role TEXT,
            content TEXT,
            timestamp TEXT,
            feedback TEXT,
            FOREIGN KEY(conversation_id) REFERENCES conversations(id)
          )
        ''');
      },
    );
  }

  static Future<void> saveConversation(Map<String, dynamic> conv) async {
    final db = await database;
    await db.insert('conversations', conv, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> saveMessage(Map<String, dynamic> msg) async {
    final db = await database;
    await db.insert('messages', msg, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return db.query('conversations', orderBy: 'created_at DESC');
  }

  static Future<List<Map<String, dynamic>>> getMessages(String convId) async {
    final db = await database;
    return db.query('messages', where: 'conversation_id = ?', whereArgs: [convId], orderBy: 'timestamp ASC');
  }

  static Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
  }
}