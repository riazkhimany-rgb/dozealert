import 'package:flutter/material.dart';

import '../screens/transit_data_licenses_screen.dart';
import '../utils/external_link_launcher.dart';
import '../utils/transit_attribution.dart';

/// Compact agency credit shown wherever transit data is in use.
class TransitAttributionNotice extends StatelessWidget {
  const TransitAttributionNotice({
    super.key,
    required this.agencyName,
    this.compact = false,
    this.showLicenseLink = true,
  });

  final String agencyName;
  final bool compact;
  final bool showLicenseLink;

  Future<void> _openLicense(BuildContext context, String url) async {
    await ExternalLinkLauncher.openOrSnackBar(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final attribution = TransitAttribution.textForAgency(agencyName);
    final licenseUrl = TransitAttribution.licenseUrlForAgency(agencyName);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.copyright_outlined,
                size: compact ? 16 : 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attribution,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (showLicenseLink) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (licenseUrl != null)
                  TextButton(
                    onPressed: () => _openLicense(context, licenseUrl),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Agency terms'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TransitDataLicensesScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('All transit licenses'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
