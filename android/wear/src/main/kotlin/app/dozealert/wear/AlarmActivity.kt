package app.dozealert.wear

import android.content.Intent
import android.os.Bundle
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (intent.getBooleanExtra(EXTRA_DISMISS_ONLY, false)) {
            WearAlarmController.stop()
            finish()
            return
        }

        WearAlarmController.start(this)

        setContent {
            DozeAlertTheme {
                val state by repository.state.collectAsStateWithLifecycle()
                LaunchedEffect(state.alarmActive) {
                    if (!state.alarmActive) {
                        WearAlarmController.stop()
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
                            WearAlarmController.stop()
                            commandSender.send(WearPaths.CMD_DISMISS_ALARM)
                        }
                    },
                )
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_DISMISS_ONLY, false)) {
            WearAlarmController.stop()
            busy = false
            finish()
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
        // Only silence vibration if the alarm is no longer active. The Activity
        // can be destroyed (screen off / ambient) while the alarm should still
        // be buzzing; WearAlarmController keeps it running independently.
        if (!repository.state.value.alarmActive) {
            WearAlarmController.stop()
        }
        super.onDestroy()
    }

    companion object {
        const val EXTRA_DISMISS_ONLY = "dismiss_only"
    }
}
