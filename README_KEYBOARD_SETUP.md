# Wiring up the system keyboard extensions

This repo has the Flutter host app fully working (`flutter run`), plus native
keyboard-extension source files that need a one-time manual step per platform
because generating an Xcode target from the CLI isn't safe to do blind.

## Android — nothing extra needed

The IME (`CopyPastaInputMethodService`) is already registered in
`android/app/src/main/AndroidManifest.xml` and ships inside the same APK.
After `flutter run` installs the app once:

1. Settings → System → Languages & input → On-screen keyboard → Manage
   keyboards → enable **CopyPasta**.
2. Switch to it from any text field's keyboard-switcher icon.

## iOS — add the extension target in Xcode

Flutter/CLI can't safely inject a new target into `Runner.xcodeproj`'s
`project.pbxproj`, so do this once in Xcode:

1. `open ios/Runner.xcworkspace`
2. File → New → Target… → **Custom Keyboard Extension** → name it
   `CopyPastaKeyboard`.
3. Xcode creates a new folder/target — delete the placeholder
   `KeyboardViewController.swift` and `Info.plist` it generates, then drag in
   the real ones from `ios/CopyPastaKeyboard/` (this repo already has
   `KeyboardViewController.swift`, `FancyTextStyler.swift`, `Info.plist`) and
   add them to the `CopyPastaKeyboard` target.
4. Select the `Runner` target → Signing & Capabilities → **+ Capability** →
   App Groups → add `group.com.calebpierre.copypasta`.
5. Select the `CopyPastaKeyboard` target → Signing & Capabilities → App
   Groups → add the same group ID.
6. Build & run `Runner` on a device/simulator, then:
   Settings → General → Keyboard → Keyboards → Add New Keyboard… →
   **CopyPasta** → tap it again → enable **Allow Full Access** (required to
   read/write the shared App Group storage used for the clip history).

## How sync works

- The Flutter app writes every clip to Hive locally (`ClipStore`) and, on
  every change, calls `KeyboardBridge.sync` which pushes the latest ~30 clips
  as a JSON string via a `MethodChannel` to native code.
- Android: `MainActivity.kt` writes that JSON into a `SharedPreferences` file
  the `CopyPastaInputMethodService` reads directly.
- iOS: `AppDelegate.swift` writes it into `UserDefaults(suiteName:)` for the
  shared App Group, which `KeyboardViewController.swift` reads directly.
- Both extensions also embed a small Unicode "fancy text" styler
  (`FancyTextStyler`) so bold/italic/script/monospace/small-caps formatting
  works without needing the Flutter engine inside the memory-constrained
  keyboard process.
