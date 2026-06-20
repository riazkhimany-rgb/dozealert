import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/app_branding.dart';
import '../widgets/branding_logo.dart';
import '../widgets/home_card.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  static String get _shareMessage =>
      'Try ${AppBranding.appName}!\n\n'
      '${AppBranding.tagline}\n\n'
      '${AppBranding.description}\n\n'
      'Download: ${AppBranding.websiteUrl}';

  Future<void> _launchShareUri(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Share.share(_shareMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final encodedMessage = Uri.encodeComponent(_shareMessage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          HomeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandingLogo(height: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppBranding.appName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppBranding.tagline,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppBranding.cyanAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppBranding.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Help fellow travelers sleep peacefully and arrive confidently. '
                  'Share DozeAlert with friends and family!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Share.share(_shareMessage),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share DozeAlert'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Share on social media',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SharePlatformButton(
                label: 'WhatsApp',
                icon: Icons.chat_bubble_outline,
                color: const Color(0xFF25D366),
                onTap: () => _launchShareUri(
                  Uri.parse('https://wa.me/?text=$encodedMessage'),
                ),
              ),
              _SharePlatformButton(
                label: 'Facebook',
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                onTap: () => _launchShareUri(
                  Uri.parse(
                    'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(AppBranding.websiteUrl)}&quote=$encodedMessage',
                  ),
                ),
              ),
              _SharePlatformButton(
                label: 'Instagram',
                icon: Icons.camera_alt_outlined,
                color: const Color(0xFFE1306C),
                onTap: () => Share.share(_shareMessage),
              ),
              _SharePlatformButton(
                label: 'X',
                icon: Icons.tag,
                color: colorScheme.onSurface,
                onTap: () => _launchShareUri(
                  Uri.parse(
                    'https://twitter.com/intent/tweet?text=$encodedMessage',
                  ),
                ),
              ),
              _SharePlatformButton(
                label: 'Email',
                icon: Icons.email_outlined,
                color: colorScheme.primary,
                onTap: () => _launchShareUri(
                  Uri.parse(
                    'mailto:?subject=${Uri.encodeComponent('Try ${AppBranding.appName}')}&body=$encodedMessage',
                  ),
                ),
              ),
              _SharePlatformButton(
                label: 'SMS',
                icon: Icons.sms_outlined,
                color: colorScheme.secondary,
                onTap: () => _launchShareUri(
                  Uri.parse('sms:?body=$encodedMessage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SharePlatformButton extends StatelessWidget {
  const _SharePlatformButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
