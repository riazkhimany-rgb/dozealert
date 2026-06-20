import 'destination.dart';

class FavoriteDestination {
  const FavoriteDestination({
    required this.destination,
    this.badges = const [],
  });

  final Destination destination;
  final List<String> badges;

  FavoriteDestination copyWith({
    Destination? destination,
    List<String>? badges,
  }) {
    return FavoriteDestination(
      destination: destination ?? this.destination,
      badges: badges ?? this.badges,
    );
  }

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    return FavoriteDestination(
      destination: Destination(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      badges: (json['badges'] as List<dynamic>? ?? const [])
          .map((badge) => badge as String)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': destination.name,
      'latitude': destination.latitude,
      'longitude': destination.longitude,
      'badges': badges,
    };
  }

  bool matches(Destination other) {
    return destination.name == other.name &&
        destination.latitude == other.latitude &&
        destination.longitude == other.longitude;
  }
}
