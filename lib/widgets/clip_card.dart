import 'package:flutter/material.dart';

import '../models/clip_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/relative_time.dart';
import 'tag_pill.dart';

class _TypeStyle {
  final String initials;
  final Color tint;
  final Color glyphBg;
  final String label;

  const _TypeStyle(this.initials, this.tint, this.glyphBg, this.label);
}

const _typeStyles = <ClipType, _TypeStyle>{
  ClipType.url: _TypeStyle('Ln', AppColors.tealBright, Color(0xFF12232A), 'Link'),
  ClipType.code: _TypeStyle('{ }', AppColors.gold, Color(0xFF241B0E), 'Code'),
  ClipType.email: _TypeStyle('Ml', AppColors.success, Color(0xFF1B241B), 'Email'),
  ClipType.phone: _TypeStyle('Ph', AppColors.orange, Color(0xFF241826), 'Phone'),
  ClipType.styledText: _TypeStyle('Aa', AppColors.orange, Color(0xFF241826), 'Styled'),
  ClipType.plainText: _TypeStyle('Tx', AppColors.textSecondary, AppColors.chip, 'Text'),
};

/// A single clip rendered as the dark, bordered card from the design's
/// main list — source glyph, relative time, snippet (mono for code), and
/// tag pills, with a gold highlight when pinned.
class ClipCard extends StatelessWidget {
  final ClipEntry entry;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onStyle;

  /// When set, shown as a drag handle that starts a reorder gesture — only
  /// meaningful while the list is in its unfiltered, unsearched order (see
  /// `HomeScreen._buildList`).
  final Widget? dragHandle;

  const ClipCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onTogglePin,
    required this.onStyle,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final style = _typeStyles[entry.type]!;
    final isCode = entry.type == ClipType.code;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: entry.pinned ? AppColors.gold : AppColors.border,
              width: entry.pinned ? 1 : 1,
            ),
            boxShadow: entry.pinned
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.08),
                      blurRadius: 24,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (dragHandle != null) ...[dragHandle!, const SizedBox(width: 6)],
                  SourceGlyph(initials: style.initials, tint: style.tint, background: style.glyphBg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${style.label} · ${relativeTime(entry.createdAt)}',
                      style: AppTheme.mono.copyWith(fontSize: 10.5, letterSpacing: 0.4),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      entry.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: entry.pinned ? AppColors.gold : AppColors.textSecondary,
                    ),
                    onPressed: onTogglePin,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.text_format, size: 18, color: AppColors.textSecondary),
                    onPressed: onStyle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isCode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.mono.copyWith(fontSize: 12.5, color: AppColors.codeText),
                  ),
                )
              else
                Text(
                  entry.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.45),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  TagPill(label: style.label, color: style.tint),
                  if (entry.pinned) const TagPill(label: 'Pinned', color: AppColors.gold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
