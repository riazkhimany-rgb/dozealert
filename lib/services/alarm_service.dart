import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../services/settings_service.dart';

class AlarmService {
  AlarmService(this._settingsService);

  final SettingsService _settingsService;

  static const _arrivalNotificationId = 1001;
  static const _alarmAssetPath = 'sounds/alarm.mp3';
  static const _defaultChannelId = 'arrival_alerts';
  static const _forcedAlarmChannelId = 'arrival_alerts_forced';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _initialized = false;
  bool _alarmActive = false;
  DateTime? _lastAlarmTriggeredAt;
  DateTime? _lastAlarmDismissedAt;

  bool get alarmActive => _alarmActive;
  DateTime? get lastAlarmTriggeredAt => _lastAlarmTriggeredAt;
  DateTime? get lastAlarmDismissedAt => _lastAlarmDismissedAt;

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

      const defaultChannel = AndroidNotificationChannel(
        _defaultChannelId,
        'Arrival Alerts',
        description: 'Alerts when you approach your destination',
        importance: Importance.max,
        playSound: true,
      );

      const forcedAlarmChannel = AndroidNotificationChannel(
        _forcedAlarmChannelId,
        'Arrival Alarm',
        description: 'Loud arrival alarms that play even on vibrate or silent',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('alarm'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(defaultChannel);
      await androidPlugin?.createNotificationChannel(forcedAlarmChannel);

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('AlarmService: initialize failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> playAlarm() async {
    await playApproachAlarm(
      title: 'Destination Reached',
      body: 'You are approaching your destination.',
    );
  }

  Future<void> playApproachAlarm({
    required String title,
    required String body,
  }) async {
    if (_alarmActive) {
      return;
    }

    _alarmActive = true;
    _lastAlarmTriggeredAt = DateTime.now();

    final forceSound = _settingsService.settings.alwaysPlayAlarmSound;

    if (forceSound) {
      await _startForcedAlarmSound();
    } else {
      await _startAlarmSound(forceSound: false);
    }

    await _startVibration();
    await showArrivalNotification(
      title: title,
      body: body,
      forceSound: forceSound,
    );
  }

  Future<void> stopAlarm() async {
    if (!_alarmActive) {
      return;
    }

    _alarmActive = false;
    _lastAlarmDismissedAt = DateTime.now();

    await _audioPlayer.stop();
    await _stopVibration();
    await _notifications.cancel(_arrivalNotificationId);
  }

  Future<void> showArrivalNotification({
    String title = 'Destination Reached',
    String body = 'You are approaching your destination.',
    bool? forceSound,
  }) async {
    try {
      final useForcedSound =
          forceSound ?? _settingsService.settings.alwaysPlayAlarmSound;

      final androidDetails = useForcedSound
          ? AndroidNotificationDetails(
              _forcedAlarmChannelId,
              'Arrival Alarm',
              channelDescription:
                  'Loud arrival alarms that play even on vibrate or silent',
              importance: Importance.max,
              priority: Priority.max,
              ongoing: true,
              autoCancel: false,
              category: AndroidNotificationCategory.alarm,
              playSound: true,
              sound: const RawResourceAndroidNotificationSound('alarm'),
              fullScreenIntent: true,
              visibility: NotificationVisibility.public,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            )
          : const AndroidNotificationDetails(
              _defaultChannelId,
              'Arrival Alerts',
              channelDescription: 'Alerts when you approach your destination',
              importance: Importance.max,
              priority: Priority.high,
              ongoing: true,
              autoCancel: false,
              category: AndroidNotificationCategory.alarm,
              playSound: true,
            );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: useForcedSound,
        interruptionLevel: useForcedSound
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        _arrivalNotificationId,
        title,
        body,
        details,
      );
    } catch (error, stackTrace) {
      debugPrint('AlarmService: failed to show notification: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _startForcedAlarmSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource(_alarmAssetPath));
    } catch (error, stackTrace) {
      debugPrint('AlarmService: failed to play forced alarm sound: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _startAlarmSound({required bool forceSound}) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: forceSound,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType:
                forceSound ? AndroidUsageType.alarm : AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: forceSound
                ? AVAudioSessionCategory.playback
                : AVAudioSessionCategory.ambient,
            options: forceSound
                ? {AVAudioSessionOptions.duckOthers}
                : {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
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
