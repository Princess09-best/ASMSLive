import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scholarship.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'asms_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scholarships(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        provider TEXT,
        amount REAL,
        deadline TEXT,
        location TEXT,
        distance REAL,
        lastUpdated TEXT
      )
    ''');
  }

  // Scholarships Operations
  Future<int> insertScholarship(Scholarship scholarship) async {
    final db = await database;
    return await db.insert(
      'scholarships',
      scholarship.toJson()
        ..addAll({'lastUpdated': DateTime.now().toIso8601String()}),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateScholarship(Scholarship scholarship) async {
    final db = await database;
    return await db.update(
      'scholarships',
      scholarship.toJson()
        ..addAll({'lastUpdated': DateTime.now().toIso8601String()}),
      where: 'id = ?',
      whereArgs: [scholarship.id],
    );
  }

  Future<List<Scholarship>> getScholarships({int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scholarships',
      orderBy: 'deadline ASC',
      limit: limit,
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Scholarship(
        id: maps[i]['id'],
        name: maps[i]['name'],
        provider: maps[i]['provider'],
        amount: maps[i]['amount'],
        deadline: maps[i]['deadline'],
        location: maps[i]['location'],
        distance: maps[i]['distance'],
      );
    });
  }

  Future<Scholarship?> getScholarship(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scholarships',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return Scholarship(
      id: maps[0]['id'],
      name: maps[0]['name'],
      provider: maps[0]['provider'],
      amount: maps[0]['amount'],
      deadline: maps[0]['deadline'],
      location: maps[0]['location'],
      distance: maps[0]['distance'],
    );
  }

  Future<int> deleteScholarship(int id) async {
    final db = await database;
    return await db.delete(
      'scholarships',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertAllScholarships(List<Scholarship> scholarships) async {
    final db = await database;
    final batch = db.batch();

    for (final scholarship in scholarships) {
      batch.insert(
        'scholarships',
        scholarship.toJson()
          ..addAll({'lastUpdated': DateTime.now().toIso8601String()}),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<DateTime?> getLastUpdated() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT lastUpdated FROM scholarships ORDER BY lastUpdated DESC LIMIT 1');

    if (result.isEmpty || result.first['lastUpdated'] == null) {
      return null;
    }

    return DateTime.parse(result.first['lastUpdated'] as String);
  }

  Future<int> getScholarshipsCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM scholarships');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearAllScholarships() async {
    final db = await database;
    await db.delete('scholarships');
  }
}
