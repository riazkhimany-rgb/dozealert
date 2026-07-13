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
      'Drop a pin or search on the map when you are not using a transit stop';

  static const mapPinSubtitleFallback =
      'Use the map if your stop list is not downloaded yet';

  static const stopDataSectionTitle = 'Stop data';

  static const downloadStops = 'Download stops';

  static const updateStops = 'Update stops';

  static const processingStopData = 'Processing stop data…';

  static String stopDataDownloaded(String agencyName) =>
      '$agencyName stop list downloaded.';

  static String stopDataUpdated(String agencyName) =>
      '$agencyName stop list updated.';

  static String couldNotDownloadStopData(String agencyName, String detail) =>
      'Could not download $agencyName stops. $detail';

  static String couldNotUpdateStopData(String agencyName, String detail) =>
      'Could not update $agencyName stops. $detail';

  static String noStopFeedConfigured(String agencyName) =>
      'No stop list is configured for $agencyName.';

  static const importStopDataHint =
      'Download the zip from the open data page, then import it from '
      'Settings → Transit → Import GTFS Zip.';

  static const noDirectDownloadLink =
      'This agency does not provide a direct download link.';

  static String routesLoadedCount(int count, {String? vehicleFilter}) {
    final filter = vehicleFilter == null ? '' : ' ($vehicleFilter)';
    return '$count routes loaded from stop data$filter.';
  }

  static String downloadStopsToLoadRoutes(String transitName) =>
      'Download stop data below to load routes for $transitName.';

  static const downloadStopsToLoadAllRoutes =
      'Download stop data below to load all routes including buses.';

  static String downloadStopsForVehicleType(String vehicleLabel) =>
      'Download stops to load ${vehicleLabel.toLowerCase()} routes';

  static const searchStopsOnRoute = 'Search stops on your route';

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
      'Switch transit and line pairs quickly on Home.';

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
