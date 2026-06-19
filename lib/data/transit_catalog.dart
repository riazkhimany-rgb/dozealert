import '../models/destination.dart';

abstract final class TransitCatalog {
  static const countries = <String>[
    'Canada',
    'United States',
    'United Kingdom',
  ];

  static const systemsByCountry = <String, List<String>>{
    'Canada': ['GO Transit', 'TTC', 'Exo'],
    'United States': ['Amtrak', 'MTA'],
    'United Kingdom': ['National Rail', 'London Underground'],
  };

  static const linesBySystem = <String, List<String>>{
    'GO Transit': [
      'Lakeshore West',
      'Lakeshore East',
      'Milton',
      'Kitchener',
      'Barrie',
      'Stouffville',
      'Richmond Hill',
    ],
    'TTC': ['Line 1', 'Line 2', 'Line 4'],
    'Exo': ['Mont-Saint-Hilaire', 'Candiac'],
    'Amtrak': ['Northeast Regional', 'Acela'],
    'MTA': ['Hudson', 'Harlem'],
    'National Rail': ['West Coast Main Line', 'East Coast Main Line'],
    'London Underground': ['Piccadilly', 'Central'],
  };

  static const defaultSystemByCountry = <String, String>{
    'Canada': 'GO Transit',
    'United States': 'Amtrak',
    'United Kingdom': 'National Rail',
  };

  static const defaultLineBySystem = <String, String>{
    'GO Transit': 'Lakeshore West',
    'TTC': 'Line 1',
    'Exo': 'Mont-Saint-Hilaire',
    'Amtrak': 'Northeast Regional',
    'MTA': 'Hudson',
    'National Rail': 'West Coast Main Line',
    'London Underground': 'Piccadilly',
  };

  static const lakeshoreWestStations = <Destination>[
    Destination(name: 'Union', latitude: 43.6453, longitude: -79.3806),
    Destination(name: 'Exhibition', latitude: 43.6359, longitude: -79.4187),
    Destination(name: 'Mimico', latitude: 43.6172, longitude: -79.4946),
    Destination(name: 'Long Branch', latitude: 43.5910, longitude: -79.5400),
    Destination(name: 'Port Credit', latitude: 43.5534, longitude: -79.5855),
    Destination(name: 'Clarkson', latitude: 43.5232, longitude: -79.6338),
    Destination(name: 'Oakville', latitude: 43.4553, longitude: -79.6829),
    Destination(name: 'Bronte', latitude: 43.4039, longitude: -79.7589),
    Destination(name: 'Appleby', latitude: 43.3811, longitude: -79.7624),
    Destination(name: 'Burlington', latitude: 43.3416, longitude: -79.8094),
    Destination(name: 'Aldershot', latitude: 43.3138, longitude: -79.8550),
    Destination(name: 'West Harbour', latitude: 43.2650, longitude: -79.8672),
  ];

  static List<String> systemsForCountry(String country) {
    return systemsByCountry[country] ?? systemsByCountry['Canada']!;
  }

  static List<String> linesForSystem(String transitSystem) {
    return linesBySystem[transitSystem] ??
        linesBySystem[defaultSystemByCountry['Canada']!]!;
  }

  static String defaultSystemForCountry(String country) {
    return defaultSystemByCountry[country] ??
        defaultSystemByCountry['Canada']!;
  }

  static String defaultLineForSystem(String transitSystem) {
    return defaultLineBySystem[transitSystem] ??
        defaultLineBySystem['GO Transit']!;
  }

  static bool isValidCountry(String country) {
    return countries.contains(country);
  }

  static bool isValidSystemForCountry(String country, String transitSystem) {
    return systemsForCountry(country).contains(transitSystem);
  }

  static bool isValidLineForSystem(String transitSystem, String line) {
    return linesForSystem(transitSystem).contains(line);
  }

  static const emptyStations = <Destination>[];

  static List<Destination> favoriteStations({
    required String transitSystem,
    required String defaultLine,
  }) {
    if (transitSystem == 'GO Transit' && defaultLine == 'Lakeshore West') {
      return lakeshoreWestStations;
    }
    return emptyStations;
  }
}
