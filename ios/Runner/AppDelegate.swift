import AVFoundation
import CoreLocation
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate,
  CLLocationManagerDelegate
{
  private var reliabilityChannel: FlutterMethodChannel?
  private var locationManager: CLLocationManager?
  private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

  private let approachRegionId = "dozealert.approach"
  private let destinationRegionId = "dozealert.destination"

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
    switch call.method {
    case "armAudioSession":
      armAudioSession(result: result)
    case "beginBackgroundTask":
      let name =
        (call.arguments as? [String: Any])?["name"] as? String ?? "dozealert.alarm"
      beginBackgroundTask(name: name, result: result)
    case "endBackgroundTask":
      endBackgroundTask(result: result)
    case "startGeofences":
      guard let args = call.arguments as? [String: Any],
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double,
            let approachRadius = args["approachRadiusMeters"] as? Double,
            let destinationRadius = args["destinationRadiusMeters"] as? Double
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
        destinationRadius: destinationRadius,
        result: result
      )
    case "stopGeofences":
      stopGeofences(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func armAudioSession(result: @escaping FlutterResult) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playback,
        mode: .default,
        options: [.duckOthers, .defaultToSpeaker]
      )
      try session.setActive(true, options: [])
      result(nil)
    } catch {
      result(
        FlutterError(
          code: "audio_session",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func beginBackgroundTask(name: String, result: @escaping FlutterResult) {
    endBackgroundTaskInternal()
    backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: name) {
      [weak self] in
      self?.endBackgroundTaskInternal()
    }
    result(nil)
  }

  private func endBackgroundTask(result: @escaping FlutterResult) {
    endBackgroundTaskInternal()
    result(nil)
  }

  private func endBackgroundTaskInternal() {
    guard backgroundTaskId != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTaskId)
    backgroundTaskId = .invalid
  }

  private func startGeofences(
    latitude: Double,
    longitude: Double,
    approachRadius: Double,
    destinationRadius: Double,
    result: @escaping FlutterResult
  ) {
    guard let manager = locationManager else {
      result(
        FlutterError(
          code: "no_manager",
          message: "CLLocationManager not ready",
          details: nil
        )
      )
      return
    }

    stopGeofencesInternal(manager: manager)

    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let approach = CLCircularRegion(
      center: center,
      radius: approachRadius,
      identifier: approachRegionId
    )
    approach.notifyOnEntry = true
    approach.notifyOnExit = false

    let destination = CLCircularRegion(
      center: center,
      radius: min(destinationRadius, approachRadius),
      identifier: destinationRegionId
    )
    destination.notifyOnEntry = true
    destination.notifyOnExit = false

    manager.startMonitoring(for: approach)
    manager.startMonitoring(for: destination)
    // Ask for an immediate state check if already inside.
    manager.requestState(for: approach)
    manager.requestState(for: destination)
    result(nil)
  }

  private func stopGeofences(result: @escaping FlutterResult) {
    if let manager = locationManager {
      stopGeofencesInternal(manager: manager)
    }
    result(nil)
  }

  private func stopGeofencesInternal(manager: CLLocationManager) {
    for region in manager.monitoredRegions {
      if region.identifier == approachRegionId
        || region.identifier == destinationRegionId
      {
        manager.stopMonitoring(for: region)
      }
    }
  }

  private func notifyRegionEntered(_ identifier: String) {
    reliabilityChannel?.invokeMethod("onRegionEntered", arguments: identifier)
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(
    _ manager: CLLocationManager,
    didEnterRegion region: CLRegion
  ) {
    notifyRegionEntered(region.identifier)
  }

  func locationManager(
    _ manager: CLLocationManager,
    didDetermineState state: CLRegionState,
    for region: CLRegion
  ) {
    if state == .inside {
      notifyRegionEntered(region.identifier)
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
