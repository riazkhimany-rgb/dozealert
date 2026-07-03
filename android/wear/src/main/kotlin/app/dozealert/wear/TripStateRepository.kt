package app.dozealert.wear

import android.content.ComponentName
import android.content.Context
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import androidx.wear.tiles.TileService
import app.dozealert.wear.complication.DozeAlertComplicationService
import app.dozealert.wear.tile.DozeAlertTileService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

class TripStateRepository private constructor(context: Context) {
    private val appContext = context.applicationContext
    private val dataClient = Wearable.getDataClient(appContext)
    private val prefs =
        appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _state = MutableStateFlow(TripState.fromPreferences(prefs))
    val state: StateFlow<TripState> = _state.asStateFlow()

    init {
        TripOngoingActivityManager.sync(appContext, _state.value)
    }

    fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) {
                continue
            }
            val path = event.dataItem.uri.path ?: continue
            if (path != WearPaths.TRIP_STATE) {
                continue
            }
            val map = DataMapItem.fromDataItem(event.dataItem).dataMap
            applyState(TripState.fromDataMap(map))
        }
    }

    suspend fun refreshFromPhone() {
        val items = dataClient.getDataItems(android.net.Uri.parse("wear://*/${WearPaths.TRIP_STATE}"))
            .await()
        try {
            for (item in items) {
                val map = DataMapItem.fromDataItem(item).dataMap
                applyState(TripState.fromDataMap(map))
                break
            }
        } finally {
            items.release()
        }
    }

    private fun applyState(next: TripState) {
        val previous = _state.value
        next.persist(prefs)
        _state.value = next
        TileService.getUpdater(appContext).requestUpdate(DozeAlertTileService::class.java)
        ComplicationDataSourceUpdateRequester.create(
            appContext,
            ComponentName(appContext, DozeAlertComplicationService::class.java),
        ).requestUpdateAll()
        handleSideEffects(previous, next)
    }

    private fun handleSideEffects(previous: TripState, next: TripState) {
        if (!previous.alarmActive && next.alarmActive) {
            AlarmLauncher.launchIfNeeded(appContext)
        }
        if (previous.alarmActive && !next.alarmActive) {
            // Dismissed on the phone (or watch): silence the buzz immediately,
            // even if the alarm screen is stopped/ambient and not observing state.
            WearAlarmController.stop()
            AlarmLauncher.dismiss(appContext)
        }
        TripOngoingActivityManager.sync(appContext, next)
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
