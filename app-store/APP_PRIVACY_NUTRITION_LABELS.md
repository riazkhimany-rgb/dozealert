# App Store Connect — App Privacy (Nutrition Labels)

Use this guide when completing **App Store Connect → Your App → App Privacy** for DozeAlert (`app.dozealert`). Answers must match [privacy_policy.md](../privacy_policy.md) and [https://dozealert.app/privacy](https://dozealert.app/privacy).

**Privacy policy URL:** `https://dozealert.app/privacy`

iOS is phone-only: do **not** declare physical activity / fitness or Wear companion data (Android-only).

---

## Overview questions

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data from this app? | **Yes** |
| Do you or your third-party partners use data for tracking? | **No** |
| Privacy policy URL | `https://dozealert.app/privacy` |

Do **not** enable App Tracking Transparency — the app does not track users across apps/sites for advertising.

---

## Data types to declare

### Location — Precise Location

| Field | Value |
|-------|--------|
| Collected | **Yes** |
| Linked to the user’s identity | **Yes** (saved destinations, active trip, and settings on device) |
| Used for tracking | **No** |
| Purposes | **App Functionality** |
| Third-party partners | **Google** (Maps SDK / Places) when the user uses map display or place search |

Precise GPS is required for trip monitoring (including Always location while a trip is active).

### Location — Coarse Location

**Do not declare** unless you later add features that only use approximate location. The app uses precise GPS for monitoring.

### Contact Info / Identifiers / Purchases / Health & Fitness / Sensitive Info / Contacts / User Content / Browsing History / Diagnostics

| Type | Declare? |
|------|----------|
| Name, Email, Phone, Physical Address, User ID | **No** (no DozeAlert account; support email is outside the app) |
| Device ID / Advertising Data | **No** |
| Health & Fitness / Fitness | **No** on iOS (physical activity is Android-only) |
| Photos, Audio, Files, Contacts, Calendar | **No** |
| Crash Data / Performance Data / Other Diagnostic | **No** (no third-party crash SDK in production) |
| Advertising Data | **No** — no ads |

### Usage Data — Product Interaction / Search History (if the form offers these)

Place search queries typed in the map picker are sent to **Google Places** for App Functionality.

| Field | Value |
|-------|--------|
| Collected | **Yes** (when the user searches places) |
| Linked to identity | **No** account; treat as not linked unless Apple’s form requires “linked” for on-device history — prefer **Not Linked** if search is only sent to Google for that request |
| Used for tracking | **No** |
| Purposes | **App Functionality** |
| Third parties | **Google** |

If the questionnaire only has a generic “Product Interaction” bucket and place search is unclear, declare **Precise Location** thoroughly and mention Maps/Places in the privacy policy (already covered). Prefer declaring search/usage when the UI clearly offers those data types.

---

## Third-party partners

Declare **Google** (Google Maps Platform / Places) for:

- Map tiles and map display
- Place search

Purpose: **App Functionality**. Not sold. Not used for advertising by DozeAlert.

GTFS stop-list downloads use public HTTPS endpoints (transit agencies / open data). No DozeAlert account is attached; typically no separate “partner” beyond the download itself.

---

## What not to declare (iOS)

- Physical activity / fitness (Android-only)
- Wear OS / watch companion
- Analytics SDKs (none in release)
- Advertising identifiers / ATT tracking

---

## Before submitting

1. Confirm `https://dozealert.app/privacy` loads and matches `privacy_policy.md`.
2. Enter the same URL under App Information → Privacy Policy URL.
3. Complete App Privacy using this guide.
4. Age rating: **4+** (no restricted content). Category: **Travel**.
5. Ads: **No**.
6. Sign-in required: **No** (no account).
7. Export compliance: `ITSAppUsesNonExemptEncryption` is set to `false` in Info.plist (HTTPS / standard encryption only).

If App Review flags a mismatch, update the questionnaire to match the live privacy policy — do not hide location or Maps usage that exists in the app.
