import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/clip_entry.dart';
import 'screens/sync_screen.dart';
import 'services/apple_foundation_service.dart';
import 'services/clip_store.dart';
import 'services/foundation_model.g.dart' show FoundationModelAvailability;
import 'services/settings_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/add_clip_sheet.dart';
import 'widgets/clip_card.dart';
import 'widgets/copy_pasta_logo.dart';
import 'widgets/style_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClipStore.instance.init();
  await SettingsStore.instance.init();
  if (SettingsStore.instance.autoClearAfterTwoHours) {
    await ClipStore.instance.purgeOlderThanTwoHours();
  }
  runApp(const CopyPastaApp());
}

class CopyPastaApp extends StatelessWidget {
  const CopyPastaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CopyPasta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}

enum _Filter { all, pinned, url, code, email, phone, styledText, plainText }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _aiAvailable = false;
  bool _aiSessionReady = false;

  @override
  void initState() {
    super.initState();
    _initAi();
  }

  Future<void> _initAi() async {
    final availability = await AppleFoundationService.checkAvailability();
    if (!mounted) return;
    setState(() => _aiAvailable = availability == FoundationModelAvailability.available);
    if (!_aiAvailable) return;
    final ready = await AppleFoundationService.initSession(
      systemPrompt:
          'You are a concise assistant inside a clipboard manager. '
          'Summarize the given clipboard text in 5 words or fewer, '
          'no punctuation at the end, no quotes around your answer.',
    );
    if (mounted) setState(() => _aiSessionReady = ready);
  }

  Future<void> _summarize(ClipEntry entry) async {
    if (!_aiSessionReady) {
      _toast('On-device model not ready');
      return;
    }
    _toast('Summarizing on-device…');
    final summary = await AppleFoundationService.generateResponse(entry.text);
    if (!mounted) return;
    _toast(summary ?? 'Could not summarize');
  }

  static const _filterTypes = <_Filter, ClipType>{
    _Filter.url: ClipType.url,
    _Filter.code: ClipType.code,
    _Filter.email: ClipType.email,
    _Filter.phone: ClipType.phone,
    _Filter.styledText: ClipType.styledText,
    _Filter.plainText: ClipType.plainText,
  };

  List<ClipEntry> get _entries {
    var items = ClipStore.instance.all();
    if (_filter == _Filter.pinned) {
      items = items.where((e) => e.pinned).toList();
    } else if (_filterTypes.containsKey(_filter)) {
      items = items.where((e) => e.type == _filterTypes[_filter]).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      items = items.where((e) => e.text.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Copied');
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddClipSheet(
        onAdd: (text) async {
          await ClipStore.instance.add(text);
          if (mounted) setState(() {});
        },
        onReadClipboard: () async {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          return data?.text?.trim();
        },
      ),
    );
  }

  void _openStyler(ClipEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StyleSheet(
        source: entry.text,
        onUseStyled: (styled) async {
          await ClipStore.instance.add(styled);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.bg,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildList()),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: IgnorePointer(child: _onDeviceBanner()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final entryCount = ClipStore.instance.all().length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: CopyPastaWordmark()),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SyncScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('$entryCount CLIPS · LOCAL', style: AppTheme.mono.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                tooltip: 'Clear unpinned',
                onPressed: () async {
                  await ClipStore.instance.clearUnpinned();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.textPrimary),
              cursorColor: AppColors.gold,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'search clips, links, code…',
                hintStyle: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.textPlaceholder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = <(_Filter, String)>[
      (_Filter.all, 'All'),
      (_Filter.pinned, 'Pinned'),
      (_Filter.url, 'Links'),
      (_Filter.code, 'Code'),
      (_Filter.email, 'Email'),
      (_Filter.phone, 'Phone'),
      (_Filter.styledText, 'Styled'),
      (_Filter.plainText, 'Text'),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (filter, label) = chips[i];
          final selected = _filter == filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: selected ? null : Border.all(color: AppColors.borderStrong),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.bg : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool get _canReorder => _filter == _Filter.all && _query.trim().isEmpty;

  Widget _buildList() {
    final entries = _entries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No clips yet',
          style: AppTheme.mono.copyWith(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    Widget buildRow(int i) {
      final entry = entries[i];
      return Padding(
        key: ValueKey(entry.id),
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey('${entry.id}-dismiss'),
          background: Container(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
          onDismissed: (_) async {
            await ClipStore.instance.delete(entry.id);
            setState(() {});
          },
          child: ClipCard(
            entry: entry,
            onTap: () => _copy(entry.text),
            onTogglePin: () async {
              await ClipStore.instance.togglePin(entry.id);
              setState(() {});
            },
            onStyle: () => _openStyler(entry),
            onSummarize: _aiAvailable ? () => _summarize(entry) : null,
            dragHandle: _canReorder
                ? ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_indicator, size: 18, color: AppColors.textPlaceholder),
                  )
                : null,
          ),
        ),
      );
    }

    if (!_canReorder) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: entries.length,
        itemBuilder: (context, i) => buildRow(i),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: entries.length,
      buildDefaultDragHandles: false,
      proxyDecorator: _springyProxyDecorator,
      onReorderItem: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        setState(() => ClipStore.instance.reorder(entries, oldIndex, newIndex));
      },
      itemBuilder: (context, i) => buildRow(i),
    );
  }

  /// Gives the lifted card a big, springy "picked up" feel: it overshoots
  /// past its final scale/tilt before settling, using an elastic curve
  /// remapped onto Flutter's lift animation (0→1 on pick-up).
  Widget _springyProxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final t = Curves.elasticOut.transform(animation.value);
        final scale = 1.0 + 0.06 * t;
        final tilt = 0.02 * (1 - animation.value) * (index.isEven ? 1 : -1);
        return Transform.rotate(
          angle: tilt,
          child: Transform.scale(
            scale: scale,
            child: Material(
              color: Colors.transparent,
              elevation: 12 * animation.value,
              shadowColor: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _onDeviceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'On-device model active — nothing leaves this phone',
              style: AppTheme.mono.copyWith(fontSize: 11, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
