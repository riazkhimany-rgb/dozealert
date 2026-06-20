# Google Play Console — Data Safety Form Guide

Use this guide when completing **App content → Data safety** for DozeAlert (`app.dozealert`). Answers must match [privacy_policy.md](../privacy_policy.md) and [https://dozealert.app/privacy](https://dozealert.app/privacy).

**Privacy policy URL:** `https://dozealert.app/privacy`

---

## Overview

| Question | Answer |
|----------|--------|
| Does your app collect or share user data? | **Yes — data is collected** (and limited data is shared with third parties for app functionality) |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS for Google APIs and GTFS downloads) |
| Do you provide a way for users to request data deletion? | **Yes** — uninstall app or clear storage (no DozeAlert account). Support: support@dozealert.app |
| Is your app designed for children? | **No** |

---

## Data types to declare

### Location — Precise location

| Field | Value |
|-------|--------|
| Collected | **Yes** |
| Shared | **Yes** (with Google when Maps/Places features are used) |
| Ephemeral | **No** (stored on device for active trip/settings; Google processes per their policy) |
| Required | **Yes** for trip monitoring |
| Purpose | **App functionality** |
| User can choose not to share | **No** for core monitoring (optional only if user does not use monitoring/maps) |

### Location — Approximate location

| Field | Value |
|-------|--------|
| Collected | **Optional / No** if form allows skip — app primarily uses **precise** GPS. If required to pick one, declare **Precise** only. |

### Personal info

| Type | Collected? |
|------|------------|
| Name, Email, User IDs, Address, Phone, etc. | **No** (unless user emails support outside the app) |

### Financial info, Health, Messages, Photos, Audio files, Calendar, Contacts

**No** — not collected by the app.

### App activity

| Field | Value |
|-------|--------|
| In-app search history (place search) | **Optional:** Some forms include “App interactions” — if shown, **Yes** for place search queries sent to Google; purpose **App functionality**; not used for advertising. |
| Other analytics | **No** — no Firebase Analytics / similar in release build. |

### App info and performance — Crash logs / Diagnostics

**No** — no third-party crash SDK in production release.

### Device or other IDs

**No** — DozeAlert does not collect advertising ID or device IDs for tracking.

---

## Third-party data sharing

Declare **Google** (Google Maps Platform / Places) when users use map search or map display:

- **Purpose:** App functionality  
- **Not sold**  
- **Not used for advertising**

GTFS downloads: public HTTP endpoints (transit agencies / open data). Typically declare as **data not linked to user identity** (no account); optional note in policy only.

---

## Security practices (Play Console)

- Data encrypted in transit: **Yes**
- Users can request deletion: **Yes** (device storage / uninstall; contact support@dozealert.app)

---

## Permissions alignment (Store listing)

Ensure listing text matches required permissions:

- Location — **All the time** (background monitoring)
- Notifications
- Foreground service (location)

---

## Before submitting

1. Upload `website/privacy/index.html` with the site so `https://dozealert.app/privacy` loads.
2. Enter the same URL in Play Console **Privacy policy**.
3. Complete **Data safety** using the table above.
4. In **App access**, note if testers need instructions (no login required).
5. **Ads:** No, app does not contain ads.
6. **Target audience:** Not designed for children under 13.

If Google rejects a mismatch, adjust the form to match the live policy — do not change the policy to hide data uses that exist in the app.
