import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelperProgress {
  static final DatabaseHelperProgress instance =
      DatabaseHelperProgress._init();
  static Database? _database;

  DatabaseHelperProgress._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('DB.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _createDB(db, 1);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS test_progress (
      user_test_id INTEGER PRIMARY KEY,
      test_id INTEGER,
      section_index INTEGER,
      question_index INTEGER,
      millis_left INTEGER
    )
    ''');
  }

  Future<void> upsertProgress(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert(
      'test_progress',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getByUserTestId(int userTestId) async {
    final db = await instance.database;
    final results = await db.query(
      'test_progress',
      where: 'user_test_id = ?',
      whereArgs: [userTestId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> deleteByUserTestId(int userTestId) async {
    final db = await instance.database;
    await db.delete(
      'test_progress',
      where: 'user_test_id = ?',
      whereArgs: [userTestId],
    );
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await instance.database;
    return db.query(
      'test_progress',
      orderBy: 'user_test_id DESC',
    );
  }

  Future close() async {
    final db = _database;
    db?.close();
  }
}
