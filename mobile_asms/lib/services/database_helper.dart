import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scholarship.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('asms_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE scholarships(
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      provider TEXT NOT NULL,
      amount REAL NOT NULL,
      deadline TEXT NOT NULL,
      location TEXT NOT NULL,
      distance REAL NOT NULL,
      lastUpdated TEXT NOT NULL
    )
    ''');
  }

  // CRUD Operations for Scholarships

  // Create
  Future<int> insertScholarship(Scholarship scholarship) async {
    final db = await database;
    return await db.insert(
      'scholarships',
      {
        'id': scholarship.id,
        'name': scholarship.name,
        'provider': scholarship.provider,
        'amount': scholarship.amount,
        'deadline': scholarship.deadline,
        'location': scholarship.location,
        'distance': scholarship.distance,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple scholarships
  Future<void> insertScholarships(List<Scholarship> scholarships) async {
    final db = await database;
    final batch = db.batch();

    for (var scholarship in scholarships) {
      batch.insert(
        'scholarships',
        {
          'id': scholarship.id,
          'name': scholarship.name,
          'provider': scholarship.provider,
          'amount': scholarship.amount,
          'deadline': scholarship.deadline,
          'location': scholarship.location,
          'distance': scholarship.distance,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  // Read
  Future<Scholarship?> getScholarship(int id) async {
    final db = await database;
    final maps = await db.query(
      'scholarships',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Scholarship.fromMap(maps.first);
    }
    return null;
  }

  // Read all
  Future<List<Scholarship>> getAllScholarships() async {
    final db = await database;
    final result = await db.query('scholarships');
    return result.map((json) => Scholarship.fromMap(json)).toList();
  }

  // Read with limit
  Future<List<Scholarship>> getScholarshipsWithLimit(int limit) async {
    final db = await database;
    final result = await db.query(
      'scholarships',
      limit: limit,
    );
    return result.map((json) => Scholarship.fromMap(json)).toList();
  }

  // Update
  Future<int> updateScholarship(Scholarship scholarship) async {
    final db = await database;
    return await db.update(
      'scholarships',
      {
        'name': scholarship.name,
        'provider': scholarship.provider,
        'amount': scholarship.amount,
        'deadline': scholarship.deadline,
        'location': scholarship.location,
        'distance': scholarship.distance,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [scholarship.id],
    );
  }

  // Delete
  Future<int> deleteScholarship(int id) async {
    final db = await database;
    return await db.delete(
      'scholarships',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all
  Future<int> deleteAllScholarships() async {
    final db = await database;
    return await db.delete('scholarships');
  }

  // Get count of scholarships
  Future<int> getScholarshipCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM scholarships');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Close the database
  Future close() async {
    final db = await database;
    db.close();
  }
}
