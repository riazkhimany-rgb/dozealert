package app.dozealert.wear.complication

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import android.util.Log
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.data.SmallImage
import androidx.wear.watchface.complications.data.SmallImageType
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import app.dozealert.wear.MainActivity
import app.dozealert.wear.R
import app.dozealert.wear.TripState
import app.dozealert.wear.TripStateRepository

class DozeAlertComplicationService : SuspendingComplicationDataSourceService() {
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return try {
            dataForType(type, PREVIEW_STATE)
        } catch (error: Exception) {
            Log.w(TAG, "getPreviewData failed for $type", error)
            fallbackShortText()
        }
    }

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        return try {
            val repository = TripStateRepository.getInstance(this)
            try {
                repository.refreshFromPhone()
            } catch (error: Exception) {
                // Still serve cached prefs state if Data Layer is unavailable.
                Log.w(TAG, "refreshFromPhone failed; using cached state", error)
            }
            dataForType(request.complicationType, repository.state.value)
        } catch (error: Exception) {
            Log.e(TAG, "onComplicationRequest failed", error)
            fallbackShortText()
        }
    }

    private fun dataForType(type: ComplicationType, state: TripState): ComplicationData? {
        // Only SHORT_TEXT is declared in the manifest so round Samsung slots bind
        // like heart rate / steps (small icon + text), not a full-bleed image.
        return when (type) {
            ComplicationType.SHORT_TEXT -> shortText(state)
            else -> null
        }
    }

    private fun shortText(state: TripState): ShortTextComplicationData {
        // Icon + compact text; faces that support color use smallImage,
        // otherwise they tint monochromaticImage (same layout as Fit shortcuts).
        return ShortTextComplicationData.Builder(
            text = PlainComplicationText.Builder(state.complicationShortText).build(),
            contentDescription = PlainComplicationText.Builder(
                state.complicationContentDescription,
            ).build(),
        )
            .setMonochromaticImage(monoImage(state))
            .setSmallImage(coloredSmallImage(state))
            .setTapAction(tapPendingIntent())
            .build()
    }

    private fun monoImage(state: TripState): MonochromaticImage {
        val icon = Icon.createWithResource(this, monoGlyphRes(state.complicationIconKind))
        return MonochromaticImage.Builder(icon).build()
    }

    private fun coloredSmallImage(state: TripState): SmallImage {
        val icon = Icon.createWithResource(this, coloredIconRes(state.complicationIconKind))
        return SmallImage.Builder(icon, SmallImageType.ICON).build()
    }

    private fun fallbackShortText(): ShortTextComplicationData {
        return ShortTextComplicationData.Builder(
            text = PlainComplicationText.Builder("OFF").build(),
            contentDescription = PlainComplicationText.Builder("DozeAlert").build(),
        )
            .setTapAction(tapPendingIntent())
            .build()
    }

    private fun tapPendingIntent(): PendingIntent {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        return PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun monoGlyphRes(kind: TripState.ComplicationIconKind): Int {
        return when (kind) {
            TripState.ComplicationIconKind.Idle -> R.drawable.ic_comp_mono_off
            TripState.ComplicationIconKind.Ready -> R.drawable.ic_comp_mono_ready
            TripState.ComplicationIconKind.Watching -> R.drawable.ic_comp_mono_watching
            TripState.ComplicationIconKind.Alarm -> R.drawable.ic_comp_mono_alarm
            TripState.ComplicationIconKind.Arrived -> R.drawable.ic_comp_mono_arrived
            TripState.ComplicationIconKind.Missed -> R.drawable.ic_comp_mono_missed
        }
    }

    private fun coloredIconRes(kind: TripState.ComplicationIconKind): Int {
        return when (kind) {
            TripState.ComplicationIconKind.Idle -> R.drawable.ic_comp_dot_off
            TripState.ComplicationIconKind.Ready -> R.drawable.ic_comp_dot_ready
            TripState.ComplicationIconKind.Watching -> R.drawable.ic_comp_dot_watching
            TripState.ComplicationIconKind.Alarm -> R.drawable.ic_comp_dot_alarm
            TripState.ComplicationIconKind.Arrived -> R.drawable.ic_comp_dot_arrived
            TripState.ComplicationIconKind.Missed -> R.drawable.ic_comp_dot_missed
        }
    }

    companion object {
        private const val TAG = "DozeAlertComplication"

        private val PREVIEW_STATE = TripState(
            state = "monitoring",
            hasDestination = true,
            transitActive = true,
            stopsRemaining = 3,
            distanceReady = true,
            distanceKm = 1.2,
        )
    }
}
