import AVFoundation
import CoreLocation
import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  CLLocationManagerDelegate
{
  private var reliabilityChannel: FlutterMethodChannel?
  private var locationManager: CLLocationManager?
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

  private var keepAlivePlayer: AVAudioPlayer?
  private var alarmPlayer: AVAudioPlayer?

  private let approachRegionId = "dozealert.approach"
  private let destinationRegionId = "dozealert.destination"

  private let tripActiveKey = "dozealert.tripActive"
  private let tripDestinationKey = "dozealert.tripDestination"
  private let alarmTitleKey = "dozealert.alarmTitle"
  private let alarmBodyKey = "dozealert.alarmBody"
  private let criticalAlertsKey = "dozealert.criticalAlerts"
  private let nativeWakeFiredKey = "dozealert.nativeWakeFired"

  private let nativeWakeNotificationId = "dozealert.native.wake"
  private let alarmSoundFile = "alarm_notification.wav"
  private let keepAliveSoundFile = "keepalive"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty
    {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "app.dozealert/ios_reliability",
      binaryMessenger: messenger
    )
    reliabilityChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleReliabilityCall(call, result: result)
    }

    let manager = CLLocationManager()
    manager.delegate = self
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    locationManager = manager
  }

  private func handleReliabilityCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "armAudioSession":
      configureAudioSession(duckOthers: false)
      result(nil)
    case "startKeepAlive":
      startKeepAlive()
      result(nil)
    case "stopKeepAlive":
      stopKeepAlive()
      result(nil)
    case "beginBackgroundTask":
      beginBackgroundTask(name: args?["name"] as? String ?? "dozealert.alarm")
      result(nil)
    case "endBackgroundTask":
      endBackgroundTaskInternal()
      result(nil)
    case "setTripInfo":
      setTripInfo(args)
      result(nil)
    case "clearTripInfo":
      clearTripInfo()
      result(nil)
    case "consumeNativeWake":
      let defaults = UserDefaults.standard
      let fired = defaults.bool(forKey: nativeWakeFiredKey)
      defaults.set(false, forKey: nativeWakeFiredKey)
      result(fired)
    case "stopNativeAlarm":
      stopNativeAlarm()
      result(nil)
    case "startGeofences":
      guard let latitude = args?["latitude"] as? Double,
            let longitude = args?["longitude"] as? Double,
            let approachRadius = args?["approachRadiusMeters"] as? Double,
            let destinationRadius = args?["destinationRadiusMeters"] as? Double
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "startGeofences requires lat/lng/radii",
            details: nil
          )
        )
        return
      }
      startGeofences(
        latitude: latitude,
        longitude: longitude,
        approachRadius: approachRadius,
        destinationRadius: destinationRadius
      )
      result(nil)
    case "stopGeofences":
      if let manager = locationManager {
        stopGeofencesInternal(manager: manager)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Audio

  /// Playback category ignores the Ring/Silent switch, which is the only way an
  /// alarm stays audible for riders who travel with the switch on.
  private func configureAudioSession(duckOthers: Bool) {
    do {
      let session = AVAudioSession.sharedInstance()
      // defaultToSpeaker / allowBluetooth are playAndRecord-only and would
      // make this call throw, leaving the session unconfigured and silent.
      let options: AVAudioSession.CategoryOptions =
        duckOthers ? [.duckOthers] : [.mixWithOthers]
      try session.setCategory(.playback, mode: .default, options: options)
      try session.setActive(true, options: [])
    } catch {
      NSLog("DozeAlert audio session failed: \(error.localizedDescription)")
    }
  }

  /// Near-silent looping track so the process (and the Dart trip evaluation)
  /// keeps running while the phone is locked.
  private func startKeepAlive() {
    if keepAlivePlayer?.isPlaying == true {
      return
    }

    configureAudioSession(duckOthers: false)

    guard let url = Bundle.main.url(forResource: keepAliveSoundFile, withExtension: "wav")
    else {
      NSLog("DozeAlert keepalive asset missing")
      return
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.numberOfLoops = -1
      player.volume = 0.02
      player.prepareToPlay()
      player.play()
      keepAlivePlayer = player
    } catch {
      NSLog("DozeAlert keepalive failed: \(error.localizedDescription)")
    }
  }

  private func stopKeepAlive() {
    keepAlivePlayer?.stop()
    keepAlivePlayer = nil

    if alarmPlayer == nil {
      try? AVAudioSession.sharedInstance().setActive(
        false,
        options: [.notifyOthersOnDeactivation]
      )
    }
  }

  private func startNativeAlarm() {
    configureAudioSession(duckOthers: true)

    guard let url = Bundle.main.url(forResource: "alarm_notification", withExtension: "wav")
    else {
      NSLog("DozeAlert alarm asset missing")
      return
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.numberOfLoops = -1
      player.volume = 1.0
      player.prepareToPlay()
      player.play()
      alarmPlayer = player
    } catch {
      NSLog("DozeAlert native alarm failed: \(error.localizedDescription)")
    }
  }

  /// Dart takes over the alarm once it runs again; drop the native tone and
  /// its notification so the rider does not get two of each.
  private func stopNativeAlarm() {
    alarmPlayer?.stop()
    alarmPlayer = nil

    let center = UNUserNotificationCenter.current()
    center.removeDeliveredNotifications(withIdentifiers: [nativeWakeNotificationId])
    center.removePendingNotificationRequests(withIdentifiers: [nativeWakeNotificationId])
  }

  // MARK: - Trip info

  private func setTripInfo(_ args: [String: Any]?) {
    let defaults = UserDefaults.standard
    defaults.set(true, forKey: tripActiveKey)
    // Only a fresh trip clears the flag; periodic copy refreshes must not
    // discard a wake that Dart has not consumed yet.
    if args?["resetWake"] as? Bool ?? false {
      defaults.set(false, forKey: nativeWakeFiredKey)
    }
    defaults.set(args?["destinationName"] as? String ?? "your stop", forKey: tripDestinationKey)
    defaults.set(args?["alarmTitle"] as? String ?? "Time to get off", forKey: alarmTitleKey)
    defaults.set(args?["alarmBody"] as? String ?? "You are arriving.", forKey: alarmBodyKey)
    defaults.set(args?["criticalAlerts"] as? Bool ?? false, forKey: criticalAlertsKey)
  }

  private func clearTripInfo() {
    let defaults = UserDefaults.standard
    defaults.set(false, forKey: tripActiveKey)
    defaults.set(false, forKey: nativeWakeFiredKey)
  }

  // MARK: - Background task

  private func beginBackgroundTask(name: String) {
    endBackgroundTaskInternal()
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: name) {
      [weak self] in
      self?.endBackgroundTaskInternal()
    }
  }

  private func endBackgroundTaskInternal() {
    guard backgroundTaskId != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
    backgroundTaskId = .invalid
  }

  // MARK: - Geofencing

  private func startGeofences(
    latitude: Double,
    longitude: Double,
    approachRadius: Double,
    destinationRadius: Double
  ) {
    guard let manager = locationManager else {
      return
    }

    stopGeofencesInternal(manager: manager)

    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let maxRadius = manager.maximumRegionMonitoringDistance
    let approach = CLCircularRegion(
      center: center,
      radius: min(approachRadius, maxRadius),
      identifier: approachRegionId
    )
    approach.notifyOnEntry = true
    approach.notifyOnExit = false

    let destination = CLCircularRegion(
      center: center,
      radius: min(min(destinationRadius, approachRadius), maxRadius),
      identifier: destinationRegionId
    )
    destination.notifyOnEntry = true
    destination.notifyOnExit = false

    manager.startMonitoring(for: approach)
    manager.startMonitoring(for: destination)
    manager.requestState(for: approach)
    manager.requestState(for: destination)
  }

  private func stopGeofencesInternal(manager: CLLocationManager) {
    for region in manager.monitoredRegions
    where region.identifier == approachRegionId || region.identifier == destinationRegionId {
      manager.stopMonitoring(for: region)
    }
  }

  // MARK: - Native wake

  /// Fires the wake without a round trip to Dart, which may be suspended while
  /// the phone is locked. Dart adopts the alarm when it next runs.
  private func handleRegionEntered(_ identifier: String) {
    reliabilityChannel?.invokeMethod("onRegionEntered", arguments: identifier)

    guard identifier == destinationRegionId else {
      return
    }

    let defaults = UserDefaults.standard
    guard defaults.bool(forKey: tripActiveKey),
          !defaults.bool(forKey: nativeWakeFiredKey)
    else {
      return
    }

    defaults.set(true, forKey: nativeWakeFiredKey)

    postNativeWakeNotification(
      title: defaults.string(forKey: alarmTitleKey) ?? "Time to get off",
      body: defaults.string(forKey: alarmBodyKey) ?? "You are arriving.",
      critical: defaults.bool(forKey: criticalAlertsKey)
    )
    startNativeAlarm()
  }

  private func postNativeWakeNotification(title: String, body: String, critical: Bool) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.threadIdentifier = "dozealert-arrival"

    if critical {
      content.sound = UNNotificationSound.criticalSoundNamed(
        UNNotificationSoundName(alarmSoundFile),
        withAudioVolume: 1.0
      )
      content.interruptionLevel = .critical
    } else {
      content.sound = UNNotificationSound(
        named: UNNotificationSoundName(alarmSoundFile)
      )
      content.interruptionLevel = .timeSensitive
    }

    let request = UNNotificationRequest(
      identifier: nativeWakeNotificationId,
      content: content,
      trigger: nil
    )
    UNUserNotificationCenter.current().add(request) { error in
      if let error {
        NSLog("DozeAlert native wake notification failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion
  ) {
    handleRegionEntered(region.identifier)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  ) {
    if state == .inside {
      handleRegionEntered(region.identifier)
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    monitoringDidFailFor region: CLRegion?,
    withError error: Error
  ) {
    NSLog(
      "DozeAlert geofence failed for \(region?.identifier ?? "?"): \(error.localizedDescription)"
    )
  }
}
