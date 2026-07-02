package app.dozealert.wear

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.wear.ongoing.OngoingActivity
import androidx.wear.ongoing.Status

/**
 * Shows trip progress on the watch face via the Ongoing Activity API (Maps-style chip).
 * Uses a silent ongoing notification — not a foreground service.
 */
object TripOngoingActivityManager {
    private const val NOTIFICATION_ID = 1001
    private const val CHANNEL_ID = "dozealert_ongoing_trip"

    private var ongoingActivity: OngoingActivity? = null

    fun sync(context: Context, state: TripState) {
        if (shouldShow(state)) {
            post(context, state)
        } else {
            dismiss(context)
        }
    }

    private fun shouldShow(state: TripState): Boolean {
        return state.isMonitoring || state.alarmActive
    }

    private fun post(context: Context, state: TripState) {
        val appContext = context.applicationContext
        ensureChannel(appContext)

        val pendingIntent = PendingIntent.getActivity(
            appContext,
            0,
            Intent(appContext, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val status = buildStatus(state)
        val notificationBuilder = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_complication)
            .setContentTitle(state.headline)
            .setContentText(state.tileLine)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        val activity = ongoingActivity
            ?: OngoingActivity.recoverOngoingActivity(appContext, NOTIFICATION_ID)
            ?: OngoingActivity.Builder(appContext, NOTIFICATION_ID, notificationBuilder)
                .setStaticIcon(R.drawable.ic_complication)
                .setTouchIntent(pendingIntent)
                .build()
                .also { ongoingActivity = it }

        activity.update(appContext, status)
        activity.apply(appContext)
        NotificationManagerCompat.from(appContext).notify(
            NOTIFICATION_ID,
            notificationBuilder.build(),
        )
    }

    private fun buildStatus(state: TripState): Status {
        return Status.Builder()
            .addTemplate(state.headline)
            .build()
    }

    private fun dismiss(context: Context) {
        val appContext = context.applicationContext
        ongoingActivity = null
        NotificationManagerCompat.from(appContext).cancel(NOTIFICATION_ID)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.ongoing_trip_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.ongoing_trip_channel_description)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }
}
