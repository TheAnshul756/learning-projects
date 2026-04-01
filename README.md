# Learning Projects

A collection of small projects built to explore new programming concepts and technologies.

---

## Projects

### [`flutter_codelab/`](./flutter_codelab)
**Flutter codelab starter app** — built by following the official
[Write your first Flutter app](https://docs.flutter.dev/get-started/codelab) tutorial.
Covers Flutter basics: stateful widgets, `provider` for state management, and the
`english_words` package to generate random word pairs. Good starting point for understanding
Flutter's widget tree and hot reload workflow.

**Stack:** Flutter, Dart, Provider

---

### [`focustube/`](./focustube)
**Distraction-free YouTube wrapper** — a Flutter app (Android, iOS, Web) that wraps the
YouTube Data API v3 to strip away everything YouTube uses to keep you watching longer.

What it keeps:
- Your subscription feed (no algorithm, just chronological uploads)
- Search (you decide what to look for)
- Full video player with description and comments

What it removes:
- YouTube Shorts (filtered by duration ≤ 65 s)
- Recommended / related videos (no sidebar, no end-screen suggestions in the UI)
- Autoplay, trending, and homepage algorithm content

**Stack:** Flutter, Dart, YouTube Data API v3, Google Sign-In (OAuth2), `youtube_player_iframe`

**Setup:** See [`focustube/SETUP.md`](./focustube/SETUP.md) — requires a Google Cloud project
with YouTube Data API v3 enabled and OAuth 2.0 credentials.

---

## Contributing

1. Fork this repository.
2. Create a branch for your changes.
3. Commit and push, then open a pull request with a description of what you added.

Each project lives in its own directory with all necessary files.

## License

MIT — see [LICENSE](./LICENSE).

## Contact

Questions or feedback: anshulasawa2011+github@gamil.com
