import '../models/destination.dart';

abstract final class MockDestinations {
  static const List<Destination> all = [
    Destination(
      name: 'Union Station',
      latitude: 43.6453,
      longitude: -79.3806,
    ),
    Destination(
      name: 'Milton GO',
      latitude: 43.5186,
      longitude: -79.8774,
    ),
    Destination(
      name: 'Pearson Airport',
      latitude: 43.6777,
      longitude: -79.6248,
    ),
    Destination(
      name: 'CN Tower',
      latitude: 43.6426,
      longitude: -79.3871,
    ),
    Destination(
      name: 'Home',
      latitude: 43.6629,
      longitude: -79.3957,
    ),
    Destination(
      name: 'Work',
      latitude: 43.6488,
      longitude: -79.3817,
    ),
  ];
}
