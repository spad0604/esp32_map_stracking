import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_map_in_flutter/main.dart';
import 'package:google_map_in_flutter/presentation/controller/show_history_distance/show_history_distance_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShowHistoryDistanceScreen extends GetView<ShowHistoryDistanceController> {
  const ShowHistoryDistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              const AppBarWidget(pageName: 'Distance History'),
              if (controller.initialCameraPosition.value != null)
                SizedBox(
                  height: Get.size.height - 400,
                  child: GoogleMap(
                    myLocationButtonEnabled: true,
                    markers: controller.markers,
                    polylines: controller.polylines,
                    initialCameraPosition: CameraPosition(
                      target: controller.initialCameraPosition.value!,
                      zoom: 14.0,
                    ),
                  ),
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
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This is trip ${controller.saveTimeInDay.value + 1} in ${controller.saveDay.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Total Distance: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            fontSize: 20),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                          text: controller.totalDistance.value
                                              .toStringAsFixed(2),
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
                              width: 10,
                            ),
                            Obx(() => controller.calories.value != null
                                ? Text(
                                    '🔥 ${controller.calories.value.toStringAsFixed(0)} cal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  )
                                : const SizedBox()),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Obx(() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Points: ${controller.data.value?.length ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                    fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              if (controller.data.value?.isNotEmpty ?? false)
                                Text(
                                  'Trip Duration: ${_calculateTripDuration(controller.data.value!)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                      fontSize: 16),
                                ),
                            ],
                          )),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  String _calculateTripDuration(List<dynamic> data) {
    if (data.isEmpty) return '0s';

    try {
      final firstPoint = data.first;
      final lastPoint = data.last;

      // Nếu có timestamp, sử dụng nó
      if (firstPoint.timestamp != null && lastPoint.timestamp != null) {
        final duration =
            Duration(milliseconds: lastPoint.timestamp - firstPoint.timestamp);

        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        if (hours > 0) {
          return '${hours}h ${minutes}m ${seconds}s';
        } else if (minutes > 0) {
          return '${minutes}m ${seconds}s';
        } else {
          return '${seconds}s';
        }
      } else {
        // Fallback: ước tính dựa trên số điểm dữ liệu (giả sử mỗi điểm cách nhau 1 giây)
        final estimatedSeconds = data.length;
        final minutes = estimatedSeconds ~/ 60;
        final seconds = estimatedSeconds % 60;

        if (minutes > 0) {
          return '~${minutes}m ${seconds}s (estimated)';
        } else {
          return '~${seconds}s (estimated)';
        }
      }
    } catch (e) {
      return 'Unknown duration';
    }
  }
}
