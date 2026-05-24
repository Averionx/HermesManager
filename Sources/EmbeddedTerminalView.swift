import SwiftUI
import AppKit
import SwiftTerm

struct EmbeddedTerminalView: View {
    @ObservedObject var manager: ServiceManager
    @State private var restartToken = UUID()
    @State private var terminalRunning = false
    @State private var terminalTitle = "terminal"

    private var terminalModeLabel: String {
        L10n.t("Hermes CLI", "Hermes CLI")
    }

    var body: some View {
        ZStack {
            SetupBackground()

            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 0) {
                    terminalToolbar

                    HermesTerminalRepresentable(
                        restartToken: restartToken,
                        isRunning: $terminalRunning,
                        title: $terminalTitle
                    )
                    .id(restartToken)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .padding(20)
        }
        .onAppear {
            manager.checkStatus()
        }
        .onDisappear {
            manager.refreshModelStatus()
            manager.checkStatus(force: true)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Embedded Hermes CLI")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(L10n.t("这里是应用内 PTY 终端，直接运行 Hermes CLI，不需要另开系统终端。", "This in-app PTY terminal runs Hermes CLI directly, so you do not need to open a separate system Terminal."))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                    TerminalStatusPill(title: "Hermes", isOn: terminalRunning)
                    TerminalStatusPill(title: "Web UI", isOn: manager.webUIRunning)
                    TerminalStatusPill(title: "In-App CLI", isOn: terminalRunning)
                }
                .frame(maxWidth: 420, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                Text(terminalRunning ? terminalModeLabel : L10n.t("终端未运行", "Terminal not running"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(terminalRunning ? SetupPalette.emerald : SetupPalette.amber)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                Button(action: restartCLI) {
                    Label(L10n.t("重启终端", "Restart Terminal"), systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(DesignTokens.surface2.opacity(0.78))
                        .cornerRadius(DesignTokens.radiusPill)
                }
                .buttonStyle(.plain)
            }
            .frame(minWidth: 170, maxWidth: 240, alignment: .trailing)
        }
        .padding(18)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(SetupPalette.emerald.opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private var terminalToolbar: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1.0, green: 0.36, blue: 0.32)).frame(width: 10, height: 10)
            Circle().fill(Color(red: 1.0, green: 0.77, blue: 0.25)).frame(width: 10, height: 10)
            Circle().fill(SetupPalette.emerald).frame(width: 10, height: 10)
            Text(terminalTitle.isEmpty ? "hermes" : terminalTitle)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(DesignTokens.textMuted)
                .lineLimit(1)
                .padding(.leading, 8)
            Spacer()
            Text(terminalRunning ? "PTY LIVE" : "STOPPED")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(terminalRunning ? SetupPalette.amber : DesignTokens.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DesignTokens.surface2.opacity(0.72))
    }

    private func restartCLI() {
        restartToken = UUID()
    }
}

struct HermesTerminalRepresentable: NSViewRepresentable {
    let restartToken: UUID
    @Binding var isRunning: Bool
    @Binding var title: String

    func makeCoordinator() -> Coordinator {
        Coordinator(isRunning: $isRunning, title: $title)
    }

    func makeNSView(context: Context) -> TerminalHostView {
        let host = TerminalHostView(frame: .zero)
        let terminal = LocalProcessTerminalView(frame: .zero)
        terminal.processDelegate = context.coordinator
        terminal.autoresizingMask = [.width, .height]
        configureAppearance(terminal)
        host.install(terminal)
        context.coordinator.start(terminal)
        context.coordinator.focus(terminal)
        return host
    }

    func updateNSView(_ nsView: TerminalHostView, context: Context) {
        context.coordinator.isRunning = $isRunning
        context.coordinator.title = $title
        if let terminal = nsView.terminalView {
            context.coordinator.focus(terminal)
        }
    }

    static func dismantleNSView(_ nsView: TerminalHostView, coordinator: Coordinator) {
        nsView.terminalView?.terminate()
        DispatchQueue.main.async {
            coordinator.isRunning.wrappedValue = false
        }
    }

    private func configureAppearance(_ terminal: LocalProcessTerminalView) {
        let terminalTheme = TerminalProfileTheme.load()
        terminal.font = terminalTheme.font
        terminal.installColors(terminalTheme.ansiPalette)
        terminal.useBrightColors = true
        terminal.customBlockGlyphs = true
        terminal.antiAliasCustomBlockGlyphs = true
        terminal.optionAsMetaKey = true
        terminal.nativeForegroundColor = terminalTheme.foreground
        terminal.nativeBackgroundColor = terminalTheme.background
        terminal.layer?.backgroundColor = terminalTheme.background.cgColor
        terminal.caretColor = terminalTheme.cursor
        terminal.caretTextColor = terminalTheme.background
        terminal.selectedTextBackgroundColor = terminalTheme.selection
        terminal.getTerminal().setCursorStyle(.steadyBlock)
        do {
            try terminal.setUseMetal(false)
        } catch {
            // CoreText rendering is stable enough here; Metal is an optional acceleration path.
        }
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var isRunning: Binding<Bool>
        var title: Binding<String>
        private var didFocusTerminal = false

        init(isRunning: Binding<Bool>, title: Binding<String>) {
            self.isRunning = isRunning
            self.title = title
        }

        func focus(_ terminal: LocalProcessTerminalView) {
            guard !didFocusTerminal else { return }
            didFocusTerminal = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                terminal.window?.makeFirstResponder(terminal)
            }
        }

        func start(_ terminal: LocalProcessTerminalView) {
            let launch = Self.launchConfiguration()
            title.wrappedValue = launch.title
            terminal.feed(text: launch.banner)
            terminal.startProcess(
                executable: launch.executable,
                args: launch.args,
                environment: launch.environment,
                execName: launch.execName,
                currentDirectory: launch.currentDirectory
            )
            DispatchQueue.main.async {
                self.isRunning.wrappedValue = terminal.process.running
            }
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            DispatchQueue.main.async {
                self.title.wrappedValue = title.isEmpty ? "terminal" : title
            }
        }

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
            guard let directory, !directory.isEmpty else { return }
            DispatchQueue.main.async {
                self.title.wrappedValue = compactPath(directory)
            }
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            DispatchQueue.main.async {
                self.isRunning.wrappedValue = false
            }
        }

        private static func launchConfiguration() -> TerminalLaunchConfiguration {
            let home = NSHomeDirectory()
            var environment = ProcessInfo.processInfo.environment

            // The app can be launched from Codex or other shells that set "no color"
            // variables. Hermes uses Rich/prompt_toolkit, so those inherited flags
            // make the real CLI fall back to the gray/white look instead of its skin.
            for key in [
                "NO_COLOR",
                "TERM_PROGRAM_VERSION",
                "HERMES_LIGHT",
                "HERMES_TUI_LIGHT",
                "HERMES_TUI_THEME",
                "HERMES_TUI_BACKGROUND"
            ] {
                environment.removeValue(forKey: key)
            }

            environment["TERM"] = "xterm-256color"
            environment["COLORTERM"] = "truecolor"
            environment["CLICOLOR"] = "1"
            environment["CLICOLOR_FORCE"] = "1"
            environment["FORCE_COLOR"] = "1"
            environment["PY_COLORS"] = "1"
            environment["RICH_FORCE_TERMINAL"] = "1"
            environment["RICH_COLOR_SYSTEM"] = "truecolor"
            environment["HERMES_TUI_THEME"] = "dark"
            environment["HERMES_TUI_BACKGROUND"] = "#000000"
            environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(home)/.local/bin:\(home)/.cargo/bin:" + (environment["PATH"] ?? "")

            environment["HOME"] = home
            environment["TERM_PROGRAM"] = "Apple_Terminal"
            environment["TERM_PROGRAM_VERSION"] = environment["TERM_PROGRAM_VERSION"] ?? "HermesManager"
            let banner = "\u{001B}[32mStarting Hermes CLI with your login shell environment...\u{001B}[0m\r\n\r\n"
            return TerminalLaunchConfiguration(
                title: "hermes",
                executable: "/bin/zsh",
                args: ["-lic", "exec hermes"],
                environment: environment.map { "\($0.key)=\($0.value)" },
                execName: "-zsh",
                currentDirectory: home,
                banner: banner
            )
        }
    }
}

final class TerminalHostView: NSView {
    private(set) var terminalView: LocalProcessTerminalView?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    func install(_ terminal: LocalProcessTerminalView) {
        terminalView?.removeFromSuperview()
        terminalView = terminal
        terminal.frame = bounds
        terminal.autoresizingMask = [.width, .height]
        addSubview(terminal)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        focusTerminal()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result != nil {
            focusTerminal()
        }
        return result
    }

    private func focusTerminal() {
        guard let terminalView else { return }
        DispatchQueue.main.async {
            terminalView.window?.makeFirstResponder(terminalView)
        }
    }
}

private struct TerminalLaunchConfiguration {
    let title: String
    let executable: String
    let args: [String]
    let environment: [String]
    let execName: String?
    let currentDirectory: String
    let banner: String
}

private struct TerminalProfileTheme {
    let foreground: NSColor
    let background: NSColor
    let cursor: NSColor
    let selection: NSColor
    let font: NSFont
    let ansiPalette: [SwiftTerm.Color]

    static func load() -> TerminalProfileTheme {
        let fallback = TerminalProfileTheme.fallback
        guard
            let domain = terminalDefaultsDomain(),
            let settings = domain["Window Settings"] as? [String: Any]
        else {
            return fallback
        }

        let preferredName = (domain["Default Window Settings"] as? String)
            ?? (domain["Startup Window Settings"] as? String)
        let profileName = preferredName.flatMap { settings[$0] != nil ? $0 : nil } ?? "Pro"
        guard let profile = settings[profileName] as? [String: Any] else {
            return fallback
        }

        var ansiPalette = fallback.ansiPalette
        for (index, key) in ansiKeys.enumerated() {
            if let color = archivedColor(key, in: profile) {
                ansiPalette[index] = color.terminalColor
            }
        }

        return TerminalProfileTheme(
            foreground: archivedColor("TextColor", in: profile) ?? fallback.foreground,
            background: fallback.background,
            cursor: archivedColor("CursorColor", in: profile) ?? fallback.cursor,
            selection: (archivedColor("SelectionColor", in: profile) ?? fallback.selection).withAlphaComponent(0.72),
            font: archivedFont("Font", in: profile) ?? fallback.font,
            ansiPalette: ansiPalette
        )
    }

    private static let fallback = TerminalProfileTheme(
        foreground: NSColor(calibratedWhite: 0.94, alpha: 1),
        background: NSColor(calibratedRed: 0.015, green: 0.018, blue: 0.016, alpha: 1),
        cursor: NSColor(calibratedRed: 0.10, green: 0.86, blue: 0.49, alpha: 1),
        selection: NSColor(calibratedWhite: 0.28, alpha: 0.72),
        font: NSFont(name: "Monaco", size: 14) ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
        ansiPalette: terminalAppAnsiPalette
    )

    private static let terminalAppAnsiPalette: [SwiftTerm.Color] = [
        color8(0, 0, 0),
        color8(194, 54, 33),
        color8(37, 188, 36),
        color8(173, 173, 39),
        color8(73, 46, 225),
        color8(211, 56, 211),
        color8(51, 187, 200),
        color8(203, 204, 205),
        color8(129, 131, 131),
        color8(252, 57, 31),
        color8(49, 231, 34),
        color8(234, 236, 35),
        color8(88, 51, 255),
        color8(249, 53, 248),
        color8(20, 240, 240),
        color8(233, 235, 235)
    ]

    private static let ansiKeys = [
        "ANSIBlackColor",
        "ANSIRedColor",
        "ANSIGreenColor",
        "ANSIYellowColor",
        "ANSIBlueColor",
        "ANSIMagentaColor",
        "ANSICyanColor",
        "ANSIWhiteColor",
        "ANSIBrightBlackColor",
        "ANSIBrightRedColor",
        "ANSIBrightGreenColor",
        "ANSIBrightYellowColor",
        "ANSIBrightBlueColor",
        "ANSIBrightMagentaColor",
        "ANSIBrightCyanColor",
        "ANSIBrightWhiteColor"
    ]

    private static func terminalDefaultsDomain() -> [String: Any]? {
        UserDefaults(suiteName: "com.apple.Terminal")?.persistentDomain(forName: "com.apple.Terminal")
            ?? UserDefaults.standard.persistentDomain(forName: "com.apple.Terminal")
    }

    private static func archivedColor(_ key: String, in profile: [String: Any]) -> NSColor? {
        guard let data = profile[key] as? Data else { return nil }
        let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        return color?.usingColorSpace(.deviceRGB) ?? color?.usingColorSpace(.sRGB) ?? color
    }

    private static func archivedFont(_ key: String, in profile: [String: Any]) -> NSFont? {
        guard let data = profile[key] as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSFont.self, from: data)
    }

    private static func color8(_ red: UInt16, _ green: UInt16, _ blue: UInt16) -> SwiftTerm.Color {
        SwiftTerm.Color(red: red * 257, green: green * 257, blue: blue * 257)
    }
}

private extension NSColor {
    var terminalColor: SwiftTerm.Color {
        let converted = usingColorSpace(.deviceRGB) ?? usingColorSpace(.sRGB) ?? self
        return SwiftTerm.Color(
            red: UInt16(max(0, min(65535, converted.redComponent * 65535))),
            green: UInt16(max(0, min(65535, converted.greenComponent * 65535))),
            blue: UInt16(max(0, min(65535, converted.blueComponent * 65535)))
        )
    }
}

struct TerminalStatusPill: View {
    let title: String
    let isOn: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isOn ? DesignTokens.textSecondary : DesignTokens.textTertiary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
        .background(isOn ? SetupPalette.emerald.opacity(0.12) : DesignTokens.surface2.opacity(0.58))
        .cornerRadius(DesignTokens.radiusPill)
    }
}
