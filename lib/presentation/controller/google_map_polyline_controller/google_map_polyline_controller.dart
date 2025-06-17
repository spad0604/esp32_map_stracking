import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:google_map_in_flutter/database/database_helper.dart';
import 'package:google_map_in_flutter/service/firebase_service.dart';
import 'package:google_map_in_flutter/service/trip_analytics_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../model/data_model.dart';
import '../../../model/trip_model.dart';

enum TripState { idle, countdown, active, paused }

class GoogleMapPolylineController extends SuperController {
  final database = DatabaseHelper.instance;
  final FirebaseService firebaseService = FirebaseService();
  final TripAnalyticsService analyticsService = TripAnalyticsService();

  Rxn<GoogleMapController> mapController = Rxn<GoogleMapController>();
  final List<LatLng> pointOnMap = [];

  final RxInt elapsedMinutes = 0.obs;
  final RxInt elapsedSeconds = 0.obs;
  final RxString formattedTime = '00:00:00'.obs;
  Timer? _timer;

  Rxn<double> speed = Rxn<double>();
  Rxn<double> distance = Rxn<double>(0.0);
  Rxn<double> maxSpeed = Rxn<double>(0.0);
  Rxn<double> averageSpeed = Rxn<double>(0.0);

  Rx<bool> isFirstTimeOpen = true.obs;
  Rx<TripState> tripState = TripState.idle.obs;

  // Countdown
  Rx<int> countdownValue = 0.obs;
  Rx<bool> isCountdownActive = false.obs;
  Timer? _countdownTimer;

  Rxn<DataModel> model1 = Rxn<DataModel>();
  Rxn<DataModel> model2 = Rxn<DataModel>();

  Rxn<LatLng> currentLocation = Rxn<LatLng>();
  RxSet<Polyline> polyline = RxSet<Polyline>();
  RxSet<Marker> markers = RxSet<Marker>();
  Rx<bool> isFirstTime = true.obs;

  // Trip management
  Rxn<String> currentTripId = Rxn<String>();
  Rxn<TripModel> currentTrip = Rxn<TripModel>();
  Rx<DateTime> tripStartTime = DateTime.now().obs;
  StreamSubscription? _firebaseSubscription;

  // Analytics
  Rxn<Map<String, dynamic>> cyclingPerformance = Rxn<Map<String, dynamic>>();
  Rxn<double> caloriesEstimate = Rxn<double>();
  Rxn<double> performanceScore = Rxn<double>();
  Rx<double> totalCaloriesBurned = 0.0.obs;

  // Computed properties
  bool get isTripActive => tripState.value == TripState.active;
  bool get canStartTrip => tripState.value == TripState.idle;
  bool get canStopTrip => tripState.value == TripState.active;

  @override
  void onInit() async {
    super.onInit();
    await checkAndRestorePreviousTrip();
    await updateTotalCalories();
    // Không tự động start trip nữa
  }

  Future<void> checkAndRestorePreviousTrip() async {
    try {
      final hasData = await database.hasData();
      if (hasData) {
        final stats = await database.getDatabaseStats();
        debugPrint('Database contains data: $stats');

        final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
        final todayTrips = await database.getTripsByDate(today);

        if (todayTrips.isNotEmpty) {
          debugPrint('Found ${todayTrips.length} trips for today: $todayTrips');

          // Hiển thị thông báo có dữ liệu cũ
          Get.snackbar(
            'Dữ liệu đã khôi phục',
            'Tìm thấy ${todayTrips.length} chuyến đi hôm nay trong database',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.blue.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } else {
        debugPrint('Database is empty - starting fresh');
      }
    } catch (e) {
      debugPrint('Error checking previous trip data: $e');
    }
  }

  Future<void> startTripWithCountdown() async {
    if (!canStartTrip) return;

    tripState.value = TripState.countdown;
    isCountdownActive.value = true;
    countdownValue.value = 3;

    // Hiệu ứng đếm ngược
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownValue.value > 1) {
        countdownValue.value--;
      } else {
        _countdownTimer?.cancel();
        isCountdownActive.value = false;
        _actuallyStartTrip();
      }
    });

    // Hiệu ứng rung và âm thanh
    Get.snackbar(
      'Chuẩn bị khởi động',
      'Hành trình sẽ bắt đầu sau 3 giây...',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.orange.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  Future<void> _actuallyStartTrip() async {
    try {
      tripState.value = TripState.active;

      // Tạo trip ID mới
      currentTripId.value = FirebaseService.generateTripId();
      tripStartTime.value = DateTime.now();

      // Reset các giá trị
      distance.value = 0.0;
      maxSpeed.value = 0.0;
      averageSpeed.value = 0.0;
      elapsedMinutes.value = 0;
      elapsedSeconds.value = 0;
      formattedTime.value = '00:00:00';
      pointOnMap.clear();
      markers.clear();
      polyline.clear();
      isFirstTimeOpen.value = true;
      model1.value = null;
      model2.value = null;
      currentLocation.value = null;
      speed.value = null;
      cyclingPerformance.value = null;
      caloriesEstimate.value = null;
      performanceScore.value = null;

      // Bắt đầu timer cập nhật mỗi giây
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (tripState.value == TripState.active) {
          elapsedSeconds.value += 1;
          if (elapsedSeconds.value >= 60) {
            elapsedMinutes.value += 1;
            elapsedSeconds.value = 0;
          }
          _updateFormattedTime();
        }
      });

      final DateTime dateTime = DateTime.now();
      final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

      int? maxInDay = await database.queryMaxTimeInDayByDateTime(formattedDate);

      // Lắng nghe data từ Firebase
      _firebaseSubscription = firebaseService.getSingleItemStream(
          maxInDay != null ? maxInDay + 1 : 0,
          tripId: currentTripId.value
      ).listen((data) async {
        if (data != null && tripState.value == TripState.active) {
          debugPrint("update data for trip: ${currentTripId.value}");
          await updateLocationAndMap(data);
          await updateAnalytics();
        }
        await initializeMarkersAndPolyline();
      });

      Get.snackbar(
        'Hành trình bắt đầu! 🚴‍♂️',
        'Chúc bạn có một chuyến đi an toàn!',
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error starting new trip: $e');
      tripState.value = TripState.idle;
    }
  }

  Future<void> stopTrip() async {
    if (!canStopTrip) return;

    // Hiển thị dialog xác nhận
    final shouldStop = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Kết thúc hành trình?'),
        content: const Text('Bạn có muốn kết thúc hành trình hiện tại không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kết thúc', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldStop) return;

    try {
      tripState.value = TripState.idle;
      _timer?.cancel();
      _firebaseSubscription?.cancel();

      // Tính toán thống kê cuối trip
      final totalDistance = await database.getTotalDistanceByTrip(currentTripId.value!);
      final averageSpeedTrip = await database.getAverageSpeedByTrip(currentTripId.value!);
      final duration = await database.getTripDuration(currentTripId.value!);

      final endTime = DateTime.now();
      final String formattedEndDate = DateFormat('dd/MM/yyyy').format(endTime);

      // Tạo TripModel
      currentTrip.value = TripModel(
        tripId: currentTripId.value!,
        startDate: DateFormat('dd/MM/yyyy').format(tripStartTime.value),
        endDate: formattedEndDate,
        startTimestamp: tripStartTime.value.millisecondsSinceEpoch,
        endTimestamp: endTime.millisecondsSinceEpoch,
        totalDistance: totalDistance,
        averageSpeed: averageSpeedTrip,
        maxSpeed: maxSpeed.value ?? 0.0,
        duration: duration,
        pointCount: pointOnMap.length,
        status: 'completed',
      );

      // Cập nhật analytics cuối cùng
      await updateAnalytics();
      await updateTotalCalories();

      Get.snackbar(
        'Hành trình kết thúc! 🏁',
        'Quãng đường: ${currentTrip.value!.formattedDistance}\n'
        'Thời gian: ${currentTrip.value!.formattedDuration}\n'
        'Calories đốt cháy: ${caloriesEstimate.value?.toStringAsFixed(0) ?? 'N/A'} cal\n'
        'Tổng calories: ${totalCaloriesBurned.value.toStringAsFixed(0)} cal\n'
        'Điểm hiệu suất: ${performanceScore.value?.toStringAsFixed(1) ?? 'N/A'}',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error ending trip: $e');
    }
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    isCountdownActive.value = false;
    tripState.value = TripState.idle;

    Get.snackbar(
      'Đã hủy',
      'Hành trình đã được hủy',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.grey.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  void _updateFormattedTime() {
    final totalSeconds = elapsedMinutes.value * 60 + elapsedSeconds.value;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    formattedTime.value = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> updateAnalytics() async {
    if (currentTripId.value == null) return;

    try {
      // Cập nhật phân tích hiệu suất đạp xe
      final performance = await analyticsService.analyzeCyclingPerformance(currentTripId.value!);
      cyclingPerformance.value = performance;

      if (performance.isNotEmpty) {
        performanceScore.value = performance['performanceScore'];
      }

      // Ước tính calories đã đốt cháy
      final calories = await analyticsService.estimateCaloriesBurned(currentTripId.value!);
      caloriesEstimate.value = distance.value! * 45;

    } catch (e) {
      print('Error updating cycling analytics: $e');
    }
  }

  Future<void> updateLocationAndMap(DataModel data) async {
    currentLocation.value = LatLng(data.latitude.toDouble(), data.longitude.toDouble());
    speed.value = data.speed.toDouble();

    // Cập nhật tốc độ tối đa
    if (data.speed.toDouble() > (maxSpeed.value ?? 0.0)) {
      maxSpeed.value = data.speed.toDouble();
    }

    if (isFirstTimeOpen.value) {
      model1.value = data;
      isFirstTimeOpen.value = false;
      debugPrint('First location point set: (${data.latitude}, ${data.longitude})');
    } else {
      model2.value = model1.value;
      model1.value = data;

      // Tính toán khoảng cách giữa hai điểm
      double distanceBetweenPoints = calculateDistance(
        model2.value!.latitude.toDouble(),
        model2.value!.longitude.toDouble(),
        model1.value!.latitude.toDouble(),
        model1.value!.longitude.toDouble(),
      );

      // Chỉ cộng dồn nếu khoảng cách > 0
      if (distanceBetweenPoints > 0) {
        distance.value = double.parse((distance.value! + distanceBetweenPoints).toStringAsFixed(2));
        debugPrint('Total distance: ${distance.value} km (Added: $distanceBetweenPoints km)');
      }
    }

    // Đảm bảo data có đầy đủ thông tin trước khi lưu
    final dataToSave = data.copyWith(
      tripId: currentTripId.value,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final insertResult = await database.insertDataModel(dataToSave);
      if (insertResult > 0) {
        debugPrint('Successfully saved data point with ID: $insertResult for trip: ${currentTripId.value}');
      } else {
        debugPrint('Failed to save data point for trip: ${currentTripId.value}');
      }
    } catch (e) {
      debugPrint('Error saving data point: $e');
    }

    pointOnMap.add(LatLng(data.latitude.toDouble(), data.longitude.toDouble()));

    // Cập nhật tốc độ trung bình
    if (pointOnMap.length > 1) {
      final speeds = await _getAllSpeedsForTrip();
      if (speeds.isNotEmpty) {
        averageSpeed.value = speeds.reduce((a, b) => a + b) / speeds.length;
      }
    }

    // Cập nhật markers và polyline
    markers.add(
      Marker(
        markerId: MarkerId(pointOnMap.length.toString()),
        position: LatLng(data.latitude.toDouble(), data.longitude.toDouble()),
        infoWindow: InfoWindow(
          title: "Vị trí hiện tại",
          snippet: "Tốc độ: ${data.speed.toStringAsFixed(1)} km/h\nQuãng đường: ${distance.value?.toStringAsFixed(2) ?? '0.00'} km",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    polyline.clear();
    polyline.add(
      Polyline(
        polylineId: const PolylineId("Id"),
        points: pointOnMap,
        color: _getPolylineColor(),
        width: 5,
      ),
    );

    if (mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newLatLng(LatLng(data.latitude.toDouble(), data.longitude.toDouble())),
      );
    }
  }

  Color _getPolylineColor() {
    final safety = performanceScore.value ?? 100.0;
    if (safety >= 80) return Colors.green;
    if (safety >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<List<double>> _getAllSpeedsForTrip() async {
    if (currentTripId.value == null) return [];

    try {
      final db = await database.database;
      final maps = await db.query(
        'dataModel',
        columns: ['speed'],
        where: 'tripId = ? AND speed > 0',
        whereArgs: [currentTripId.value],
      );

      return maps.map((map) => (map['speed'] as num).toDouble()).toList();
    } catch (e) {
      print('Error getting speeds: $e');
      return [];
    }
  }

  Future<void> initializeMarkersAndPolyline() async {
    for (int i = 0; i < pointOnMap.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId(i.toString()),
          position: pointOnMap[i],
          infoWindow: const InfoWindow(
            title: "Place around my Country",
            snippet: "So Beautiful",
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    }

    polyline.add(
      Polyline(
        polylineId: const PolylineId("Id"),
        points: pointOnMap,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Kiểm tra nếu điểm trùng nhau
    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    const double R = 6371.0; // Bán kính trái đất tính bằng km
    const double d2r = pi / 180.0; // Hệ số chuyển đổi độ sang radian

    // Chuyển đổi tọa độ sang radian
    double lat1Rad = lat1 * d2r;
    double lon1Rad = lon1 * d2r;
    double lat2Rad = lat2 * d2r;
    double lon2Rad = lon2 * d2r;

    // Tính toán khoảng cách
    double dlat = lat2Rad - lat1Rad;
    double dlon = lon2Rad - lon1Rad;

    // Công thức Haversine
    double a = pow(sin(dlat / 2), 2) + cos(lat1Rad) * cos(lat2Rad) * pow(sin(dlon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = R * c;

    // Làm tròn đến 4 chữ số thập phân để có độ chính xác cao hơn
    return double.parse(distance.toStringAsFixed(4));
  }

  Future<void> updateTotalCalories() async {
    try {
      // Lấy tổng quãng đường từ database
      final totalDistance = await database.getTotalDistance();
      // Tính calories dựa trên quãng đường (20 calories/km cơ bản)
      totalCaloriesBurned.value = totalDistance * 20;
    } catch (e) {
      debugPrint('Error updating total calories: $e');
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _firebaseSubscription?.cancel();
    super.onClose();
  }

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {}
}
