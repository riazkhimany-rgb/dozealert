import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

import '../services/ios_locked_reliability_service.dart';
import '../services/settings_service.dart';
import '../utils/transit_wake_message.dart';
import '../models/app_settings.dart';
import '../services/system_volume_service.dart';
import '../utils/app_log.dart';
import '../utils/trip_ux_copy.dart';

class AlarmService {
  AlarmService(
    this._settingsService, [
    SystemVolumeService? volumeService,
    IosLockedReliabilityService? iosReliability,
  ])  : _volumeService = volumeService ?? SystemVolumeService(),
        _iosReliability = iosReliability ?? IosLockedReliabilityService();

  final SettingsService _settingsService;
  final SystemVolumeService _volumeService;
  final IosLockedReliabilityService _iosReliability;

  static const _arrivalNotificationId = 1001;
  static const _tripHeartbeatNotificationId = 1002;
  static const _preAlertNotificationId = 1003;
  static const _alarmAssetPath = 'sounds/alarm.mp3';
  /// Bundled in ios/Runner (Copy Bundle Resources) for UNNotificationSound.
  static const _iosNotificationSound = 'alarm_notification.wav';
  static const _defaultChannelId = 'arrival_alerts';
  static const _forcedAlarmChannelId = 'arrival_alerts_forced';
  static const _approachPhrase = AlarmTtsCopy.defaultApproaching;
  static const _pauseBetweenTtsRepeats = Duration(milliseconds: 1500);
  static const _heartbeatMinInterval = Duration(seconds: 45);

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _alarmActive = false;
  bool _ttsConfigured = false;
  String _activeTtsPhrase = _approachPhrase;
  int _ttsLoopGeneration = 0;
  DateTime? _lastAlarmTriggeredAt;
  DateTime? _lastAlarmDismissedAt;
  DateTime? _lastHeartbeatAt;
  String? _lastHeartbeatDetail;
  Timer? _backgroundTaskEndTimer;

  IosLockedReliabilityService get iosReliability => _iosReliability;

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
      // Defer the iOS permission prompt until trip start / onboarding.
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      );
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

  /// Requests iOS alert/sound/badge permission (no-op on other platforms).
  ///
  /// Does not block trip start if denied — TTS/audio may still work while
  /// foregrounded. Silent Mode still limits notification sounds without
  /// Critical Alerts (not requested).
  Future<bool> ensureNotificationPermission() async {
    if (!Platform.isIOS) {
      return true;
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: iOS notification permission failed: $error');
      AppLog.d('$stackTrace');
      return false;
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
    String? ttsPhrase,
  }) async {
    if (_alarmActive) {
      return;
    }

    _alarmActive = true;
    _lastAlarmTriggeredAt = DateTime.now();
    _activeTtsPhrase = ttsPhrase ?? _approachPhrase;

    final forceSound = _settingsService.settings.alwaysPlayAlarmSound;
    // iOS background/locked: TTS and vibration often fail; always start the
    // looping alarm asset so UIBackgroundModes audio can keep the wake audible.
    final playForcedTone = forceSound || Platform.isIOS;
    final volume = _settingsService.settings.alarmVolume;
    final approachSystemVolume =
        _settingsService.settings.approachSystemVolume;

    if (Platform.isIOS) {
      await _iosReliability.beginBackgroundTask(name: 'dozealert.alarm');
      _scheduleBackgroundTaskEnd();
    }

    // Notification first — works while suspended if Core Location woke us.
    await showArrivalNotification(
      title: title,
      body: body,
      forceSound: playForcedTone,
    );

    await _volumeService.applyApproachAlertVolume(
      targetVolume: approachSystemVolume,
    );

    if (playForcedTone) {
      await _startForcedAlarmSound(volume: volume);
    }

    await _startVibration();
    await _startApproachSpeechLoop(volume: volume);
  }

  void _scheduleBackgroundTaskEnd() {
    _backgroundTaskEndTimer?.cancel();
    // Keep the wake long enough to start looping audio; system may still
    // reclaim sooner. Cleared early in [stopAlarm].
    _backgroundTaskEndTimer = Timer(const Duration(seconds: 28), () {
      unawaited(_iosReliability.endBackgroundTask());
    });
  }

  /// Restarts tone / TTS / vibration after the app returns to the foreground.
  ///
  /// iOS often suppresses Flutter audio while locked; unlocking with an active
  /// alarm must re-engage outputs or the wake screen stays silent.
  Future<void> reinforceAlarmIfActive() async {
    if (!_alarmActive) {
      return;
    }

    final forceSound = _settingsService.settings.alwaysPlayAlarmSound;
    final playForcedTone = forceSound || Platform.isIOS;
    final volume = _settingsService.settings.alarmVolume;
    final approachSystemVolume =
        _settingsService.settings.approachSystemVolume;

    AppLog.d('AlarmService: reinforcing active alarm outputs');

    await showArrivalNotification(
      title: 'Approaching Destination',
      body: _activeTtsPhrase,
      forceSound: playForcedTone,
    );
    await _volumeService.applyApproachAlertVolume(
      targetVolume: approachSystemVolume,
    );

    if (playForcedTone) {
      await _startForcedAlarmSound(volume: volume);
    }

    await _stopVibration();
    await _startVibration();
    await _startApproachSpeechLoop(volume: volume);
  }

  Future<void> stopAlarm() async {
    if (!_alarmActive) {
      return;
    }

    _alarmActive = false;
    _lastAlarmDismissedAt = DateTime.now();
    _activeTtsPhrase = _approachPhrase;

    _ttsLoopGeneration++;
    await _tts.stop();
    await _audioPlayer.stop();
    await _stopVibration();
    await _notifications.cancel(_arrivalNotificationId);
    await _notifications.cancel(_preAlertNotificationId);
    await _volumeService.restoreSavedVolume();
    _backgroundTaskEndTimer?.cancel();
    _backgroundTaskEndTimer = null;
    await _iosReliability.endBackgroundTask();
  }

  /// Quiet replaceable “watching trip” notification (iOS locked observability).
  Future<void> updateTripHeartbeatNotification({
    required String destinationName,
    required String statusDetail,
    bool force = false,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastHeartbeatDetail == statusDetail &&
        _lastHeartbeatAt != null &&
        now.difference(_lastHeartbeatAt!) < _heartbeatMinInterval) {
      return;
    }

    _lastHeartbeatAt = now;
    _lastHeartbeatDetail = statusDetail;

    try {
      if (!_initialized) {
        await initialize();
      }

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentBanner: true,
        presentList: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
        threadIdentifier: 'dozealert-trip',
      );

      await _notifications.show(
        _tripHeartbeatNotificationId,
        'DozeAlert',
        TripUxCopy.notificationTripStatus(
          destinationName: destinationName,
          statusDetail: statusDetail,
        ),
        const NotificationDetails(iOS: iosDetails),
      );
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: heartbeat notification failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> clearTripHeartbeatNotification() async {
    if (!Platform.isIOS) {
      return;
    }
    _lastHeartbeatAt = null;
    _lastHeartbeatDetail = null;
    try {
      await _notifications.cancel(_tripHeartbeatNotificationId);
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: clear heartbeat failed: $error');
      AppLog.d('$stackTrace');
    }
  }

  /// One-shot “getting close” alert before the main wake (iOS locked backup).
  Future<void> showPreAlertNotification({
    required String title,
    required String body,
  }) async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      if (!_initialized) {
        await initialize();
      }

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        sound: _iosNotificationSound,
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'dozealert-prealert',
      );

      await _notifications.show(
        _preAlertNotificationId,
        title,
        body,
        const NotificationDetails(iOS: iosDetails),
      );
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: pre-alert notification failed: $error');
      AppLog.d('$stackTrace');
    }
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

  /// Restarts vibration while an alert is playing (e.g. after slider change).
  Future<void> updateActiveAlarmVibration() async {
    if (!_alarmActive) {
      return;
    }

    await _stopVibration();
    await _startVibration();
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
        presentBanner: true,
        presentList: true,
        // Custom bundled tone so locked wakes stay audible when Flutter
        // audio cannot start; falls back if the file is missing.
        presentSound: true,
        sound: _iosNotificationSound,
        // timeSensitive breaks through Focus better than active; Critical
        // Alerts need a special Apple entitlement (deferred).
        interruptionLevel: InterruptionLevel.timeSensitive,
        threadIdentifier: 'dozealert-arrival',
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
      await _tts.setQueueMode(0);
    }

    if (Platform.isIOS) {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions
              .interruptSpokenAudioAndMixWithOthers,
          // Helps keep speaking if the screen locks mid-alert.
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
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

      final generation = ++_ttsLoopGeneration;
      unawaited(_runApproachSpeechLoop(volume: volume, generation: generation));
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: failed to start approach speech: $error');
      AppLog.d('$stackTrace');
    }
  }

  Future<void> _runApproachSpeechLoop({
    required double volume,
    required int generation,
  }) async {
    while (_alarmActive && generation == _ttsLoopGeneration) {
      final spoke = await _speakApproachOnce(
        volume: volume,
        generation: generation,
      );
      if (!spoke || !_alarmActive || generation != _ttsLoopGeneration) {
        return;
      }
      await Future<void>.delayed(_pauseBetweenTtsRepeats);
    }
  }

  Future<bool> _speakApproachOnce({
    required double volume,
    required int generation,
  }) async {
    if (!_alarmActive || generation != _ttsLoopGeneration) {
      return false;
    }

    try {
      final effectiveVolume = volume.clamp(0.0, 1.0);
      await _tts.setVolume(effectiveVolume);
      return await _speakPhraseAndWait(
        _activeTtsPhrase,
        generation: generation,
        volume: effectiveVolume,
      );
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: TTS speak failed: $error');
      AppLog.d('$stackTrace');
      return false;
    }
  }

  Future<bool> _speakPhraseAndWait(
    String phrase, {
    required int generation,
    required double volume,
  }) async {
    if (!_alarmActive || generation != _ttsLoopGeneration) {
      return false;
    }

    final completer = Completer<void>();
    void completeOnce() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    _tts.setCompletionHandler(completeOnce);
    _tts.setErrorHandler((message) {
      AppLog.d('AlarmService: TTS error: $message');
      completeOnce();
    });

    try {
      await _tts.speak(phrase);
      await completer.future.timeout(
        _estimatedTtsDuration(phrase),
        onTimeout: () {
          AppLog.d(
            'AlarmService: TTS completion timeout (${phrase.length} chars)',
          );
        },
      );
      return _alarmActive && generation == _ttsLoopGeneration;
    } catch (error, stackTrace) {
      AppLog.d('AlarmService: TTS wait failed: $error');
      AppLog.d('$stackTrace');
      return false;
    } finally {
      _tts.setCompletionHandler(() {});
      _tts.setErrorHandler((message) {});
    }
  }

  Duration _estimatedTtsDuration(String phrase) {
    // Speech rate 0.48 — allow roughly 100ms per character, min 4s for short lines.
    return Duration(
      milliseconds: (phrase.length * 100).clamp(4000, 35000),
    );
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
            // playback ignores the Ring/Silent switch (ambient would not).
            // Combined with Info.plist UIBackgroundModes=audio so a locked
            // iPhone can keep the looping tone alive after a location wake.
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
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

      final intensity = AppSettings.clampVibrationIntensity(
        _settingsService.settings.vibrationIntensity,
      );
      final amplitude = (intensity * 255).round().clamp(1, 255);

      final hasAmplitudeControl = await Vibration.hasAmplitudeControl();
      if (hasAmplitudeControl == true) {
        await Vibration.vibrate(
          pattern: [500, 500],
          intensities: [amplitude, 0],
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
    await clearTripHeartbeatNotification();
    await _iosReliability.dispose();
    await _audioPlayer.dispose();
  }
}
