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
import app.dozealert.wear.ui.DozeAlertTheme
import app.dozealert.wear.ui.TripScreen
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class MainActivity : ComponentActivity() {
    private val repository by lazy { TripStateRepository.getInstance(this) }
    private val commandSender by lazy { PhoneCommandSender.getInstance(this) }
    private val tripAmbientController by lazy {
        TripAmbientController(this) { isAmbient ->
            isAmbientMode = isAmbient
        }
    }

    private var phoneConnected by mutableStateOf(false)
    private var busy by mutableStateOf(false)
    private var statusMessage by mutableStateOf<String?>(null)
    private var isAmbientMode by mutableStateOf(false)
    private var connectionJob: Job? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            DozeAlertTheme {
                val state by repository.state.collectAsStateWithLifecycle()
                androidx.compose.runtime.LaunchedEffect(
                    state.isMonitoring,
                    state.alarmActive,
                ) {
                    tripAmbientController.sync(
                        shouldEnable = state.isMonitoring || state.alarmActive,
                    )
                }
                androidx.compose.runtime.LaunchedEffect(state.alarmActive) {
                    if (state.alarmActive) {
                        startActivity(Intent(this@MainActivity, AlarmActivity::class.java))
                    }
                }
                TripScreen(
                    state = state,
                    phoneConnected = phoneConnected,
                    busy = busy,
                    statusMessage = statusMessage,
                    isAmbient = isAmbientMode,
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
            repository.refreshFromPhone()
            refreshPhoneConnection()
        }
        startConnectionPolling()
    }

    override fun onStop() {
        connectionJob?.cancel()
        connectionJob = null
        super.onStop()
    }

    private fun startConnectionPolling() {
        connectionJob?.cancel()
        connectionJob = lifecycleScope.launch {
            while (isActive) {
                refreshPhoneConnection()
                delay(15_000)
            }
        }
    }

    private fun sendCommand(path: String) {
        lifecycleScope.launch {
            busy = true
            statusMessage = null
            val sent = commandSender.send(path)
            if (!sent) {
                statusMessage = getString(R.string.open_phone_failed)
            } else {
                statusMessage = when (path) {
                    WearPaths.CMD_START_MONITORING ->
                        getString(R.string.start_monitoring_sent)
                    WearPaths.CMD_STOP_MONITORING ->
                        getString(R.string.stop_monitoring_sent)
                    else -> null
                }
                delay(600)
                repository.refreshFromPhone()
            }
            refreshPhoneConnection()
            busy = false
        }
    }

    private fun openPhoneApp() {
        lifecycleScope.launch {
            busy = true
            statusMessage = null
            val opened = PhoneRemoteLauncher.openOnPhone(this@MainActivity, commandSender)
            if (!opened) {
                statusMessage = getString(R.string.open_phone_failed)
            }
            refreshPhoneConnection()
            busy = false
        }
    }

    private suspend fun refreshPhoneConnection() {
        val nodes = Wearable.getNodeClient(this).connectedNodes.await()
        phoneConnected = nodes.isNotEmpty()
    }
}
