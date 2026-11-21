// HeatCheck — a menu bar icon that shows your Mac's thermal state.
//
// Uses only Apple's public API ProcessInfo.thermalState.
// No timers: macOS notifies the app when the state changes.
// Runs in the macOS App Sandbox with no network or file access.

import AppKit

@main
struct HeatCheckApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let stateItem = NSMenuItem()
    private let hintItem = NSMenuItem()
    private let sinceItem = NSMenuItem()
    private var observer: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        for line in [stateItem, hintItem, sinceItem] {
            line.isEnabled = false
            menu.addItem(line)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L10n.text("Quit", "Вийти"),
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))
        item.menu = menu
        statusItem = item

        // State changes arrive as a notification; deliver it on the main thread.
        observer = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        refresh()
    }

    private func refresh() {
        let look = Look.of(ProcessInfo.processInfo.thermalState)

        if let button = statusItem?.button {
            var image = NSImage(systemSymbolName: look.symbol,
                                accessibilityDescription: look.title)
            if let color = look.color {
                image = image?.withSymbolConfiguration(.init(paletteColors: [color]))
                image?.isTemplate = false
            } else {
                image?.isTemplate = true  // plain monochrome icon, like the system ones
            }
            button.image = image
            button.imagePosition = .imageLeading
            // Normal: icon only. Elevated: icon plus a label, so it stands out.
            button.title = look.color == nil ? "" : " " + look.title
            button.toolTip = L10n.text("Thermal state: ", "Тепловий стан: ") + look.title
        }

        stateItem.title = L10n.text("State: ", "Стан: ") + look.title
        hintItem.title = look.hint
        sinceItem.title = L10n.text("Unchanged since ", "Без змін з ")
            + Self.timeFormatter.string(from: Date())
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

/// How each state is shown. Descriptions paraphrase Apple's docs for ProcessInfo.ThermalState.
private struct Look {
    let symbol: String
    let color: NSColor?  // nil: monochrome icon without a label
    let title: String
    let hint: String

    static func of(_ state: ProcessInfo.ThermalState) -> Look {
        switch state {
        case .nominal:
            return Look(symbol: "thermometer.low", color: nil,
                        title: L10n.text("Normal", "Норма"),
                        hint: L10n.text("Within normal limits, nothing to do",
                                        "У межах норми, нічого робити не треба"))
        case .fair:
            return Look(symbol: "thermometer.medium", color: .systemYellow,
                        title: L10n.text("Elevated", "Помірно"),
                        hint: L10n.text("Slightly above normal",
                                        "Трохи вище норми"))
        case .serious:
            return Look(symbol: "thermometer.high", color: .systemOrange,
                        title: L10n.text("Hot", "Гаряче"),
                        hint: L10n.text("macOS may already be slowing your Mac down",
                                        "Система вже може пригальмовувати Mac"))
        case .critical:
            return Look(symbol: "thermometer.high", color: .systemRed,
                        title: L10n.text("Critical", "Критично"),
                        hint: L10n.text("Your Mac is heavily throttled to cool down",
                                        "Mac сильно пригальмовує, щоб охолонути"))
        @unknown default:
            return Look(symbol: "thermometer.medium", color: .systemGray,
                        title: L10n.text("Unknown", "Невідомо"),
                        hint: L10n.text("macOS reported a new, unknown state",
                                        "macOS повідомила новий, невідомий стан"))
        }
    }
}

/// UI language: Ukrainian if it is the first preferred system language, English otherwise.
private enum L10n {
    static let isUkrainian = Locale.preferredLanguages.first?.hasPrefix("uk") ?? false

    static func text(_ english: String, _ ukrainian: String) -> String {
        isUkrainian ? ukrainian : english
    }
}
