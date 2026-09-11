/// Converts plain ASCII text into visually styled Unicode look-alikes.
/// This is the same trick used by "fancy text" keyboards: real bold/italic
/// markup isn't renderable in plain-text fields (SMS, most social apps),
/// so we swap each letter for its Unicode Mathematical Alphanumeric twin.
enum FancyStyle { bold, italic, boldItalic, script, monospace, fullwidth, smallCaps, strikethrough }

class TextStyler {
  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';

  static String apply(String input, FancyStyle style) {
    switch (style) {
      case FancyStyle.bold:
        return _mapWithBase(input, upperBase: 0x1D400, lowerBase: 0x1D41A, digitBase: 0x1D7CE);
      case FancyStyle.italic:
        return _mapWithBase(input, upperBase: 0x1D434, lowerBase: 0x1D44E, digitBase: null);
      case FancyStyle.boldItalic:
        return _mapWithBase(input, upperBase: 0x1D468, lowerBase: 0x1D482, digitBase: null);
      case FancyStyle.script:
        return _mapWithBase(input, upperBase: 0x1D49C, lowerBase: 0x1D4B6, digitBase: null,
            upperExceptions: _scriptUpperExceptions, lowerExceptions: _scriptLowerExceptions);
      case FancyStyle.monospace:
        return _mapWithBase(input, upperBase: 0x1D670, lowerBase: 0x1D68A, digitBase: 0x1D7F6);
      case FancyStyle.fullwidth:
        return _mapFullwidth(input);
      case FancyStyle.smallCaps:
        return _mapSmallCaps(input);
      case FancyStyle.strikethrough:
        return input.split('').map((c) => '$c̶').join();
    }
  }

  static const Map<int, int> _scriptUpperExceptions = {
    2: 0x212C, // B -> SCRIPT CAPITAL B
    4: 0x2130, // E
    5: 0x2131, // F
    7: 0x210B, // H
    8: 0x2110, // I
    11: 0x2112, // L
    12: 0x2133, // M
    17: 0x211B, // R
  };
  static const Map<int, int> _scriptLowerExceptions = {
    4: 0x212F, // e
    6: 0x210A, // g
    14: 0x2134, // o
  };

  static String _mapWithBase(
    String input, {
    required int upperBase,
    required int lowerBase,
    required int? digitBase,
    Map<int, int>? upperExceptions,
    Map<int, int>? lowerExceptions,
  }) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final upperIdx = _upper.indexOf(ch);
      final lowerIdx = _lower.indexOf(ch);
      final digitIdx = _digits.indexOf(ch);
      if (upperIdx != -1) {
        final override = upperExceptions?[upperIdx];
        buffer.writeCharCode(override ?? (upperBase + upperIdx));
      } else if (lowerIdx != -1) {
        final override = lowerExceptions?[lowerIdx];
        buffer.writeCharCode(override ?? (lowerBase + lowerIdx));
      } else if (digitIdx != -1 && digitBase != null) {
        buffer.writeCharCode(digitBase + digitIdx);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  static String _mapFullwidth(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune == 0x20) {
        buffer.writeCharCode(0x3000);
      } else if (rune >= 0x21 && rune <= 0x7E) {
        buffer.writeCharCode(rune - 0x21 + 0xFF01);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  static const Map<String, String> _smallCapsMap = {
    'a': 'ᴀ', 'b': 'ʙ', 'c': 'ᴄ', 'd': 'ᴅ', 'e': 'ᴇ', 'f': 'ꜰ', 'g': 'ɢ',
    'h': 'ʜ', 'i': 'ɪ', 'j': 'ᴊ', 'k': 'ᴋ', 'l': 'ʟ', 'm': 'ᴍ', 'n': 'ɴ',
    'o': 'ᴏ', 'p': 'ᴘ', 'q': 'ǫ', 'r': 'ʀ', 's': 'ꜱ', 't': 'ᴛ', 'u': 'ᴜ',
    'v': 'ᴠ', 'w': 'ᴡ', 'x': 'x', 'y': 'ʏ', 'z': 'ᴢ',
  };

  static String _mapSmallCaps(String input) {
    return input.split('').map((c) => _smallCapsMap[c.toLowerCase()] ?? c).join();
  }

  static String label(FancyStyle style) {
    switch (style) {
      case FancyStyle.bold:
        return 'Bold';
      case FancyStyle.italic:
        return 'Italic';
      case FancyStyle.boldItalic:
        return 'Bold Italic';
      case FancyStyle.script:
        return 'Script';
      case FancyStyle.monospace:
        return 'Monospace';
      case FancyStyle.fullwidth:
        return 'Fullwidth';
      case FancyStyle.smallCaps:
        return 'Small Caps';
      case FancyStyle.strikethrough:
        return 'Strikethrough';
    }
  }
}
