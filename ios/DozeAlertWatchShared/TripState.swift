import Foundation

/// Shared trip-state model for Watch app + complications (mirrors Wear TripState).
struct TripState: Equatable, Codable {
  var state: String = "idle"
  var destinationName: String = ""
  var distanceKm: Double = 0
  var distanceReady: Bool = false
  var stopsRemaining: Int = -1
  var transitActive: Bool = false
  var lineLabel: String = ""
  var tripConcern: String = ""
  var gpsStale: Bool = false
  var directionLabel: String = ""
  var nextStopName: String = ""
  var wakeStopCount: Int = -1
  var alarmActive: Bool = false
  var hasDestination: Bool = false
  var alarmStopName: String = ""
  var alarmHeadline: String = ""
  var alarmUiHeadline: String = ""
  var alarmSubline: String = ""
  var updatedAt: Int64 = 0

  static let appGroupId = "group.app.dozealert"
  static let defaultsKey = "dozealert.watch.tripState"

  var isMonitoring: Bool { state == "monitoring" }

  var hasTripConcern: Bool { !tripConcern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

  var showTripConcernBanner: Bool { isMonitoring && hasTripConcern && !alarmActive }

  var canStart: Bool { hasDestination && state == "idle" }

  var canStop: Bool { isMonitoring || state == "arrived" || alarmActive }

  enum StatusKind {
    case idle, ready, monitoring, alarm, arrived, missed
  }

  var statusKind: StatusKind {
    if alarmActive { return .alarm }
    if state == "arrived" { return .arrived }
    if state == "missed" { return .missed }
    if isMonitoring { return .monitoring }
    if hasDestination { return .ready }
    return .idle
  }

  var statusLabel: String {
    switch statusKind {
    case .alarm: return "Alarm"
    case .arrived: return "Arrived"
    case .missed: return "Missed"
    case .monitoring: return "Watching"
    case .ready: return "Ready"
    case .idle: return "Idle"
    }
  }

  var headline: String {
    if alarmActive {
      return alarmUiHeadline.isEmpty ? "GET READY" : alarmUiHeadline
    }
    if !hasDestination { return "Set up on phone" }
    if isMonitoring && hasTripConcern && tripConcern == "wrong_direction" {
      return "Wrong direction?"
    }
    if isMonitoring && hasTripConcern { return "Trip check needed" }
    if isMonitoring && gpsStale { return "GPS signal weak" }
    if isMonitoring && transitActive && stopsRemaining >= 0 {
      switch stopsRemaining {
      case 0: return "At destination stop"
      case 1: return "1 stop to go"
      default: return "\(stopsRemaining) stops to go"
      }
    }
    if isMonitoring && distanceReady {
      return String(format: "%.1f km left", distanceKm)
    }
    if isMonitoring { return "Watching your trip" }
    if state == "arrived" { return "You've arrived" }
    if state == "missed" { return "Trip missed" }
    if hasDestination {
      if !destinationName.isEmpty { return destinationName }
      if !lineLabel.isEmpty { return lineLabel }
      return "Your trip"
    }
    return "Set up on phone"
  }

  var alarmPrimaryStopName: String {
    alarmStopName.isEmpty ? destinationName : alarmStopName
  }

  var alarmContextLine: String {
    let synced = alarmSubline.trimmingCharacters(in: .whitespacesAndNewlines)
    if !synced.isEmpty { return synced }
    if wakeStopCount > 0 && stopsRemaining >= 0 {
      let capped = min(stopsRemaining, wakeStopCount)
      switch capped {
      case 0: return "Time to get off"
      case 1: return "1 more stop to go"
      default: return "\(capped) more stops to go"
      }
    }
    return "Within alert distance"
  }

  var tripConcernDetail: String {
    tripConcern == "wrong_direction"
      ? "Check line & direction on phone."
      : "Check your line and direction on phone."
  }

  var subline: String {
    if alarmActive { return alarmContextLine }
    if !hasDestination { return "Pick a destination on phone" }
    if isMonitoring && transitActive { return buildMonitoringSubline() }
    if isMonitoring && !distanceReady {
      return destinationName.isEmpty ? "Waiting for GPS…" : destinationName
    }
    if isMonitoring {
      return destinationName.isEmpty ? "Trip in progress" : destinationName
    }
    if hasDestination && !isMonitoring && state != "arrived" && state != "missed" {
      if !lineLabel.isEmpty { return lineLabel }
      return "Tap Start when on board"
    }
    if hasDestination {
      if !destinationName.isEmpty && !lineLabel.isEmpty {
        return "\(destinationName) · \(lineLabel)"
      }
      if !destinationName.isEmpty { return destinationName }
      if !lineLabel.isEmpty { return lineLabel }
      return "Tap Start when you are on board"
    }
    return "Open phone to set destination"
  }

  private func buildMonitoringSubline() -> String {
    var parts: [String] = []
    if !nextStopName.isEmpty { parts.append("Next: \(nextStopName)") }
    if !lineLabel.isEmpty && !destinationName.isEmpty {
      parts.append("\(lineLabel) · \(destinationName)")
    } else if !lineLabel.isEmpty {
      parts.append(lineLabel)
    } else if !destinationName.isEmpty {
      parts.append(destinationName)
    }
    if !directionLabel.isEmpty && !hasTripConcern {
      parts.append(directionLabel)
    }
    if gpsStale { parts.append("Last known position") }
    if hasTripConcern { parts.append("Check line on phone") }
    return parts.isEmpty ? "Waiting for route data…" : parts.joined(separator: " · ")
  }

  var complicationShortText: String {
    if alarmActive { return "WAKE" }
    if state == "arrived" { return "ARR" }
    if state == "missed" { return "MISS" }
    if isMonitoring && transitActive && stopsRemaining >= 0 {
      switch stopsRemaining {
      case 0: return "At"
      case 1: return "1 stp"
      default: return "\(stopsRemaining) stp"
      }
    }
    if isMonitoring && distanceReady {
      return String(format: "%.1f km", distanceKm)
    }
    if isMonitoring { return "ON" }
    if hasDestination { return "RDY" }
    return "OFF"
  }

  var complicationContentDescription: String {
    if alarmActive { return "Alarm · \(alarmContextLine)" }
    if state == "arrived" { return "You've arrived" }
    if state == "missed" { return "Trip missed" }
    if isMonitoring && transitActive && stopsRemaining >= 0 {
      switch stopsRemaining {
      case 0: return "Watching · At destination stop"
      case 1: return "Watching · 1 stop to go"
      default: return "Watching · \(stopsRemaining) stops to go"
      }
    }
    if isMonitoring && distanceReady {
      return String(format: "Watching · %.1f km left", distanceKm)
    }
    if isMonitoring { return "Watching your trip" }
    if hasDestination {
      let name = destinationName.isEmpty ? "Tap Start on phone" : destinationName
      return "Ready · \(name)"
    }
    return "DozeAlert idle"
  }

  static func from(dictionary: [String: Any]) -> TripState {
    TripState(
      state: dictionary["state"] as? String ?? "idle",
      destinationName: dictionary["destinationName"] as? String ?? "",
      distanceKm: (dictionary["distanceKm"] as? NSNumber)?.doubleValue
        ?? (dictionary["distanceKm"] as? Double) ?? 0,
      distanceReady: dictionary["distanceReady"] as? Bool ?? false,
      stopsRemaining: (dictionary["stopsRemaining"] as? NSNumber)?.intValue
        ?? (dictionary["stopsRemaining"] as? Int) ?? -1,
      transitActive: dictionary["transitActive"] as? Bool ?? false,
      lineLabel: dictionary["lineLabel"] as? String ?? "",
      tripConcern: dictionary["tripConcern"] as? String ?? "",
      gpsStale: dictionary["gpsStale"] as? Bool ?? false,
      directionLabel: dictionary["directionLabel"] as? String ?? "",
      nextStopName: dictionary["nextStopName"] as? String ?? "",
      wakeStopCount: (dictionary["wakeStopCount"] as? NSNumber)?.intValue
        ?? (dictionary["wakeStopCount"] as? Int) ?? -1,
      alarmActive: dictionary["alarmActive"] as? Bool ?? false,
      hasDestination: dictionary["hasDestination"] as? Bool ?? false,
      alarmStopName: dictionary["alarmStopName"] as? String ?? "",
      alarmHeadline: dictionary["alarmHeadline"] as? String ?? "",
      alarmUiHeadline: dictionary["alarmUiHeadline"] as? String ?? "",
      alarmSubline: dictionary["alarmSubline"] as? String ?? "",
      updatedAt: (dictionary["updatedAt"] as? NSNumber)?.int64Value
        ?? (dictionary["updatedAt"] as? Int64) ?? 0
    )
  }

  func asDictionary() -> [String: Any] {
    [
      "state": state,
      "destinationName": destinationName,
      "distanceKm": distanceKm,
      "distanceReady": distanceReady,
      "stopsRemaining": stopsRemaining,
      "transitActive": transitActive,
      "lineLabel": lineLabel,
      "tripConcern": tripConcern,
      "gpsStale": gpsStale,
      "directionLabel": directionLabel,
      "nextStopName": nextStopName,
      "wakeStopCount": wakeStopCount,
      "alarmActive": alarmActive,
      "hasDestination": hasDestination,
      "alarmStopName": alarmStopName,
      "alarmHeadline": alarmHeadline,
      "alarmUiHeadline": alarmUiHeadline,
      "alarmSubline": alarmSubline,
      "updatedAt": updatedAt,
    ]
  }

  static func loadFromAppGroup() -> TripState {
    let defaults = UserDefaults(suiteName: appGroupId) ?? .standard
    guard let dict = defaults.dictionary(forKey: defaultsKey) else {
      return TripState()
    }
    return TripState.from(dictionary: dict)
  }

  func saveToAppGroup() {
    let defaults = UserDefaults(suiteName: Self.appGroupId) ?? .standard
    defaults.set(asDictionary(), forKey: Self.defaultsKey)
    defaults.synchronize()
  }
}
