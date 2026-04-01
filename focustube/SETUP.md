# FocusTube — Setup Guide

A distraction-free YouTube wrapper built with Flutter.
- No Shorts, no recommendations
- Your subscriptions feed only
- Search any topic
- Watch with description & comments — nothing else

---

## Prerequisites

- Flutter SDK >= 3.13 (`flutter --version`)
- A Google account
- A Google Cloud project (free)

---

## Step 1 — Google Cloud Project

1. Go to [console.cloud.google.com](https://console.cloud.google.com/)
2. Create a new project (e.g. "FocusTube")
3. Enable the **YouTube Data API v3**:
   - APIs & Services → Library → search "YouTube Data API v3" → Enable

---

## Step 2 — OAuth 2.0 Credentials

Go to **APIs & Services → Credentials → Create Credentials → OAuth 2.0 Client ID**.

### Web client (required for Flutter Web)
- Application type: **Web application**
- Name: `FocusTube Web`
- Authorised JavaScript origins: `http://localhost` and `http://localhost:PORT`
- Authorised redirect URIs: `http://localhost` (Flutter web uses postMessage, not redirects)
- Copy the **Client ID** — you'll need it in `web/index.html`

### Android client (for Android app)
- Application type: **Android**
- Package name: `com.example.focustube` (match your `android/app/build.gradle`)
- SHA-1 fingerprint: run `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`

### iOS client (for iOS app)
- Application type: **iOS**
- Bundle ID: `com.example.focustube` (match your `ios/Runner/Info.plist`)

---

## Step 3 — Configure the App

### Web
Open `web/index.html` and replace:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```
with your actual Web Client ID.

### Android
Place `google-services.json` in `android/app/` (download from Firebase Console, or create
a minimal one with just the OAuth client ID — see Google docs).

### iOS
Place `GoogleService-Info.plist` in `ios/Runner/` and add the reversed client ID to
`ios/Runner/Info.plist` as a URL scheme:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

---

## Step 4 — Generate platform boilerplate

If you cloned this repo without the `android/`, `ios/`, `linux/`, `macos/`, `windows/`
directories, generate them:

```bash
flutter create . --project-name focustube --org com.example
```

This leaves your `lib/` and `pubspec.yaml` intact and only creates missing platform files.

---

## Step 5 — Run the app

```bash
flutter pub get

# Web
flutter run -d chrome

# Android (with device/emulator connected)
flutter run -d android

# iOS (macOS only)
flutter run -d ios
```

---

## YouTube API Quota

The YouTube Data API v3 has a default quota of **10,000 units/day** per project.
FocusTube is designed to be quota-efficient:
- Results are cached (feed: 30 min, search: 10 min, video: 1 hour)
- The feed loads 15 channels at a time with pagination
- Search costs ~100 units per query — use it thoughtfully

You can monitor usage in Google Cloud Console → APIs & Services → YouTube Data API v3 → Quotas.

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, providers
├── core/
│   ├── theme.dart             # Dark theme, colors
│   └── utils.dart             # Format helpers (counts, dates)
├── models/
│   ├── video.dart             # Video model + shorts filter
│   └── comment.dart           # Comment model
├── services/
│   ├── auth_service.dart      # Google Sign-In (ChangeNotifier)
│   └── youtube_service.dart   # YouTube Data API v3 client
├── screens/
│   ├── login_screen.dart      # Sign-in page
│   ├── home_screen.dart       # Subscription feed
│   ├── search_screen.dart     # Search results
│   └── watch_screen.dart      # Video player + metadata + comments
└── widgets/
    ├── video_card.dart        # Thumbnail + info card
    └── comment_card.dart      # Single comment row
```
