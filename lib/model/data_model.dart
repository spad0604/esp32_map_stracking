class DataModel {
  final double latitude;
  final double longtitude;
  final double speed;
  final String dateTime;
  final int timeInDay;

  DataModel({required this.latitude, required this.longtitude, required this.speed, required this.dateTime,
      required this.timeInDay});

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longtitude': longtitude,
      'speed': speed,
      'dateTime': dateTime,
      'timeInDay': timeInDay
    };
  }

  factory DataModel.fromMap(Map<String, dynamic> map) {
    return DataModel(
      latitude: map['latitude'],
      longtitude: map['longtitude'],
      speed: map['speed'],
      dateTime: map['dateTime'],
      timeInDay: map['timeInDay'],
    );
  }
}