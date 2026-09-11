import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/text_styler.dart';

class StyleSheet extends StatefulWidget {
  final String source;
  final ValueChanged<String> onUseStyled;

  const StyleSheet({super.key, required this.source, required this.onUseStyled});

  @override
  State<StyleSheet> createState() => _StyleSheetState();
}

class _StyleSheetState extends State<StyleSheet> {
  late String _text = widget.source;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Style text', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: _text)
                ..selection = TextSelection.collapsed(offset: _text.length),
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => _text = v,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FancyStyle.values.map((style) {
                return ActionChip(
                  label: Text(TextStyler.label(style)),
                  onPressed: () async {
                    final styled = TextStyler.apply(_text, style);
                    await Clipboard.setData(ClipboardData(text: styled));
                    widget.onUseStyled(styled);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${TextStyler.label(style)} copied & saved')),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
