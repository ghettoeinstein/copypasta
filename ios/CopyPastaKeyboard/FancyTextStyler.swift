import Foundation

/// Swift port of lib/utils/text_styler.dart so the keyboard extension has no
/// dependency on the host app's Flutter engine (keyboard extensions run in a
/// separate, memory-constrained process).
enum FancyStyle: CaseIterable {
    case bold, italic, script, monospace, smallCaps

    var label: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .script: return "Script"
        case .monospace: return "Mono"
        case .smallCaps: return "SMALL"
        }
    }
}

enum FancyTextStyler {
    private static let upper = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lower = Array("abcdefghijklmnopqrstuvwxyz")

    private static let smallCaps: [Character: Character] = [
        "a": "ᴀ", "b": "ʙ", "c": "ᴄ", "d": "ᴅ", "e": "ᴇ", "f": "ꜰ", "g": "ɢ",
        "h": "ʜ", "i": "ɪ", "j": "ᴊ", "k": "ᴋ", "l": "ʟ", "m": "ᴍ", "n": "ɴ",
        "o": "ᴏ", "p": "ᴘ", "q": "ǫ", "r": "ʀ", "s": "ꜱ", "t": "ᴛ", "u": "ᴜ",
        "v": "ᴠ", "w": "ᴡ", "x": "x", "y": "ʏ", "z": "ᴢ",
    ]

    static func apply(_ input: String, style: FancyStyle) -> String {
        switch style {
        case .bold: return mapBase(input, upperBase: 0x1D400, lowerBase: 0x1D41A)
        case .italic: return mapBase(input, upperBase: 0x1D434, lowerBase: 0x1D44E)
        case .script: return mapBase(input, upperBase: 0x1D49C, lowerBase: 0x1D4B6)
        case .monospace: return mapBase(input, upperBase: 0x1D670, lowerBase: 0x1D68A)
        case .smallCaps:
            return String(input.map { smallCaps[Character($0.lowercased())] ?? $0 })
        }
    }

    private static func mapBase(_ input: String, upperBase: Int, lowerBase: Int) -> String {
        var scalars: [Unicode.Scalar] = []
        for ch in input {
            if let idx = upper.firstIndex(of: ch), let scalar = Unicode.Scalar(upperBase + idx) {
                scalars.append(scalar)
            } else if let idx = lower.firstIndex(of: ch), let scalar = Unicode.Scalar(lowerBase + idx) {
                scalars.append(scalar)
            } else {
                scalars.append(contentsOf: ch.unicodeScalars)
            }
        }
        return String(String.UnicodeScalarView(scalars))
    }
}
