import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';

import '../config/env_config.dart';
import '../providers/destination_history_provider.dart';
import '../providers/gtfs_provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/transit_provider.dart';
import '../services/location_service.dart';
import '../services/place_search_service.dart';
import '../utils/map_defaults.dart';
import '../utils/trip_ux_copy.dart';
import '../widgets/home_card.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _markerId = MarkerId('selected_destination');

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(
      MapDefaults.torontoLatitude,
      MapDefaults.torontoLongitude,
    ),
    zoom: MapDefaults.initialZoom,
  );
  bool _centeredOnUser = false;

  Set<Marker> get _markers {
    final position = _selectedPosition;
    if (position == null) {
      return const {};
    }

    return {
      Marker(
        markerId: _markerId,
        position: position,
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_centerOnUserLocation());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _searchFocusNode.dispose();
    _nameFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _centerOnUserLocation() async {
    if (_centeredOnUser) {
      return;
    }

    final locationService = context.read<LocationService>();
    final location = await locationService.fetchCurrentLocation();
    if (!mounted || location == null) {
      return;
    }

    final target = LatLng(location.latitude, location.longitude);
    setState(() {
      _centeredOnUser = true;
      _initialCameraPosition = CameraPosition(target: target, zoom: 14);
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
  }

  List<String> _placeCountries() {
    final country = context.read<TransitProvider>().preferences.country;
    return switch (country) {
      'United States' => const ['us'],
      'Canada' => const ['ca'],
      _ => const ['ca', 'us'],
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedPosition = position);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _nameFocusNode.requestFocus();
      if (_nameController.text == MapDefaults.customDestinationName) {
        _nameController.clear();
      }
    });
  }

  void _selectSearchResult(PlaceSearchResult result) {
    setState(() {
      _selectedPosition = result.latLng;
      _nameController.text = result.name;
    });

    _searchFocusNode.unfocus();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  Future<void> _saveDestination({bool addToMyTrips = false}) async {
    final position = _selectedPosition;
    if (position == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a place from search results or tap the map to drop a pin.',
          ),
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final destination = PlaceSearchResult(
      name: name.isEmpty ? MapDefaults.customDestinationName : name,
      latitude: position.latitude,
      longitude: position.longitude,
    ).toDestination();

    await context.read<MonitoringProvider>().setDestination(destination);
    if (!mounted) {
      return;
    }

    if (addToMyTrips) {
      await context.read<DestinationHistoryProvider>().addFavoriteItem(
        context.read<GtfsProvider>().buildFavoriteDestination(destination),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${destination.name} to My Trips')),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeSearchService = context.read<PlaceSearchService>();
    final selectedPosition = _selectedPosition;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardOpen = keyboardInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(TripUxCopy.pickDestination),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Material(
                elevation: 3,
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!placeSearchService.isConfigured)
                        Text(
                          EnvConfig.missingApiKeyMessage,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        )
                      else
                        GooglePlaceAutoCompleteTextField(
                          textEditingController: _searchController,
                          focusNode: _searchFocusNode,
                          googleAPIKey: placeSearchService.apiKey,
                          debounceTime: 400,
                          countries: _placeCountries(),
                          isLatLngRequired: true,
                          isCrossBtnShown: true,
                          containerHorizontalPadding: 0,
                          containerVerticalPadding: 0,
                          boxDecoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          inputDecoration: InputDecoration(
                            hintText: PlaceSearchService.searchPlaceholder,
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          itemClick: (Prediction prediction) {
                            _searchController.text =
                                prediction.description ?? '';
                            _searchController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                offset: _searchController.text.length,
                              ),
                            );
                          },
                          getPlaceDetailWithLatLng: (Prediction prediction) {
                            final result =
                                placeSearchService.parsePrediction(prediction);
                            if (result != null) {
                              _selectSearchResult(result);
                            }
                          },
                          itemBuilder: (context, index, Prediction prediction) {
                            return ListTile(
                              leading: Icon(
                                Icons.place_outlined,
                                color: colorScheme.primary,
                              ),
                              title: Text(
                                prediction.description ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              dense: true,
                            );
                          },
                          seperatedBuilder: Divider(
                            height: 1,
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                      if (placeSearchService.isConfigured && !keyboardOpen) ...[
                        const SizedBox(height: 8),
                        Text(
                          placeSearchService.searchHelperText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                markers: _markers,
                onMapCreated: _onMapCreated,
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: !keyboardOpen,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: HomeCard(
                  child: _DestinationPanel(
                    nameController: _nameController,
                    nameFocusNode: _nameFocusNode,
                    selectedPosition: selectedPosition,
                    keyboardOpen: keyboardOpen,
                    onSave: () => unawaited(_saveDestination()),
                    onSaveToMyTrips: () =>
                        unawaited(_saveDestination(addToMyTrips: true)),
                    onCancel: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationPanel extends StatelessWidget {
  const _DestinationPanel({
    required this.nameController,
    required this.nameFocusNode,
    required this.selectedPosition,
    required this.keyboardOpen,
    required this.onSave,
    required this.onSaveToMyTrips,
    required this.onCancel,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final LatLng? selectedPosition;
  final bool keyboardOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveToMyTrips;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!keyboardOpen) ...[
          Text(
            'Destination Name',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: nameController,
          focusNode: nameFocusNode,
          decoration: InputDecoration(
            labelText: keyboardOpen ? 'Destination name' : null,
            hintText: MapDefaults.customDestinationName,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: keyboardOpen,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: keyboardOpen ? 10 : 12,
            ),
          ),
          textInputAction: TextInputAction.done,
        ),
        if (!keyboardOpen) ...[
          const SizedBox(height: 16),
          _CoordinateRow(
            label: 'Latitude',
            value: selectedPosition != null
                ? selectedPosition!.latitude.toStringAsFixed(4)
                : '—',
          ),
          const SizedBox(height: 8),
          _CoordinateRow(
            label: 'Longitude',
            value: selectedPosition != null
                ? selectedPosition!.longitude.toStringAsFixed(4)
                : '—',
          ),
          const SizedBox(height: 12),
          Text(
            selectedPosition == null
                ? 'Pick a search result or tap the map to place a pin first.'
                : 'Tap the map to fine-tune the marker position.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_rounded),
              label: const Text(TripUxCopy.setDestination),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onSaveToMyTrips,
              icon: const Icon(Icons.favorite_border_outlined),
              label: const Text(TripUxCopy.saveToMyTrips),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(TripUxCopy.setDestination),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSaveToMyTrips,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(TripUxCopy.saveToMyTrips),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CoordinateRow extends StatelessWidget {
  const _CoordinateRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
