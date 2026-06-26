import 'destination.dart';

class FavoriteDestination {
  const FavoriteDestination({
    required this.destination,
    this.badges = const [],
    this.transitSystem,
    this.lineName,
  });

  final Destination destination;
  final List<String> badges;
  final String? transitSystem;
  final String? lineName;

  FavoriteDestination copyWith({
    Destination? destination,
    List<String>? badges,
    String? transitSystem,
    String? lineName,
  }) {
    return FavoriteDestination(
      destination: destination ?? this.destination,
      badges: badges ?? this.badges,
      transitSystem: transitSystem ?? this.transitSystem,
      lineName: lineName ?? this.lineName,
    );
  }

  ({String transitSystem, String lineName})? get savedTransitLine {
    if (transitSystem != null &&
        transitSystem!.isNotEmpty &&
        lineName != null &&
        lineName!.isNotEmpty) {
      return (transitSystem: transitSystem!, lineName: lineName!);
    }

    for (final badge in badges) {
      final parts = badge.split(' · ');
      if (parts.length != 2) {
        continue;
      }
      final system = parts[0].trim();
      final line = parts[1].trim();
      if (system.isNotEmpty && line.isNotEmpty) {
        return (transitSystem: system, lineName: line);
      }
    }

    return null;
  }

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    final badges = (json['badges'] as List<dynamic>? ?? const [])
        .map((badge) => badge as String)
        .toList(growable: false);
    var transitSystem = json['transitSystem'] as String?;
    var lineName = json['lineName'] as String?;

    final item = FavoriteDestination(
      destination: Destination(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      badges: badges,
      transitSystem: transitSystem,
      lineName: lineName,
    );
    final saved = item.savedTransitLine;
    if (saved != null &&
        (transitSystem == null ||
            transitSystem!.isEmpty ||
            lineName == null ||
            lineName!.isEmpty)) {
      return item.copyWith(
        transitSystem: saved.transitSystem,
        lineName: saved.lineName,
      );
    }
    return item;
  }

  Map<String, dynamic> toJson() {
    final saved = savedTransitLine;
    return {
      'name': destination.name,
      'latitude': destination.latitude,
      'longitude': destination.longitude,
      'badges': badges,
      if (saved != null) ...{
        'transitSystem': saved.transitSystem,
        'lineName': saved.lineName,
      },
    };
  }

  bool matches(Destination other) {
    return destination.name == other.name &&
        destination.latitude == other.latitude &&
        destination.longitude == other.longitude;
  }
}
