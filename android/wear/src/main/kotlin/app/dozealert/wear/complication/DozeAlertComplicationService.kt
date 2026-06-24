package app.dozealert.wear.complication

import android.app.PendingIntent
import android.content.Intent
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingComplicationDataSourceService
import app.dozealert.wear.MainActivity
import app.dozealert.wear.TripStateRepository

class DozeAlertComplicationService : SuspendingComplicationDataSourceService() {
    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        return when (type) {
            ComplicationType.SHORT_TEXT -> shortText("DozeAlert", "Ready")
            else -> null
        }
    }

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationData? {
        TripStateRepository.getInstance(this).refreshFromPhone()
        val state = TripStateRepository.getInstance(this).state.value
        return when (request.complicationType) {
            ComplicationType.SHORT_TEXT -> shortText(
                title = state.statusLabel,
                text = state.tileLine,
            )
            else -> null
        }
    }

    private fun shortText(title: String, text: String): ShortTextComplicationData {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        return ShortTextComplicationData.Builder(
            text = PlainComplicationText.Builder(text).build(),
            contentDescription = PlainComplicationText.Builder("$title · $text").build(),
        )
            .setTitle(PlainComplicationText.Builder(title).build())
            .setTapAction(pendingIntent)
            .build()
    }
}
