import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ProfilePhotoStore {
  ProfilePhotoStore._();

  static final ProfilePhotoStore instance = ProfilePhotoStore._();
  static Database? _database;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'profile.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS profile_photos (
            user_id INTEGER PRIMARY KEY,
            image BLOB NOT NULL,
            updated_at TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  Future<Uint8List?> loadPhoto(int userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_key(userId));
      if (encoded == null) return null;
      return Uint8List.fromList(base64Decode(encoded));
    }

    final db = await _db;
    final rows = await db.query(
      'profile_photos',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final data = rows.first['image'];
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    return null;
  }

  Future<void> savePhoto(int userId, Uint8List imageBytes) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), base64Encode(imageBytes));
      return;
    }

    final db = await _db;
    await db.insert(
      'profile_photos',
      {
        'user_id': userId,
        'image': imageBytes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _key(int userId) => 'profile_photo_$userId';
}
