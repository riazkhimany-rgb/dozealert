/// Open capability tokens for catalog feeds.
///
/// Unknown tokens are ignored by the app. New tokens can be added without a
/// schema bump.
abstract final class GtfsCapabilities {
  static const gtfsStaticDownload = 'gtfs_static_download';
  static const manualImport = 'manual_import';
  static const gtfsRtTripUpdates = 'gtfs_rt_trip_updates';
  static const gtfsRtVehiclePositions = 'gtfs_rt_vehicle_positions';
  static const gtfsRtServiceAlerts = 'gtfs_rt_service_alerts';
  static const requiresUserAcknowledgement = 'requires_user_acknowledgement';

  static const realtimeTokens = <String>{
    gtfsRtTripUpdates,
    gtfsRtVehiclePositions,
    gtfsRtServiceAlerts,
  };

  static bool impliesRealtime(Iterable<String> capabilities) {
    return capabilities.any(realtimeTokens.contains);
  }
}
