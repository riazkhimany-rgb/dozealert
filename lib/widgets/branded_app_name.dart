import 'package:flutter/material.dart';

import '../utils/app_branding.dart';

/// Wordmark: **Doze** in brand midnight (or white on dark), **Alert** in cyan.
class BrandedAppName extends StatelessWidget {
  const BrandedAppName({
    super.key,
    this.style,
    this.dozeColor,
    this.alertColor,
    this.prefix,
    this.suffix,
    this.textAlign,
    this.onDarkBackground = false,
  });

  final TextStyle? style;
  final Color? dozeColor;
  final Color? alertColor;
  final String? prefix;
  final String? suffix;
  final TextAlign? textAlign;

  /// When true (or dark theme), **Doze** uses white so it stays readable on
  /// midnight / branded backgrounds.
  final bool onDarkBackground;

  static List<TextSpan> spans({
    required TextStyle style,
    required Color dozeColor,
    Color? alertColor,
    String prefix = '',
    String suffix = '',
  }) {
    final boldStyle = style.copyWith(fontWeight: FontWeight.w700);
    final resolvedAlertColor = alertColor ?? AppBranding.cyanAccent;
    // Prefix/suffix stay at the surrounding weight/color — only DozeAlert is bold.
    final surroundingStyle = style.copyWith(inherit: false);
    return [
      if (prefix.isNotEmpty)
        TextSpan(
          text: prefix,
          style: surroundingStyle,
        ),
      TextSpan(
        text: 'Doze',
        style: boldStyle.copyWith(
          color: dozeColor,
          inherit: false,
        ),
      ),
      TextSpan(
        text: 'Alert',
        style: boldStyle.copyWith(
          color: resolvedAlertColor,
          inherit: false,
        ),
      ),
      if (suffix.isNotEmpty)
        TextSpan(
          text: suffix,
          style: surroundingStyle,
        ),
    ];
  }

  /// Wordmark on [FilledButton]: white **Doze**; **Alert** contrasts with fill.
  static BrandedAppName forFilledButton(
    BuildContext context, {
    String prefix = '',
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    final onCyanFill = theme.brightness == Brightness.dark;
    final dozeColor = AppBranding.white;
    final alertColor = AppBranding.resolveAlertColor(
      onCyanBackground: onCyanFill,
    );
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: dozeColor,
    );

    return BrandedAppName(
      prefix: prefix,
      suffix: suffix,
      style: labelStyle,
      dozeColor: dozeColor,
      alertColor: alertColor,
      onDarkBackground: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStyle = style ??
        theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ) ??
        const TextStyle(fontWeight: FontWeight.w700);
    final resolvedDoze = dozeColor ??
        AppBranding.resolveDozeColor(
          context,
          onDarkBackground: onDarkBackground,
        );
    final resolvedAlert = alertColor ?? AppBranding.cyanAccent;

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: spans(
          style: resolvedStyle,
          dozeColor: resolvedDoze,
          alertColor: resolvedAlert,
          prefix: prefix ?? '',
          suffix: suffix ?? '',
        ),
      ),
      textAlign: textAlign,
    );
  }
}

/// Body copy that styles every "DozeAlert" mention with the brand wordmark.
class BrandedMentionText extends StatelessWidget {
  const BrandedMentionText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.dozeColor,
    this.alertColor,
    this.onDarkBackground = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? dozeColor;
  final Color? alertColor;
  final bool onDarkBackground;

  static const _token = 'DozeAlert';

  static List<TextSpan> buildSpans({
    required String text,
    required TextStyle style,
    required Color dozeColor,
    Color? alertColor,
  }) {
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = text.indexOf(_token, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.addAll(
        BrandedAppName.spans(
          style: style,
          dozeColor: dozeColor,
          alertColor: alertColor,
        ),
      );
      start = index + _token.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    if (resolvedStyle == null) {
      return Text(text, textAlign: textAlign);
    }

    final resolvedDoze = dozeColor ??
        AppBranding.resolveDozeColor(
          context,
          onDarkBackground: onDarkBackground,
        );

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: buildSpans(
          text: text,
          style: resolvedStyle,
          dozeColor: resolvedDoze,
          alertColor: alertColor,
        ),
      ),
      textAlign: textAlign,
    );
  }
}

/// Tappable inline brand mention (optional).
class BrandedMentionLink extends StatelessWidget {
  const BrandedMentionLink({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.onTap,
    this.onDarkBackground = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final VoidCallback? onTap;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    return BrandedMentionText(
      text,
      style: style,
      textAlign: textAlign,
      onDarkBackground: onDarkBackground,
    );
  }
}
