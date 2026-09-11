import UIKit

/// Mirrors lib/theme/app_colors.dart so the keyboard extension (a
/// separate process with no access to the Flutter engine or its theme)
/// still reads as the same app as the host.
enum KeyboardTheme {
    static let background = UIColor(red: 0x11 / 255, green: 0x13 / 255, blue: 0x18 / 255, alpha: 1)
    static let chip = UIColor(red: 0x1B / 255, green: 0x1D / 255, blue: 0x22 / 255, alpha: 1)
    static let chipAccent = UIColor(red: 0x24 / 255, green: 0x1B / 255, blue: 0x0E / 255, alpha: 1)

    static let textPrimary = UIColor(red: 0xED / 255, green: 0xE6 / 255, blue: 0xD6 / 255, alpha: 1)
    static let textSecondary = UIColor(red: 0xC9 / 255, green: 0xC2 / 255, blue: 0xB2 / 255, alpha: 1)

    static let gold = UIColor(red: 0xD9 / 255, green: 0xA4 / 255, blue: 0x41 / 255, alpha: 1)
    static let border = UIColor(white: 1, alpha: 0.08)

    static let chipCornerRadius: CGFloat = 16
    static let keyCornerRadius: CGFloat = 7
}
