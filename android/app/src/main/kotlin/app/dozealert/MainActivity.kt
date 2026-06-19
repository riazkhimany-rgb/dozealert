package app.dozealert

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }
}
