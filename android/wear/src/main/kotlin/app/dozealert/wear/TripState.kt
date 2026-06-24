package app.dozealert.wear

data class TripState(
    val state: String = "idle",
    val destinationName: String = "",
    val distanceKm: Double = 0.0,
    val distanceReady: Boolean = false,
    val stopsRemaining: Int = -1,
    val transitActive: Boolean = false,
    val lineLabel: String = "",
    val alarmActive: Boolean = false,
    val hasDestination: Boolean = false,
    val updatedAt: Long = 0L,
) {
    val isMonitoring: Boolean
        get() = state == "monitoring"

    val canStart: Boolean
        get() = hasDestination && !isMonitoring && state != "arrived"

    val canStop: Boolean
        get() = isMonitoring || state == "arrived" || alarmActive

    val statusLabel: String
        get() = when (state) {
            "monitoring" -> "Monitoring"
            "arrived" -> "Arrived"
            "missed" -> "Missed"
            else -> "Idle"
        }

    val detailLine: String
        get() = when {
            alarmActive -> "Alarm active"
            !hasDestination -> "Set destination on phone"
            isMonitoring && transitActive && stopsRemaining >= 0 ->
                "$stopsRemaining stops · $lineLabel"
            isMonitoring && distanceReady -> String.format("%.1f km remaining", distanceKm)
            isMonitoring -> "Waiting for GPS…"
            hasDestination && destinationName.isNotBlank() -> destinationName
            else -> lineLabel.ifBlank { "Ready on phone" }
        }

    val tileLine: String
        get() = when {
            alarmActive -> "Wake up!"
            isMonitoring && distanceReady -> String.format("%.1f km", distanceKm)
            isMonitoring -> "Monitoring"
            hasDestination -> destinationName
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
                alarmActive = map.getBoolean("alarmActive", false),
                hasDestination = map.getBoolean("hasDestination", false),
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
                alarmActive = prefs.getBoolean("alarmActive", false),
                hasDestination = prefs.getBoolean("hasDestination", false),
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
        .putBoolean("alarmActive", alarmActive)
        .putBoolean("hasDestination", hasDestination)
        .putLong("updatedAt", updatedAt)
        .apply()
}
