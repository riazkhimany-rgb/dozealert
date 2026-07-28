import Foundation
import WatchConnectivity
import WidgetKit

enum WatchPaths {
  static let tripState = "/trip_state"
  static let cmdStartMonitoring = "/cmd/start_monitoring"
  static let cmdStopMonitoring = "/cmd/stop_monitoring"
  static let cmdDismissAlarm = "/cmd/dismiss_alarm"
  static let cmdOpenPhone = "/cmd/open_phone"
  static let cmdOpenWatch = "/cmd/open_watch"
}

@MainActor
final class TripStateStore: NSObject, ObservableObject {
  static let shared = TripStateStore()

  @Published private(set) var tripState = TripState()
  @Published private(set) var phoneReachable = false
  @Published var shouldPresentAlarm = false
  @Published var shouldOpenFromPhone = false

  private var session: WCSession?

  private override init() {
    super.init()
    tripState = TripState.loadFromAppGroup()
    activateSession()
  }

  func activateSession() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
    self.session = session
  }

  func sendCommand(_ path: String) {
    guard let session, session.activationState == .activated else { return }
    let message: [String: Any] = ["path": path]
    if session.isReachable {
      session.sendMessage(message, replyHandler: nil) { error in
        NSLog("DozeAlert Watch sendCommand failed: \(error)")
      }
    } else {
      session.transferUserInfo(message)
    }
  }

  func applyTripState(_ state: TripState) {
    let wasAlarm = tripState.alarmActive
    tripState = state
    state.saveToAppGroup()
    WidgetCenter.shared.reloadAllTimelines()

    if state.alarmActive && !wasAlarm {
      shouldPresentAlarm = true
      WatchAlarmController.shared.start()
    } else if !state.alarmActive {
      shouldPresentAlarm = false
      WatchAlarmController.shared.stop()
    }

    phoneReachable = session?.isReachable ?? false
  }

  private func ingest(dictionary: [String: Any]) {
    applyTripState(TripState.from(dictionary: dictionary))
  }

  private func handleMessage(_ message: [String: Any]) {
    if let path = message["path"] as? String {
      if path == WatchPaths.cmdOpenWatch {
        shouldOpenFromPhone = true
        return
      }
      if path == WatchPaths.tripState, let payload = message["payload"] as? [String: Any] {
        ingest(dictionary: payload)
        return
      }
    }
    // Application-context style maps have no path wrapper.
    if message["state"] != nil || message["destinationName"] != nil {
      ingest(dictionary: message)
    }
  }
}

extension TripStateStore: WCSessionDelegate {
  nonisolated func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    Task { @MainActor in
      self.phoneReachable = session.isReachable
      let context = session.receivedApplicationContext
      if !context.isEmpty {
        self.ingest(dictionary: context)
      }
    }
  }

  nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
    Task { @MainActor in
      self.phoneReachable = session.isReachable
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveApplicationContext applicationContext: [String: Any]
  ) {
    Task { @MainActor in
      self.ingest(dictionary: applicationContext)
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    Task { @MainActor in
      self.handleMessage(message)
    }
  }

  nonisolated func session(
    _ session: WCSession,
    didReceiveMessage message: [String: Any],
    replyHandler: @escaping ([String: Any]) -> Void
  ) {
    Task { @MainActor in
      self.handleMessage(message)
      replyHandler(["ok": true])
    }
  }

  nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
    Task { @MainActor in
      self.handleMessage(userInfo)
    }
  }

  #if os(iOS)
  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
  #endif
}
