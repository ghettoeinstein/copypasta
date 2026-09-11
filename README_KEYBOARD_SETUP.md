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

## Submission compliance checklist

App icon (`assets/icon/app_icon.png`, from `copypasta.jpeg`) has been run
through `flutter_launcher_icons` and is wired into both platforms:

- **iOS**: full `AppIcon.appiconset` regenerated, including the 1024×1024
  App Store icon with its alpha channel stripped (Apple rejects icons with
  transparency).
- **Android**: legacy `mipmap-*` icons plus a proper adaptive icon
  (`ic_launcher_foreground`/`ic_launcher_background`, artwork scaled to 66%
  so it isn't clipped by circular/squircle launcher masks).

Re-run `dart run flutter_launcher_icons` any time you swap
`assets/icon/app_icon.png` (or regenerate
`assets/icon/app_icon_foreground.png` — see the Pillow snippet in git
history — if you change the artwork's padding needs).

Still required before you can actually submit:

1. **Android release signing** (blocks Play Console upload — release builds
   currently fall back to the debug key, which Google will reject):
   ```bash
   keytool -genkey -v -keystore ~/copypasta-upload-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias copypasta
   ```
   Then create `android/key.properties` (already gitignored) with:
   ```properties
   storePassword=<password you set above>
   keyPassword=<password you set above>
   keyAlias=copypasta
   storeFile=/Users/you/copypasta-upload-key.jks
   ```
   `android/app/build.gradle.kts` picks this up automatically once the file
   exists.
2. **iOS**: Apple Developer Program enrollment + a distribution
   certificate/provisioning profile in Xcode (Signing & Capabilities →
   switch off "Automatically manage signing" only if you need a specific
   profile for the keyboard extension's App Group entitlement).
3. Store listing assets (screenshots, description, privacy policy URL) —
   not something a build step can generate for you.

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
