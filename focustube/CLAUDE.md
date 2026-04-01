# FocusTube — Claude Code Guide

## Build & Run

Flutter must be installed (`flutter --version` ≥ 3.13).

```bash
# First time: generate platform boilerplate (android/, ios/, linux/, etc.)
flutter create . --project-name focustube --org com.example

# Install dependencies
flutter pub get

# Run
flutter run -d chrome      # web (fastest iteration)
flutter run -d android
flutter run -d ios          # macOS only
```

Before running on web, fill in `web/index.html`:
```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">
```
See `SETUP.md` for the full Google Cloud / OAuth credential setup.

## Architecture

```
lib/
├── main.dart          # Entry point; ChangeNotifierProvider(AuthService)
│                      # + ProxyProvider(AuthService → YouTubeService)
├── core/
│   ├── theme.dart     # Material 3 dark theme + shared color constants
│   └── utils.dart     # formatCount(), timeAgo(), formatDate()
├── models/
│   ├── video.dart     # Video DTO; isShort getter (duration ≤ 65s)
│   └── comment.dart   # Comment DTO
├── services/
│   ├── auth_service.dart    # GoogleSignIn ChangeNotifier; getAuthHeaders()
│   └── youtube_service.dart # YouTube Data API v3 HTTP client + in-memory cache
├── screens/
│   ├── login_screen.dart    # Google Sign-In UI
│   ├── home_screen.dart     # Subscription feed; infinite scroll via _scrollController
│   ├── search_screen.dart   # Search results; infinite scroll
│   └── watch_screen.dart    # Video player + metadata + comments; NO sidebar
└── widgets/
    ├── video_card.dart      # Thumbnail + duration badge + info
    └── comment_card.dart    # Author avatar + text + likes
```

## Key Design Decisions

**No recommendations** — `watch_screen.dart` intentionally has no sidebar. On wide screens
the right column shows a static "No recommendations" banner.

**Shorts filtering** — `Video.isShort` returns `true` when `contentDetails.duration` ≤ 65 s
(ISO 8601 PT##S/M/H parsed in `video.dart`). Applied in both feed and search in
`youtube_service.dart` after a batch `videos.list` call.

**YouTube player** — `youtube_player_iframe` with `privacyEnhancedMode: true`
(uses `youtube-nocookie.com`) and `rel: false` (related videos limited to same channel).

**Caching** — `YouTubeService._cache` is a plain `Map` with expiry timestamps.
Feed: 30 min, search: 10 min, video details: 1 h, channel: 6 h, comments: 15 min.
The cache lives on the `YouTubeService` instance; it resets if the user signs out (because
`ProxyProvider` creates a new `YouTubeService` when `AuthService` notifies).

**Quota** — YouTube Data API default is 10 000 units/day.
- `search.list` costs 100 units/call — discourage aggressive searching.
- Feed is ~20 units per page (1 subscriptions + 1 channels + ~15 playlistItems + ~3 videos).
- Everything else is 1 unit per call.

## Adding a New Screen

1. Create `lib/screens/my_screen.dart` extending `StatefulWidget` or `StatelessWidget`.
2. Access services with `context.read<YouTubeService>()` / `context.read<AuthService>()`.
3. Push the route from the relevant screen — this app uses plain `MaterialPageRoute`,
   no named routes.

## Modifying the Feed Logic

`YouTubeService.getFeed()` in `lib/services/youtube_service.dart`:
- `_maxFeedChannels = 15` — channels processed per subscription page (adjust for quota).
- `_videosPerChannel = 5` — recent uploads fetched per channel.
- Filtering happens after `_batchVideoDetails(videoIds)` which calls `videos.list` once.

## Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Sign-in popup doesn't appear on web | Missing client ID meta tag | Edit `web/index.html` |
| `401` errors | OAuth token expired | Sign out and sign back in |
| Empty feed | No subscriptions, or all recent uploads are Shorts | Expected; try searching |
| `quotaExceeded` errors | Exceeded 10 000 units/day | Wait 24 h or raise quota in Cloud Console |
| Player blank on mobile | WebView not configured | Run `flutter pub get`; ensure `webview_flutter` transitive dep is present |
