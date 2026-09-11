import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/clip_entry.dart';
import 'services/clip_store.dart';
import 'widgets/style_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClipStore.instance.init();
  runApp(const CopyPastaApp());
}

class CopyPastaApp extends StatelessWidget {
  const CopyPastaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CopyPasta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B5FEF),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B5FEF),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ClipType? _filter;
  final _composeController = TextEditingController();

  List<ClipEntry> get _entries {
    final all = ClipStore.instance.all();
    if (_filter == null) return all;
    return all.where((e) => e.type == _filter).toList();
  }

  Future<void> _addFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _toast('Clipboard is empty');
      return;
    }
    await ClipStore.instance.add(text);
    setState(() {});
  }

  Future<void> _addFromCompose() async {
    final text = _composeController.text.trim();
    if (text.isEmpty) return;
    await ClipStore.instance.add(text);
    _composeController.clear();
    setState(() {});
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Copied');
  }

  void _openStyler(ClipEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
      appBar: AppBar(
        title: const Text('CopyPasta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_outlined),
            tooltip: 'Add from clipboard',
            onPressed: _addFromClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear unpinned',
            onPressed: () async {
              await ClipStore.instance.clearUnpinned();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildComposeBar(),
          _buildFilterChips(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildComposeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _composeController,
              decoration: const InputDecoration(
                hintText: 'Type or paste text to save…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _addFromCompose(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.add),
            onPressed: _addFromCompose,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final types = <ClipType?>[null, ...ClipType.values];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final type = types[i];
          final selected = _filter == type;
          return ChoiceChip(
            label: Text(type == null ? 'All' : _typeLabel(type)),
            selected: selected,
            onSelected: (_) => setState(() => _filter = type),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final entries = _entries;
    if (entries.isEmpty) {
      return const Center(child: Text('No clips yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Dismissible(
          key: ValueKey(entry.id),
          background: Container(color: Colors.redAccent),
          onDismissed: (_) async {
            await ClipStore.instance.delete(entry.id);
            setState(() {});
          },
          child: ListTile(
            key: ValueKey('${entry.id}-tile'),
            leading: Icon(_typeIcon(entry.type)),
            title: Text(
              entry.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_typeLabel(entry.type)),
            onTap: () => _copy(entry.text),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(entry.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                  onPressed: () async {
                    await ClipStore.instance.togglePin(entry.id);
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.text_format),
                  tooltip: 'Style text',
                  onPressed: () => _openStyler(entry),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _typeLabel(ClipType type) {
    switch (type) {
      case ClipType.url:
        return 'Link';
      case ClipType.email:
        return 'Email';
      case ClipType.phone:
        return 'Phone';
      case ClipType.code:
        return 'Code';
      case ClipType.styledText:
        return 'Styled';
      case ClipType.plainText:
        return 'Text';
    }
  }

  IconData _typeIcon(ClipType type) {
    switch (type) {
      case ClipType.url:
        return Icons.link;
      case ClipType.email:
        return Icons.email_outlined;
      case ClipType.phone:
        return Icons.phone_outlined;
      case ClipType.code:
        return Icons.code;
      case ClipType.styledText:
        return Icons.text_format;
      case ClipType.plainText:
        return Icons.notes;
    }
  }
}
