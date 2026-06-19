import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../providers/monitoring_provider.dart';
import '../utils/map_defaults.dart';
import '../widgets/home_card.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _markerId = MarkerId('selected_destination');

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

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
    });
  }

  Future<void> _saveLocation() async {
    final position = _selectedPosition;
    if (position == null) {
      return;
    }

    final destination = Destination(
      name: MapDefaults.customDestinationName,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    await context.read<MonitoringProvider>().setDestination(destination);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPosition = _selectedPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick on Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            onTap: _onMapTap,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
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
                    'Selected coordinates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  Text(
                    selectedPosition == null
                        ? 'Tap the map to drop a marker.'
                        : 'Tap another location to move the marker.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selectedPosition == null ? null : _saveLocation,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Location'),
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
