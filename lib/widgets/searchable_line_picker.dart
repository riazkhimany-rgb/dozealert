import 'package:flutter/material.dart';

import '../models/transit_line_option.dart';

class SearchableLinePicker extends StatelessWidget {
  const SearchableLinePicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText = 'Search route number or name…',
    this.title = 'Choose route',
  });

  final String value;
  final List<TransitLineOption> options;
  final ValueChanged<String> onChanged;
  final String hintText;
  final String title;

  String get _selectedLabel {
    for (final option in options) {
      if (option.lineName == value) {
        return option.singleLineLabel;
      }
    }
    return value;
  }

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showSearchableLineSheet(
      context: context,
      options: options,
      selectedLineName: value,
      hintText: hintText,
      title: title,
    );

    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        alignment: Alignment.centerLeft,
      ),
      onPressed: options.isEmpty ? null : () => _openPicker(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedLabel,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const Icon(Icons.search),
        ],
      ),
    );
  }
}

Future<String?> showSearchableLineSheet({
  required BuildContext context,
  required List<TransitLineOption> options,
  required String selectedLineName,
  String hintText = 'Search route number or name…',
  String title = 'Choose route',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _SearchableLineSheet(
        options: options,
        selectedLineName: selectedLineName,
        hintText: hintText,
        title: title,
      );
    },
  );
}

class _SearchableLineSheet extends StatefulWidget {
  const _SearchableLineSheet({
    required this.options,
    required this.selectedLineName,
    required this.hintText,
    required this.title,
  });

  final List<TransitLineOption> options;
  final String selectedLineName;
  final String hintText;
  final String title;

  @override
  State<_SearchableLineSheet> createState() => _SearchableLineSheetState();
}

class _SearchableLineSheetState extends State<_SearchableLineSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((option) => option.matchesQuery(_query))
        .toList(growable: false);
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SearchBar(
              controller: _searchController,
              hintText: widget.hintText,
              leading: const Icon(Icons.search),
              trailing: _query.isEmpty
                  ? null
                  : [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ],
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No routes match "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final isSelected =
                          option.lineName == widget.selectedLineName;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.singleLineLabel),
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () =>
                            Navigator.of(context).pop(option.lineName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class TransitLineListTile extends StatelessWidget {
  const TransitLineListTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TransitLineOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(option.singleLineLabel),
      trailing: selected
          ? Icon(Icons.check, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
