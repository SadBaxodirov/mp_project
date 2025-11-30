import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelperTests {
  static final DatabaseHelperTests instance = DatabaseHelperTests._init();
  static Database? _database;

  DatabaseHelperTests._init();

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
      onCreate: _createDBTest,
      onOpen: (db) async {
        await _createDBTest(db, 1);
      },
    );
  }

  Future _createDBTest(Database db, int version) async {
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
  }

//tests methods
  Future<void> insertTest(Map<String, dynamic> test) async {
    final db = await instance.database;
    await db.insert(
      'tests',
      test,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTests() async {
    final db = await instance.database;
    return await db
        .rawQuery('SELECT DISTINCT test_id FROM tests ORDER BY test_id DESC');
  }

  Future<List<Map<String, dynamic>>> getTestsById(int id) async {
    final db = await instance.database;
    return await db.query('tests', where: 'test_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getTestsByIdList(List<int> idList) async {
    final db = await instance.database;
    return await db.query('tests',
        where: 'test_id IN (${idList.join(',')})', orderBy: 'id DESC');
  }

  Future<void> updateTest(Map<String, dynamic> test) async {
    final db = await instance.database;
    final id = test['test_id'];
    await db.update('tests', test, where: 'test_id = ?', whereArgs: [id]);
  }

  Future<void> deleteTestById(String id) async {
    final db = await instance.database;
    await db.delete('tests', where: 'test_id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = _database;
    db?.close();
  }
}
