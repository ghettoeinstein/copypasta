import 'package:flutter/material.dart';

import '../services/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _settings = SettingsStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync & Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          _syncCard(),
          const SizedBox(height: 22),
          _modelCard(),
          const SizedBox(height: 22),
          _sectionLabel('DEVICES'),
          _deviceRow(Icons.phone_iphone, 'This device', 'Active', AppColors.success),
          _deviceRow(Icons.laptop_mac, 'Studio MacBook', 'Synced 4m ago', AppColors.textSecondary),
          _deviceRow(Icons.tablet_mac, 'Pixel Tablet', 'Synced 1h ago', AppColors.textSecondary),
          const SizedBox(height: 22),
          _sectionLabel('CONTROLS'),
          _switchRow(
            'Share clipboard across devices',
            _settings.shareAcrossDevices,
            (v) => setState(() => _settings.setShareAcrossDevices(v)),
          ),
          _switchRow(
            'Include images',
            _settings.includeImages,
            (v) => setState(() => _settings.setIncludeImages(v)),
          ),
          _switchRow(
            'Auto-clear after 2 hours',
            _settings.autoClearAfterTwoHours,
            (v) => setState(() => _settings.setAutoClearAfterTwoHours(v)),
          ),
        ],
      ),
    );
  }

  Widget _syncCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(height: 90, width: double.infinity, child: CustomPaint(painter: _SyncDiagramPainter())),
          const SizedBox(height: 16),
          Text('Synced device to device', style: AppTheme.display.copyWith(fontSize: 17)),
          const SizedBox(height: 6),
          const Text(
            'No server ever holds your clipboard. Phone, laptop, and tablet '
            'exchange it directly over your local network.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 12, color: AppColors.gold),
                const SizedBox(width: 6),
                Text('NO CLOUD', style: AppTheme.mono.copyWith(fontSize: 9.5, color: AppColors.gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modelCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('On-device model', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('240 MB · runs fully offline', style: AppTheme.mono.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.success),
            ),
            child: Text('READY', style: AppTheme.mono.copyWith(fontSize: 9.5, color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text, style: AppTheme.mono.copyWith(fontSize: 10, letterSpacing: 0.6)),
      );

  Widget _deviceRow(IconData icon, String name, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.codeText),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary))),
          Text(status, style: AppTheme.mono.copyWith(fontSize: 10.5, color: statusColor)),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.gold,
            activeThumbColor: AppColors.textPrimary,
            inactiveTrackColor: AppColors.chip,
            inactiveThumbColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _SyncDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(size.width * 0.2, size.height * 0.27);
    final right = Offset(size.width * 0.8, size.height * 0.27);
    final bottom = Offset(size.width * 0.5, size.height * 0.78);

    final line = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 1;
    canvas.drawLine(left, bottom, line);
    canvas.drawLine(right, bottom, line);

    final dashed = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 1;
    _drawDashedLine(canvas, left, right, dashed);

    _node(canvas, left, 10, AppColors.card, AppColors.orange);
    _node(canvas, right, 10, AppColors.card, AppColors.orange);
    _node(canvas, bottom, 12, AppColors.card, AppColors.gold);
    canvas.drawCircle(bottom, 4, Paint()..color = AppColors.gold);
  }

  void _node(Canvas canvas, Offset center, double radius, Color fill, Color stroke) {
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashWidth = 4.0, gapWidth = 3.0;
    final total = (b - a).distance;
    final direction = (b - a) / total;
    var covered = 0.0;
    while (covered < total) {
      final start = a + direction * covered;
      final end = a + direction * (covered + dashWidth).clamp(0, total);
      canvas.drawLine(start, end, paint);
      covered += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
