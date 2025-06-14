import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import '../model/data_model.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  static const Uuid _uuid = Uuid();

  Stream<DataModel?> getSingleItemStream(int timeInDay, {String? tripId}) {
    return _databaseRef.child('/data').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final double latitude = double.tryParse(data['LAT'].toString()) ?? 21.00444;
        final double longitude = double.tryParse(data['LON'].toString()) ?? 105.84678;
        final double speed = double.tryParse(data['speed'].toString()) ?? 0.0;

        final DateTime dateTime = DateTime.now();
        final String formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

        return DataModel(
          latitude: latitude,
          longitude: longitude,
          speed: speed,
          dateTime: formattedDate,
          timeInDay: timeInDay,
          tripId: tripId ?? _uuid.v4(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        return null;
      }
    });
  }

  static String generateTripId() {
    return _uuid.v4();
  }

  Future<List<Map<String, dynamic>>> getDataByTimeRange(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final snapshot = await _databaseRef
          .child('/data')
          .orderByChild('timestamp')
          .startAt(startTime.millisecondsSinceEpoch)
          .endAt(endTime.millisecondsSinceEpoch)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return {
            'key': entry.key,
            'value': entry.value,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting data by time range: $e');
      return [];
    }
  }
}
