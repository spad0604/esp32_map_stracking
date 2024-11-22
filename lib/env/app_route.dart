// ignore_for_file: non_constant_identifier_names
import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/google_map_polyline_controller/google_map_polyline_binding.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_binding.dart';
import 'package:google_map_in_flutter/presentation/controller/service_controller/service_binding.dart';
import 'package:google_map_in_flutter/presentation/controller/show_history_distance/show_history_distance_binding.dart';
import 'package:google_map_in_flutter/presentation/views/google_map_polyline_screen/google_map_polyline_screen.dart';
import 'package:google_map_in_flutter/presentation/views/root_page/root_page_screen.dart';
import 'package:google_map_in_flutter/presentation/views/service/service_screen.dart';
import 'package:google_map_in_flutter/presentation/views/show_history_distance_screen/show_history_distance_screen.dart';

class AppRoute {
  static String ROOT = '/';

  static String GOOGLE_MAP = '/google_map';

  static String SERVICE = '/service';

  static String DISTANCE_HISTORY = '/distance_history';

  static List<GetPage> generateGetPages = [
    GetPage(
        name: ROOT,
        page: RootPageScreen.new,
        binding: RootPageBinding()
    ),
    GetPage(
        name: GOOGLE_MAP,
        page: GoogleMapPolylineScreen.new,
        binding: GoogleMapPolylineBindings()),
    GetPage(
        name: SERVICE,
        page: ServiceScreen.new,
        binding: ServiceBinding()
    ),
    GetPage(
        name: DISTANCE_HISTORY,
        page: ShowHistoryDistanceScreen.new,
        binding: ShowHistoryDistanceBinding()
    )
  ];

  static GetPage? getPage(String name) {
    return generateGetPages.firstWhereOrNull((e) => e.name == name);
  }
}
