import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The small mono-font outlined pill used for clip metadata ("Link",
/// "Code", "Pinned", …) in the design's card list.
class TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const TagPill({super.key, required this.label, this.color = AppColors.codeText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.mono.copyWith(fontSize: 10, letterSpacing: 0.5, color: color),
      ),
    );
  }
}

/// The small rounded-square glyph that stands in for a source app's icon
/// (Figma "Fg", Terminal "Tm", Mail "Ml", …).
class SourceGlyph extends StatelessWidget {
  final String initials;
  final Color tint;
  final Color background;

  const SourceGlyph({
    super.key,
    required this.initials,
    required this.tint,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(7)),
      child: Text(initials, style: AppTheme.mono.copyWith(fontSize: 11, color: tint)),
    );
  }
}
