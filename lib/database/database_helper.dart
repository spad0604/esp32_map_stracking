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
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      // Xóa bảng cũ nếu tồn tại
      await db.execute('DROP TABLE IF EXISTS dataModel');

      // Tạo bảng mới với cấu trúc đúng
      await db.execute('''
      CREATE TABLE dataModel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        speed REAL NOT NULL,
        dateTime TEXT NOT NULL,
        timeInDay INTEGER NOT NULL,
        tripId TEXT,
        timestamp INTEGER
      )
      ''');

      // Tạo index để tối ưu query
      await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_datetime_timeinday 
      ON dataModel(dateTime, timeInDay)
      ''');

      await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tripid 
      ON dataModel(tripId)
      ''');
    } catch (e) {
      print('Error creating table: $e');
      rethrow; // Thêm rethrow để báo lỗi rõ ràng hơn
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Thêm cột mới thay vì xóa toàn bộ dữ liệu
        await db.execute('ALTER TABLE dataModel ADD COLUMN tripId TEXT');
        await db.execute('ALTER TABLE dataModel ADD COLUMN timestamp INTEGER');

        // Tạo index mới
        await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_tripid 
        ON dataModel(tripId)
        ''');
      }

      // Không xóa dữ liệu cũ, chỉ cập nhật cấu trúc
      print('Database upgraded successfully from version $oldVersion to $newVersion');
    } catch (e) {
      print('Error upgrading database: $e');
      // Nếu có lỗi nghiêm trọng, mới xóa và tạo lại
      await db.execute('DROP TABLE IF EXISTS dataModel');
      await _createDB(db, newVersion);
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

  //Tìm so hanh trinh trong ngay
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

  // Thêm method để tính tổng quãng đường của một trip
  Future<double> getTotalDistanceByTrip(String tripId) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        'dataModel',
        where: 'tripId = ?',
        whereArgs: [tripId],
        orderBy: 'timestamp ASC',
      );

      if (maps.length < 2) return 0.0;

      double totalDistance = 0.0;
      for (int i = 1; i < maps.length; i++) {
        final prev = DataModel.fromMap(maps[i - 1]);
        final curr = DataModel.fromMap(maps[i]);

        totalDistance += _calculateDistance(
          prev.latitude.toDouble(),
          prev.longitude.toDouble(),
          curr.latitude.toDouble(),
          curr.longitude.toDouble(),
        );
      }

      return totalDistance;
    } catch (e) {
      print('Error calculating total distance: $e');
      return 0.0;
    }
  }

  // Thêm method để lấy tốc độ trung bình của trip
  Future<double> getAverageSpeedByTrip(String tripId) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT AVG(speed) as avgSpeed FROM dataModel WHERE tripId = ? AND speed > 0',
        [tripId],
      );

      return result.isNotEmpty && result.first['avgSpeed'] != null
          ? (result.first['avgSpeed'] as double)
          : 0.0;
    } catch (e) {
      print('Error calculating average speed: $e');
      return 0.0;
    }
  }

  // Thêm method để lấy thời gian của trip
  Future<Duration> getTripDuration(String tripId) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery(
        'SELECT MIN(timestamp) as startTime, MAX(timestamp) as endTime FROM dataModel WHERE tripId = ?',
        [tripId],
      );

      if (result.isNotEmpty &&
          result.first['startTime'] != null &&
          result.first['endTime'] != null) {
        final startTime = result.first['startTime'] as int;
        final endTime = result.first['endTime'] as int;
        return Duration(milliseconds: endTime - startTime);
      }

      return Duration.zero;
    } catch (e) {
      print('Error calculating trip duration: $e');
      return Duration.zero;
    }
  }

  // Helper method để tính khoảng cách
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers
    double dLat = (lat2 - lat1) * (3.14159265359 / 180);
    double dLon = (lon2 - lon1) * (3.14159265359 / 180);

    lat1 = lat1 * (3.14159265359 / 180);
    lat2 = lat2 * (3.14159265359 / 180);

    double a = (dLat / 2).abs() * (dLat / 2).abs() +
        (lat1).abs() * (lat2).abs() * (dLon / 2).abs() * (dLon / 2).abs();
    double c = 2 * (a.abs().clamp(0.0, 1.0)).abs();

    return R * c;
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }

  // Thêm method để lấy tất cả trips trong ngày
  Future<List<Map<String, dynamic>>> getTripsByDate(String dateTime) async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT DISTINCT timeInDay, tripId, MIN(timestamp) as startTime, MAX(timestamp) as endTime,
               COUNT(*) as pointCount
        FROM dataModel 
        WHERE dateTime = ? AND tripId IS NOT NULL
        GROUP BY timeInDay, tripId
        ORDER BY timeInDay ASC
      ''', [dateTime]);

      return result;
    } catch (e) {
      print('Error getting trips by date: $e');
      return [];
    }
  }

  // Thêm method để kiểm tra xem có dữ liệu trong database không
  Future<bool> hasData() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM dataModel');
      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      print('Error checking data existence: $e');
      return false;
    }
  }

  // Thêm method để lấy thống kê tổng quan
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await instance.database;
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as totalPoints,
          COUNT(DISTINCT dateTime) as totalDays,
          COUNT(DISTINCT tripId) as totalTrips,
          MIN(dateTime) as firstDate,
          MAX(dateTime) as lastDate
        FROM dataModel
      ''');

      return result.first;
    } catch (e) {
      print('Error getting database stats: $e');
      return {};
    }
  }

  Future<double> getTotalDistance() async {
    try {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT SUM(distance) as total_distance 
        FROM (
          SELECT tripId, 
                 SUM(distance) as distance 
          FROM dataModel 
          GROUP BY tripId
        )
      ''');

      if (result.isNotEmpty && result[0]['total_distance'] != null) {
        return (result[0]['total_distance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting total distance: $e');
      return 0.0;
    }
  }
}
