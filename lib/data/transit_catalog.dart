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
}
