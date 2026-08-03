package app.dozealert.wear

import android.content.Context
import android.content.Intent
import app.dozealert.MainActivity

object WearBridge {
    @Volatile
    var commandHandler: ((String) -> Unit)? = null

    @Volatile
    var connectionChangeHandler: (() -> Unit)? = null

    @Volatile
    var pendingCommand: String? = null

    fun deliverCommand(context: Context, command: String) {
        when (command) {
            WearPaths.CMD_OPEN_PHONE -> {
                openPhoneApp(context)
                return
            }
        }

        val handler = commandHandler
        if (handler != null) {
            openPhoneApp(context)
            handler(command)
            return
        }

        pendingCommand = command
        openPhoneApp(context, command)
    }

    fun openPhoneApp(context: Context, wearCommand: String? = null) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = android.net.Uri.parse("dozealert://open")
            addCategory(Intent.CATEGORY_DEFAULT)
            addCategory(Intent.CATEGORY_BROWSABLE)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            wearCommand?.let { putExtra(WearPaths.EXTRA_WEAR_COMMAND, it) }
        }
        try {
            context.startActivity(launchIntent)
        } catch (_: Exception) {
            // Fallback without deep-link extras if the VIEW path is blocked.
            val fallback = Intent(context, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                )
                wearCommand?.let { putExtra(WearPaths.EXTRA_WEAR_COMMAND, it) }
            }
            context.startActivity(fallback)
        }
    }

    fun consumePendingCommand(): String? {
        val command = pendingCommand
        pendingCommand = null
        return command
    }
}
