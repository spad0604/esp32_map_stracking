import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../model/data_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('database.db');
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
    CREATE TABLE dataModel (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      latitude REAL NOT NULL,
      longtitude REAL NOT NULL,
      speed REAL NOT NULL,
      dateTime TEXT NOT NULL,
      timeInDay INTEGER NOT NULL
    )
    ''');
  }

  Future<int> insertDataModel(DataModel data) async {
    final db = await instance.database;
    return await db.insert('dataModel', data.toMap());
  }

  Future<int> deleteDataModel(String dateTime, int timeInDay) async {
    final db = await instance.database;
    return await db.delete(
      'dataModel',
      where: 'dateTime = ? AND timeInDay = ?',
      whereArgs: [dateTime, timeInDay],
    );
  }

  Future<int?> queryMaxTimeInDayByDateTime(String dateTime) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT MAX(timeInDay) as maxTimeInDay FROM dataModel WHERE dateTime = ?',
      [dateTime],
    );

    if (result.isNotEmpty && result.first['maxTimeInDay'] != null) {
      return result.first['maxTimeInDay'] as int;
    } else {
      return null;
    }
  }

  Future<DataModel?> queryByDateTimeAndTimeInDay(String dateTime, int timeInDay) async {
    final db = await instance.database;
    final maps = await db.query(
      'dataModel',
      where: 'dateTime = ? AND timeInDay = ?',
      whereArgs: [dateTime, timeInDay],
    );

    if (maps.isNotEmpty) {
      return DataModel.fromMap(maps.first);
    } else {
      return null;
    }
  }
}
