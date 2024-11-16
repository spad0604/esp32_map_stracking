import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/main.dart';
import 'package:google_map_in_flutter/presentation/controller/show_history_distance/show_history_distance_controller.dart';

class ShowHistoryDistanceScreen extends GetView<ShowHistoryDistanceController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppBarWidget(pageName: 'Distance History'),
          Expanded(child: Container(

          ))
        ],
      ),
    );
  }
}