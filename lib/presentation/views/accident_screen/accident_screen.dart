import 'package:google_map_in_flutter/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class AccidentMapScreen extends StatelessWidget {
  final double latitude;
  final double longitude;

  const AccidentMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const AppBarWidget(pageName: 'Accident Map'),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(latitude, longitude),
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('accident'),
                    position: LatLng(latitude, longitude),
                    infoWindow: const InfoWindow(
                      title: 'Tai nạn',
                      snippet: 'Vị trí tai nạn đã được phát hiện',
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
