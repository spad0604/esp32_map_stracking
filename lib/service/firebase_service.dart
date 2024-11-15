import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

import '../model/data_model.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  Stream<DataModel?> getSingleItemStream(int timeInDay) {
    return _databaseRef.child('/').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.isNotEmpty) {
        final entry = data.entries.first;
        final value = entry.value as Map<dynamic, dynamic>;

        final double latitude = value['latitude'];
        final double longitude = value['longtitude'];
        final double speed = value['speed'];

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
