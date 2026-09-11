import 'package:flutter/material.dart';

/// CopyPasta's dark palette. Mirrors the values baked into the design
/// canvas mockups (Main/Keyboard/Context/Emoji/Sync) so the shipped app,
/// the keyboard extension, and the design source all agree on one look.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0B0C0E);
  static const bgFooter = Color(0xFF111318);
  static const card = Color(0xFF15171B);
  static const chip = Color(0xFF1B1D22);

  static const border = Color(0x14EDE6D6); // rgba(237,230,214,0.08)
  static const borderStrong = Color(0x24EDE6D6); // 0.14
  static const borderFocus = Color(0x1FEDE6D6); // 0.12

  static const textPrimary = Color(0xFFEDE6D6); // cream
  static const textSecondary = Color(0xFFA79C89); // muted tan
  static const textPlaceholder = Color(0xFF5B5142); // dark tan

  static const gold = Color(0xFFD9A441);
  static const teal = Color(0xFF3E8FA3);
  static const tealBright = Color(0xFF4E9CAE);
  static const success = Color(0xFF8FBF8F);
  static const orange = Color(0xFFC97A44);
  static const codeText = Color(0xFFC9A876);
  static const danger = Color(0xFFE0665C);
}
