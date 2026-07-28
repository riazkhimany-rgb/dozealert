import SwiftUI

struct TripScreen: View {
  @ObservedObject var store: TripStateStore
  @Environment(\.isLuminanceReduced) private var isLuminanceReduced

  var body: some View {
    Group {
      if isLuminanceReduced {
        ambientContent
      } else {
        activeContent
      }
    }
    .navigationTitle("DozeAlert")
  }

  private var ambientContent: some View {
    VStack(spacing: 8) {
      Text(store.tripState.statusLabel.uppercased())
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(store.tripState.headline)
        .font(.headline.weight(.bold))
        .multilineTextAlignment(.center)
        .lineLimit(2)
      if !store.tripState.subline.isEmpty {
        Text(store.tripState.subline)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var activeContent: some View {
    ScrollView {
      VStack(spacing: 10) {
        connectionRow

        Text(store.tripState.statusLabel)
          .font(.caption.weight(.semibold))
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Capsule().fill(Color.accentColor.opacity(0.2)))

        if store.tripState.showTripConcernBanner {
          Text(store.tripState.tripConcernDetail)
            .font(.caption2)
            .foregroundStyle(.orange)
            .multilineTextAlignment(.center)
        }

        Text(store.tripState.headline)
          .font(.title3.weight(.bold))
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)

        Text(store.tripState.subline)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)

        actions
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    }
  }

  private var connectionRow: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(store.phoneReachable ? Color.green : Color.red)
        .frame(width: 8, height: 8)
      Text(store.phoneReachable ? "Phone connected" : "Phone unreachable")
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var actions: some View {
    if store.tripState.alarmActive {
      Button("Dismiss alarm") {
        store.sendCommand(WatchPaths.cmdDismissAlarm)
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
    }

    if store.tripState.canStart {
      Button("Start trip") {
        store.sendCommand(WatchPaths.cmdStartMonitoring)
      }
      .buttonStyle(.borderedProminent)
    }

    if store.tripState.canStop && !store.tripState.alarmActive {
      Button("Stop trip") {
        store.sendCommand(WatchPaths.cmdStopMonitoring)
      }
      .buttonStyle(.bordered)
    }

    Button("Open on phone") {
      store.sendCommand(WatchPaths.cmdOpenPhone)
    }
    .buttonStyle(.bordered)
  }
}
