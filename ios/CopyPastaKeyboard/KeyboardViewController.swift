import UIKit

/// Custom Keyboard Extension entry point. Add this file (plus
/// FancyTextStyler.swift and Info.plist) to a new "Custom Keyboard Extension"
/// target in Xcode named "CopyPastaKeyboard" — see ../../README_KEYBOARD_SETUP.md
/// for the exact steps, since a new target can't be wired up safely outside Xcode.
class KeyboardViewController: UIInputViewController {

    /// Must match the App Group configured in both this extension's and the
    /// host app's entitlements (Signing & Capabilities > App Groups).
    static let appGroupID = "group.com.calebpierre.copypasta"
    private static let clipsKey = "clips_json"

    private var clipStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = KeyboardTheme.background

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -44),
        ])

        container.addArrangedSubview(buildStyleRow())

        clipStack = buildClipRow()
        container.addArrangedSubview(clipStack)

        // "Next Keyboard" is required by Apple for any custom keyboard so
        // the user can switch back to the system keyboard.
        let nextKeyboardButton = chipButton(title: "🌐", tint: KeyboardTheme.textSecondary, background: KeyboardTheme.chip)
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextKeyboardButton)
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
        ])
    }

    /// A rounded, filled chip matching the suggestion pills in the design
    /// (Keyboard.dc.html) — system `UIButton`s default to plain text with
    /// no background, which read as invisible on the dark extension.
    private func chipButton(title: String, tint: UIColor, background: UIColor) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = tint
        configuration.background.backgroundColor = background
        configuration.background.cornerRadius = KeyboardTheme.chipCornerRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 13, bottom: 8, trailing: 13)
        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        return button
    }

    private func buildStyleRow() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            row.topAnchor.constraint(equalTo: scroll.topAnchor),
            row.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            row.heightAnchor.constraint(equalTo: scroll.heightAnchor),
        ])
        for style in FancyStyle.allCases {
            let button = chipButton(title: style.label, tint: KeyboardTheme.gold, background: KeyboardTheme.chipAccent)
            button.tag = FancyStyle.allCases.firstIndex(of: style) ?? 0
            button.addAction(UIAction { [weak self] _ in self?.applyStyleToSelection(style) }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        return scroll
    }

    private func buildClipRow() -> UIStackView {
        let scroll = UIStackView()
        scroll.axis = .horizontal
        scroll.spacing = 8
        for clip in readClips().prefix(20) {
            let short = clip.count > 24 ? String(clip.prefix(24)) + "…" : clip
            let button = chipButton(title: short, tint: KeyboardTheme.textPrimary, background: KeyboardTheme.chip)
            button.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText(clip) }, for: .touchUpInside)
            scroll.addArrangedSubview(button)
        }
        return scroll
    }

    private func readClips() -> [String] {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let json = defaults.string(forKey: Self.clipsKey),
              let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return list
    }

    private func applyStyleToSelection(_ style: FancyStyle) {
        guard let selected = textDocumentProxy.selectedText, !selected.isEmpty else { return }
        textDocumentProxy.deleteBackward()
        textDocumentProxy.insertText(FancyTextStyler.apply(selected, style: style))
    }
}
