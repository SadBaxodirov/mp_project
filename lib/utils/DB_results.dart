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

//start_time YYYY-MM-DD HH:MM:SS
  Future _createDBresult(Database db, int version) async {
    await db.execute('''
    CREATE TABLE results IF not EXISTS (
      question_Id INTEGER FOREIGN KEY,
      right_answer TEXT,
      user_answer TEXT,
      score FLOAT,
      start_time TEXT,
    )
    ''');
  }

//results methods
  Future<List<Map<String, dynamic>>> getResultsbyTime(String time) async {
    final db = await instance.database;
    return await db.query('results', where: 'start_time = ?', whereArgs: [time]);
  }

  Future<void> insertResult(Map<String, dynamic> result) async {
    final db = await instance.database;
    await db.insert('results', result);
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await instance.database;
    return await db.query('results', orderBy: 'start_time DESC');
  }

  Future<List<Map<String, dynamic>>> getResultsSums() async {
    final db = await instance.database;

    final result = await db.rawQuery(
    '''
    SELECT SUM(Score) as total_score, start_time
    FROM results
    GROUP BY start_timec
    '''
  );
    
    return result;
  }

  Future close() async {
    final db = _database;
    db?.close();
  }
}

