package app.dozealert.wear

import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import app.dozealert.wear.ui.AlarmScreen
import app.dozealert.wear.ui.DozeAlertTheme
import kotlinx.coroutines.launch

class AlarmActivity : ComponentActivity() {
    private val repository by lazy { TripStateRepository.getInstance(this) }
    private val commandSender by lazy { PhoneCommandSender.getInstance(this) }

    private var busy by mutableStateOf(false)
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (intent.getBooleanExtra(EXTRA_DISMISS_ONLY, false)) {
            finish()
            return
        }

        startAlarmVibration()

        setContent {
            DozeAlertTheme {
                val state by repository.state.collectAsStateWithLifecycle()
                LaunchedEffect(state.alarmActive) {
                    if (!state.alarmActive) {
                        stopAlarmVibration()
                        busy = false
                        finish()
                    }
                }
                AlarmScreen(
                    state = state,
                    busy = busy,
                    onDismiss = {
                        lifecycleScope.launch {
                            busy = true
                            stopAlarmVibration()
                            commandSender.send(WearPaths.CMD_DISMISS_ALARM)
                        }
                    },
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        lifecycleScope.launch {
            repository.refreshFromPhone()
        }
    }

    override fun onStop() {
        super.onStop()
    }

    override fun onDestroy() {
        stopAlarmVibration()
        super.onDestroy()
    }

    private fun startAlarmVibration() {
        val activeVibrator = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            val manager = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(VIBRATOR_SERVICE) as Vibrator
        }
        vibrator = activeVibrator

        val pattern = longArrayOf(0, 600, 200, 600, 200, 600)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            activeVibrator.vibrate(
                VibrationEffect.createWaveform(pattern, 0),
            )
        } else {
            @Suppress("DEPRECATION")
            activeVibrator.vibrate(pattern, 0)
        }
    }

    private fun stopAlarmVibration() {
        vibrator?.cancel()
        vibrator = null
    }

    companion object {
        const val EXTRA_DISMISS_ONLY = "dismiss_only"
    }
}
