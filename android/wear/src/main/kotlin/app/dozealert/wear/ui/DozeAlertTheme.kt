package app.dozealert.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

private val MidnightBlue = Color(0xFF0D1B2A)
private val CyanAccent = Color(0xFF4CC9F0)
private val MutedText = Color(0xFFADB5BD)
private val AlarmAccent = Color(0xFFFFB703)
private val SuccessGreen = Color(0xFF52B788)
private val MissedRed = Color(0xFFE63946)
// Wear App Quality: OLED screens require true black app/tile backgrounds.
private val WearBlack = Color(0xFF000000)
private val WearSurfaceLow = Color(0xFF121212)
private val WearSurface = Color(0xFF1C1C1C)
private val WearSurfaceHigh = Color(0xFF2A2A2A)

val DozeAlertColorScheme = ColorScheme(
    primary = CyanAccent,
    onPrimary = MidnightBlue,
    primaryContainer = Color(0xFF1B4965),
    onPrimaryContainer = CyanAccent,
    background = WearBlack,
    onBackground = Color.White,
    surfaceContainerLow = WearSurfaceLow,
    surfaceContainer = WearSurface,
    surfaceContainerHigh = WearSurfaceHigh,
    onSurface = Color(0xFFE0E1DD),
    onSurfaceVariant = MutedText,
    error = MissedRed,
    onError = Color.White,
)

val StatusIdleColor @Composable get() = MutedText
val StatusReadyColor @Composable get() = CyanAccent
val StatusMonitoringColor @Composable get() = CyanAccent
val StatusAlarmColor @Composable get() = AlarmAccent
val StatusArrivedColor @Composable get() = SuccessGreen
val StatusMissedColor @Composable get() = MissedRed

@Composable
fun DozeAlertTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DozeAlertColorScheme,
        content = content,
    )
}
