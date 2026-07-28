import SwiftUI

struct AlarmScreen: View {
  @ObservedObject var store: TripStateStore

  var body: some View {
    VStack(spacing: 12) {
      Text(store.tripState.alarmUiHeadline.isEmpty ? "GET READY" : store.tripState.alarmUiHeadline)
        .font(.title3.weight(.bold))
        .multilineTextAlignment(.center)

      Text(store.tripState.alarmPrimaryStopName)
        .font(.headline)
        .multilineTextAlignment(.center)

      Text("is your stop")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text(store.tripState.alarmContextLine)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)

      Button("Dismiss") {
        store.sendCommand(WatchPaths.cmdDismissAlarm)
        store.shouldPresentAlarm = false
        WatchAlarmController.shared.stop()
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
    }
    .padding()
    .onAppear {
      WatchAlarmController.shared.start()
    }
    .onDisappear {
      if !store.tripState.alarmActive {
        WatchAlarmController.shared.stop()
      }
    }
  }
}
