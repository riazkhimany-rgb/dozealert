import 'package:flutter/material.dart';

import '../../widgets/onboarding_permissions_page.dart';

class PermissionsSettingsScreen extends StatelessWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: OnboardingPermissionsPage(
        embedded: true,
        onStatusChanged: (_) {},
      ),
    );
  }
}
