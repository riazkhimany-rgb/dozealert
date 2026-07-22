import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/app_branding.dart';
import '../../utils/external_link_launcher.dart';
import '../../widgets/branded_app_name.dart';
import '../../widgets/branding_logo.dart';
import '../../widgets/settings_section_tile.dart';
import '../our_story_screen.dart';
import '../privacy_policy_screen.dart';
import '../share_screen.dart';
import '../transit_data_licenses_screen.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  String _versionLabel = '…';
  String _version = '';
  String _buildNumber = '';

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
      _version = info.version;
      _buildNumber = info.buildNumber;
      _versionLabel = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _openFeedback() async {
    final version = _version.isEmpty
        ? (await PackageInfo.fromPlatform()).version
        : _version;
    final buildNumber = _buildNumber.isEmpty
        ? (await PackageInfo.fromPlatform()).buildNumber
        : _buildNumber;
    if (!mounted) {
      return;
    }
    await ExternalLinkLauncher.openOrSnackBar(
      context,
      AppBranding.feedbackUrlForApp(
        version: version,
        buildNumber: buildNumber,
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    await ExternalLinkLauncher.openOrSnackBar(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Center(
              child: BrandingHero(
                logoHeight: 96,
                showDarkBadge: true,
              ),
            ),
          ),
          Text(
            _versionLabel == '…'
                ? 'Version …'
                : 'Version $_versionLabel',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BrandedMentionText(
              AppBranding.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SettingsSectionHeader(title: 'App'),
          ListTile(
            leading: Icon(Icons.auto_stories_outlined, color: colorScheme.primary),
            title: const Text('Our Story'),
            subtitle: BrandedMentionText(
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
          ListTile(
            leading: Icon(Icons.share_outlined, color: colorScheme.primary),
            title: BrandedAppName(
              prefix: 'Share ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShareScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback_outlined, color: colorScheme.primary),
            title: const Text('Send feedback'),
            subtitle: Text(
              'Bugs, ideas, or praise — opens the website form',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openFeedback,
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'Legal'),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.language_outlined, color: colorScheme.primary),
            title: const Text('Privacy Policy (Web)'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _launchUrl(AppBranding.privacyPolicyUrl),
          ),
          SettingsNavTile(
            icon: Icons.gavel_outlined,
            title: 'Transit Data Licenses',
            subtitle: 'Agency attribution and open data terms',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TransitDataLicensesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          const SettingsSectionHeader(title: 'More'),
          ListTile(
            leading: Icon(Icons.mail_outline, color: colorScheme.primary),
            title: const Text('Support'),
            subtitle: Text(
              AppBranding.supportEmail,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
