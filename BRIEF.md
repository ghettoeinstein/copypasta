# CopyPasta — Product Brief

For any agent picking up work in this repo. Read this before making changes.

## What this is

A personal, cross-platform clipboard manager with a **system keyboard
extension** on iOS and Android. Not a team/enterprise tool — single user,
local-only, no backend, no accounts.

Core jobs:
1. Keep a searchable history of copied text, auto-tagged by content type
   (URL, email, phone, code, plain text).
2. Let the user convert any clip into "fancy" Unicode-styled text (bold,
   italic, script, monospace, small caps, etc.) in one tap — the same trick
   used by third-party "fancy text" keyboards, since real rich text can't
   render in plain-text fields (SMS, most social apps).
3. Surface both of the above — clip history and the style row — as an
   accessory strip inside the **system keyboard itself**, so the user never
   has to leave whatever app they're typing in.

## Non-goals (don't build these unless explicitly asked)

- No shared/team clipboard, no multi-user sync, no accounts — local-only by
  deliberate choice.
- No backend/server. All state lives on-device (Hive on the Flutter side,
  SharedPreferences/UserDefaults App Group on the native side).
- Not attempting a full custom keyboard layout (no QWERTY rebuild) — only an
  accessory row that sits above the system keyboard.

## Architecture

Three cooperating pieces, because a real system keyboard extension can't
run a Flutter engine (iOS keyboard extensions have a hard memory ceiling):

1. **Flutter host app** (`lib/`) — the actual UI: clip list, search/filter,
   add-clip sheet, text styler sheet, settings, sync screen. Source of
   truth for clip data, stored in Hive (`lib/services/clip_store.dart`).
2. **Android keyboard extension** — a native `InputMethodService`
   (`android/.../CopyPastaInputMethodService.kt`) bundled in the same APK.
   Reads clips from a plain `SharedPreferences` file the host app pushes to
   via a `MethodChannel` (`MainActivity.kt` ↔ `lib/services/keyboard_bridge.dart`).
   Has its own Kotlin port of the Unicode styler (`FancyTextStyler`) so it
   needs no Flutter engine.
3. **iOS keyboard extension** — a native Custom Keyboard Extension target
   (`ios/CopyPastaKeyboard/`, Swift). Reads clips from an **App Group**
   `UserDefaults` suite (`group.com.calebpierre.copypasta`) that
   `AppDelegate.swift` writes to via the same `MethodChannel` name. Also has
   its own Swift port of the styler (`FancyTextStyler.swift`). **This target
   must be added by hand in Xcode** — see `README_KEYBOARD_SETUP.md` — a
   CLI can't safely inject a new target into `project.pbxproj`.

Sync is one-directional and dumb on purpose: host app writes, extension
reads. No conflict resolution needed because there's only one writer.

## Key files

| File | Role |
|---|---|
| `lib/main.dart` | Home screen: list, search, filters, header |
| `lib/models/clip_entry.dart` | Hive model + `detectClipType()` regex classifier |
| `lib/services/clip_store.dart` | Local Hive CRUD, pin/unpin, auto-clear |
| `lib/services/keyboard_bridge.dart` | Pushes clips to native side after every mutation |
| `lib/services/settings_store.dart` | User prefs (e.g. auto-clear-after-2h) |
| `lib/utils/text_styler.dart` | Unicode "fancy text" mapping (Dart) — canonical version |
| `lib/widgets/style_sheet.dart` | Bottom sheet: type text, tap a style, copies + saves |
| `lib/theme/app_colors.dart`, `app_theme.dart` | Dark/gold palette, shared across app + keyboard mockups |
| `android/.../CopyPastaInputMethodService.kt` | Android IME, Kotlin port of styler |
| `ios/CopyPastaKeyboard/*.swift` | iOS keyboard extension, Swift port of styler |
| `README_KEYBOARD_SETUP.md` | Manual Xcode steps + submission compliance checklist |

**Important**: the Unicode styler exists in three languages (Dart, Kotlin,
Swift) that must stay in sync. If you change the style mapping, update all
three.

## Design system

Dark background (`#0B0C0E`), cream text (`#EDE6D6`), gold accent
(`#D9A441`), teal/orange/danger secondary accents. Monospace font for
metadata/labels (`AppTheme.mono`), matches a set of design-canvas mockups
(Main/Keyboard/Context/Emoji/Sync screens) that this implementation follows.

## Platform status

- **Android**: fully wired, installable end-to-end from a single `flutter
  run` — IME registered in the manifest, no manual steps.
- **iOS**: host app builds and runs (`flutter run` / installed standalone
  via `devicectl` on device "EMPEROR"). Keyboard extension target still
  needs one-time manual Xcode setup (not yet done as of this brief).
- **Submission compliance**: app icon generated for both platforms via
  `flutter_launcher_icons` (iOS 1024 icon alpha-stripped, Android adaptive
  icon layers). Android release signing wired to a gitignored
  `key.properties`/keystore (not yet generated — currently falls back to
  debug signing, which Play Console will reject). iOS needs a paid Apple
  Developer Program enrollment for anything beyond 7-day free-tier installs.

## Repo / remote

`git@github.com:ghettoeinstein/copypasta` (public). Bundle ID / applicationId
on both platforms: `com.calebpierre.copypasta`.

## In progress

Drag-and-drop reordering of the clip list with fluid spring physics (not
just Flutter's default `ReorderableListView` — a custom
`Draggable`/`SpringSimulation`-driven interaction) is being added next.
