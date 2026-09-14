package app.dozealert.wear

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper

/**
 * Wear branded launch (WO-V15): shows the 48dp launcher icon on black before
 * [MainActivity].
 *
 * `Theme.DozeAlert.Splash` gives the platform splash on API 31+ and a matching
 * `windowBackground` below that; holding [R.layout.activity_splash] afterwards
 * guarantees an explicitly painted icon for Play review automation, which
 * screenshots cold start and can otherwise catch a system splash that dismisses
 * in a single frame. Every path draws @mipmap/ic_launcher, so the frames are
 * visually identical.
 */
class SplashActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private val advance = Runnable {
        if (isFinishing) {
            return@Runnable
        }
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
        )
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)
        // Long enough for humans and Play WO-V15 automation to capture the icon.
        handler.postDelayed(advance, SPLASH_HOLD_MS)
    }

    override fun onDestroy() {
        handler.removeCallbacks(advance)
        super.onDestroy()
    }

    companion object {
        private const val SPLASH_HOLD_MS = 2_000L
    }
}
