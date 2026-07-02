import '../models/transit_line_option.dart';
import '../models/transit_vehicle_type.dart';

abstract final class TransitLinePickerUtils {
  /// Whether line pickers should use [SearchableLinePicker] instead of a short
  /// dropdown. Bus, streetcar, and subway lists always use search so riders see
  /// route numbers plus long names from GTFS.
  static bool shouldUseSearchableLinePicker({
    required List<TransitLineOption> lineOptions,
    TransitVehicleType? vehicleType,
  }) {
    if (lineOptions.isEmpty) {
      return false;
    }

    if (vehicleType == TransitVehicleType.bus ||
        vehicleType == TransitVehicleType.streetcar ||
        vehicleType == TransitVehicleType.subway) {
      return true;
    }

    return lineOptions.length > 4;
  }
}
