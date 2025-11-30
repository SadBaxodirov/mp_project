import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
      onCreate: _createDBresult,
    );
  }

  Future _createDBresult(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS user_answers (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_test_id    INTEGER NOT NULL,
    question_id     INTEGER NOT NULL,
    selected_option_id INTEGER,
    is_correct      INTEGER NOT NULL CHECK (is_correct IN (0,1))),
    FOREIGN KEY (user_test_id) REFERENCES tests(test_id),
    FOREIGN KEY (question_id) REFERENCES tests(question_id);
    )
    ''');
  }

//results methods
  Future<List<Map<String, dynamic>>> getResultsbyId(String id) async {
    final db = await instance.database;
    return await db.query('user_answers', where: 'question_id = ?', whereArgs: [id]);
  }

  Future<void> insertResult(Map<String, dynamic> result) async {
    final db = await instance.database;
    await db.insert('user_answers', result);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await instance.database;
    return await db.query('user_answers', orderBy: 'question_id DESC');
  }

  Future<void> deleteResultsById(String id) async {
    final db = await instance.database;
    await db.delete('user_answers', where: 'question_id = ?', whereArgs: [id]);
  }

  Future<void> deleteResults() async {
    final db = await instance.database;
    await db.delete('user_answers');
  }

  Future close() async {
    final db = _database;
    db?.close();
  }
}

