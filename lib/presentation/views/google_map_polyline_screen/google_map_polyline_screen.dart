import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/main.dart';
import 'package:google_map_in_flutter/presentation/controller/google_map_polyline_controller/google_map_polyline_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapPolylineScreen extends GetView<GoogleMapPolylineController> {
  const GoogleMapPolylineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AppBarWidget(pageName: 'Tracking Map'),
            Obx(
              () => SizedBox(
                height: Get.height - 400,
                child: (controller.currentLocation.value != null)
                    ? Obx(
                  () => GoogleMap(
                          myLocationButtonEnabled: true,
                          markers: controller.markers,
                          polylines: controller.polyline,
                          initialCameraPosition: CameraPosition(
                            target: controller.currentLocation.value!,
                            zoom: 14.0,
                          ),
                          onMapCreated: (GoogleMapController gController) {
                            controller.mapController.value = gController;
                          },
                        ),
                    )
                    : const SizedBox(),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.25),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/speed.png',
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Obx(
                            () => RichText(
                                text: TextSpan(
                                    text: controller.speed.value?.toStringAsFixed(1) ?? '0.0',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 20),
                                    children: const [
                                  TextSpan(
                                      text: ' km/h',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black))
                                ])),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/distance.png',
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Obx(
                            () => RichText(
                                text: TextSpan(
                                    text: controller.distance.value.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 20),
                                    children: const [
                                  TextSpan(
                                      text: ' km',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black))
                                ])),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/time.png',
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Obx(
                            () => RichText(
                                text: TextSpan(
                                    text: controller.formattedTime.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize: 20),
                                    children: const [
                                  TextSpan(
                                      text: ' (h:m:s)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey))
                                ])),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Hiển thị thông tin đạp xe
                      Obx(() => controller.caloriesEstimate.value != null
                          ? Text(
                              '🔥 ${controller.caloriesEstimate.value!.toStringAsFixed(0)} cal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                            )
                          : const SizedBox()),
                      const SizedBox(height: 5),
                      Obx(() => controller.performanceScore.value != null
                          ? Text(
                              '⭐ ${controller.performanceScore.value!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            )
                          : const SizedBox()),
                      const SizedBox(height: 5),
                      Obx(() => controller.cyclingPerformance.value != null
                          ? Text(
                              '${controller.cyclingPerformance.value!['intensity'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            )
                          : const SizedBox()),
                    ],
                  ),
                  Image.asset('assets/images/bicycle.png')
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
