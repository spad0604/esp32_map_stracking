import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/google_map_polyline_controller/google_map_polyline_controller.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_controller.dart';

import '../service_controller/service_controller.dart';

class RootPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RootPageController());
    
    Get.put(GoogleMapPolylineController());

    Get.put(ServiceController());
  }
}