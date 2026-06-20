import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/alarm_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/alarm_test_page.dart';

class AlarmTestScreen extends StatefulWidget {
  const AlarmTestScreen({super.key});

  @override
  State<AlarmTestScreen> createState() => _AlarmTestScreenState();
}

class _AlarmTestScreenState extends State<AlarmTestScreen> {
  bool _alarmTestPlaying = false;
  bool _alarmTestCompleted = false;
  AlarmService? _alarmService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _alarmService ??= context.read<AlarmService>();
  }

  @override
  void dispose() {
    if (_alarmTestPlaying) {
      unawaited(_alarmService?.stopAlarm());
    }
    super.dispose();
  }

  Future<void> _playTestAlarm() async {
    await context.read<AlarmService>().playAlarm();
    if (!mounted) {
      return;
    }
    setState(() => _alarmTestPlaying = true);
  }

  Future<void> _stopTestAlarm() async {
    await context.read<AlarmService>().stopAlarm();
    await OnboardingService().markAlarmTested();
    if (!mounted) {
      return;
    }
    setState(() {
      _alarmTestPlaying = false;
      _alarmTestCompleted = true;
    });
  }

  Future<void> _close() async {
    if (_alarmTestPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop the test alarm before closing.'),
        ),
      );
      return;
    }

    await context.read<AlarmService>().stopAlarm();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test alarm'),
        actions: [
          TextButton(
            onPressed: _close,
            child: const Text('Done'),
          ),
        ],
      ),
      body: AlarmTestPage(
        alarmPlaying: _alarmTestPlaying,
        alarmTestCompleted: _alarmTestCompleted,
        onPlay: () => unawaited(_playTestAlarm()),
        onStop: () => unawaited(_stopTestAlarm()),
      ),
    );
  }
}
