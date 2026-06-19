import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  AlarmService();

  static const _arrivalNotificationId = 1001;
  static const _alarmAssetPath = 'sounds/alarm.mp3';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;
  bool _alarmActive = false;

  bool get alarmActive => _alarmActive;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);

      const androidChannel = AndroidNotificationChannel(
        'arrival_alerts',
        'Arrival Alerts',
        description: 'Alerts when you approach your destination',
        importance: Importance.max,
        playSound: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('AlarmService: initialize failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> playAlarm() async {
    if (_alarmActive) {
      return;
    }

    _alarmActive = true;

    await _startAlarmSound();
    await _startVibration();
    await showArrivalNotification();
  }

  Future<void> stopAlarm() async {
    if (!_alarmActive) {
      return;
    }

    _alarmActive = false;

    await _audioPlayer.stop();
    await _stopVibration();
    await _notifications.cancel(_arrivalNotificationId);
  }

  Future<void> showArrivalNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'arrival_alerts',
        'Arrival Alerts',
        channelDescription: 'Alerts when you approach your destination',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        category: AndroidNotificationCategory.alarm,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _arrivalNotificationId,
        'Destination Reached',
        'You are approaching your destination.',
        details,
      );
    } catch (error, stackTrace) {
      debugPrint('AlarmService: failed to show notification: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _startAlarmSound() async {
    try {
      await _audioPlayer.play(AssetSource(_alarmAssetPath));
    } catch (error, stackTrace) {
      debugPrint('AlarmService: failed to play alarm sound: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _startVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        return;
      }

      final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
      if (hasAmplitudeControl == true) {
        await Vibration.vibrate(
          pattern: [500, 500],
          intensities: [255, 0],
          repeat: 0,
        );
      } else {
        await Vibration.vibrate(pattern: [500, 500], repeat: 0);
      }
    } catch (error, stackTrace) {
      debugPrint('AlarmService: vibration unavailable: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (error, stackTrace) {
      debugPrint('AlarmService: failed to cancel vibration: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> dispose() async {
    await stopAlarm();
    await _audioPlayer.dispose();
  }
}
