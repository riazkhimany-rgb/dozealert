package app.dozealert.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.ScalingLazyListAnchorType
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.FilledTonalButton
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import app.dozealert.wear.R
import app.dozealert.wear.TripState

private val AmbientBackground = Color.Black
private val AmbientPrimaryText = Color.White
private val AmbientSecondaryText = Color(0xFFB0B0B0)

@Composable
fun TripScreen(
    state: TripState,
    phoneConnected: Boolean,
    busy: Boolean,
    statusMessage: String?,
    isAmbient: Boolean,
    onStartMonitoring: () -> Unit,
    onStopMonitoring: () -> Unit,
    onDismissAlarm: () -> Unit,
    onOpenPhone: () -> Unit,
) {
    if (isAmbient) {
        AmbientTripContent(state = state)
    } else {
        ActiveTripContent(
            state = state,
            phoneConnected = phoneConnected,
            busy = busy,
            statusMessage = statusMessage,
            onStartMonitoring = onStartMonitoring,
            onStopMonitoring = onStopMonitoring,
            onDismissAlarm = onDismissAlarm,
            onOpenPhone = onOpenPhone,
        )
    }
}

@Composable
private fun AmbientTripContent(state: TripState) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AmbientBackground)
            .padding(horizontal = 24.dp, vertical = 28.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = state.statusLabel.uppercase(),
            style = MaterialTheme.typography.labelSmall.copy(
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.sp,
            ),
            color = AmbientSecondaryText,
            textAlign = TextAlign.Center,
        )

        Text(
            text = state.headline,
            style = MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Bold,
                fontSize = 20.sp,
                lineHeight = 24.sp,
            ),
            color = AmbientPrimaryText,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
        )

        if (state.subline.isNotBlank()) {
            Text(
                text = state.subline,
                style = MaterialTheme.typography.bodyMedium,
                color = AmbientSecondaryText,
                textAlign = TextAlign.Center,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 6.dp),
            )
        }
    }
}

@Composable
private fun ActiveTripContent(
    state: TripState,
    phoneConnected: Boolean,
    busy: Boolean,
    statusMessage: String?,
    onStartMonitoring: () -> Unit,
    onStopMonitoring: () -> Unit,
    onDismissAlarm: () -> Unit,
    onOpenPhone: () -> Unit,
) {
    ScreenScaffold {
        ScalingLazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
            anchorType = ScalingLazyListAnchorType.ItemStart,
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = 20.dp,
                vertical = 20.dp,
            ),
        ) {
            item { ConnectionRow(phoneConnected = phoneConnected) }

            item { StatusChip(state = state) }

            if (state.showTripConcernBanner) {
                item { TripConcernBanner(state = state) }
            }

            item {
                Text(
                    text = state.headline,
                    style = MaterialTheme.typography.titleLarge.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp,
                        lineHeight = 24.sp,
                    ),
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            item {
                Text(
                    text = state.subline,
                    style = MaterialTheme.typography.bodySmall.copy(
                        fontSize = 12.sp,
                        lineHeight = 15.sp,
                    ),
                    color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.75f),
                    textAlign = TextAlign.Center,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            if (!phoneConnected) {
                item {
                    Text(
                        text = stringResource(R.string.hint_setup),
                        style = MaterialTheme.typography.bodySmall,
                        color = StatusIdleColor,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }

            item {
                PrimaryAction(
                    state,
                    busy,
                    phoneConnected,
                    onStartMonitoring,
                    onStopMonitoring,
                    onDismissAlarm,
                )
            }

            item {
                FilledTonalButton(
                    onClick = onOpenPhone,
                    enabled = !busy,
                    modifier = Modifier.watchActionButton(),
                ) {
                    WatchButtonLabel(stringResource(R.string.open_phone))
                }
            }

            if (statusMessage != null) {
                item {
                    Text(
                        text = statusMessage,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth(),
                    )
                }
            }
        }
    }
}

@Composable
private fun ConnectionRow(phoneConnected: Boolean) {
    val dotColor = if (phoneConnected) StatusArrivedColor else StatusMissedColor
    val label = if (phoneConnected) {
        stringResource(R.string.phone_connected)
    } else {
        stringResource(R.string.waiting_for_phone)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(50))
            .background(MaterialTheme.colorScheme.surfaceContainerLow)
            .padding(horizontal = 12.dp, vertical = 6.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(dotColor),
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.85f),
            modifier = Modifier.padding(start = 8.dp),
        )
    }
}

@Composable
private fun StatusChip(state: TripState) {
    val (label, color) = when (state.statusKind) {
        TripState.StatusKind.Alarm -> stringResource(R.string.status_alarm) to StatusAlarmColor
        TripState.StatusKind.Arrived -> stringResource(R.string.status_arrived) to StatusArrivedColor
        TripState.StatusKind.Missed -> stringResource(R.string.status_missed) to StatusMissedColor
        TripState.StatusKind.Monitoring -> stringResource(R.string.status_monitoring) to StatusMonitoringColor
        TripState.StatusKind.Ready -> stringResource(R.string.status_ready) to StatusReadyColor
        TripState.StatusKind.Idle -> stringResource(R.string.status_idle) to StatusIdleColor
    }

    Text(
        text = label.uppercase(),
        style = MaterialTheme.typography.labelSmall.copy(
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 1.sp,
        ),
        color = color,
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(color.copy(alpha = 0.15f))
            .padding(horizontal = 12.dp, vertical = 4.dp),
    )
}

@Composable
private fun TripConcernBanner(state: TripState) {
    val title = when (state.tripConcern) {
        "wrong_direction" -> "Wrong direction?"
        "unlikely_route" -> "Route uncertain"
        else -> "Trip check needed"
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(StatusMissedColor.copy(alpha = 0.18f))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge.copy(
                fontWeight = FontWeight.Bold,
            ),
            color = StatusMissedColor,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = state.tripConcernDetail,
            style = MaterialTheme.typography.bodySmall.copy(
                fontSize = 11.sp,
                lineHeight = 14.sp,
            ),
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.82f),
            textAlign = TextAlign.Center,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Composable
private fun PrimaryAction(
    state: TripState,
    busy: Boolean,
    phoneConnected: Boolean,
    onStartMonitoring: () -> Unit,
    onStopMonitoring: () -> Unit,
    onDismissAlarm: () -> Unit,
) {
    val enabled = !busy && phoneConnected

    when {
        state.alarmActive -> {
            Button(
                onClick = onDismissAlarm,
                enabled = enabled,
                modifier = Modifier.watchActionButton(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = StatusAlarmColor,
                    contentColor = Color(0xFF0D1B2A),
                ),
            ) {
                WatchButtonLabel(
                    text = stringResource(R.string.dismiss_alarm),
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        state.canStart -> {
            Button(
                onClick = onStartMonitoring,
                enabled = enabled,
                modifier = Modifier.watchActionButton(),
            ) {
                WatchButtonLabel(stringResource(R.string.start_monitoring))
            }
        }

        state.canStop -> {
            Button(
                onClick = onStopMonitoring,
                enabled = enabled,
                modifier = Modifier.watchActionButton(),
            ) {
                WatchButtonLabel(stringResource(R.string.stop_monitoring))
            }
        }
    }
}

private fun Modifier.watchActionButton(): Modifier = this
    .fillMaxWidth()
    .padding(horizontal = 8.dp)

@Composable
private fun WatchButtonLabel(
    text: String,
    fontWeight: FontWeight? = null,
) {
    Text(
        text = text,
        fontWeight = fontWeight,
        textAlign = TextAlign.Center,
        maxLines = 2,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier.fillMaxWidth(),
    )
}
