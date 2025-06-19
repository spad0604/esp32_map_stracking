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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const AppBarWidget(pageName: 'Tracking Map', ),
                Obx(
                  () => SizedBox(
                    height: MediaQuery.of(context).size.height - 480, // Use MediaQuery instead of Get.height
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
                        : const Center(
                            child: Text(
                              'Nhấn START để bắt đầu hành trình',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                // Stats Container
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
                                width: 24, // Add explicit width
                                height: 24, // Add explicit height
                              ),
                              const SizedBox(width: 10),
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/distance.png',
                                width: 24, // Add explicit width
                                height: 24, // Add explicit height
                              ),
                              const SizedBox(width: 10),
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
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/time.png',
                                width: 24, // Add explicit width
                                height: 24, // Add explicit height
                              ),
                              const SizedBox(width: 10),
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                )
                              : const SizedBox()),
                        ],
                      ),
                      Image.asset(
                        'assets/images/bicycle.png',
                        width: 48, // Add explicit width
                        height: 48, // Add explicit height
                      )
                    ],
                  ),
                ),
                // Start/Stop Button Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Obx(() => _buildControlButton()),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Countdown Overlay
          Obx(() => controller.isCountdownActive.value
              ? _buildCountdownOverlay()
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    switch (controller.tripState.value) {
      case TripState.idle:
        return _buildStartButton();
      case TripState.countdown:
        return _buildCancelButton();
      case TripState.active:
        return _buildStopButton();
      case TripState.paused:
        return _buildResumeButton();
    }
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: controller.startTripWithCountdown,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 28),
          SizedBox(width: 10),
          Text(
            'BẮT ĐẦU HÀNH TRÌNH',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: controller.cancelCountdown,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, size: 28),
          SizedBox(width: 10),
          Text(
            'HỦY BỎ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return ElevatedButton(
      onPressed: controller.stopTrip,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stop, size: 28),
          SizedBox(width: 10),
          Text(
            'KẾT THÚC HÀNH TRÌNH',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeButton() {
    return ElevatedButton(
      onPressed: controller.startTripWithCountdown,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_arrow, size: 28),
          SizedBox(width: 10),
          Text(
            'TIẾP TỤC',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chuẩn bị khởi động...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 30),
              Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getCountdownColor(),
                  boxShadow: [
                    BoxShadow(
                      color: _getCountdownColor().withOpacity(0.5),
                      spreadRadius: 10,
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    controller.countdownValue.value.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 30),
              const Text(
                'Hành trình sắp bắt đầu!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCountdownColor() {
    switch (controller.countdownValue.value) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
