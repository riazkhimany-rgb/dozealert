import 'package:flutter/material.dart';

import '../../utils/transit_user_copy.dart';
import '../../widgets/transit_preferences_section.dart';

class PreferredAgenciesScreen extends StatelessWidget {
  const PreferredAgenciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TransitUserCopy.transitAndLine),
      ),
      body: ListView(
        children: const [
          TransitPreferencesSection(),
        ],
      ),
    );
  }
}
