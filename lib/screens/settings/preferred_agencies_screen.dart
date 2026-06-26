import 'package:flutter/material.dart';

import '../../widgets/transit_preferences_section.dart';

class PreferredAgenciesScreen extends StatelessWidget {
  const PreferredAgenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferred Agencies'),
      ),
      body: ListView(
        children: const [
          TransitPreferencesSection(),
        ],
      ),
    );
  }
}
