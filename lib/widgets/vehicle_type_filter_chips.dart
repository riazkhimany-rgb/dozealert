import 'package:flutter/material.dart';

import '../models/transit_vehicle_type.dart';

class VehicleTypeFilterChips extends StatelessWidget {
  const VehicleTypeFilterChips({
    super.key,
    required this.vehicleTypes,
    required this.selected,
    required this.onSelected,
    this.allLabel = 'All',
  });

  final List<TransitVehicleType> vehicleTypes;
  final TransitVehicleType? selected;
  final ValueChanged<TransitVehicleType?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    if (vehicleTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(allLabel),
          selected: selected == null,
          onSelected: (_) => onSelected(null),
        ),
        for (final type in vehicleTypes)
          ChoiceChip(
            label: Text(type.label),
            selected: selected == type,
            onSelected: (_) => onSelected(type),
          ),
      ],
    );
  }
}
