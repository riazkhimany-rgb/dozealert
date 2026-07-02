package app.dozealert.wear

import android.content.Context

object PhoneRemoteLauncher {
    suspend fun openOnPhone(context: Context, commandSender: PhoneCommandSender): Boolean {
        // The watch shares the phone app's package id, so startActivity() only relaunches
        // the watch app. Ask the paired phone to foreground DozeAlert instead.
        return commandSender.send(WearPaths.CMD_OPEN_PHONE)
    }
}
