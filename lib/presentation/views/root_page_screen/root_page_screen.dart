import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/presentation/controller/root_page_controller/root_page_controller.dart';
import 'package:google_map_in_flutter/presentation/views/google_map_polyline_screen/google_map_polyline_screen.dart';
import 'package:google_map_in_flutter/presentation/views/service/service_screen.dart';

class RootPageScreen extends GetView<RootPageController> {
  const RootPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Cycling Tracker'),
      ),
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          GoogleMapPolylineScreen(),
          ServiceScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: controller.selectedIndex.value,
        onTap: (index) {
          controller.selectedIndex.value = index;
          controller.pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services),
            label: 'Service',
          ),
        ],
      ),
    );
  }
} 