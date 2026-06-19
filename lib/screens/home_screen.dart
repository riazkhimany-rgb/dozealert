import 'package:flutter/material.dart';

import '../widgets/info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DozeAlert'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: 72,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Wake up at the right stop',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'DozeAlert alerts you as you approach your destination, '
            'whether you are traveling or resting on the way.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          const InfoCard(
            icon: Icons.place_outlined,
            title: 'Set a destination',
            subtitle: 'Location alerts are coming soon. You will be able to '
                'pick a stop and get notified before you arrive.',
          ),
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.bedtime_outlined,
            title: 'Travel with peace of mind',
            subtitle: 'Rest on buses, trains, or rides without worrying about '
                'missing your stop.',
          ),
        ],
      ),
    );
  }
}
