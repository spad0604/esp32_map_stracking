import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/model/data_model.dart';
import 'package:google_map_in_flutter/presentation/controller/service_controller/service_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'dart:math';

class ShowHistoryDistanceController extends SuperController {
  Rxn<List<DataModel>> data = Rxn<List<DataModel>>();
  RxSet<Marker> markers = RxSet<Marker>();
  RxSet<Polyline> polylines = RxSet<Polyline>();
  final ServiceController serviceController = Get.find();
  final Rxn<LatLng> initialCameraPosition = Rxn<LatLng>();

  final RxBool isLoading = true.obs;

  final RxDouble totalDistance = 0.0.obs;

  Rx<String> saveDay = ''.obs;
  Rx<int> saveTimeInDay = 0.obs;

  @override
  void onInit() async {
    data.value = [];
    ever(serviceController.list, (list) async {
      saveDay = serviceController.saveDay;
      saveTimeInDay = serviceController.saveTimeInDay;
      //debugPrint('hello ${saveDay.value}');
      if (list != null && list.isNotEmpty) {
        initialCameraPosition.value = LatLng(list[0].latitude.toDouble(), list[0].longtitude.toDouble());
        data.value = list;
        await createMarkersAndPolylines(data.value!);
        calculateTotalDistance(data.value!);
      } else {
        debugPrint("List is null or empty.");
      }
      isLoading.value = false;
    });
    super.onInit();
  }

  Future<void> createMarkersAndPolylines(List<DataModel> list) async {
    markers.clear();
    polylines.clear();

    List<LatLng> points = [];
    for (int i = 0; i < list.length; i++) {
      LatLng position = LatLng(list[i].latitude.toDouble(), list[i].longtitude.toDouble());
      points.add(position);
      markers.add(
        Marker(
          markerId: MarkerId(i.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: 'Point ${i + 1}',
            snippet: 'Speed: ${list[i].speed.toStringAsFixed(2)} km/h',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    }

    polylines.add(
      Polyline(
        polylineId: const PolylineId('history_polyline'),
        points: points,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  void calculateTotalDistance(List<DataModel> list) {
    if (list.length <= 1) {
      totalDistance.value = 0.0;
      return;
    }

    double distance = 0.0;
    for (int i = 0; i < list.length - 1; i++) {
      distance += calculateDistance(
        list[i].latitude.toDouble(),
        list[i].longtitude.toDouble(),
        list[i + 1].latitude.toDouble(),
        list[i + 1].longtitude.toDouble(),
      );
    }
    totalDistance.value = distance;
    debugPrint('Total Distance: $distance km');
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
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
