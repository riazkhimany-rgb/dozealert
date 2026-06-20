import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/app_branding.dart';
import '../../widgets/branding_logo.dart';
import '../../widgets/settings_section_tile.dart';
import '../about_screen.dart';
import '../our_story_screen.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  String _version = '…';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'App'),
          ListTile(
            leading: const BrandingLogo(height: 44),
            title: const Text('About DozeAlert'),
            subtitle: Text(
              AppBranding.tagline,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.auto_stories_outlined, color: colorScheme.primary),
            title: const Text('Our Story'),
            subtitle: Text(
              'Why DozeAlert exists and about the creator',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OurStoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Version'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('App Version'),
            trailing: Text(
              _version,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
