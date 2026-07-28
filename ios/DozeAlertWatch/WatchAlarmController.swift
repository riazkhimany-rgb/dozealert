import WatchKit

/// Repeating haptic pattern while the phone reports alarmActive.
@MainActor
final class WatchAlarmController {
  static let shared = WatchAlarmController()

  private var timer: Timer?
  private var running = false

  private init() {}

  func start() {
    guard !running else { return }
    running = true
    fire()
    timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.fire()
      }
    }
  }

  func stop() {
    running = false
    timer?.invalidate()
    timer = nil
  }

  private func fire() {
    WKInterfaceDevice.current().play(.notification)
  }
}
