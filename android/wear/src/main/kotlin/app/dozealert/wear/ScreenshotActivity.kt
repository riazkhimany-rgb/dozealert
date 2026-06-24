package app.dozealert.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
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
            MaterialTheme {
                if (scenario == SCENARIO_ALARM) {
                    AlarmScreenshot(state)
                } else {
                    TripScreen(
                        state = state,
                        phoneConnected = phoneConnected,
                        busy = false,
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
            lineLabel = "Lakeshore West",
        ) to true
        ScreenshotActivity.SCENARIO_MONITORING -> TripState(
            state = "monitoring",
            hasDestination = true,
            destinationName = "Bronte GO",
            distanceKm = 2.3,
            distanceReady = true,
        ) to true
        ScreenshotActivity.SCENARIO_TRANSIT -> TripState(
            state = "monitoring",
            hasDestination = true,
            destinationName = "Bronte GO",
            transitActive = true,
            stopsRemaining = 3,
            lineLabel = "Lakeshore West",
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

@androidx.compose.runtime.Composable
private fun AlarmScreenshot(state: TripState) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Wake up",
            style = MaterialTheme.typography.titleLarge,
            textAlign = TextAlign.Center,
        )
        Text(
            text = state.destinationName.ifBlank { "Your stop" },
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
        )
        Text(
            text = state.detailLine,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        Button(
            onClick = {},
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Dismiss alarm")
        }
    }
}
