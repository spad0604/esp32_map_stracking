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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS dataModel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longtitude REAL NOT NULL,
        speed REAL NOT NULL,
        dateTime TEXT NOT NULL,
        timeInDay INTEGER NOT NULL
      )
      ''');
    } catch (e) {
      print('Error creating table: $e');
    }
  }

  Future<int> insertDataModel(DataModel data) async {
    try {
      final db = await instance.database;
      final id = await db.insert('dataModel', data.toMap());
      print('Inserted data with id: $id');
      return id;
    } catch (e) {
      print('Error inserting data: $e');
      return -1;
    }
  }

  Future<int> deleteDataModel(String dateTime, int timeInDay) async {
    try {
      final db = await instance.database;
      return await db.delete(
        'dataModel',
        where: 'dateTime = ? AND timeInDay = ?',
        whereArgs: [dateTime, timeInDay],
      );
    } catch (e) {
      print('Error deleting data: $e');
      return -1;
    }
  }

  Future<int?> queryMaxTimeInDayByDateTime(String dateTime) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT MAX(timeInDay) as maxTimeInDay FROM dataModel WHERE dateTime = ?',
        [dateTime],
      );
      return result.isNotEmpty ? result.first['maxTimeInDay'] as int? : null;
    } catch (e) {
      print('Error querying max timeInDay: $e');
      return null;
    }
  }

  Future<List<DataModel>> queryListByDateTimeAndTimeInDay(String dateTime, int timeInDay) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        'dataModel',
        where: 'dateTime = ? AND timeInDay = ?',
        whereArgs: [dateTime, timeInDay],
      );

      return maps.isNotEmpty
          ? maps.map((map) => DataModel.fromMap(map)).toList()
          : [];
    } catch (e) {
      print('Error querying list: $e');
      return [];
    }
  }

  Future<int> countUniqueTimeInDayByDateTime(String dateTime) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(DISTINCT timeInDay) as uniqueCount FROM dataModel WHERE dateTime = ?',
        [dateTime],
      );

      return result.isNotEmpty && result.first['uniqueCount'] != null
          ? result.first['uniqueCount'] as int
          : 0;
    } catch (e) {
      print('Error counting unique timeInDay: $e');
      return 0;
    }
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
