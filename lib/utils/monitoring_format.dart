import '../models/monitoring_state.dart';

abstract final class MonitoringFormat {
  static String stateLabel(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => 'Idle',
      MonitoringState.monitoring => 'Monitoring',
      MonitoringState.arrived => 'Arriving',
      MonitoringState.missed => 'Missed',
    };
  }

  static String homeStatusLabel(MonitoringState state) {
    return switch (state) {
      MonitoringState.idle => 'Idle',
      MonitoringState.monitoring => 'Monitoring',
      MonitoringState.arrived => 'Arriving',
      MonitoringState.missed => 'Missed',
    };
  }

  static String radiusLabel(int meters) {
    return '${meters}m';
  }
}
