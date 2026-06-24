package app.dozealert.wear.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.OutlinedButton
import androidx.wear.compose.material3.Text
import app.dozealert.wear.R
import app.dozealert.wear.TripState

@Composable
fun TripScreen(
    state: TripState,
    phoneConnected: Boolean,
    busy: Boolean,
    onStartMonitoring: () -> Unit,
    onStopMonitoring: () -> Unit,
    onDismissAlarm: () -> Unit,
    onOpenPhone: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 12.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "DozeAlert",
            style = MaterialTheme.typography.titleMedium,
        )
        Text(
            text = state.statusLabel,
            style = MaterialTheme.typography.titleLarge,
        )
        Text(
            text = state.detailLine,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
        )

        if (!phoneConnected) {
            Text(
                text = stringResource(R.string.waiting_for_phone),
                style = MaterialTheme.typography.bodySmall,
                textAlign = TextAlign.Center,
            )
        }

        if (state.alarmActive) {
            Button(
                onClick = onDismissAlarm,
                enabled = !busy && phoneConnected,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.dismiss_alarm))
            }
        } else if (state.canStart) {
            Button(
                onClick = onStartMonitoring,
                enabled = !busy && phoneConnected,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.start_monitoring))
            }
        } else if (state.canStop) {
            Button(
                onClick = onStopMonitoring,
                enabled = !busy && phoneConnected,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text(stringResource(R.string.stop_monitoring))
            }
        }

        OutlinedButton(
            onClick = onOpenPhone,
            enabled = !busy,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text(stringResource(R.string.open_phone))
        }
    }
}
