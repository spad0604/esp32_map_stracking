class TripModel {
  final String tripId;
  final String startDate;
  final String endDate;
  final int startTimestamp;
  final int endTimestamp;
  final double totalDistance;
  final double averageSpeed;
  final double maxSpeed;
  final Duration duration;
  final int pointCount;
  final String status; // 'ongoing', 'completed', 'paused'

  TripModel({
    required this.tripId,
    required this.startDate,
    required this.endDate,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.totalDistance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.duration,
    required this.pointCount,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'startDate': startDate,
      'endDate': endDate,
      'startTimestamp': startTimestamp,
      'endTimestamp': endTimestamp,
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'durationMs': duration.inMilliseconds,
      'pointCount': pointCount,
      'status': status,
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      tripId: map['tripId'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      startTimestamp: map['startTimestamp'],
      endTimestamp: map['endTimestamp'],
      totalDistance: map['totalDistance']?.toDouble() ?? 0.0,
      averageSpeed: map['averageSpeed']?.toDouble() ?? 0.0,
      maxSpeed: map['maxSpeed']?.toDouble() ?? 0.0,
      duration: Duration(milliseconds: map['durationMs'] ?? 0),
      pointCount: map['pointCount'] ?? 0,
      status: map['status'] ?? 'completed',
    );
  }

  TripModel copyWith({
    String? tripId,
    String? startDate,
    String? endDate,
    int? startTimestamp,
    int? endTimestamp,
    double? totalDistance,
    double? averageSpeed,
    double? maxSpeed,
    Duration? duration,
    int? pointCount,
    String? status,
  }) {
    return TripModel(
      tripId: tripId ?? this.tripId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      totalDistance: totalDistance ?? this.totalDistance,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      duration: duration ?? this.duration,
      pointCount: pointCount ?? this.pointCount,
      status: status ?? this.status,
    );
  }

  // Helper methods
  String get formattedDuration {
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
  }

  String get formattedDistance {
    if (totalDistance >= 1) {
      return '${totalDistance.toStringAsFixed(2)} km';
    } else {
      return '${(totalDistance * 1000).toStringAsFixed(0)} m';
    }
  }

  String get formattedAverageSpeed {
    return '${averageSpeed.toStringAsFixed(1)} km/h';
  }

  String get formattedMaxSpeed {
    return '${maxSpeed.toStringAsFixed(1)} km/h';
  }
} 