import 'dart:io';

import 'package:flutter/services.dart';

import 'foundation_model.g.dart';

/// Typed wrapper around the Pigeon-generated `FoundationModelHostApi`
/// (see pigeons/foundation_model.dart). iOS-only — Apple's on-device
/// Foundation Models framework has no Android equivalent, so every method
/// here is a safe no-op off iOS.
///
/// Requires iOS 26+ on an Apple Intelligence-eligible device (iPhone 15 Pro
/// or later) with Apple Intelligence enabled.
///
/// Personal-tool scope: one session at a time, nothing persisted across
/// app relaunches, no fallback model bundled. If `checkAvailability()`
/// comes back anything other than `.available`, don't show AI-powered UI —
/// don't silently degrade to a stubbed response.
class AppleFoundationService {
  AppleFoundationService._();

  static final _api = FoundationModelHostApi();

  static Future<FoundationModelAvailability> checkAvailability() async {
    if (!Platform.isIOS) return FoundationModelAvailability.unsupportedOS;
    try {
      return await _api.checkAvailability();
    } on PlatformException {
      return FoundationModelAvailability.unsupportedOS;
    }
  }

  /// Starts (or restarts) a session. Call once before `generateResponse`,
  /// and again if you need to change the system instructions.
  static Future<bool> initSession({required String systemPrompt}) async {
    if (!Platform.isIOS) return false;
    try {
      await _api.initializeSession(systemPrompt);
      return true;
    } on PlatformException {
      return false;
    }
  }

  /// Returns null on any failure (unavailable, no session, inference
  /// error) — callers should treat null as "skip the AI feature", not
  /// retry in a loop.
  static Future<String?> generateResponse(String prompt) async {
    if (!Platform.isIOS) return null;
    try {
      return await _api.generateResponse(prompt);
    } on PlatformException {
      return null;
    }
  }
}
