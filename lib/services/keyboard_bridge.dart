import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/clip_entry.dart';

/// Pushes the current clip list to the platform side so the system
/// keyboard extension can read it without embedding a Flutter engine.
/// Android: written into a plain SharedPreferences file via MethodChannel.
/// iOS: the extension shares an App Group container; see ios/CopyPastaKeyboard.
class KeyboardBridge {
  static const _channel = MethodChannel('com.calebpierre.copypasta/clip_bridge');

  static Future<void> sync(List<ClipEntry> entries) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final texts = entries.take(30).map((e) => e.text).toList();
    try {
      await _channel.invokeMethod('syncClips', {'json': jsonEncode(texts)});
    } on MissingPluginException {
      // No native handler yet (e.g. running tests, or the iOS host target
      // hasn't added the App Group bridge from AppDelegate.swift).
    }
  }
}
