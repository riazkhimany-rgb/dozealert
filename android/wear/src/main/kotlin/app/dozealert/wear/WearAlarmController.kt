package app.dozealert.wear

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Owns the alarm vibration independently of any Activity lifecycle.
 *
 * The alarm UI ([AlarmActivity]) can be stopped/ambient while buzzing, which
 * pauses its Compose state collection. If vibration were owned by the Activity
 * it would keep running after a phone-side dismiss (the state update is never
 * observed). Keeping it in a process-wide singleton lets the data listener
 * ([TripStateRepository]) silence the watch the instant the phone reports the
 * alarm was dismissed — from either device.
 */
object WearAlarmController {
    private val lock = Any()
    private var vibrator: Vibrator? = null

    fun start(context: Context) {
        synchronized(lock) {
            if (vibrator != null) {
                return
            }
            val appContext = context.applicationContext
            val activeVibrator =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val manager = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                        as VibratorManager
                    manager.defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    appContext.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }
            vibrator = activeVibrator

            val pattern = longArrayOf(0, 600, 200, 600, 200, 600)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                activeVibrator.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                activeVibrator.vibrate(pattern, 0)
            }
        }
    }

    fun stop() {
        synchronized(lock) {
            vibrator?.cancel()
            vibrator = null
        }
    }
}
