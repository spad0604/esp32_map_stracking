class DataModel {
  final num latitude;
  final num longitude;
  final num speed;
  final String dateTime;
  final int timeInDay;
  final String? tripId;
  final int? timestamp;

  DataModel({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.dateTime,
    required this.timeInDay,
    this.tripId,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'dateTime': dateTime,
      'timeInDay': timeInDay,
      'tripId': tripId,
      'timestamp': timestamp,
    };
  }

  factory DataModel.fromMap(Map<String, dynamic> map) {
    return DataModel(
      latitude: map['latitude'],
      longitude: map['longitude'],
      speed: map['speed'],
      dateTime: map['dateTime'],
      timeInDay: map['timeInDay'],
      tripId: map['tripId'],
      timestamp: map['timestamp'],
    );
  }

  DataModel copyWith({
    num? latitude,
    num? longitude,
    num? speed,
    String? dateTime,
    int? timeInDay,
    String? tripId,
    int? timestamp,
  }) {
    return DataModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      dateTime: dateTime ?? this.dateTime,
      timeInDay: timeInDay ?? this.timeInDay,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
