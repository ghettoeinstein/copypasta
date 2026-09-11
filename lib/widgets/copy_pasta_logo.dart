import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The dashed-orbit + solid-nucleus mark used across every screen in the
/// design (header, sync diagram nodes, keyboard preview).
class CopyPastaMark extends StatelessWidget {
  final double size;

  const CopyPastaMark({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orbit = Paint()
      ..color = AppColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 22;
    final dashLength = size.width * 0.07;
    final gapLength = size.width * 0.18;
    final radius = size.width * 0.43;
    final circumference = 2 * 3.14159265 * radius;
    var covered = 0.0;
    while (covered < circumference) {
      final startAngle = covered / radius;
      final sweep = dashLength / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        orbit,
      );
      covered += dashLength + gapLength;
    }
    final nucleus = Paint()..color = AppColors.gold;
    canvas.drawCircle(center, size.width * 0.18, nucleus);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "copypasta" wordmark in Fraunces, paired with [CopyPastaMark].
class CopyPastaWordmark extends StatelessWidget {
  final double fontSize;
  final double markSize;
  final double opacity;

  const CopyPastaWordmark({super.key, this.fontSize = 19, this.markSize = 22, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyPastaMark(size: markSize),
          const SizedBox(width: 9),
          Text('copypasta', style: AppTheme.logo.copyWith(fontSize: fontSize)),
        ],
      ),
    );
  }
}
