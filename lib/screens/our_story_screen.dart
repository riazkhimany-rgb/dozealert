import 'package:flutter/material.dart';

import '../utils/app_branding.dart';
import '../widgets/branded_app_name.dart';

class OurStoryScreen extends StatelessWidget {
  const OurStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.55,
    );
    final boldStyle = bodyStyle?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Story'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
          BrandedAppName(
            prefix: 'Why ',
            suffix: ' Exists?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          BrandedMentionText(
            'The idea for DozeAlert came from a real experience. '
            'During one of my daily train commutes, I dozed off and '
            'woke up just in time to realize that I had reached my '
            'stop. The train doors were about to close, and I barely '
            'made it off in time. As I walked away, I couldn\'t help '
            'but think, "There has to be a technological way to solve this problem."',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          BrandedMentionText(
            'That moment sparked the idea for DozeAlert.',
            style: boldStyle,
          ),
          const SizedBox(height: 16),
          BrandedMentionText(
            'What started as a simple thought quickly became a passion project. '
            'I created DozeAlert to help people relax, rest, and travel with '
            'confidence. Whether you\'re commuting to work, taking a long train '
            'ride, or traveling by bus, everyone deserves the peace of mind that '
            'they won\'t miss their destination.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          Text(
            'I believe that some of the best ideas come from real-life '
            'experiences and simple needs. As an independent creator, I enjoy '
            'building practical tools that make life a little easier and bring '
            'peace of mind to everyday moments.',
            style: bodyStyle,
          ),
          const SizedBox(height: 16),
          BrandedMentionText(
            'Thank you for being part of this journey and for supporting '
            'independent app development. Your feedback and encouragement help '
            'shape the future of DozeAlert.',
            style: bodyStyle,
          ),
          const SizedBox(height: 24),
          Text(
            AppBranding.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 24),
          Text(
            'About the Creator',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                const TextSpan(
                  text:
                      'I am a technology enthusiast based in Canada who enjoys using technology to solve everyday problems and create practical tools that improve people\'s lives.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: bodyStyle,
              children: [
                ...BrandedAppName.spans(
                  style: boldStyle ?? bodyStyle!,
                  dozeColor: colorScheme.onSurface,
                ),
                TextSpan(
                  text: ' is a passion project',
                  style: boldStyle,
                ),
                TextSpan(
                  text:
                      ' inspired by a simple but relatable problem faced by '
                      'commuters everywhere. Built with care and driven by '
                      'real-life experience, the app continues to evolve thanks '
                      'to the support, feedback, and ideas shared by its users.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thank you for being part of the journey.',
            style: bodyStyle,
          ),
          const SizedBox(height: 24),
          Text(
            '— Riaz',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          BrandedAppName(
            prefix: 'Creator of ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            dozeColor: colorScheme.onSurfaceVariant,
          ),
          ],
        ),
      ),
    );
  }
}
