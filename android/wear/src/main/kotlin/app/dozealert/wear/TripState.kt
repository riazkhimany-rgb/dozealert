package app.dozealert.wear

data class TripState(
    val state: String = "idle",
    val destinationName: String = "",
    val distanceKm: Double = 0.0,
    val distanceReady: Boolean = false,
    val stopsRemaining: Int = -1,
    val transitActive: Boolean = false,
    val lineLabel: String = "",
    val tripConcern: String = "",
    val gpsStale: Boolean = false,
    val directionLabel: String = "",
    val nextStopName: String = "",
    val wakeStopCount: Int = -1,
    val alarmActive: Boolean = false,
    val hasDestination: Boolean = false,
    val alarmStopName: String = "",
    val alarmHeadline: String = "",
    val alarmUiHeadline: String = "",
    val alarmSubline: String = "",
    val updatedAt: Long = 0L,
) {
    val isMonitoring: Boolean
        get() = state == "monitoring"

    val hasTripConcern: Boolean
        get() = tripConcern.isNotBlank()

    val showTripConcernBanner: Boolean
        get() = isMonitoring && hasTripConcern && !alarmActive

    val canStart: Boolean
        get() = hasDestination && state == "idle"

    val canStop: Boolean
        get() = isMonitoring || state == "arrived" || alarmActive

    enum class StatusKind {
        Idle,
        Ready,
        Monitoring,
        Alarm,
        Arrived,
        Missed,
    }

    val statusKind: StatusKind
        get() = when {
            alarmActive -> StatusKind.Alarm
            state == "arrived" -> StatusKind.Arrived
            state == "missed" -> StatusKind.Missed
            isMonitoring -> StatusKind.Monitoring
            hasDestination -> StatusKind.Ready
            else -> StatusKind.Idle
        }

    val headline: String
        get() = when {
            alarmActive -> alarmUiHeadline.ifBlank { "GET READY" }
            !hasDestination -> "Set up on phone"
            isMonitoring && hasTripConcern && tripConcern == "wrong_direction" ->
                "Wrong direction?"
            isMonitoring && hasTripConcern && tripConcern == "unlikely_route" ->
                "Route uncertain"
            isMonitoring && gpsStale -> "GPS signal weak"
            isMonitoring && transitActive && stopsRemaining >= 0 -> when (stopsRemaining) {
                0 -> "At destination stop"
                1 -> "1 stop to go"
                else -> "$stopsRemaining stops to go"
            }
            isMonitoring && distanceReady -> String.format("%.1f km left", distanceKm)
            isMonitoring -> "Watching your trip"
            state == "arrived" -> "You've arrived"
            state == "missed" -> "Trip missed"
            hasDestination -> destinationName.ifBlank { lineLabel }.ifBlank { "Your trip" }
            else -> "Set up on phone"
        }

    val alarmPrimaryStopName: String
        get() = alarmStopName.ifBlank { destinationName }

    val alarmContextLine: String
        get() {
            val synced = alarmSubline.trim()
            if (synced.isNotEmpty()) {
                return synced
            }

            if (wakeStopCount > 0 && stopsRemaining >= 0) {
                val capped = minOf(stopsRemaining, wakeStopCount)
                return when (capped) {
                    0 -> "Time to get off"
                    1 -> "1 more stop to go"
                    else -> "$capped more stops to go"
                }
            }

            return if (destinationName.isNotBlank()) {
                "Within wake radius"
            } else {
                "Within wake radius"
            }
        }

    val tripConcernDetail: String
        get() = when (tripConcern) {
            "wrong_direction" -> "Check line & direction on phone."
            "unlikely_route" -> "Confirm your trip on phone."
            else -> "Check your line and direction on phone."
        }

    val subline: String
        get() = when {
            alarmActive -> alarmContextLine
            !hasDestination -> "Pick a destination on phone"
            isMonitoring && transitActive -> buildMonitoringSubline()
            isMonitoring && !distanceReady -> destinationName.ifBlank { "Waiting for GPS…" }
            isMonitoring -> destinationName.ifBlank { "Trip in progress" }
            hasDestination && !isMonitoring && state != "arrived" && state != "missed" -> {
                val line = lineLabel.ifBlank { null }
                when {
                    line != null -> line
                    else -> "Tap Start when on board"
                }
            }
            hasDestination -> {
                val dest = destinationName.ifBlank { null }
                val line = lineLabel.ifBlank { null }
                when {
                    dest != null && line != null -> "$dest · $line"
                    dest != null -> dest
                    line != null -> line
                    else -> "Tap Start when you are on board"
                }
            }
            else -> "Open phone to set destination"
        }

    private fun buildMonitoringSubline(): String {
        val parts = mutableListOf<String>()
        if (nextStopName.isNotBlank()) {
            parts.add("Next: $nextStopName")
        }
        val line = lineLabel.ifBlank { null }
        val dest = destinationName.ifBlank { null }
        when {
            line != null && dest != null -> parts.add("$line · $dest")
            line != null -> parts.add(line)
            dest != null -> parts.add(dest)
        }
        if (directionLabel.isNotBlank() && !hasTripConcern) {
            parts.add(directionLabel)
        }
        if (gpsStale) {
            parts.add("Last known position")
        }
        if (hasTripConcern) {
            parts.add("Check line on phone")
        }
        return parts.joinToString(" · ").ifBlank { "Waiting for route data…" }
    }

    val statusLabel: String
        get() = when (statusKind) {
            StatusKind.Alarm -> "Alarm"
            StatusKind.Arrived -> "Arrived"
            StatusKind.Missed -> "Missed"
            StatusKind.Monitoring -> "Watching"
            StatusKind.Ready -> "Ready"
            StatusKind.Idle -> "Idle"
        }

    val tileLine: String
        get() = when {
            alarmActive -> alarmPrimaryStopName.ifBlank { alarmUiHeadline }.ifBlank { "GET READY" }
            isMonitoring && hasTripConcern -> "Check line on phone"
            isMonitoring && gpsStale -> "GPS weak"
            isMonitoring && transitActive && stopsRemaining >= 0 -> when (stopsRemaining) {
                0 -> "At stop"
                1 -> "1 stop to go"
                else -> "$stopsRemaining stops to go"
            }
            isMonitoring && nextStopName.isNotBlank() -> "Next: $nextStopName"
            isMonitoring && distanceReady -> String.format("%.1f km", distanceKm)
            isMonitoring -> "Watching"
            hasDestination -> destinationName
                .ifBlank { if (transitActive) lineLabel else "" }
                .ifBlank { "DozeAlert" }
            else -> "DozeAlert"
        }

    companion object {
        fun fromDataMap(map: com.google.android.gms.wearable.DataMap): TripState {
            return TripState(
                state = map.getString("state", "idle"),
                destinationName = map.getString("destinationName", ""),
                distanceKm = map.getDouble("distanceKm", 0.0),
                distanceReady = map.getBoolean("distanceReady", false),
                stopsRemaining = map.getInt("stopsRemaining", -1),
                transitActive = map.getBoolean("transitActive", false),
                lineLabel = map.getString("lineLabel", ""),
                tripConcern = map.getString("tripConcern", ""),
                gpsStale = map.getBoolean("gpsStale", false),
                directionLabel = map.getString("directionLabel", ""),
                nextStopName = map.getString("nextStopName", ""),
                wakeStopCount = map.getInt("wakeStopCount", -1),
                alarmActive = map.getBoolean("alarmActive", false),
                hasDestination = map.getBoolean("hasDestination", false),
                alarmStopName = map.getString("alarmStopName", ""),
                alarmHeadline = map.getString("alarmHeadline", ""),
                alarmUiHeadline = map.getString("alarmUiHeadline", ""),
                alarmSubline = map.getString("alarmSubline", ""),
                updatedAt = map.getLong("updatedAt", 0L),
            )
        }

        fun fromPreferences(prefs: android.content.SharedPreferences): TripState {
            return TripState(
                state = prefs.getString("state", "idle") ?: "idle",
                destinationName = prefs.getString("destinationName", "") ?: "",
                distanceKm = prefs.getFloat("distanceKm", 0f).toDouble(),
                distanceReady = prefs.getBoolean("distanceReady", false),
                stopsRemaining = prefs.getInt("stopsRemaining", -1),
                transitActive = prefs.getBoolean("transitActive", false),
                lineLabel = prefs.getString("lineLabel", "") ?: "",
                tripConcern = prefs.getString("tripConcern", "") ?: "",
                gpsStale = prefs.getBoolean("gpsStale", false),
                directionLabel = prefs.getString("directionLabel", "") ?: "",
                nextStopName = prefs.getString("nextStopName", "") ?: "",
                wakeStopCount = prefs.getInt("wakeStopCount", -1),
                alarmActive = prefs.getBoolean("alarmActive", false),
                hasDestination = prefs.getBoolean("hasDestination", false),
                alarmStopName = prefs.getString("alarmStopName", "") ?: "",
                alarmHeadline = prefs.getString("alarmHeadline", "") ?: "",
                alarmUiHeadline = prefs.getString("alarmUiHeadline", "") ?: "",
                alarmSubline = prefs.getString("alarmSubline", "") ?: "",
                updatedAt = prefs.getLong("updatedAt", 0L),
            )
        }
    }
}

fun TripState.persist(prefs: android.content.SharedPreferences) {
    prefs.edit()
        .putString("state", state)
        .putString("destinationName", destinationName)
        .putFloat("distanceKm", distanceKm.toFloat())
        .putBoolean("distanceReady", distanceReady)
        .putInt("stopsRemaining", stopsRemaining)
        .putBoolean("transitActive", transitActive)
        .putString("lineLabel", lineLabel)
        .putString("tripConcern", tripConcern)
        .putBoolean("gpsStale", gpsStale)
        .putString("directionLabel", directionLabel)
        .putString("nextStopName", nextStopName)
        .putInt("wakeStopCount", wakeStopCount)
        .putBoolean("alarmActive", alarmActive)
        .putBoolean("hasDestination", hasDestination)
        .putString("alarmStopName", alarmStopName)
        .putString("alarmHeadline", alarmHeadline)
        .putString("alarmUiHeadline", alarmUiHeadline)
        .putString("alarmSubline", alarmSubline)
        .putLong("updatedAt", updatedAt)
        .apply()
}
