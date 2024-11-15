import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/google_map_polyline_controller/google_map_polyline_controller.dart';

class GoogleMapPolylineBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => GoogleMapPolylineController());
  }
}