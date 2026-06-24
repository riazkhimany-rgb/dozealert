package app.dozealert.wear

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.lifecycleScope
import androidx.wear.compose.material3.MaterialTheme
import app.dozealert.wear.ui.TripScreen
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity : ComponentActivity() {
    private val repository by lazy { TripStateRepository.getInstance(this) }
    private val commandSender by lazy { PhoneCommandSender.getInstance(this) }

    private var phoneConnected by mutableStateOf(false)
    private var busy by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            MaterialTheme {
                val state by repository.state.collectAsStateWithLifecycle()
                androidx.compose.runtime.LaunchedEffect(state.alarmActive) {
                    if (state.alarmActive) {
                        startActivity(Intent(this@MainActivity, AlarmActivity::class.java))
                    }
                }
                TripScreen(
                    state = state,
                    phoneConnected = phoneConnected,
                    busy = busy,
                    onStartMonitoring = { sendCommand(WearPaths.CMD_START_MONITORING) },
                    onStopMonitoring = { sendCommand(WearPaths.CMD_STOP_MONITORING) },
                    onDismissAlarm = {
                        sendCommand(WearPaths.CMD_DISMISS_ALARM)
                        startActivity(
                            Intent(this, AlarmActivity::class.java).apply {
                                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                putExtra(AlarmActivity.EXTRA_DISMISS_ONLY, true)
                            },
                        )
                    },
                    onOpenPhone = { openPhoneApp() },
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        lifecycleScope.launch {
            repository.start()
            refreshPhoneConnection()
        }
    }

    override fun onStop() {
        repository.stop()
        super.onStop()
    }

    private fun sendCommand(path: String) {
        lifecycleScope.launch {
            busy = true
            val sent = commandSender.send(path)
            if (!sent) {
                openPhoneApp()
            }
            refreshPhoneConnection()
            busy = false
        }
    }

    private suspend fun refreshPhoneConnection() {
        val nodes = Wearable.getNodeClient(this).connectedNodes.await()
        phoneConnected = nodes.isNotEmpty()
    }

    private fun openPhoneApp() {
        val intent = packageManager.getLaunchIntentForPackage("app.dozealert")
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
}
