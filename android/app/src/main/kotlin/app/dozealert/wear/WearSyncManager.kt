package app.dozealert.wear

import android.content.Context
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

class WearSyncManager(context: Context) {
    private val appContext = context.applicationContext
    private val dataClient = Wearable.getDataClient(appContext)
    private val messageClient = Wearable.getMessageClient(appContext)
    private val nodeClient = Wearable.getNodeClient(appContext)

    fun pushTripState(fields: Map<String, Any?>) {
        val request = PutDataMapRequest.create(WearPaths.TRIP_STATE).apply {
            val map = dataMap
            fields.forEach { (key, value) ->
                when (value) {
                    null -> map.remove(key)
                    is String -> map.putString(key, value)
                    is Boolean -> map.putBoolean(key, value)
                    is Int -> map.putInt(key, value)
                    is Long -> map.putLong(key, value)
                    is Double -> map.putDouble(key, value)
                    is Float -> map.putFloat(key, value)
                    else -> map.putString(key, value.toString())
                }
            }
            map.putLong("updatedAt", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()

        dataClient.putDataItem(request)
    }

    fun launchWearApp() {
        nodeClient.connectedNodes.addOnSuccessListener { nodes ->
            for (node in nodes) {
                messageClient.sendMessage(
                    node.id,
                    WearPaths.CMD_OPEN_WATCH,
                    ByteArray(0),
                )
            }
        }
    }

    companion object {
        @Volatile
        private var instance: WearSyncManager? = null

        fun getInstance(context: Context): WearSyncManager {
            return instance ?: synchronized(this) {
                instance ?: WearSyncManager(context.applicationContext).also { instance = it }
            }
        }
    }
}
