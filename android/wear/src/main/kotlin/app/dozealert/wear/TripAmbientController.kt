package app.dozealert.wear

import androidx.activity.ComponentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.wear.ambient.AmbientLifecycleObserver

/**
 * Enables Wear OS always-on (dim ambient) mode while a trip is being monitored so the
 * trip screen stays visible instead of returning to the watch face.
 */
class TripAmbientController(
    private val activity: ComponentActivity,
    private val onAmbientChanged: (Boolean) -> Unit,
) {
    private var ambientObserver: AmbientLifecycleObserver? = null
    private var enabled = false

    private val teardownObserver = LifecycleEventObserver { _, event ->
        if (event == Lifecycle.Event.ON_DESTROY) {
            disable()
        }
    }

    init {
        activity.lifecycle.addObserver(teardownObserver)
    }

    fun sync(shouldEnable: Boolean) {
        if (shouldEnable) {
            enable()
        } else {
            disable()
        }
    }

    private fun enable() {
        if (enabled) {
            return
        }

        enabled = true
        if (ambientObserver != null) {
            return
        }

        ambientObserver = AmbientLifecycleObserver(
            activity,
            object : AmbientLifecycleObserver.AmbientLifecycleCallback {
                override fun onEnterAmbient(
                    ambientDetails: AmbientLifecycleObserver.AmbientDetails,
                ) {
                    onAmbientChanged(true)
                }

                override fun onExitAmbient() {
                    onAmbientChanged(false)
                }
            },
        ).also { observer ->
            activity.lifecycle.addObserver(observer)
        }
    }

    private fun disable() {
        if (!enabled) {
            return
        }

        enabled = false
        onAmbientChanged(false)
        ambientObserver?.let { observer ->
            activity.lifecycle.removeObserver(observer)
        }
        ambientObserver = null
    }
}
