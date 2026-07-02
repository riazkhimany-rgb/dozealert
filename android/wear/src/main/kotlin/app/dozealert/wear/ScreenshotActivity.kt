package app.dozealert.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import app.dozealert.wear.ui.AlarmScreen
import app.dozealert.wear.ui.DozeAlertTheme
import app.dozealert.wear.ui.TripScreen

/**
 * Renders fixed UI states for Play Store / marketing screenshots.
 * Launch via adb only (not exported in manifest).
 */
class ScreenshotActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val scenario = intent.getStringExtra(EXTRA_SCENARIO) ?: SCENARIO_READY
        val (state, phoneConnected) = scenarioState(scenario)

        setContent {
            DozeAlertTheme {
                if (scenario == SCENARIO_ALARM) {
                    AlarmScreen(state = state, busy = false, onDismiss = {})
                } else {
                    TripScreen(
                        state = state,
                        phoneConnected = phoneConnected,
                        busy = false,
                        statusMessage = null,
                        isAmbient = false,
                        onStartMonitoring = {},
                        onStopMonitoring = {},
                        onDismissAlarm = {},
                        onOpenPhone = {},
                    )
                }
            }
        }
    }

    companion object {
        const val EXTRA_SCENARIO = "scenario"
        const val SCENARIO_IDLE = "idle"
        const val SCENARIO_READY = "ready"
        const val SCENARIO_MONITORING = "monitoring"
        const val SCENARIO_TRANSIT = "transit"
        const val SCENARIO_ALARM = "alarm"
    }
}

private fun scenarioState(scenario: String): Pair<TripState, Boolean> {
    return when (scenario) {
        ScreenshotActivity.SCENARIO_IDLE -> TripState() to false
        ScreenshotActivity.SCENARIO_READY -> TripState(
            state = "idle",
            hasDestination = true,
            destinationName = "Bronte GO",
            lineLabel = "GO Transit - LW - Lakeshore West",
        ) to true
        ScreenshotActivity.SCENARIO_MONITORING -> TripState(
            state = "monitoring",
            hasDestination = true,
            destinationName = "Bronte GO",
            distanceKm = 2.3,
            distanceReady = true,
            lineLabel = "GO Transit - LW - Lakeshore West",
        ) to true
        ScreenshotActivity.SCENARIO_TRANSIT -> TripState(
            state = "monitoring",
            hasDestination = true,
            destinationName = "Bronte GO",
            transitActive = true,
            stopsRemaining = 1,
            lineLabel = "GO Transit - LW - Lakeshore West",
        ) to true
        ScreenshotActivity.SCENARIO_ALARM -> TripState(
            state = "arrived",
            hasDestination = true,
            destinationName = "Bronte GO",
            alarmActive = true,
            distanceKm = 0.1,
            distanceReady = true,
        ) to true
        else -> TripState(
            state = "idle",
            hasDestination = true,
            destinationName = "Bronte GO",
        ) to true
    }
}
