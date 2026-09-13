# CopyPasta — PM Status Report

**Date:** 2026-09-11
**Repo:** [ghettoeinstein/copypasta](https://github.com/ghettoeinstein/copypasta) (public)
**Stage:** Working prototype, running standalone on one physical device (iPhone "EMPEROR"). Not yet submittable to either app store.

---

## 1. What it is

A personal, local-only clipboard manager with a system keyboard extension on iOS and Android. Two jobs:

1. Keep a searchable, auto-tagged history of copied text (links, code, email, phone, plain text).
2. Convert any clip into "fancy" Unicode-styled text (bold/italic/script/monospace/small-caps) in one tap, and surface both the clip history and the style row **inside the system keyboard itself** — not just inside the app.

No accounts, no backend, no team/shared state. Single user, on-device, by design.

---

## 2. Current feature state

| Feature | Status |
|---|---|
| Clip capture (manual paste / typed) | ✅ Working |
| Auto content-type detection (URL/email/phone/code/text) | ✅ Working (regex-based) |
| Search + filter chips | ✅ Working |
| Pin / unpin, swipe-to-delete | ✅ Working |
| Unicode text styler (bold/italic/script/mono/small-caps/etc.) | ✅ Working, ported natively to Kotlin + Swift too |
| Drag-to-reorder clip list | ✅ Working — custom spring/elastic pick-up animation, not stock `ReorderableListView` feel |
| Auto-clear old unpinned clips (2h) | ✅ Working (settings toggle) |
| Android system keyboard (IME) | ✅ Fully wired, installs with the app, no manual steps |
| iOS system keyboard extension | ⚠️ Source code complete (Swift), but the Xcode target itself must still be added by hand — one-time manual step, documented, not done yet |
| On-device AI summarize (Apple Foundation Models) | ✅ Working via Pigeon-typed bridge, gated behind a live availability check — requires iOS 26 + Apple Intelligence-eligible hardware |
| App icon / launcher icon (both platforms) | ✅ Generated, App Store/Play compliant (alpha-stripped 1024 icon, Android adaptive icon) |
| Android release signing | ❌ Not done — currently falls back to debug key, which Play Console will reject |
| iOS distribution signing | ❌ Free-tier personal signing only (7-day expiry); no paid Apple Developer Program enrollment yet |
| Store listing assets | ❌ Not started (screenshots, description, privacy policy) |

**Bottom line:** functionally complete for personal use today (it's literally running on a personal phone right now). Not submittable to either store yet — that's a checklist of account/signing/asset work, not engineering risk.

---

## 3. Technical architecture, top to bottom

### Why three codebases instead of one

A real system keyboard extension cannot run a Flutter engine — iOS keyboard extensions in particular have a hard memory ceiling that a Flutter engine blows past. So the app is split into three cooperating pieces that share data through native OS mechanisms instead of a network call:

```
┌─────────────────────────────┐
│      Flutter host app       │  ← source of truth, all UI, all writes
│   (lib/) — Dart, ~1,900 LOC │
└──────────────┬──────────────┘
               │ MethodChannel: "com.calebpierre.copypasta/clip_bridge"
               │ (one-directional: host writes, extensions read)
     ┌─────────┴─────────┐
     ▼                   ▼
┌─────────┐        ┌───────────┐
│ Android │        │    iOS    │
│   IME   │        │  Keyboard │
│ (Kotlin)│        │Extension  │
│         │        │ (Swift)   │
└─────────┘        └───────────┘
reads from          reads from
SharedPreferences   App Group
                    UserDefaults
```

### Layer 1 — Flutter host app (`lib/`)

- **State/storage**: [Hive](https://pub.dev/packages/hive) (`clip_store.dart`) — an embedded NoSQL box, not SQL. Every `ClipEntry` has a UUIDv4 primary key, a `sortOrder` field for manual drag-reordering, `pinned`, `createdAt`, and a `typeIndex` (URL/email/phone/code/text/styled).
- **Classification**: regex-based (`detectClipType`) — no ML, no network call, instant.
- **UI**: single `HomeScreen` (list + search + filter chips + FAB), two bottom sheets (`AddClipSheet`, `StyleSheet`), one secondary screen (`SyncScreen` — settings/privacy). Dark/gold design system (`theme/app_colors.dart`, `app_theme.dart`) shared conceptually with the native keyboard extensions so the whole product looks like one thing.
- **Text styling engine** (`utils/text_styler.dart`): maps ASCII to Unicode Mathematical Alphanumeric code points (bold/italic/script/monospace) plus small-caps and fullwidth lookup tables. This is the actual mechanism "fancy text" keyboards use, since real rich-text markup can't render in plain-text fields (SMS, most social apps).
- **On-device AI** (`services/apple_foundation_service.dart`): thin Dart wrapper around a Pigeon-generated typed API (see Layer 4).

### Layer 2 — Sync bridge

- One `MethodChannel`, one method (`syncClips`), fired after every mutation in `ClipStore` (add/delete/pin/clear/purge).
- Payload: JSON array of the 30 most recent clip texts (not full objects — extensions only need to display and insert text, not manage full records).
- Deliberately dumb: single writer (the host app), no conflict resolution, no bidirectional sync needed.

### Layer 3 — Android keyboard extension

- `CopyPastaInputMethodService.kt`, a real `InputMethodService` registered in the manifest — ships in the same APK, no separate install.
- Reads clips from a plain `SharedPreferences` file (`copypasta_shared`) that `MainActivity.kt`'s channel handler writes to.
- Carries its own Kotlin port of the Unicode styler (`FancyTextStyler`) — no Flutter engine dependency at all in the keyboard process.
- **Fully installable and testable today** via Settings → System → Languages & input.

### Layer 4 — iOS keyboard extension + Foundation Models bridge

- `KeyboardViewController.swift` (Custom Keyboard Extension) reads clips from an **App Group** `UserDefaults` suite (`group.com.calebpierre.copypasta`), written by `AppDelegate.swift`. Same Unicode styler, ported to Swift (`FancyTextStyler.swift`).
- **Manual step outstanding**: this extension's Xcode target must be added by hand (File → New Target → Custom Keyboard Extension, then wire in the existing source files + App Group capability). A CLI/agent can't safely inject a new target into `project.pbxproj` blind — this project's pbxproj predates Xcode's auto-sync-groups format, so even the two Foundation Models Swift files required careful manual `PBXBuildFile`/`PBXFileReference`/Sources-phase edits this session, verified by intentionally getting a real compiler error first, then fixing it.
- **Apple Foundation Models integration**: typed via [Pigeon](https://pub.dev/packages/pigeon) (`pigeons/foundation_model.dart` → generates `lib/services/foundation_model.g.dart` + `ios/Runner/FoundationModelApi.g.swift`), rather than hand-rolled string-keyed `MethodChannel` calls. `FoundationModelHandler.swift` implements it against `LanguageModelSession`/`SystemLanguageModel`. Requires iOS 26 + an Apple Intelligence-eligible device — confirmed the hard way (initial `@available(iOS 18.1, *)` guess was wrong; the compiler corrected it). Gated behind a live `checkAvailability()` call so the "AI summarize" button only appears when it will actually work — no stubbed/fake fallback response.

### Cross-cutting

- **Bundle/application ID**: `com.calebpierre.copypasta` on both platforms (consistent, required for the App Group to line up).
- **Icons**: generated via `flutter_launcher_icons` from one source PNG — full iOS `AppIcon.appiconset` (1024 App Store icon alpha-stripped, as Apple requires) and Android adaptive icon (foreground scaled to 66% so it isn't clipped by circular/squircle launcher masks).
- **Signing**: Android release builds are wired to read a keystore from a gitignored `android/key.properties` (not yet generated — that requires a password only the account owner should set, so it was left as a documented manual step rather than fabricated). iOS is on free-tier personal signing (auto-managed, 7-day re-trust cycle).
- **CI/tests**: one Dart unit test file covering the Unicode styler; `flutter analyze` clean, no linter warnings as of the last commit.

---

## 4. Open risks / decisions needed

1. **iOS keyboard extension isn't installed on-device yet** — the app itself runs, but the actual keyboard feature (this product's headline capability) hasn't been manually wired into Xcode. This is the single biggest gap between "demo" and "dogfoodable."
2. **No Android signing keystore** — blocks any real Play Console upload, even internal testing tracks.
3. **Single-device verification only** — everything has been tested on one iPhone (EMPEROR) and via `flutter analyze`/`flutter test`; Android hasn't been verified on a physical device this session (debug APK build succeeded, but no device install/launch confirmed).
4. **Personal Apple Developer account** — fine for personal use, but the free tier means re-signing every ~7 days. Distribution (TestFlight, App Store, or even installing on a second device) needs the paid Program.
5. **Non-goals reaffirmed**: no sync/backend/multi-user has been built, and nothing in this session suggests that should change — the product's value is being fast and fully private, not collaborative.

---

## 5. Recommended next steps, in order

1. Finish the iOS keyboard extension Xcode wiring (manual, ~15 min, steps already written in `README_KEYBOARD_SETUP.md`) — unlocks testing the actual core feature end-to-end.
2. Verify Android on a physical device (not just emulator/build success).
3. Generate the Android release keystore and do one full release-mode install to confirm the signing config path works.
4. Decide on Apple Developer Program enrollment timing — gates any real distribution beyond this one phone.
5. Everything else (store listings, screenshots, privacy policy) is standard submission prep, not blocked on engineering.
