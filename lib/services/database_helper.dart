import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
    final path = join(dbPath, 'health_app_v2.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE Calories_Records (id INTEGER PRIMARY KEY AUTOINCREMENT, calories INTEGER, datetime TEXT)',
    );
    await db.execute(
      'CREATE TABLE Water_Records (id INTEGER PRIMARY KEY AUTOINCREMENT, amount_ml INTEGER, datetime TEXT)',
    );
    await db.execute(
      'CREATE TABLE Mood_Records (id INTEGER PRIMARY KEY AUTOINCREMENT, score INTEGER, datetime TEXT)',
    );
    await db.execute(
      'CREATE TABLE Activity_Records (id INTEGER PRIMARY KEY AUTOINCREMENT, sport_name TEXT, minutes INTEGER, met REAL, datetime TEXT)',
    );

    await db.execute('''
      CREATE TABLE Sleep_Records (
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        start_time TEXT,
        end_time TEXT,
        datetime TEXT
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final rng = Random();
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));

      await db.insert('Calories_Records', {
        'calories': 400 + rng.nextInt(200),
        'datetime': date.copyWith(hour: 9).toIso8601String(),
      });
      await db.insert('Calories_Records', {
        'calories': 600 + rng.nextInt(300),
        'datetime': date.copyWith(hour: 13).toIso8601String(),
      });
      await db.insert('Calories_Records', {
        'calories': 500 + rng.nextInt(200),
        'datetime': date.copyWith(hour: 19).toIso8601String(),
      });
      await db.insert('Water_Records', {
        'amount_ml': 1000 + rng.nextInt(500),
        'datetime': date.copyWith(hour: 10).toIso8601String(),
      });
      await db.insert('Water_Records', {
        'amount_ml': 700 + rng.nextInt(500),
        'datetime': date.copyWith(hour: 15).toIso8601String(),
      });
      await db.insert('Mood_Records', {
        'score': 2 + rng.nextInt(4),
        'datetime': date.copyWith(hour: 20).toIso8601String(),
      });
      if (rng.nextBool()) {
        await db.insert('Activity_Records', {
          'sport_name': 'Бег',
          'minutes': 30 + rng.nextInt(40),
          'met': 8.0,
          'datetime': date.copyWith(hour: 18).toIso8601String(),
        });
      }

      DateTime wakeTime = date.copyWith(
        hour: 7 + rng.nextInt(2),
        minute: rng.nextInt(59),
      );
      DateTime sleepTime = wakeTime.subtract(
        Duration(hours: 6 + rng.nextInt(3)),
      );

      await db.insert('Sleep_Records', {
        'start_time': sleepTime.toIso8601String(),
        'end_time': wakeTime.toIso8601String(),
        'datetime': wakeTime.toIso8601String(),
      });
    }
  }

  String _getDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<int> insertSleep(DateTime start, DateTime end) async {
    final db = await database;
    return await db.insert('Sleep_Records', {
      'start_time': start.toIso8601String(),
      'end_time': end.toIso8601String(),
      'datetime': end.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSleepForDay(DateTime date) async {
    final db = await database;
    final dateStr = _getDateString(date);
    return await db.query(
      'Sleep_Records',
      where: "datetime LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: "datetime DESC",
    );
  }

  Future<int> updateSleep(int id, DateTime start, DateTime end) async {
    final db = await database;
    return await db.update(
      'Sleep_Records',
      {
        'start_time': start.toIso8601String(),
        'end_time': end.toIso8601String(),
        'datetime': end.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCalories(int calories, DateTime date) async {
    final db = await database;
    return await db.insert('Calories_Records', {
      'calories': calories,
      'datetime': date.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCaloriesForDay(DateTime date) async {
    final db = await database;
    final dateStr = _getDateString(date);
    return await db.query(
      'Calories_Records',
      where: "datetime LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: "datetime DESC",
    );
  }

  Future<int> updateCalories(int id, int calories) async {
    final db = await database;
    return await db.update(
      'Calories_Records',
      {'calories': calories},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCalories(int id) async {
    final db = await database;
    return await db.delete(
      'Calories_Records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertWater(int amount, DateTime date) async {
    final db = await database;
    return await db.insert('Water_Records', {
      'amount_ml': amount,
      'datetime': date.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getWaterForDay(DateTime date) async {
    final db = await database;
    final dateStr = _getDateString(date);
    return await db.query(
      'Water_Records',
      where: "datetime LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: "datetime DESC",
    );
  }

  Future<int> updateWater(int id, int amount) async {
    final db = await database;
    return await db.update(
      'Water_Records',
      {'amount_ml': amount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWater(int id) async {
    final db = await database;
    return await db.delete('Water_Records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSleep(int id) async {
    final db = await database;
    return await db.delete('Sleep_Records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertMood(int score, DateTime date) async {
    final db = await database;
    return await db.insert('Mood_Records', {
      'score': score,
      'datetime': date.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMoodForDay(DateTime date) async {
    final db = await database;
    final dateStr = _getDateString(date);
    return await db.query(
      'Mood_Records',
      where: "datetime LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: "datetime DESC",
    );
  }

  Future<int> updateMood(int id, int score) async {
    final db = await database;
    return await db.update(
      'Mood_Records',
      {'score': score},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMood(int id) async {
    final db = await database;
    return await db.delete('Mood_Records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertActivity(
    String name,
    int minutes,
    double met,
    DateTime date,
  ) async {
    final db = await database;
    return await db.insert('Activity_Records', {
      'sport_name': name,
      'minutes': minutes,
      'met': met,
      'datetime': date.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getActivityForDay(DateTime date) async {
    final db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await db.query(
      'Activity_Records',
      where: "datetime LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: "datetime DESC",
    );
  }

  Future<int> updateActivity(
    int id,
    String name,
    int minutes,
    double met,
  ) async {
    final db = await database;
    return await db.update(
      'Activity_Records',
      {'sport_name': name, 'minutes': minutes, 'met': met},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete(
      'Activity_Records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getRecordsForRange(
    String tableName,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.query(
      tableName,
      where: "datetime >= ? AND datetime <= ?",
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: "datetime ASC",
    );
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete('Calories_Records');
    await db.delete('Water_Records');
    await db.delete('Sleep_Records');
    await db.delete('Mood_Records');
    await db.delete('Activity_Records');
  }
}
