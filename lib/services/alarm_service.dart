import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../services/settings_service.dart';
import '../services/system_volume_service.dart';
import '../utils/app_log.dart';

class AlarmService {
  AlarmService(this._settingsService, [SystemVolumeService? volumeService])
      : _volumeService = volumeService ?? SystemVolumeService();

  final SettingsService _settingsService;
  final SystemVolumeService _volumeService;

  static const _arrivalNotificationId = 1001;
  static const _alarmAssetPath = 'sounds/alarm.mp3';
  static const _defaultChannelId = 'arrival_alerts';
  static const _forcedAlarmChannelId = 'arrival_alerts_forced';
  static const _approachPhrase = 'Heads up! Approaching destination.';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _alarmActive = false;
  bool _ttsConfigured = false;
  Timer? _ttsRepeatTimer;
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
          AndroidInitializationSettings('@drawable/ic_stat_dozealert');
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
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);

      _initialized = true;
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: initialize failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> playAlarm() async {
    await playApproachAlarm(
      title: 'Approaching Destination',
      body: _approachPhrase,
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
    final volume = _settingsService.settings.alarmVolume;
    final approachSystemVolume =
        _settingsService.settings.approachSystemVolume;

    await _volumeService.applyApproachAlertVolume(
      targetVolume: approachSystemVolume,
    );
    await _startApproachSpeechLoop(volume: volume);
    await _startVibration();

    if (forceSound) {
      await _startForcedAlarmSound(volume: volume);
    }

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

    _ttsRepeatTimer?.cancel();
    _ttsRepeatTimer = null;
    await _tts.stop();
    await _audioPlayer.stop();
    await _stopVibration();
    await _notifications.cancel(_arrivalNotificationId);
    await _volumeService.restoreSavedVolume();
  }

  /// Updates TTS, tone, and temporary system volume while an alert is playing.
  Future<void> updateActiveAlarmVolume() async {
    if (!_alarmActive) {
      return;
    }

    final volume = _settingsService.settings.alarmVolume.clamp(0.0, 1.0);
    final approachSystemVolume =
        _settingsService.settings.approachSystemVolume;

    await _volumeService.applyApproachAlertVolume(
      targetVolume: approachSystemVolume,
    );
    await _tts.setVolume(volume);
    await _audioPlayer.setVolume(volume);
  }

  Future<void> showArrivalNotification({
    String title = 'Approaching Destination',
    String body = _approachPhrase,
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
              playSound: false,
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
      AppLog.d('AlarmService: failed to show notification: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> _configureTts({required double volume}) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
    await _tts.setSpeechRate(0.48);
    await _tts.awaitSpeakCompletion(true);

    if (Platform.isAndroid) {
      await _tts.setQueueMode(1);
    }

    if (Platform.isIOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions
              .interruptSpokenAudioAndMixWithOthers,
        ],
      );
    }

    _ttsConfigured = true;
  }

  Future<void> _startApproachSpeechLoop({required double volume}) async {
    try {
      if (!_ttsConfigured) {
        await _configureTts(volume: volume);
      } else {
        await _tts.setVolume(volume);
      }

      unawaited(_speakApproachOnce(volume: volume));

      _ttsRepeatTimer?.cancel();
      _ttsRepeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_alarmActive) {
          unawaited(_speakApproachOnce());
        }
      });
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: failed to start approach speech: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> _speakApproachOnce({double? volume}) async {
    if (!_alarmActive) {
      return;
    }

    try {
      final effectiveVolume = (volume ?? _settingsService.settings.alarmVolume)
          .clamp(0.0, 1.0);
      await _tts.setVolume(effectiveVolume);
      await _tts.stop();
      await _tts.speak(_approachPhrase);
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: TTS speak failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> _startForcedAlarmSound({required double volume}) async {
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
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(AssetSource(_alarmAssetPath));
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: failed to play forced alarm sound: $error');
      AppLog.d('$stackTrace');
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
      AppLog.d('AlarmService: vibration unavailable: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> _stopVibration() async {
    try {
      await Vibration.cancel();
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: failed to cancel vibration: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> dispose() async {
    await stopAlarm();
    await _audioPlayer.dispose();
  }
}
