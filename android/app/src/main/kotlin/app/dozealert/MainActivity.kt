package app.dozealert

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import app.dozealert.wear.WearBridge
import app.dozealert.wear.WearPaths
import app.dozealert.wear.WearSyncManager
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private var wearCommandSink: EventChannel.EventSink? = null
    private var wearConnectionSink: EventChannel.EventSink? = null

    private val wearCapabilityListener =
        CapabilityClient.OnCapabilityChangedListener { capabilityInfo ->
            if (capabilityInfo.name == WearPaths.WEAR_CAPABILITY) {
                WearBridge.connectionChangeHandler?.invoke()
            }
        }

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
        WearBridge.connectionChangeHandler = {
            runOnUiThread {
                wearConnectionSink?.success("changed")
            }
        }

        Wearable.getCapabilityClient(this).addListener(
            wearCapabilityListener,
            Uri.parse("wear://*/"),
            CapabilityClient.FILTER_ALL,
        )

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

                "openTtsSettings" -> {
                    result.success(openTextToSpeechSettings())
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

                "launchWearApp" -> {
                    WearSyncManager.getInstance(this).launchWearApp()
                    result.success(null)
                }

                "wearAppStatus" -> {
                    val capabilityClient = Wearable.getCapabilityClient(this)
                    val nodeClient = Wearable.getNodeClient(this)
                    capabilityClient
                        .getCapability(WearPaths.WEAR_CAPABILITY, CapabilityClient.FILTER_ALL)
                        .addOnSuccessListener { all ->
                            // FILTER_ALL includes paired watches that have the app but
                            // are currently offline, so this is true iff the DozeAlert
                            // watch app is installed somewhere.
                            val installed = all.nodes.isNotEmpty()
                            if (!installed) {
                                result.success(
                                    mapOf(
                                        "installed" to false,
                                        "connected" to false,
                                    ),
                                )
                                return@addOnSuccessListener
                            }

                            val dozeAlertNodeIds = all.nodes.map { it.id }.toSet()
                            nodeClient.connectedNodes
                                .addOnSuccessListener { connected ->
                                    // connectedNodes reflects live Bluetooth reachability.
                                    // Capability FILTER_REACHABLE can stay stale for minutes
                                    // after a watch powers off, which is why we avoid it.
                                    val reachable = connected.any { it.id in dozeAlertNodeIds }
                                    result.success(
                                        mapOf(
                                            "installed" to true,
                                            "connected" to reachable,
                                        ),
                                    )
                                }
                                .addOnFailureListener {
                                    result.success(
                                        mapOf(
                                            "installed" to installed,
                                            "connected" to false,
                                        ),
                                    )
                                }
                        }
                        .addOnFailureListener {
                            result.success(
                                mapOf("installed" to false, "connected" to false),
                            )
                        }
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

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WEAR_CONNECTION_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    wearConnectionSink = events
                }

                override fun onCancel(arguments: Any?) {
                    wearConnectionSink = null
                }
            },
        )
    }

    override fun onDestroy() {
        if (isFinishing) {
            Wearable.getCapabilityClient(this).removeListener(wearCapabilityListener)
            WearBridge.commandHandler = null
            WearBridge.connectionChangeHandler = null
        }
        super.onDestroy()
    }

    private fun deliverWearCommandFromIntent(intent: Intent?) {
        val command = intent?.getStringExtra(WearPaths.EXTRA_WEAR_COMMAND) ?: return
        intent.removeExtra(WearPaths.EXTRA_WEAR_COMMAND)
        WearBridge.deliverCommand(this, command)
    }

    /**
     * Opens the system Text-to-speech settings so the user can pick a voice /
     * engine. Falls back to Accessibility settings, then general Settings, since
     * the dedicated TTS screen is not guaranteed on every OEM build. Returns
     * true if any settings screen was launched.
     */
    private fun openTextToSpeechSettings(): Boolean {
        val intents = listOf(
            Intent("com.android.settings.TTS_SETTINGS"),
            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS),
            Intent(Settings.ACTION_SETTINGS),
        )
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
                // Try the next fallback.
            }
        }
        return false
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
        private const val WEAR_CONNECTION_EVENT_CHANNEL = "app.dozealert/wear_connection"

        // Must match android_wear_capabilities in the wear module's wear.xml.
        private const val WEAR_CAPABILITY = WearPaths.WEAR_CAPABILITY
    }
}
