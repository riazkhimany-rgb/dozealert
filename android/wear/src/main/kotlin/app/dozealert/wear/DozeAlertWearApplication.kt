package app.dozealert.wear

import android.app.Application

class DozeAlertWearApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        TripStateRepository.getInstance(this)
    }
}
