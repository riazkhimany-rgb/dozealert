package app.dozealert.wear

import android.content.Context
import android.content.Intent

object AlarmLauncher {
    fun launchIfNeeded(context: Context) {
        val intent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
        }
        context.startActivity(intent)
    }

    /**
     * Best-effort request to close the alarm screen after a dismiss. Vibration
     * is already stopped via [WearAlarmController]; this just clears the UI when
     * the Activity is running. If a background launch is blocked, the screen
     * still closes on its own once it resumes and observes `alarmActive = false`.
     */
    fun dismiss(context: Context) {
        val intent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra(AlarmActivity.EXTRA_DISMISS_ONLY, true)
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            // Background activity launch may be restricted; state observation
            // will close the screen when it next resumes.
        }
    }
}
