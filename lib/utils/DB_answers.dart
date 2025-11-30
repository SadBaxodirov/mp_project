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
      onOpen: (db) async {
        // Ensure both answers and tests tables exist for resume flows.
        await _createDBresult(db, 1);
        await db.execute('''
        CREATE TABLE IF NOT EXISTS tests (
          test_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          question_text TEXT,
          image TEXT,
          score REAL,
          question_type TEXT,
          section TEXT,
          ansver TEXT,
          PRIMARY KEY (test_id, question_id)
        )
        ''');
      },
    );
  }

  Future _createDBresult(Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS user_answers (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_test_id        INTEGER NOT NULL,
    question_id         INTEGER NOT NULL,
    selected_option_id  INTEGER,
    is_correct          INTEGER NOT NULL CHECK (is_correct IN (0,1)),
    FOREIGN KEY (user_test_id) REFERENCES tests(test_id),
    FOREIGN KEY (question_id) REFERENCES tests(question_id)
    );
    ''');
  }

//results methods
  Future<List<Map<String, dynamic>>> getResultsbyId(String id) async {
    final db = await instance.database;
    return await db
        .query('user_answers', where: 'question_id = ?', whereArgs: [id]);
  }

  Future<void> insertResult(Map<String, dynamic> result) async {
    final db = await instance.database;
    await db.insert('user_answers', result);
  }

  Future<void> upsertResult(Map<String, dynamic> result) async {
    final db = await instance.database;
    final userTestId = result['user_test_id'];
    final questionId = result['question_id'];
    await db.delete(
      'user_answers',
      where: 'user_test_id = ? AND question_id = ?',
      whereArgs: [userTestId, questionId],
    );
    await db.insert('user_answers', result);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await instance.database;
    return await db.query('user_answers', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getByUserTestId(int userTestId) async {
    final db = await instance.database;
    return await db.query(
      'user_answers',
      where: 'user_test_id = ?',
      whereArgs: [userTestId],
    );
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
