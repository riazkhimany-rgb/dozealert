import 'package:flutter/material.dart';

import '../utils/app_branding.dart';

/// Wordmark: **Doze** in [dozeColor], **Alert** in brand cyan.
class BrandedAppName extends StatelessWidget {
  const BrandedAppName({
    super.key,
    this.style,
    this.dozeColor,
    this.alertColor,
    this.prefix,
    this.suffix,
    this.textAlign,
  });

  final TextStyle? style;
  final Color? dozeColor;
  final Color? alertColor;
  final String? prefix;
  final String? suffix;
  final TextAlign? textAlign;

  static List<TextSpan> spans({
    required TextStyle style,
    Color? dozeColor,
    Color? alertColor,
    String prefix = '',
    String suffix = '',
  }) {
    final boldStyle = style.copyWith(fontWeight: FontWeight.w700);
    final resolvedAlertColor = alertColor ?? AppBranding.cyanAccent;
    return [
      if (prefix.isNotEmpty)
        TextSpan(
          text: prefix,
          style: boldStyle.copyWith(
            color: dozeColor ?? style.color,
            inherit: false,
          ),
        ),
      TextSpan(
        text: 'Doze',
        style: boldStyle.copyWith(
          color: dozeColor ?? style.color,
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
          style: boldStyle.copyWith(
            color: dozeColor ?? style.color,
            inherit: false,
          ),
        ),
    ];
  }

  /// Wordmark label for [FilledButton] — white/cyan on dark buttons, white/cyan
  /// on light (midnight) buttons so "Alert" never matches the button fill.
  static BrandedAppName forFilledButton(
    BuildContext context, {
    String prefix = '',
    String suffix = '',
  }) {
    final theme = Theme.of(context);
    final dozeColor = theme.colorScheme.brightness == Brightness.dark
        ? AppBranding.white
        : theme.colorScheme.onPrimary;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: dozeColor,
    );

    return BrandedAppName(
      prefix: prefix,
      suffix: suffix,
      style: labelStyle,
      dozeColor: dozeColor,
      alertColor: AppBranding.cyanAccent,
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

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: spans(
          style: resolvedStyle,
          dozeColor: dozeColor,
          alertColor: alertColor,
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
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color? dozeColor;
  final Color? alertColor;

  static const _token = 'DozeAlert';

  static List<TextSpan> buildSpans({
    required String text,
    required TextStyle style,
    Color? dozeColor,
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

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: buildSpans(
          text: text,
          style: resolvedStyle,
          dozeColor: dozeColor,
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
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BrandedMentionText(
      text,
      style: style,
      textAlign: textAlign,
    );
  }
}
