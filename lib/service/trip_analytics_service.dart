import 'dart:math';
import '../database/database_helper.dart';
import '../model/data_model.dart';
import '../model/trip_model.dart';

class TripAnalyticsService {
  final DatabaseHelper _database = DatabaseHelper.instance;

  // Phân tích hiệu suất đạp xe
  Future<Map<String, dynamic>> analyzeCyclingPerformance(String tripId) async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'dataModel',
        where: 'tripId = ?',
        whereArgs: [tripId],
        orderBy: 'timestamp ASC',
      );

      if (maps.isEmpty) return {};

      final dataPoints = maps.map((map) => DataModel.fromMap(map)).toList();

      // Phân tích tốc độ (phù hợp với xe đạp: 0-50 km/h)
      final speeds = dataPoints.map((d) => d.speed.toDouble()).where((s) => s > 0).toList();
      final accelerations = _calculateAccelerations(dataPoints);

      // Đếm số lần tăng tốc mạnh (tăng tốc > 1.5 m/s² - phù hợp xe đạp)
      final strongAcceleration = accelerations.where((a) => a > 1.5).length;

      // Đếm số lần giảm tốc mạnh (giảm tốc > 2.0 m/s²)
      final strongDeceleration = accelerations.where((a) => a < -2.0).length;

      // Đếm số lần đạp nhanh (> 25 km/h - tốc độ cao cho xe đạp)
      final highSpeedEvents = speeds.where((s) => s > 25).length;

      // Tính điểm hiệu suất đạp xe (0-100)
      final performanceScore = _calculateCyclingScore(
          strongAcceleration,
          strongDeceleration,
          highSpeedEvents,
          dataPoints.length,
          speeds
      );

      // Phân loại cường độ tập luyện
      final intensity = _calculateIntensity(speeds);

      return {
        'performanceScore': performanceScore,
        'strongAcceleration': strongAcceleration,
        'strongDeceleration': strongDeceleration,
        'highSpeedEvents': highSpeedEvents,
        'averageSpeed': speeds.isNotEmpty ? speeds.reduce((a, b) => a + b) / speeds.length : 0.0,
        'maxSpeed': speeds.isNotEmpty ? speeds.reduce(max) : 0.0,
        'smoothnessScore': _calculateSmoothnessScore(accelerations),
        'intensity': intensity,
        'consistencyScore': _calculateConsistencyScore(speeds),
      };
    } catch (e) {
      print('Error analyzing cycling performance: $e');
      return {};
    }
  }

  // Tính toán gia tốc
  List<double> _calculateAccelerations(List<DataModel> dataPoints) {
    List<double> accelerations = [];

    for (int i = 1; i < dataPoints.length; i++) {
      final prev = dataPoints[i - 1];
      final curr = dataPoints[i];

      final timeDiff = (curr.timestamp! - prev.timestamp!) / 1000.0; // seconds
      if (timeDiff > 0) {
        final speedDiff = (curr.speed.toDouble() - prev.speed.toDouble()) * 0.277778; // km/h to m/s
        final acceleration = speedDiff / timeDiff;
        accelerations.add(acceleration);
      }
    }

    return accelerations;
  }

  // Tính điểm hiệu suất đạp xe
  double _calculateCyclingScore(int strongAccel, int strongDecel, int highSpeed, int totalPoints, List<double> speeds) {
    if (totalPoints == 0) return 100.0;

    // Với xe đạp, tăng tốc mạnh và tốc độ cao là tích cực
    final accelBonus = (strongAccel / totalPoints) * 20; // Bonus cho tăng tốc tốt
    final speedBonus = (highSpeed / totalPoints) * 30; // Bonus cho duy trì tốc độ cao
    final decelPenalty = (strongDecel / totalPoints) * 10; // Penalty nhẹ cho phanh gấp

    // Bonus cho tốc độ trung bình
    final avgSpeed = speeds.isNotEmpty ? speeds.reduce((a, b) => a + b) / speeds.length : 0.0;
    final avgSpeedBonus = (avgSpeed / 30) * 20; // Bonus tối đa 20 điểm cho tốc độ TB 30km/h

    final score = 50 + accelBonus + speedBonus + avgSpeedBonus - decelPenalty;
    return score.clamp(0.0, 100.0);
  }

  // Tính cường độ tập luyện
  String _calculateIntensity(List<double> speeds) {
    if (speeds.isEmpty) return 'Unknown';

    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;

    if (avgSpeed >= 25) return 'High Intensity'; // Tốc độ cao
    if (avgSpeed >= 15) return 'Moderate Intensity'; // Tốc độ trung bình
    if (avgSpeed >= 8) return 'Light Intensity'; // Tốc độ nhẹ
    return 'Very Light'; // Đi chậm
  }

  // Tính điểm nhất quán trong tốc độ
  double _calculateConsistencyScore(List<double> speeds) {
    if (speeds.length < 2) return 100.0;

    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    final variance = _calculateVariance(speeds);
    final coefficient = variance / (mean * mean); // Coefficient of variation

    // Điểm nhất quán cao khi tốc độ ít biến động
    final consistencyScore = 100 - (coefficient * 100).clamp(0.0, 100.0);
    return consistencyScore;
  }

  // Tính điểm mượt mà trong đạp xe
  double _calculateSmoothnessScore(List<double> accelerations) {
    if (accelerations.isEmpty) return 100.0;

    final variance = _calculateVariance(accelerations);
    final smoothnessScore = 100 - (variance * 5).clamp(0.0, 100.0); // Giảm hệ số cho xe đạp

    return smoothnessScore;
  }

  // Tính phương sai
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();

    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  // Ước tính calories đã đốt cháy (thay thế cho tiêu thụ nhiên liệu)
  Future<double> estimateCaloriesBurned(String tripId) async {
    try {
      final distance = await _database.getTotalDistanceByTrip(tripId);
      final analysis = await analyzeCyclingPerformance(tripId);
      
      // Công thức mới tính calories cho xe đạp
      // Cơ bản: ~300-400 calories/giờ tùy theo cường độ
      // Giả sử tốc độ trung bình 15km/h, ta có:
      // 300 calories/giờ = 20 calories/km
      double baseCalories = distance * 20; // 20 calories/km cơ bản
      
      // Điều chỉnh dựa trên cường độ
      final intensity = analysis['intensity'] ?? 'Light Intensity';
      double intensityMultiplier = 1.0;

      switch (intensity) {
        case 'High Intensity':
          intensityMultiplier = 2.0; // 40 calories/km
          break;
        case 'Moderate Intensity':
          intensityMultiplier = 1.5; // 30 calories/km
          break;
        case 'Light Intensity':
          intensityMultiplier = 1.0; // 20 calories/km
          break;
        default:
          intensityMultiplier = 0.8; // 16 calories/km
      }
      
      // Thêm hệ số điều chỉnh dựa trên tốc độ trung bình
      final avgSpeed = analysis['averageSpeed'] ?? 0.0;
      if (avgSpeed > 0) {
        // Tốc độ càng cao, đốt calories càng nhiều
        final speedMultiplier = 1.0 + (avgSpeed / 30.0); // Tăng 1% cho mỗi km/h
        return baseCalories * intensityMultiplier * speedMultiplier;
      }

      return baseCalories * intensityMultiplier;
    } catch (e) {
      print('Error estimating calories burned: $e');
      return 0.0;
    }
  }

  // Phân tích xu hướng đạp xe theo thời gian
  Future<Map<String, dynamic>> getCyclingTrendAnalysis(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final db = await _database.database;
      final maps = await db.query(
        'dataModel',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
        orderBy: 'timestamp ASC',
      );

      // Group by trip
      Map<String, List<DataModel>> tripGroups = {};
      for (final map in maps) {
        final data = DataModel.fromMap(map);
        final tripId = data.tripId ?? 'unknown';
        tripGroups.putIfAbsent(tripId, () => []).add(data);
      }

      List<double> dailyDistances = [];
      List<double> averageSpeeds = [];
      List<double> performanceScores = [];
      List<double> caloriesBurned = [];

      for (final entry in tripGroups.entries) {
        final tripData = entry.value;
        final tripId = entry.key;

        if (tripData.length >= 2) {
          // Calculate distance for this trip
          double tripDistance = 0.0;
          for (int i = 1; i < tripData.length; i++) {
            tripDistance += _calculateDistance(
              tripData[i-1].latitude.toDouble(),
              tripData[i-1].longitude.toDouble(),
              tripData[i].latitude.toDouble(),
              tripData[i].longitude.toDouble(),
            );
          }
          dailyDistances.add(tripDistance);

          // Calculate average speed
          final speeds = tripData.map((d) => d.speed.toDouble()).where((s) => s > 0).toList();
          if (speeds.isNotEmpty) {
            averageSpeeds.add(speeds.reduce((a, b) => a + b) / speeds.length);
          }

          // Calculate performance score
          final accelerations = _calculateAccelerations(tripData);
          final strongAccel = accelerations.where((a) => a > 1.5).length;
          final strongDecel = accelerations.where((a) => a < -2.0).length;
          final highSpeed = speeds.where((s) => s > 25).length;

          final score = _calculateCyclingScore(strongAccel, strongDecel, highSpeed, tripData.length, speeds);
          performanceScores.add(score);

          // Estimate calories for this trip
          final calories = tripDistance * 45 * _getIntensityMultiplier(speeds);
          caloriesBurned.add(calories);
        }
      }

      return {
        'totalTrips': tripGroups.length,
        'totalDistance': dailyDistances.isNotEmpty ? dailyDistances.reduce((a, b) => a + b) : 0.0,
        'averageDistance': dailyDistances.isNotEmpty ? dailyDistances.reduce((a, b) => a + b) / dailyDistances.length : 0.0,
        'averageSpeed': averageSpeeds.isNotEmpty ? averageSpeeds.reduce((a, b) => a + b) / averageSpeeds.length : 0.0,
        'averagePerformanceScore': performanceScores.isNotEmpty ? performanceScores.reduce((a, b) => a + b) / performanceScores.length : 100.0,
        'totalCaloriesBurned': caloriesBurned.isNotEmpty ? caloriesBurned.reduce((a, b) => a + b) : 0.0,
        'distanceTrend': _calculateTrend(dailyDistances),
        'performanceTrend': _calculateTrend(performanceScores),
      };
    } catch (e) {
      print('Error getting cycling trend analysis: $e');
      return {};
    }
  }

  // Helper method để tính hệ số cường độ
  double _getIntensityMultiplier(List<double> speeds) {
    if (speeds.isEmpty) return 1.0;

    final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;

    if (avgSpeed >= 25) return 1.4; // High intensity
    if (avgSpeed >= 15) return 1.2; // Moderate intensity
    if (avgSpeed >= 8) return 1.0;  // Light intensity
    return 0.8; // Very light
  }

  // Tính xu hướng (tăng/giảm)
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';

    final firstHalf = values.take(values.length ~/ 2).toList();
    final secondHalf = values.skip(values.length ~/ 2).toList();

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final diff = secondAvg - firstAvg;
    final threshold = firstAvg * 0.05; // 5% threshold

    if (diff > threshold) return 'improving';
    if (diff < -threshold) return 'declining';
    return 'stable';
  }

  // Helper method to calculate distance
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    lat1 = lat1 * (pi / 180);
    lat2 = lat2 * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  // Tính tổng calories đã đốt cháy cho tất cả các chuyến đi
  Future<double> getTotalCaloriesBurned() async {
    try {
      final db = await _database.database;
      final maps = await db.query(
        'dataModel',
        distinct: true,
        columns: ['tripId'],
      );

      double totalCalories = 0.0;
      for (final map in maps) {
        final tripId = map['tripId'] as String;
        final calories = await estimateCaloriesBurned(tripId);
        totalCalories += calories;
      }

      return totalCalories;
    } catch (e) {
      print('Error calculating total calories burned: $e');
      return 0.0;
    }
  }
} 