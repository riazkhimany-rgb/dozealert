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
}
