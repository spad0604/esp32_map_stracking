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
  Rx<bool> isTripActive = false.obs;

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
  
  // Analytics
  Rxn<Map<String, dynamic>> cyclingPerformance = Rxn<Map<String, dynamic>>();
  Rxn<double> caloriesEstimate = Rxn<double>();
  Rxn<double> performanceScore = Rxn<double>();

  @override
  void onInit() async {
    super.onInit();
    await checkAndRestorePreviousTrip();
    await startNewTrip();
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

  Future<void> startNewTrip() async {
    try {
      // Tạo trip ID mới
      currentTripId.value = FirebaseService.generateTripId();
      tripStartTime.value = DateTime.now();
      isTripActive.value = true;
      
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

      // Bắt đầu timer cập nhật mỗi giây
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        elapsedSeconds.value += 1;
        if (elapsedSeconds.value >= 60) {
          elapsedMinutes.value += 1;
          elapsedSeconds.value = 0;
        }
        _updateFormattedTime();
      });

      final DateTime dateTime = DateTime.now();
      final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

      int? maxInDay = await database.queryMaxTimeInDayByDateTime(formattedDate);

      // Lắng nghe data từ Firebase
      firebaseService.getSingleItemStream(
        maxInDay != null ? maxInDay + 1 : 0,
        tripId: currentTripId.value
      ).listen((data) async {
        if (data != null && isTripActive.value) {
          debugPrint("update data for trip: ${currentTripId.value}");
          await updateLocationAndMap(data);
          await updateAnalytics();
        }
        await initializeMarkersAndPolyline();
      });
    } catch (e) {
      print('Error starting new trip: $e');
    }
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

  Future<void> endTrip() async {
    try {
      if (!isTripActive.value || currentTripId.value == null) return;

      isTripActive.value = false;
      _timer?.cancel();

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

      Get.snackbar(
        'Hành trình kết thúc',
        'Quãng đường: ${currentTrip.value!.formattedDistance}\n'
        'Thời gian: ${currentTrip.value!.formattedDuration}\n'
        'Calories đốt cháy: ${caloriesEstimate.value?.toStringAsFixed(0) ?? 'N/A'} cal\n'
        'Điểm hiệu suất: ${performanceScore.value?.toStringAsFixed(1) ?? 'N/A'}',
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error ending trip: $e');
    }
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
      caloriesEstimate.value = calories;

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
    } else {
      model2.value = model1.value;
      model1.value = data;

      double distanceBetweenPoints = calculateDistance(
        model2.value!.latitude.toDouble(),
        model2.value!.longitude.toDouble(),
        model1.value!.latitude.toDouble(),
        model1.value!.longitude.toDouble(),
      );

      distance.value = double.parse((distance.value! + distanceBetweenPoints).toStringAsFixed(2));
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

    // Cập nhật markers
    if (markers.isNotEmpty) {
      final List<Marker> updatedMarkers = markers.map((marker) {
        return marker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      }).toList();
      markers.clear();
      markers.addAll(updatedMarkers);
    }

    markers.add(
      Marker(
        markerId: MarkerId(pointOnMap.length.toString()),
        position: LatLng(data.latitude.toDouble(), data.longitude.toDouble()),
        infoWindow: InfoWindow(
          title: "Vị trí hiện tại",
          snippet: "Tốc độ: ${data.speed.toStringAsFixed(1)} km/h\nTrip: ${currentTripId.value?.substring(0, 8) ?? 'N/A'}",
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
    const double R = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    lat1 = lat1 * pi / 180;
    lat2 = lat2 * pi / 180;

    double a = pow(sin(dLat / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
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
