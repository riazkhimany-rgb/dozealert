import Flutter
import UIKit
import WatchConnectivity
import WidgetKit

/// Phone-side WatchConnectivity bridge for the DozeAlert Apple Watch companion.
/// Mirrors Android WearBridge / WearSyncManager over WCSession.
final class WatchConnectivityBridge: NSObject, WCSessionDelegate {
  static let shared = WatchConnectivityBridge()

  static let methodChannelName = "app.dozealert/watch"
  static let commandsEventChannelName = "app.dozealert/watch_commands"
  static let connectionEventChannelName = "app.dozealert/watch_connection"

  static let cmdStartMonitoring = "/cmd/start_monitoring"
  static let cmdStopMonitoring = "/cmd/stop_monitoring"
  static let cmdDismissAlarm = "/cmd/dismiss_alarm"
  static let cmdOpenPhone = "/cmd/open_phone"
  static let cmdOpenWatch = "/cmd/open_watch"

  static let appGroupId = "group.app.dozealert"
  static let tripStateDefaultsKey = "dozealert.watch.tripState"

  private var methodChannel: FlutterMethodChannel?
  private var commandEventSink: FlutterEventSink?
  private var connectionEventSink: FlutterEventSink?
  private var pendingCommand: String?

  private override init() {
    super.init()
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let method = FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    )
    methodChannel = method
    method.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }

    let commands = FlutterEventChannel(
      name: Self.commandsEventChannelName,
      binaryMessenger: messenger
    )
    commands.setStreamHandler(WatchCommandStreamHandler { [weak self] sink in
      self?.commandEventSink = sink
    })

    let connection = FlutterEventChannel(
      name: Self.connectionEventChannelName,
      binaryMessenger: messenger
    )
    connection.setStreamHandler(WatchCommandStreamHandler { [weak self] sink in
      self?.connectionEventSink = sink
      self?.emitConnectionChanged()
    })

    activateSession()
  }

  private func activateSession() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pushTripState":
      guard let payload = call.arguments as? [String: Any] else {
        result(
          FlutterError(code: "bad_args", message: "pushTripState expects a map", details: nil)
        )
        return
      }
      pushTripState(payload)
      result(nil)
    case "launchWatchApp":
      launchWatchApp()
      result(nil)
    case "watchAppStatus":
      result(watchAppStatus())
    case "consumePendingWatchCommand":
      let command = pendingCommand
      pendingCommand = nil
      result(command)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pushTripState(_ payload: [String: Any]) {
    var context = payload
    context["updatedAt"] = Int64(Date().timeIntervalSince1970 * 1000)

    persistForComplications(context)

    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated else { return }

    do {
      try session.updateApplicationContext(context)
    } catch {
      NSLog("DozeAlert WatchConnectivity updateApplicationContext failed: \(error)")
    }

    if session.isReachable {
      session.sendMessage(
        ["path": "/trip_state", "payload": context],
        replyHandler: nil,
        errorHandler: { error in
          NSLog("DozeAlert WatchConnectivity sendMessage trip_state failed: \(error)")
        }
      )
    } else {
      session.transferUserInfo(["path": "/trip_state", "payload": context])
    }
  }

  private func persistForComplications(_ context: [String: Any]) {
    let defaults = UserDefaults(suiteName: Self.appGroupId) ?? UserDefaults.standard
    defaults.set(context, forKey: Self.tripStateDefaultsKey)
    defaults.synchronize()
    WidgetCenter.shared.reloadAllTimelines()
  }

  private func launchWatchApp() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    guard session.activationState == .activated else { return }

    let message: [String: Any] = ["path": Self.cmdOpenWatch]
    if session.isReachable {
      session.sendMessage(message, replyHandler: nil) { error in
        NSLog("DozeAlert WatchConnectivity open_watch failed: \(error)")
      }
    } else {
      session.transferUserInfo(message)
    }
  }

  private func watchAppStatus() -> [String: Any] {
    guard WCSession.isSupported() else {
      return ["installed": false, "connected": false]
    }
    let session = WCSession.default
    let installed = session.isWatchAppInstalled
    let connected = installed && session.isReachable
    return ["installed": installed, "connected": connected]
  }

  private func emitConnectionChanged() {
    connectionEventSink?("changed")
  }

  private func deliverCommand(_ path: String) {
    // Mirror WearBridge: bring the phone app forward when the watch asks.
    openPhoneApp()

    if path == Self.cmdOpenPhone {
      return
    }

    if let sink = commandEventSink {
      sink(path)
    } else {
      pendingCommand = path
    }
  }

  private func openPhoneApp() {
    DispatchQueue.main.async {
      for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        for window in windowScene.windows {
          window.makeKeyAndVisible()
        }
      }
    }
  }

  private func handleIncomingMessage(_ message: [String: Any]) {
    guard let path = message["path"] as? String else { return }
    if path == "/trip_state" {
      return
    }
    deliverCommand(path)
  }

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    if let error {
      NSLog("DozeAlert WatchConnectivity activation error: \(error)")
    }
    emitConnectionChanged()
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    emitConnectionChanged()
  }

  func sessionDidDeactivate(_ session: WCSession) {
    emitConnectionChanged()
    session.activate()
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    emitConnectionChanged()
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    emitConnectionChanged()
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    handleIncomingMessage(message)
  }

  func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    handleIncomingMessage(message)
    replyHandler(["ok": true])
  }

  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    handleIncomingMessage(userInfo)
  }

  func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {}
}

private final class WatchCommandStreamHandler: NSObject, FlutterStreamHandler {
  private let onListen: (FlutterEventSink?) -> Void

  init(onListen: @escaping (FlutterEventSink?) -> Void) {
    self.onListen = onListen
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    onListen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onListen(nil)
    return nil
  }
}
