package app.dozealert.wear

import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WearListenerService : WearableListenerService() {
    override fun onMessageReceived(messageEvent: MessageEvent) {
        when (messageEvent.path) {
            WearPaths.CMD_START_MONITORING,
            WearPaths.CMD_STOP_MONITORING,
            WearPaths.CMD_DISMISS_ALARM,
            -> WearBridge.deliverCommand(applicationContext, messageEvent.path)
        }
    }
}
