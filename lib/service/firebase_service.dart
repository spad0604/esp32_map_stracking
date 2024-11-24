import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

import '../model/data_model.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Stream<DataModel?> getSingleItemStream(int timeInDay) {
    return _databaseRef.child('/data').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final double latitude = double.tryParse(data['LAT'].toString()) ?? 0.0;
        final double longitude = double.tryParse(data['LON'].toString()) ?? 0.0;
        final double speed = double.tryParse(data['speed'].toString()) ?? 0.0;

        final DateTime dateTime = DateTime.now();
        final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

        return DataModel(
          latitude: latitude,
          longtitude: longitude,
          speed: speed,
          dateTime: formattedDate,
          timeInDay: timeInDay,
        );
      } else {
        return null;
      }
    });
  }

}
