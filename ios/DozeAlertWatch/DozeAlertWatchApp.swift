import SwiftUI

@main
struct DozeAlertWatchApp: App {
  @StateObject private var store = TripStateStore.shared

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        TripScreen(store: store)
          .navigationDestination(isPresented: $store.shouldPresentAlarm) {
            AlarmScreen(store: store)
          }
      }
      .onChange(of: store.shouldOpenFromPhone) { _, open in
        if open {
          store.shouldOpenFromPhone = false
        }
      }
      .onChange(of: store.tripState.alarmActive) { _, active in
        if active {
          store.shouldPresentAlarm = true
        }
      }
    }
  }
}
