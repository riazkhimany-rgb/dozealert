import SwiftUI
import WidgetKit

struct DozeAlertComplicationEntry: TimelineEntry {
  let date: Date
  let state: TripState
}

struct DozeAlertComplicationProvider: TimelineProvider {
  func placeholder(in context: Context) -> DozeAlertComplicationEntry {
    var sample = TripState()
    sample.hasDestination = true
    return DozeAlertComplicationEntry(date: Date(), state: sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (DozeAlertComplicationEntry) -> Void) {
    completion(DozeAlertComplicationEntry(date: Date(), state: TripState.loadFromAppGroup()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DozeAlertComplicationEntry>) -> Void) {
    let entry = DozeAlertComplicationEntry(date: Date(), state: TripState.loadFromAppGroup())
    let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

struct DozeAlertComplicationView: View {
  var entry: DozeAlertComplicationEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular:
        ZStack {
          AccessoryWidgetBackground()
          Text(entry.state.complicationShortText)
            .font(.system(size: 12, weight: .bold))
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.center)
        }
        .widgetAccentable()
      case .accessoryCorner:
        Text(entry.state.complicationShortText)
          .font(.headline.weight(.bold))
          .widgetAccentable()
      case .accessoryRectangular:
        VStack(alignment: .leading, spacing: 2) {
          Text("DozeAlert")
            .font(.caption2.weight(.semibold))
          Text(entry.state.complicationShortText)
            .font(.headline.weight(.bold))
          Text(entry.state.headline)
            .font(.caption2)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      case .accessoryInline:
        Text("DozeAlert · \(entry.state.complicationShortText)")
      default:
        Text(entry.state.complicationShortText)
      }
    }
    .containerBackground(for: .widget) {
      AccessoryWidgetBackground()
    }
  }
}

@main
struct DozeAlertWatchWidgets: WidgetBundle {
  var body: some Widget {
    DozeAlertComplication()
  }
}

struct DozeAlertComplication: Widget {
  let kind = "DozeAlertComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DozeAlertComplicationProvider()) { entry in
      DozeAlertComplicationView(entry: entry)
    }
    .configurationDisplayName("DozeAlert")
    .description("Trip status at a glance.")
    .supportedFamilies([
      .accessoryCircular,
      .accessoryCorner,
      .accessoryRectangular,
      .accessoryInline,
    ])
  }
}
