import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/monitoring_provider.dart';
import '../utils/monitoring_format.dart';

class WakeRadiusDropdown extends StatelessWidget {
  const WakeRadiusDropdown({super.key});

  static const radiusOptions = <int>[250, 500, 1000, 2000];

  @override
  Widget build(BuildContext context) {
    final radiusMeters = context.select<MonitoringProvider, int>(
      (provider) => provider.radiusMeters,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Alert distance',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: radiusMeters,
            items: radiusOptions
                .map(
                  (meters) => DropdownMenuItem<int>(
                    value: meters,
                    child: Text(MonitoringFormat.radiusLabel(meters)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<MonitoringProvider>().setRadius(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
