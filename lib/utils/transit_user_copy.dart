/// Plain-language strings for transit setup — no GTFS jargon in user UI.
abstract final class TransitUserCopy {
  static String stopListFor(String agencyName) => '$agencyName stop list';

  static String downloadStopListFor(String agencyName) =>
      'Download $agencyName stops';

  static String downloadingStopListFor(String agencyName) =>
      'Downloading $agencyName stops…';

  static String stopListReadyFor(String agencyName) =>
      '$agencyName stops are ready';

  static String stopListNeededFor(String agencyName) =>
      'Download $agencyName stops to pick your station and wake by stops.';

  static const transitDataScreenTitle = 'Transit stops';

  static String transitDataIntro(String region, String country) =>
      'Download stop lists for agencies in $region ($country). '
      'One tap — no account needed.';

  static const settingsTransitDataSubtitle =
      'Download and update agency stop lists';

  static const pickStopSubtitle =
      'Search stops on your line — best for buses and trains';

  static const mapPinSubtitle =
      'Advanced: drop a pin when you are not using a transit stop';

  static String wakeByStopsHint(String agencyName) =>
      'Wake by stops on $agencyName once you are on your route';

  static String waitingForStopData(String agencyName) =>
      'Download $agencyName stops to track your ride';

  /// Shared labels for the transit + line selection flow (Home button, picker, Settings).
  static const chooseTransitAndLine = 'Choose transit & line';

  static const changeTransit = 'Change transit';

  static const transitAndLineSettings = 'Transit & line settings';

  static const transitAndLine = 'Transit & line';

  static const transitLabel = 'Transit';

  static const lineLabel = 'Line';

  static const linePreferences = 'Line preferences';

  static const settingsTransitAndLineIntro =
      'Choose your country, province or state, transit, and line.';

  static const settingsTransitAndLineSubtitle =
      'Country, region, transit, and line';

  static const defaultOnHomeHint =
      'Which transit should Home show first? You can switch anytime from '
      'Choose transit & line.';

  static const homeTourConfirmTransitTitle = 'Confirm your transit & line';

  static const homeTourConfirmTransitBody =
      'Make sure the right transit and line are selected for your ride. '
      'Tap to change if you need a different agency or route.';

  static const saveTransitLinePairsHint =
      'Save transit and line pairs for quick switching on Home.';

  static const favoriteLinesSectionTitle = 'Favorite lines';

  static const allRoutesSectionTitle = 'All routes';

  static const favoriteLinesQuickSwitchHint =
      'Quick-switch transit and line pairs from Home during transfers.';

  static String downloadStopListsForRoutes(String transitName) =>
      'Download stop lists in Settings → Transit & line to load routes '
      'for $transitName.';

  static const chooseRegionInTransitAndLineSettings =
      'Choose another region under Transit & line settings, or import';

  static const selectTransitToContinue =
      'Select at least one transit to continue.';

  static const selectTransitAbove = 'Select at least one transit above.';

  static const permissionsContinueHint =
      'Required permissions are set. Tap Continue to finish setup, '
      'then pick your stop on Home.';

  static String downloadStopListForTransit(String transitName) =>
      'Download stop lists for $transitName to browse and search stops.';

  static String noStopsForTransit(String transitName) =>
      'No stops available for $transitName.';

  static String pickStopAfterDownloadHint(String transitName) =>
      'Pick the stop where you want to wake up — search by name after you '
      'download $transitName stops.';
}
