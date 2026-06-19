import '../models/destination.dart';

class DestinationCatalogItem {
  const DestinationCatalogItem({
    required this.destination,
    this.badges = const [],
  });

  final Destination destination;
  final List<String> badges;
}

abstract final class MockDestinations {
  static const unionStation = Destination(
    name: 'Union Station',
    latitude: 43.6453,
    longitude: -79.3806,
  );

  static const miltonGo = Destination(
    name: 'Milton GO',
    latitude: 43.5186,
    longitude: -79.8774,
  );

  static const pearsonAirport = Destination(
    name: 'Pearson Airport',
    latitude: 43.6777,
    longitude: -79.6248,
  );

  static const recent = <DestinationCatalogItem>[
    DestinationCatalogItem(
      destination: unionStation,
      badges: ['Recent'],
    ),
    DestinationCatalogItem(
      destination: miltonGo,
      badges: ['Recent'],
    ),
    DestinationCatalogItem(
      destination: pearsonAirport,
      badges: ['Recent'],
    ),
  ];

  static const all = <DestinationCatalogItem>[
    DestinationCatalogItem(
      destination: unionStation,
      badges: ['Recent'],
    ),
    DestinationCatalogItem(
      destination: miltonGo,
      badges: ['Recent'],
    ),
    DestinationCatalogItem(
      destination: pearsonAirport,
      badges: ['Recent'],
    ),
    DestinationCatalogItem(
      destination: Destination(
        name: 'CN Tower',
        latitude: 43.6426,
        longitude: -79.3871,
      ),
    ),
    DestinationCatalogItem(
      destination: Destination(
        name: 'Home',
        latitude: 43.6629,
        longitude: -79.3957,
      ),
      badges: ['Home'],
    ),
    DestinationCatalogItem(
      destination: Destination(
        name: 'Work',
        latitude: 43.6488,
        longitude: -79.3817,
      ),
      badges: ['Work'],
    ),
  ];
}
