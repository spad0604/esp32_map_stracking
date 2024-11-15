import 'package:get/get.dart';
import 'package:google_map_in_flutter/env/route_type.dart';

import 'app_route.dart';

class N {
  static void popUntilRoot() {
    Get.until((route) => route.isFirst);
  }

  static void closeAllDialog() {
    Get.until((route) => Get.isDialogOpen == false);
  }

  static void toHomePage({RouteType type = RouteType.offAll}) {
    type.navigate(name: AppRoute.ROOT);
  }

  static void toCameraView({RouteType type = RouteType.to}) {
    type.navigate(name: AppRoute.GOOGLE_MAP);
  }

  static void toImagePreview({RouteType type = RouteType.to}) {
    type.navigate(name: AppRoute.SERVICE);
  }
}