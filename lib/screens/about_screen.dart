import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/app_branding.dart';
import '../utils/external_link_launcher.dart';
import '../widgets/branding_logo.dart';
import 'privacy_policy_screen.dart';
import 'share_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    await ExternalLinkLauncher.openOrSnackBar(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final buildNumber = snapshot.data?.buildNumber ?? '1';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(
                child: BrandingHero(
                  logoHeight: 120,
                  showDarkBadge: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Version $version ($buildNumber)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppBranding.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShareScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share DozeAlert'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Privacy Policy'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    _launchUrl(context, AppBranding.privacyPolicyUrl),
                icon: const Icon(Icons.language_outlined),
                label: const Text('Privacy Policy (Web)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _launchUrl(context, AppBranding.githubUrl),
                icon: const Icon(Icons.code_outlined),
                label: const Text('GitHub Repository'),
              ),
              const SizedBox(height: 32),
              Text(
                AppBranding.supportEmail,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
