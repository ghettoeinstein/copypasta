import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/services/foundation_model.g.dart',
    swiftOut: 'ios/Runner/FoundationModelApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartOptions: DartOptions(),
  ),
)

/// Availability of Apple's on-device Foundation Models framework. Mirrors
/// `SystemLanguageModel.Availability` on the Swift side. `notEligible`,
/// `notEnabled`, and `notReady` map to `SystemLanguageModel.Availability
/// .unavailable(reason:)`'s three cases — kept distinct so the UI can give
/// the right nudge (turn on Apple Intelligence vs. wait for it to download).
enum FoundationModelAvailability {
  available,
  notEligibleDevice,
  notEnabled,
  modelNotReady,
  unsupportedOS,
}

/// Generated from this schema via:
///   dart run pigeon --input pigeons/foundation_model.dart
/// Re-run that after editing this file — do not hand-edit the .g. outputs.
@HostApi()
abstract class FoundationModelHostApi {
  /// Cheap synchronous check — call before showing any AI-powered UI.
  FoundationModelAvailability checkAvailability();

  /// Starts (or restarts) a session with the given system instructions.
  /// Throws a PlatformException if Foundation Models isn't available.
  @async
  void initializeSession(String instructions);

  /// Sends a prompt through the current session and returns the full
  /// response. Call `initializeSession` first.
  @async
  String generateResponse(String prompt);
}
