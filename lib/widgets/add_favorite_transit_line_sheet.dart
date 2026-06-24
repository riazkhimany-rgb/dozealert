import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/transit_catalog.dart';
import '../models/favorite_transit_line.dart';
import '../providers/favorite_transit_line_provider.dart';
import '../providers/transit_provider.dart';
import 'accessible_scroll_body.dart';

class AddFavoriteTransitLineSheet extends StatefulWidget {
  const AddFavoriteTransitLineSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const AddFavoriteTransitLineSheet(),
    );
  }

  @override
  State<AddFavoriteTransitLineSheet> createState() =>
      _AddFavoriteTransitLineSheetState();
}

class _AddFavoriteTransitLineSheetState extends State<AddFavoriteTransitLineSheet> {
  late String _country;
  late String _region;
  late String _transitSystem;
  late String _lineName;

  @override
  void initState() {
    super.initState();
    final current = context.read<TransitProvider>().preferences;
    _country = current.country;
    _region = current.region;
    _transitSystem = current.transitSystem;
    _lineName = current.defaultLine;
    _normalizeSelections();
  }

  void _normalizeSelections() {
    if (!TransitCatalog.isValidCountry(_country)) {
      _country = TransitCatalog.countries.first;
    }
    if (!TransitCatalog.isValidRegionForCountry(_country, _region)) {
      _region = TransitCatalog.defaultRegionForCountry(_country);
    }
    if (!TransitCatalog.isValidAgencyForRegion(_country, _region, _transitSystem)) {
      _transitSystem = TransitCatalog.defaultAgencyForRegion(_country, _region);
    }
    if (!TransitCatalog.isValidLineForSystem(_transitSystem, _lineName)) {
      _lineName = TransitCatalog.defaultLineForSystem(_transitSystem);
    }
  }

  List<String> _linesForAgency() => TransitCatalog.linesForSystem(_transitSystem);

  Future<void> _save() async {
    final favorite = FavoriteTransitLine(
      country: _country,
      region: _region,
      transitSystem: _transitSystem,
      lineName: _lineName,
    );

    await context.read<FavoriteTransitLineProvider>().add(favorite);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${favorite.label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AccessibleSheetBody(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
              'Add favorite line',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save agency and line pairs for quick switching on Home.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _PickerField(
              label: 'Country',
              value: _country,
              options: TransitCatalog.countries,
              onChanged: (value) {
                setState(() {
                  _country = value;
                  _region = TransitCatalog.defaultRegionForCountry(value);
                  _transitSystem =
                      TransitCatalog.defaultAgencyForRegion(_country, _region);
                  _lineName = TransitCatalog.defaultLineForSystem(_transitSystem);
                });
              },
            ),
            _PickerField(
              label: TransitCatalog.regionLabelForCountry(_country),
              value: _region,
              options: TransitCatalog.regionsForCountry(_country),
              onChanged: (value) {
                setState(() {
                  _region = value;
                  _transitSystem =
                      TransitCatalog.defaultAgencyForRegion(_country, _region);
                  _lineName = TransitCatalog.defaultLineForSystem(_transitSystem);
                });
              },
            ),
            _PickerField(
              label: 'Transit agency',
              value: _transitSystem,
              options: TransitCatalog.agenciesForRegion(_country, _region),
              onChanged: (value) {
                setState(() {
                  _transitSystem = value;
                  _lineName = TransitCatalog.defaultLineForSystem(value);
                });
              },
            ),
            _PickerField(
              label: 'Line',
              value: _lineName,
              options: _linesForAgency(),
              onChanged: (value) => setState(() => _lineName = value),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => unawaited(_save()),
              child: const Text('Save favorite line'),
            ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: options.contains(value) ? value : options.first,
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (next) {
              if (next != null) {
                onChanged(next);
              }
            },
          ),
        ),
      ),
    );
  }
}
