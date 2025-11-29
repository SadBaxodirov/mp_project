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
      onCreate: _createDBTest,
    );
  }

  Future _createDBTest(Database db, int version) async {
    await db.execute('''
    CREATE TABLE tests IF not EXISTS (
      id INTEGER PRIMARY ,
      question_text TEXT,
      image BLOB,
      score FLOAT,
      question_type TEXT,
      section TEXT,
      ansver TEXT
    )
    ''');
  }


  
//tests methods
  Future<void> insertTest(Map<String, dynamic> test) async {
    final db = await instance.database;
    await db.insert('tests', test);
  }

  Future<List<Map<String, dynamic>>> getTests() async {
    final db = await instance.database;
    return await db.query('tests', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getTestsByIdList(List<int> idList) async {
    final db = await instance.database;
    return await db.query('tests', where: 'id IN (${idList.join(',')})', orderBy: 'id DESC');
  }

  Future<void> updateTest(Map<String, dynamic> test) async {
    final db = await instance.database;
    final id = test['id'];
    await db.update('tests', test, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTestById(String id) async {
    final db = await instance.database;
    await db.delete('tests', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = _database;
    db?.close();
  }
}

