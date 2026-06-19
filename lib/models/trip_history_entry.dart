class TripHistoryEntry {
  const TripHistoryEntry({
    required this.id,
    required this.destination,
    required this.tripStart,
    this.tripEnd,
    this.alarmTriggered,
    this.alarmDismissed,
    this.missedTrip = false,
  });

  final String id;
  final String destination;
  final DateTime tripStart;
  final DateTime? tripEnd;
  final DateTime? alarmTriggered;
  final DateTime? alarmDismissed;
  final bool missedTrip;

  TripHistoryEntry copyWith({
    String? id,
    String? destination,
    DateTime? tripStart,
    DateTime? tripEnd,
    DateTime? alarmTriggered,
    DateTime? alarmDismissed,
    bool? missedTrip,
  }) {
    return TripHistoryEntry(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      tripStart: tripStart ?? this.tripStart,
      tripEnd: tripEnd ?? this.tripEnd,
      alarmTriggered: alarmTriggered ?? this.alarmTriggered,
      alarmDismissed: alarmDismissed ?? this.alarmDismissed,
      missedTrip: missedTrip ?? this.missedTrip,
    );
  }

  factory TripHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TripHistoryEntry(
      id: json['id'] as String,
      destination: json['destination'] as String,
      tripStart: DateTime.parse(json['tripStart'] as String),
      tripEnd: json['tripEnd'] == null
          ? null
          : DateTime.parse(json['tripEnd'] as String),
      alarmTriggered: json['alarmTriggered'] == null
          ? null
          : DateTime.parse(json['alarmTriggered'] as String),
      alarmDismissed: json['alarmDismissed'] == null
          ? null
          : DateTime.parse(json['alarmDismissed'] as String),
      missedTrip: json['missedTrip'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'tripStart': tripStart.toIso8601String(),
      'tripEnd': tripEnd?.toIso8601String(),
      'alarmTriggered': alarmTriggered?.toIso8601String(),
      'alarmDismissed': alarmDismissed?.toIso8601String(),
      'missedTrip': missedTrip,
    };
  }
}
