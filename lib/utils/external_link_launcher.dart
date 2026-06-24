import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens http(s) links in the device browser.
abstract final class ExternalLinkLauncher {
  static Future<bool> open(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return false;
    }

    if (!uri.hasScheme) {
      return open('https://$url');
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return false;
    }

    const modes = [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
    ];

    for (final mode in modes) {
      try {
        if (await launchUrl(uri, mode: mode)) {
          return true;
        }
      } catch (_) {
        // Try the next launch mode.
      }
    }

    if (uri.scheme == 'http') {
      final httpsUri = uri.replace(scheme: 'https');
      for (final mode in modes) {
        try {
          if (await launchUrl(httpsUri, mode: mode)) {
            return true;
          }
        } catch (_) {
          // Try the next launch mode.
        }
      }
    }

    return false;
  }

  static Future<void> openOrSnackBar(BuildContext context, String url) async {
    final opened = await open(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }
}
