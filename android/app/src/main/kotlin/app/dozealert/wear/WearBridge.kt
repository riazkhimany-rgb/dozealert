package app.dozealert.wear

import android.content.Context
import android.content.Intent
import app.dozealert.MainActivity

object WearBridge {
    @Volatile
    var commandHandler: ((String) -> Unit)? = null

    @Volatile
    var pendingCommand: String? = null

    fun deliverCommand(context: Context, command: String) {
        val handler = commandHandler
        if (handler != null) {
            handler(command)
            return
        }

        pendingCommand = command
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(WearPaths.EXTRA_WEAR_COMMAND, command)
        }
        context.startActivity(launchIntent)
    }

    fun consumePendingCommand(): String? {
        val command = pendingCommand
        pendingCommand = null
        return command
    }
}
