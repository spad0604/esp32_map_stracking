import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/service_controller/service_controller.dart';
import 'package:google_map_in_flutter/presentation/controller/show_history_distance/show_history_distance_controller.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ServiceController());

    Get.put(ShowHistoryDistanceController());
  }
}