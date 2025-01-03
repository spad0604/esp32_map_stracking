import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/google_map_polyline_controller/google_map_polyline_controller.dart';
import 'package:google_map_in_flutter/presentation/controller/service_controller/service_controller.dart';
import 'package:google_map_in_flutter/presentation/controller/show_history_distance/show_history_distance_controller.dart';

class ShowHistoryDistanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShowHistoryDistanceController());

    Get.put(ServiceController());

    Get.put(GoogleMapPolylineController());
  }
}