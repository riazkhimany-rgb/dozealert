import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../providers/transit_line_provider.dart';
import '../providers/transit_provider.dart';
import '../widgets/home_card.dart';

class TransitPreferencesSection extends StatelessWidget {
  const TransitPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preferences = context.watch<TransitProvider>().preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            'Transit Preferences',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: 'Country',
            value: preferences.country,
            options: TransitCatalog.countries,
            onChanged: (value) async {
              await context.read<TransitProvider>().setCountry(value);
              if (!context.mounted) {
                return;
              }
              await context.read<TransitLineProvider>().loadCurrentLine();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: 'Transit System',
            value: preferences.transitSystem,
            options: TransitCatalog.systemsForCountry(preferences.country),
            onChanged: (value) async {
              await context.read<TransitProvider>().setTransitSystem(value);
              if (!context.mounted) {
                return;
              }
              await context.read<TransitLineProvider>().loadCurrentLine();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _TransitPreferenceCard(
            title: 'Default Line',
            value: preferences.defaultLine,
            options: TransitCatalog.linesForSystem(preferences.transitSystem),
            onChanged: (value) async {
              await context.read<TransitProvider>().setDefaultLine(value);
              if (!context.mounted) {
                return;
              }
              await context.read<TransitLineProvider>().loadCurrentLine();
            },
          ),
        ),
      ],
    );
  }
}

class _TransitPreferenceCard extends StatelessWidget {
  const _TransitPreferenceCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: options.contains(value) ? value : options.first,
                items: options
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      ),
                    )
                    .toList(),
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
