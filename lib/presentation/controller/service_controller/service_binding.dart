import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/service_controller/service_controller.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ServiceController.new);
  }
}