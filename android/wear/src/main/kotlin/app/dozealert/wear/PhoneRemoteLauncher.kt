package app.dozealert.wear

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.wear.remote.interactions.RemoteActivityHelper
import kotlinx.coroutines.guava.await
import kotlinx.coroutines.withTimeoutOrNull

object PhoneRemoteLauncher {
    private const val TAG = "PhoneRemoteLauncher"
    private const val OPEN_PHONE_URI = "dozealert://open"

    /**
     * Opens the companion phone app.
     *
     * Prefer [RemoteActivityHelper] (Wear quality / non-standalone expectation), then fall back
     * to the Data Layer message so an already-running phone process can still foreground.
     */
    suspend fun openOnPhone(context: Context, commandSender: PhoneCommandSender): Boolean {
        val remoteOk = tryOpenViaRemoteActivity(context)
        if (remoteOk) return true
        return commandSender.send(WearPaths.CMD_OPEN_PHONE)
    }

    private suspend fun tryOpenViaRemoteActivity(context: Context): Boolean {
        return try {
            val helper = RemoteActivityHelper(context)
            val intent = Intent(Intent.ACTION_VIEW)
                .addCategory(Intent.CATEGORY_BROWSABLE)
                .setData(Uri.parse(OPEN_PHONE_URI))
            val result = withTimeoutOrNull(8_000) {
                helper.startRemoteActivity(intent).await()
            }
            result != null
        } catch (e: Exception) {
            Log.w(TAG, "RemoteActivityHelper failed; will try Message API", e)
            false
        }
    }
}
