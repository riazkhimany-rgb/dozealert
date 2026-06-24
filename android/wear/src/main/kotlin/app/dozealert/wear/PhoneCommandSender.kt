package app.dozealert.wear

import android.content.Context
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.tasks.await

class PhoneCommandSender(context: Context) {
    private val messageClient = Wearable.getMessageClient(context.applicationContext)
    private val nodeClient = Wearable.getNodeClient(context.applicationContext)

    suspend fun send(path: String): Boolean {
        val nodes = nodeClient.connectedNodes.await()
        if (nodes.isEmpty()) {
            return false
        }

        var sent = false
        for (node in nodes) {
            messageClient.sendMessage(node.id, path, byteArrayOf()).await()
            sent = true
        }
        return sent
    }

    companion object {
        @Volatile
        private var instance: PhoneCommandSender? = null

        fun getInstance(context: Context): PhoneCommandSender {
            return instance ?: synchronized(this) {
                instance ?: PhoneCommandSender(context.applicationContext).also { instance = it }
            }
        }
    }
}
