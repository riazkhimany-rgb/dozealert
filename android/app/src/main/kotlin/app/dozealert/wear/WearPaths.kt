package app.dozealert.wear

object WearPaths {
    const val TRIP_STATE = "/trip_state"

    /** Must match android_wear_capabilities in the wear module's wear.xml. */
    const val WEAR_CAPABILITY = "dozealert_wear_app"

    const val CMD_START_MONITORING = "/cmd/start_monitoring"
    const val CMD_STOP_MONITORING = "/cmd/stop_monitoring"
    const val CMD_DISMISS_ALARM = "/cmd/dismiss_alarm"
    const val CMD_OPEN_PHONE = "/cmd/open_phone"
    const val CMD_OPEN_WATCH = "/cmd/open_watch"

    const val EXTRA_WEAR_COMMAND = "wear_command"
}
