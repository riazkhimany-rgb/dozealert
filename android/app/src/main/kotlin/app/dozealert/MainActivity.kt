package app.dozealert

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import app.dozealert.wear.WearBridge
import app.dozealert.wear.WearPaths
import app.dozealert.wear.WearSyncManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private var wearCommandSink: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deliverWearCommandFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverWearCommandFromIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        WearBridge.commandHandler = { command ->
            runOnUiThread {
                wearCommandSink?.success(command)
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SYSTEM_VOLUME_CHANNEL,
        ).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

            when (call.method) {
                "getVolume" -> {
                    result.success(readMusicVolume(audioManager))
                }

                "setVolume" -> {
                    val volume = call.argument<Double>("volume")
                    if (volume == null) {
                        result.error("invalid_argument", "volume is required", null)
                        return@setMethodCallHandler
                    }

                    writeMusicVolume(audioManager, volume)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pushTripState" -> {
                    @Suppress("UNCHECKED_CAST")
                    val fields = call.arguments as? Map<String, Any?>
                    if (fields == null) {
                        result.error("invalid_argument", "state map is required", null)
                        return@setMethodCallHandler
                    }

                    WearSyncManager.getInstance(this).pushTripState(fields)
                    result.success(null)
                }

                "consumePendingWearCommand" -> {
                    result.success(WearBridge.consumePendingCommand())
                }

                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    wearCommandSink = events
                    WearBridge.consumePendingCommand()?.let { command ->
                        events?.success(command)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    wearCommandSink = null
                }
            },
        )
    }

    override fun onDestroy() {
        if (isFinishing) {
            WearBridge.commandHandler = null
        }
        super.onDestroy()
    }

    private fun deliverWearCommandFromIntent(intent: Intent?) {
        val command = intent?.getStringExtra(WearPaths.EXTRA_WEAR_COMMAND) ?: return
        intent.removeExtra(WearPaths.EXTRA_WEAR_COMMAND)
        WearBridge.deliverCommand(this, command)
    }

    private fun readMusicVolume(audioManager: AudioManager): Double {
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (maxVolume <= 0) {
            return 0.0
        }

        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        return currentVolume.toDouble() / maxVolume.toDouble()
    }

    private fun writeMusicVolume(audioManager: AudioManager, volume: Double) {
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        if (maxVolume <= 0) {
            return
        }

        val clamped = volume.coerceIn(0.0, 1.0)
        val targetLevel = (clamped * maxVolume).roundToInt().coerceIn(0, maxVolume)
        audioManager.setStreamVolume(
            AudioManager.STREAM_MUSIC,
            targetLevel,
            0,
        )
    }

    companion object {
        private const val SYSTEM_VOLUME_CHANNEL = "app.dozealert/system_volume"
        private const val WEAR_CHANNEL = "app.dozealert/wear"
        private const val WEAR_EVENT_CHANNEL = "app.dozealert/wear_commands"
    }
}
