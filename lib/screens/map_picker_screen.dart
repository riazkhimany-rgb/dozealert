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
import '../providers/settings_provider.dart';
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
  /// Soft bias only — Places still returns matches worldwide.
  static const _searchBiasRadiusMeters = 50000;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  /// Prefer results near the device / map viewport; never hard-filters country.
  LatLng _searchBias = const LatLng(
    MapDefaults.torontoLatitude,
    MapDefaults.torontoLongitude,
  );
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(
      MapDefaults.torontoLatitude,
      MapDefaults.torontoLongitude,
    ),
    zoom: MapDefaults.initialZoom,
  );
  bool _centeredOnUser = false;
  /// While true, the Google Map is not in the tree so a name dialog can own the IME.
  bool _editingName = false;
  /// Same workaround while the Places search field has focus.
  bool _searchFocused = false;

  bool get _mapSuspended => _editingName || _searchFocused;

  Set<Marker> get _markers {
    final position = _selectedPosition;
    if (position == null) {
      return const {};
    }

    return {
      Marker(
        markerId: _markerId,
        position: position,
        consumeTapEvents: true,
        onTap: () => unawaited(_editDestinationName()),
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_centerOnUserLocation());
    });
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _nameController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    final focused = _searchFocusNode.hasFocus;
    if (focused == _searchFocused) {
      return;
    }

    setState(() {
      _searchFocused = focused;
      if (focused) {
        _mapController = null;
      } else {
        final selected = _selectedPosition;
        if (selected != null) {
          _initialCameraPosition = CameraPosition(target: selected, zoom: 15);
        }
      }
    });
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
      _searchBias = target;
      _initialCameraPosition = CameraPosition(target: target, zoom: 14);
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraIdle() {
    unawaited(_refreshSearchBiasFromCamera());
  }

  Future<void> _refreshSearchBiasFromCamera() async {
    final controller = _mapController;
    if (controller == null || _mapSuspended) {
      return;
    }

    final bounds = await controller.getVisibleRegion();
    if (!mounted) {
      return;
    }

    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    if ((center.latitude - _searchBias.latitude).abs() < 0.0001 &&
        (center.longitude - _searchBias.longitude).abs() < 0.0001) {
      return;
    }

    setState(() => _searchBias = center);
  }

  /// Rename via dialog (not an inline TextField). Google Map platform views on
  /// Android routinely block the soft keyboard for sibling Flutter text fields.
  Future<void> _editDestinationName({bool promptIfEmptyOnly = false}) async {
    if (_editingName) {
      return;
    }

    final current = _nameController.text.trim();
    final isPlaceholder = current.isEmpty ||
        current == MapDefaults.customDestinationName;
    if (promptIfEmptyOnly && !isPlaceholder) {
      return;
    }

    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _editingName = true;
      _mapController = null;
    });
    // Drop the platform view before the dialog opens so Android can show the IME.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) {
      return;
    }

    final updated = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _DestinationNameDialog(
          initialName: isPlaceholder ? '' : current,
        );
      },
    );

    if (!mounted) {
      return;
    }

    final selected = _selectedPosition;
    setState(() {
      _editingName = false;
      if (selected != null) {
        _initialCameraPosition = CameraPosition(target: selected, zoom: 15);
      }
      if (updated != null) {
        final trimmed = updated.trim();
        _nameController.text = trimmed.isEmpty
            ? MapDefaults.customDestinationName
            : trimmed;
      }
    });
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedPosition = position);
    unawaited(_editDestinationName(promptIfEmptyOnly: true));
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
  }

  Future<void> _saveDestination() async {
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

    Navigator.of(context).pop();
  }

  Future<void> _bookmarkToMyTrips() async {
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

    final includeTransit =
        context.read<SettingsProvider>().transitModeEnabled;
    await context.read<DestinationHistoryProvider>().addFavoriteItem(
      context.read<GtfsProvider>().buildFavoriteDestination(
        destination,
        includeTransit: includeTransit,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${destination.name} to My Trips')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeSearchService = context.read<PlaceSearchService>();
    final selectedPosition = _selectedPosition;
    final displayName = _nameController.text.trim().isEmpty
        ? MapDefaults.customDestinationName
        : _nameController.text.trim();

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
                          // No country hard-filter: bias near the map/device
                          // so local hits rank first, but any country is allowed.
                          countries: null,
                          latitude: _searchBias.latitude,
                          longitude: _searchBias.longitude,
                          radius: _searchBiasRadiusMeters,
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
                      if (placeSearchService.isConfigured) ...[
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
              // Remove the map while renaming/searching — Android MapView blocks the IME.
              child: _mapSuspended
                  ? ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          _editingName
                              ? 'Naming destination…'
                              : 'Search results appear above',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      markers: _markers,
                      onMapCreated: _onMapCreated,
                      onTap: _onMapTap,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: HomeCard(
                child: _DestinationPanel(
                  displayName: displayName,
                  selectedPosition: selectedPosition,
                  onEditName: () => unawaited(_editDestinationName()),
                  onSave: () => unawaited(_saveDestination()),
                  onSaveToMyTrips: () => unawaited(_bookmarkToMyTrips()),
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationNameDialog extends StatefulWidget {
  const _DestinationNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_DestinationNameDialog> createState() => _DestinationNameDialogState();
}

class _DestinationNameDialogState extends State<_DestinationNameDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Destination name'),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: MapDefaults.customDestinationName,
          border: OutlineInputBorder(),
        ),
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

class _DestinationPanel extends StatelessWidget {
  const _DestinationPanel({
    required this.displayName,
    required this.selectedPosition,
    required this.onEditName,
    required this.onSave,
    required this.onSaveToMyTrips,
    required this.onCancel,
  });

  final String displayName;
  final LatLng? selectedPosition;
  final VoidCallback onEditName;
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
        Text(
          'Destination Name',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outline),
          ),
          child: InkWell(
            onTap: onEditName,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          selectedPosition == null
              ? 'Pick a search result or tap the map to place a pin first.'
              : 'Tap the name to edit. Tap the map to fine-tune the pin.',
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
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onSaveToMyTrips,
            icon: const Icon(Icons.bookmarks_outlined, size: 18),
            label: const Text(TripUxCopy.saveToMyTrips),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
