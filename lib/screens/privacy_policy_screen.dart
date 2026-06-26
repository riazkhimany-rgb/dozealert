import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../utils/app_branding.dart';
import '../utils/external_link_launcher.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late Future<String> _policyFuture;

  @override
  void initState() {
    super.initState();
    _policyFuture = rootBundle.loadString(AppBranding.privacyPolicyAsset);
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) {
      return;
    }

    await ExternalLinkLauncher.openOrSnackBar(context, href);
  }

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium?.copyWith(
      height: 1.6,
      color: colorScheme.onSurface,
    );
    final muted = body?.copyWith(color: colorScheme.onSurfaceVariant);

    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      h1Padding: const EdgeInsets.only(bottom: 12),
      h2: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
      p: body,
      pPadding: const EdgeInsets.only(bottom: 10),
      listBullet: body,
      listIndent: 24,
      blockSpacing: 12,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      strong: body?.copyWith(fontWeight: FontWeight.w700),
      em: body?.copyWith(fontStyle: FontStyle.italic),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        color: colorScheme.onSurface,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      blockquote: muted,
      blockquoteDecoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        border: Border(
          left: BorderSide(color: colorScheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      tableHead: theme.textTheme.labelLarge?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      tableBody: body,
      tableCellsPadding: const EdgeInsets.all(10),
      tableBorder: TableBorder.all(color: colorScheme.outlineVariant),
      a: body?.copyWith(
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: FutureBuilder<String>(
        future: _policyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Unable to load privacy policy.',
                style: TextStyle(color: colorScheme.error),
              ),
            );
          }

          return SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: MarkdownBody(
                data: snapshot.data!,
                selectable: true,
                extensionSet: md.ExtensionSet.gitHubWeb,
                styleSheet: _styleSheet(context),
                onTapLink: (text, href, title) => _openLink(href),
              ),
            ),
          );
        },
      ),
    );
  }
}
