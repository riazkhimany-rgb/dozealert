import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';

import '../config/env_config.dart';
import '../providers/monitoring_provider.dart';
import '../services/place_search_service.dart';
import '../utils/map_defaults.dart';
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

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;

  CameraPosition get _initialCameraPosition {
    return const CameraPosition(
      target: LatLng(
        MapDefaults.torontoLatitude,
        MapDefaults.torontoLongitude,
      ),
      zoom: MapDefaults.initialZoom,
    );
  }

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
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = MapDefaults.customDestinationName;
      }
    });
  }

  void _selectSearchResult(PlaceSearchResult result) {
    setState(() {
      _selectedPosition = result.latLng;
      _nameController.text = result.name;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 15),
    );
  }

  Future<void> _saveDestination() async {
    final position = _selectedPosition;
    if (position == null) {
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeSearchService = context.read<PlaceSearchService>();
    final selectedPosition = _selectedPosition;
    final canSave = selectedPosition != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Destination'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            onMapCreated: _onMapCreated,
            onTap: _onMapTap,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Material(
              elevation: 3,
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!placeSearchService.isConfigured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          EnvConfig.missingApiKeyMessage,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      )
                    else
                      GooglePlaceAutoCompleteTextField(
                        textEditingController: _searchController,
                        googleAPIKey: placeSearchService.apiKey,
                        debounceTime: 400,
                        countries: const ['ca'],
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
                          _searchController.text = prediction.description ?? '';
                          _searchController.selection = TextSelection.fromPosition(
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
                    if (placeSearchService.isConfigured) ...[
                      const SizedBox(height: 8),
                      Text(
                        placeSearchService.searchHelperText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: HomeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: MapDefaults.customDestinationName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  _CoordinateRow(
                    label: 'Latitude',
                    value: selectedPosition != null
                        ? selectedPosition.latitude.toStringAsFixed(4)
                        : '—',
                  ),
                  const SizedBox(height: 8),
                  _CoordinateRow(
                    label: 'Longitude',
                    value: selectedPosition != null
                        ? selectedPosition.longitude.toStringAsFixed(4)
                        : '—',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedPosition == null
                        ? 'Search above or tap the map to place a marker.'
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
                      onPressed: canSave ? _saveDestination : null,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Destination'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
