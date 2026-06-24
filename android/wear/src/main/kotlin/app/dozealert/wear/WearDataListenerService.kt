package app.dozealert.wear

import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

class WearDataListenerService : WearableListenerService() {
    override fun onDataChanged(dataEvents: DataEventBuffer) {
        TripStateRepository.getInstance(this).onDataChanged(dataEvents)
    }
}
