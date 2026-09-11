import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The design canvas only ever mocked a dark surface, so CopyPasta ships
/// dark-only for now rather than guessing at a light variant no one drew.
class AppTheme {
  AppTheme._();

  static TextStyle get logo => GoogleFonts.fraunces(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get display => GoogleFonts.fraunces(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get mono => GoogleFonts.ibmPlexMono(
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg,
        primary: AppColors.gold,
        secondary: AppColors.teal,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.ibmPlexSansTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: logo.copyWith(fontSize: 19),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.card,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
