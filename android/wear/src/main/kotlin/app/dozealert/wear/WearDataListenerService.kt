package app.dozealert.wear

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class WearDataListenerService : WearableListenerService() {
    private val repository by lazy { TripStateRepository.getInstance(this) }
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    override fun onCreate() {
        super.onCreate()
        serviceScope.launch {
            repository.refreshFromPhone()
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        repository.onDataChanged(dataEvents)
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            WearPaths.CMD_OPEN_WATCH -> WatchAppLauncher.openTripScreen(this)
        }
    }
}
