import 'package:get/get.dart';
import 'package:google_map_in_flutter/env/route_type.dart';

import '../presentation/controller/show_history_distance/show_history_distance_controller.dart';
import 'app_route.dart';

class N {
  static void popUntilRoot() {
    Get.until((route) => route.isFirst);
  }

  // static void closeAllDialog() {
  //   Get.until((route) => !Get.isDialogOpen);
  // }

  static void toHomePage({RouteType type = RouteType.offAll}) {
    type.navigate(name: AppRoute.ROOT);
  }

  static void toCameraView({RouteType type = RouteType.offAll}) {
    type.navigate(name: AppRoute.GOOGLE_MAP);
  }

  static void toImagePreview({RouteType type = RouteType.offAll}) {
    type.navigate(name: AppRoute.SERVICE);
  }

  static void toShowHistory({RouteType type = RouteType.to}) {
    if (!Get.isRegistered<ShowHistoryDistanceController>()) {
      Get.put(ShowHistoryDistanceController());
    }
    type.navigate(name: AppRoute.DISTANCE_HISTORY);
  }
}
