# DozeAlert Privacy Policy

**Effective date:** June 18, 2026  
**Last updated:** July 12, 2026

**App:** DozeAlert (`app.dozealert`)  
**Developer:** Riaz (Creator of DozeAlert)  
**Contact:** [support@dozealert.app](mailto:support@dozealert.app)  
**Website:** [https://dozealert.app](https://dozealert.app)

This Privacy Policy describes how DozeAlert (“the app”, “we”, “us”) handles information when you use our Android application. DozeAlert helps you wake up before you reach a selected destination using location-based alerts.

---

## Summary

- **No account required.** We do not operate a user login system.
- **No advertising.** We do not show ads or sell your data.
- **No DozeAlert cloud.** Trip data is stored on your device, not on our servers.
- **Location is essential** for trip monitoring and optional map features.
- **Physical activity (Android)** may be used on transit trips to tell riding from waiting at a platform.
- **Third-party services** (Google Maps Platform and public transit data hosts) may receive limited data when you use those features, as described below.

---

## Information We Collect

### 1. Precise location (GPS)

**What:** Latitude, longitude, speed, accuracy, and timestamps from your device’s location services.

**When:** While you use map features, pick a destination, or run trip monitoring (including in the background when monitoring is active).

**Why:** To measure distance to your destination, trigger approach alerts, support transit-mode stop detection, and show your position on the map.

**Required?** Yes, if you use trip monitoring or map-based destination selection. You can deny permissions, but core features will not work.

**Stored where:** On your device only (for example active destination, monitoring session state, and trip history). We do not upload your live GPS track to DozeAlert servers.

### 2. Physical activity (Android)

**What:** Motion-activity signals from Android’s activity recognition API (for example in a vehicle, walking, or stationary), when you grant the **Physical activity** permission.

**When:** During trip monitoring on Android, if you allow this permission in setup.

**Why:** To help DozeAlert tell when you are riding versus waiting at a station, so wake timing and route detection stay accurate on transit trips.

**Required?** Optional. Off by default — wake uses GPS only. When turned on in Location settings, Android physical activity permission is required.

**Stored where:** Processed on your device during an active trip. We do not upload activity recognition data to DozeAlert servers.

### 3. Destination and trip information you choose

**What:** Destination names, coordinates, alert distance, saved destinations, recent destinations, trip history entries (destination label, start/end times, whether an alarm fired), and monitoring settings.

**Why:** To save your preferences and show trip history inside the app.

**Stored where:** On your device only (local app storage).

### 4. App settings and onboarding state

**What:** Alarm volume preferences, transit agency selections, theme choice, test-mode flags, and whether you completed onboarding steps.

**Why:** To remember how you configured the app.

**Stored where:** On your device only.

### 5. Transit data (GTFS) you download

**What:** Public transit schedule and stop data files downloaded from agency or open-data URLs you choose in the app. Where permitted by an agency's terms, the app may download a GTFS file mirrored on [dozealert.app](https://dozealert.app/gtfs-mirror/) instead of the agency's direct host.

**Why:** To support stop lists, transit mode, and line detection.

**Stored where:** On your device only. Downloads are standard HTTP requests to third-party transit data providers or the DozeAlert website mirror; we do not control third-party agency servers.

### 6. Information sent to third parties when you use certain features

DozeAlert does **not** operate backend servers that collect your personal profile. However, these third parties may receive data when you use related features:

| Service | When it is used | What may be sent |
|--------|------------------|------------------|
| **Google Maps Platform** (Maps SDK, Places) | Map picker, place search, map display | Search queries you type, map tile requests, and location-related data needed to show the map and resolve places. Governed by [Google’s Privacy Policy](https://policies.google.com/privacy). |
| **Public GTFS / open data hosts** | When you download transit feeds | Standard download requests (URL, IP address, device network information). No account is created by DozeAlert. |
| **dozealert.app (GTFS mirror)** | When you download a mirrored transit feed in the app | Standard download requests for the mirrored GTFS file. No account is created. |
| **dozealert.app (transit catalog)** | Periodically (about once per day) when the app checks for catalog updates | A small JSON manifest listing supported transit agencies, download URLs, and license metadata. No account is created. GTFS schedule files are **not** downloaded automatically. |
| **Your chosen share target** | When you tap Share in the app | Only what you explicitly share through Android’s system share sheet (for example a message or link you send). |

We do **not** use analytics, advertising, or crash-reporting SDKs in the production app.

### 7. Support email

If you email [support@dozealert.app](mailto:support@dozealert.app) or use the [website feedback form](https://dozealert.app/feedback/), we receive whatever you choose to include (your email address, message content, and optional screenshots). Feedback is emailed to us via Amazon SES. Google reCAPTCHA may run on the form to reduce spam. We use submissions only to respond and improve the app.

---

## Android Permissions

The app may request these permissions. Each is used only for the stated purpose:

| Permission | Purpose |
|------------|---------|
| **Location (while in use)** | First step for map and monitoring features. |
| **Location (all the time / background)** | Continue trip monitoring when the screen is off or another app is open. |
| **Notifications** | Show the ongoing trip monitoring notification and arrival alerts. |
| **Physical activity** (Android) | Distinguish riding on transit from waiting at a platform during trip monitoring. |
| **Internet** | Map search, GTFS downloads, and HTTPS requests to third-party data sources. |
| **Vibrate** | Approach and alarm vibration. |
| **Foreground service (location)** | Reliable background trip monitoring on Android. |
| **Modify audio settings** | Temporarily adjust media volume during an approach alert, then restore your previous level. |
| **Ignore battery optimizations** (optional) | Improve monitoring reliability on some devices if you approve it. |

You can change or revoke permissions in Android Settings at any time. Revoking location or notification access may stop monitoring or alerts from working.

---

## How We Use Information

We use the information above only to:

- Monitor your progress toward a destination you select
- Sound voice, vibration, and optional alarm alerts
- Show maps, search places, and support transit features you enable
- Save your preferences and trip history on your device
- Respond to support requests you send us

We do **not** use your information for targeted advertising, credit decisions, or selling personal data.

---

## Data Retention and Deletion

- **On-device data** (destinations, history, settings, cached GTFS) remains until you remove it or uninstall the app.
- **Clear** from the Home screen removes your active destination.
- **Clear app storage** (Android Settings → Apps → DozeAlert → Storage → Clear storage) deletes local app data.
- **Uninstall** removes app data from your device.
- **Support emails** are kept only as long as needed to handle your request.

We do not maintain a separate DozeAlert account database to delete.

---

## Data Security

- Network requests to third-party APIs use HTTPS where supported by those services.
- Sensitive signing keys (for example Google Maps API keys in the app build) are not stored in your user data.
- No security method is perfect; keep your device updated and protected with a screen lock.

---

## Children’s Privacy

DozeAlert is not directed at children under 13 (or the minimum age required in your country). We do not knowingly collect personal information from children. If you believe a child has provided information to us, contact [support@dozealert.app](mailto:support@dozealert.app).

---

## International Users

DozeAlert is developed in Canada. If you use the app outside Canada, your information may be processed on your device and by third-party services (such as Google) under their own policies and applicable laws.

If you are in the European Economic Area, United Kingdom, or similar regions, you may have rights to access, correct, or delete personal data we hold about you (primarily via device controls and contacting us). We rely on **contract necessity** and **legitimate interests** to provide the app you requested, and on **consent** where Android prompts you for permissions.

---

## Transit agencies

DozeAlert is an independent app. **We are not affiliated with, endorsed by, or sponsored by any transit agency.** Transit agency names, logos, and schedule data may appear when you choose a supported feed; those references are for identification and open-data attribution only. See **Settings → About → Transit Data Licenses** in the app or [Transit Data Licenses](https://dozealert.app/transit-licenses/) on our website.

---

## Changes to This Policy

We may update this policy when the app or legal requirements change. We will update the “Last updated” date. The current version is always available in the app (Settings → About → Privacy Policy) and at [https://dozealert.app/privacy](https://dozealert.app/privacy).

Continued use of the app after changes means you accept the updated policy.

---

## Contact

Questions about privacy or this policy:

**Email:** [support@dozealert.app](mailto:support@dozealert.app)  
**Website:** [https://dozealert.app](https://dozealert.app)

---

## Google Play Data Safety (summary for transparency)

This summary aligns with how we complete Google Play’s Data safety form:

- **Collected:** Precise location; physical activity signals on Android when permitted; app activity related to destinations/trips stored on device; device permissions status as needed for features.
- **Shared:** Location-related and search data may be processed by **Google** when you use Maps/Places features. Activity recognition data is **not** shared with third parties.
- **Not collected:** Name, email, or payment info through the app itself; advertising ID for ads; health records or financial data.
- **Purpose:** App functionality only.
- **Optional:** Some permissions (for example battery optimization) are optional; trip monitoring on Android requires location and notifications. Physical activity is optional and only used when enabled in Location settings.
- **Deletion:** Uninstall or clear app storage on your device.

For the official store declaration, see the Data safety section on our Google Play listing once published.
