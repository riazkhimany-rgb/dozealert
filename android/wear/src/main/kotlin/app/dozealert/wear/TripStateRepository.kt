package app.dozealert.wear

import android.content.Context
import androidx.wear.tiles.TileService
import app.dozealert.wear.tile.DozeAlertTileService
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

class TripStateRepository private constructor(context: Context) :
    DataClient.OnDataChangedListener {
    private val appContext = context.applicationContext
    private val dataClient = Wearable.getDataClient(appContext)
    private val prefs =
        appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(TripState.fromPreferences(prefs))
    val state: StateFlow<TripState> = _state.asStateFlow()

    private var listening = false

    suspend fun start() {
        if (listening) {
            return
        }
        listening = true
        dataClient.addListener(this)
        refreshFromPhone()
    }

    fun stop() {
        if (!listening) {
            return
        }
        dataClient.removeListener(this)
        listening = false
    }

    suspend fun refreshFromPhone() {
        val items = dataClient.getDataItems(android.net.Uri.parse("wear://*/${WearPaths.TRIP_STATE}"))
            .await()
        try {
            for (item in items) {
                val map = DataMapItem.fromDataItem(item).dataMap
                updateState(TripState.fromDataMap(map))
                break
            }
        } finally {
            items.release()
        }
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) {
                continue
            }
            val path = event.dataItem.uri.path ?: continue
            if (path != WearPaths.TRIP_STATE) {
                continue
            }
            val map = DataMapItem.fromDataItem(event.dataItem).dataMap
            updateState(TripState.fromDataMap(map))
        }
    }

    private fun updateState(next: TripState) {
        next.persist(prefs)
        _state.value = next
        TileService.getUpdater(appContext).requestUpdate(DozeAlertTileService::class.java)
    }

    companion object {
        private const val PREFS_NAME = "dozealert_trip_state"

        @Volatile
        private var instance: TripStateRepository? = null

        fun getInstance(context: Context): TripStateRepository {
            return instance ?: synchronized(this) {
                instance ?: TripStateRepository(context.applicationContext).also { instance = it }
            }
        }
    }
}
