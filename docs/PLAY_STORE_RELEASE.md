# Google Play Release Guide

## Prerequisites

- Flutter SDK (stable)
- Java JDK 17+
- Google Play Developer account
- Google Maps API key (for map features)

## 1. Create upload keystore

From the project root:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Never commit the keystore or passwords to git.**

## 2. Configure signing

Copy the example file and fill in your values:

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

## 3. Configure Google Maps key

Add to `android/local.properties`:

```properties
GOOGLE_MAPS_API_KEY=your_key_here
```

## 4. Build signed App Bundle

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter build appbundle --release
```

Output:

```
build/app/outputs/bundle/release/app-release.aab
```

## 5. Upload to Internal Testing

1. Open [Google Play Console](https://play.google.com/console)
2. Create app **DozeAlert** (applicationId: `app.dozealert`)
3. Complete **Store listing** using files in `play-store/`
4. Set **Privacy policy URL** (see `play-store/PRIVACY_POLICY_URL.txt`)
5. Go to **Testing → Internal testing → Create release**
6. Upload `app-release.aab`
7. Add release notes from `RELEASE_NOTES.txt`
8. Add testers and roll out

## Versioning

Update `pubspec.yaml` before each release:

```yaml
version: 1.0.0+1   # versionName+versionCode
```

## Store assets

| Asset | Path |
| --- | --- |
| App icon 512×512 | `play-store/icon-512.png` |
| Feature graphic | `play-store/feature-graphic-1024x500.png` |
| Short description | `play-store/SHORT_DESCRIPTION.txt` |
| Full description | `play-store/FULL_DESCRIPTION.txt` |
| Privacy policy (source) | `privacy_policy.md` |
| Privacy policy (public URL) | `https://dozealert.app/privacy` |
| Data safety form guide | `play-store/DATA_SAFETY_PLAY_CONSOLE.md` |

## Privacy policy and Data safety

Before publishing:

1. Deploy `website/` so **https://dozealert.app/privacy** loads (`website/privacy/index.html`).
2. In Play Console → **App content** → **Privacy policy**, enter `https://dozealert.app/privacy`.
3. Complete **Data safety** using `play-store/DATA_SAFETY_PLAY_CONSOLE.md` (must match `privacy_policy.md`).
4. Declare **Precise location** (collected + shared with Google for Maps/Places), **no ads**, **no account**.

The in-app policy (Settings → About → Privacy Policy) loads `privacy_policy.md` from the app bundle — keep it in sync with the website.
