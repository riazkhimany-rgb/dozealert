import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/trip_diagnostics_log.dart';

/// Read-only view of the persisted trip breadcrumb trail, newest first.
class TripDiagnosticsLogScreen extends StatefulWidget {
  const TripDiagnosticsLogScreen({super.key});

  @override
  State<TripDiagnosticsLogScreen> createState() =>
      _TripDiagnosticsLogScreenState();
}

class _TripDiagnosticsLogScreenState extends State<TripDiagnosticsLogScreen> {
  List<String>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await TripDiagnosticsLog.entries();
    if (!mounted) {
      return;
    }
    setState(() => _entries = entries);
  }

  Future<void> _copyAll() async {
    final entries = _entries ?? const <String>[];
    await Clipboard.setData(ClipboardData(text: entries.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip log copied')),
    );
  }

  Future<void> _clear() async {
    await TripDiagnosticsLog.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copy all',
            onPressed: entries == null || entries.isEmpty ? null : _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: entries == null || entries.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No trip events recorded yet.\n'
                      'Start a trip and the log fills in as it runs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        entries[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
