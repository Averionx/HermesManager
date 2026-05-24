import SwiftUI
import Foundation

// MARK: - Design Tokens

enum DesignTokens {
    static let canvas = Color(red: 0.035, green: 0.039, blue: 0.043)
    static let surface1 = Color(red: 0.059, green: 0.063, blue: 0.067)
    static let surface2 = Color(red: 0.078, green: 0.082, blue: 0.086)
    static let surface3 = Color(red: 0.102, green: 0.106, blue: 0.110)
    static let borderSubtle = Color(red: 0.14, green: 0.15, blue: 0.16)
    static let borderDefault = Color(red: 0.20, green: 0.21, blue: 0.23)
    static let textPrimary = Color(red: 0.97, green: 0.97, blue: 0.97)
    static let textSecondary = Color(red: 0.82, green: 0.84, blue: 0.88)
    static let textTertiary = Color(red: 0.54, green: 0.56, blue: 0.60)
    static let textMuted = Color(red: 0.38, green: 0.40, blue: 0.43)
    static let accent = Color(red: 0.37, green: 0.42, blue: 0.82)
    static let success = Color(red: 0.15, green: 0.65, blue: 0.27)
    static let error = Color(red: 1.0, green: 0.38, blue: 0.38)
    static let warning = Color(red: 1.0, green: 0.77, blue: 0.20)
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 8
    static let radiusLG: CGFloat = 12
    static let radiusPill: CGFloat = 9999
    static let spaceXS: CGFloat = 4
    static let spaceSM: CGFloat = 8
    static let spaceMD: CGFloat = 12
    static let spaceLG: CGFloat = 16
    static let spaceXL: CGFloat = 24
}

enum AppRuntimeMode {
    static var documentationScreenshot: Bool {
        let value = ProcessInfo.processInfo.environment["HERMES_MANAGER_DOC_SCREENSHOT"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let value, !value.isEmpty else { return false }
        return !["0", "false", "no", "live"].contains(value)
    }

    static var uiPrototype: Bool {
        let environment = ProcessInfo.processInfo.environment
        let value = (environment["HERMES_MANAGER_SAFE_PREVIEW"] ?? environment["HERMES_MANAGER_UI_PROTOTYPE"])?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let value, !value.isEmpty else { return false }
        return !["0", "false", "no", "live"].contains(value)
    }
    static let autoStartServicesOnLaunch = true
    static let stopServicesOnAppQuit = true
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zh:
            return "中文"
        case .en:
            return "English"
        }
    }

    static func normalized(_ value: String) -> AppLanguage {
        AppLanguage(rawValue: value) ?? .zh
    }
}

enum L10n {
    static let languageKey = "appLanguage"

    static var current: AppLanguage {
        AppLanguage.normalized(UserDefaults.standard.string(forKey: languageKey) ?? AppLanguage.zh.rawValue)
    }

    static func t(_ zh: String, _ en: String) -> String {
        current == .en ? en : zh
    }

    static func dynamic(_ value: String) -> String {
        guard current == .en else { return value }
        let exact: [String: String] = [
            "等待检测": "Waiting for check",
            "等待记忆连接检测": "Waiting for memory bridge check",
            "就绪": "Ready",
            "尚未检测": "Not checked yet",
            "等待校准": "Waiting for calibration",
            "无": "None",
            "未检测": "Not detected",
            "待选择组件": "select components",
            "未检测到 Hermes 当前模型": "Hermes current model not detected",
            "安全预览：不会自动启动服务": "Safe preview: services will not auto-start",
            "安全预览：已预览启动 Web UI": "Safe preview: Web UI start previewed",
            "安全预览：已预览停止 Web UI": "Safe preview: Web UI stop previewed",
            "安全预览：已预览启动 Gateway": "Safe preview: Gateway start previewed",
            "安全预览：已预览停止 Gateway": "Safe preview: Gateway stop previewed",
            "安全预览：已预览启动所有服务": "Safe preview: starting all services previewed",
            "安全预览：已预览停止所有服务": "Safe preview: stopping all services previewed",
            "安全预览：已预览重启所有服务": "Safe preview: restarting all services previewed",
            "安全预览：不会打开浏览器": "Safe preview: browser opening is skipped",
            "控制面板就绪，服务仅在用户点击后启动": "Dashboard ready; services start only after user action",
            "服务已就绪": "Services ready",
            "服务已自动启动": "Services auto-started",
            "部分服务未启动": "Some services did not start",
            "服务自动启动失败": "Service auto-start failed",
            "所有服务已启动": "All services started",
            "服务启动失败": "Service start failed",
            "所有服务已停止": "All services stopped",
            "所有服务已重启": "All services restarted",
            "部分服务重启失败": "Some services failed to restart",
            "服务重启失败": "Service restart failed",
            "Web UI 已启动": "Web UI started",
            "Web UI 启动失败": "Web UI failed to start",
            "Web UI 已停止": "Web UI stopped",
            "Web UI 停止失败": "Web UI failed to stop",
            "Gateway 已启动": "Gateway started",
            "Gateway 启动失败": "Gateway failed to start",
            "Gateway 已停止": "Gateway stopped",
            "Gateway 停止失败": "Gateway failed to stop",
            "已预览启动 Web UI": "Web UI start previewed",
            "已预览停止 Web UI": "Web UI stop previewed",
            "已预览启动 Gateway": "Gateway start previewed",
            "已预览停止 Gateway": "Gateway stop previewed",
            "已预览启动全部": "Start all previewed",
            "已预览停止全部": "Stop all previewed",
            "已预览重启全部": "Restart all previewed",
            "已预览打开 Web UI": "Opening Web UI previewed",
            "已启动全部服务": "All services started",
            "已停止全部服务": "All services stopped",
            "已重启全部服务": "All services restarted",
            "部分服务未停止": "Some services did not stop",
            "需要先修复记忆连接": "Repair memory bridge first",
            "可以打开控制台地址继续使用": "You can open the console URL to continue",
            "请到日志页查看详细输出": "Check the Logs page for details",
            "服务已关闭": "Service closed",
            "Hermes 主控链路已打开": "Hermes brain bridge is open",
            "Hermes 主控链路已关闭": "Hermes brain bridge is closed",
            "Web UI 和 Gateway 均已运行": "Web UI and Gateway are both running",
            "Web UI 和 Gateway 均未运行，请查看日志": "Web UI and Gateway are both stopped; check logs",
            "安全预览不会启动真实服务": "Safe preview will not start real services",
            "安全预览不会停止真实服务": "Safe preview will not stop real services",
            "安全预览不会修改真实进程": "Safe preview will not modify real processes",
            "Web UI + Gateway 已进入预览状态": "Web UI + Gateway entered preview state",
            "Web UI + Gateway 已重新进入预览状态": "Web UI + Gateway re-entered preview state",
            "OpenHuman 已作为 Hermes 长期记忆库": "OpenHuman is the Hermes long-term memory store",
            "Hermes config.yaml 不存在": "Hermes config.yaml does not exist",
            "OpenHuman Vault 不存在": "OpenHuman Vault does not exist",
            "OpenHuman SQLite 记忆库不存在": "OpenHuman SQLite memory database does not exist",
            "memory.provider 不是 openhuman": "memory.provider is not openhuman",
            "Hermes 内置长期记忆未关闭": "Hermes native long-term memory is not disabled",
            "Hermes 内置 memory toolset 未禁用": "Hermes native memory toolset is not disabled",
            "缺少 OPENHUMAN_VAULT": "Missing OPENHUMAN_VAULT",
            "缺少 OPENHUMAN_WORKSPACE": "Missing OPENHUMAN_WORKSPACE",
            "OpenHuman memory provider 插件不存在": "OpenHuman memory provider plugin does not exist",
            "Hermes 长期记忆未迁移到 OpenHuman": "Hermes long-term memory has not been migrated to OpenHuman",
            "OpenHuman DB 为空，尚未写入长期记忆": "OpenHuman DB is empty; no long-term memory has been written yet",
            "Web UI 已读取，CLI 当前模型未检测到": "Web UI was read; CLI current model was not detected",
            "需要同步：CLI 当前模型不在 Web UI 可用清单": "Needs sync: CLI current model is not in the Web UI available list",
            "Web UI API 未响应，已回退读取 CLI 配置": "Web UI API did not respond; fell back to CLI config",
            "安全预览：正在检测": "Safe preview: checking",
            "没有检测到可测试模型": "No testable model detected",
            "没有可检测模型": "No detectable model",
        ]
        if let translated = exact[value] {
            return translated
        }

        if let suffix = value.removingPrefix("记忆连接未完成：") {
            return "Memory bridge incomplete: \(dynamic(suffix))"
        }
        if let suffix = value.removingPrefix("安全预览：已预览同步 ") {
            return "Safe preview: synced \(suffix)"
        }
        if let suffix = value.removingPrefix("已校准：Web UI 与 CLI 都是 ") {
            return "Calibrated: Web UI and CLI both use \(suffix)"
        }
        if let suffix = value.removingPrefix("Web UI 当前 ") {
            return "Web UI current \(suffix)"
                .replacingOccurrences(of: "，CLI 配置 ", with: ", CLI config ")
        }
        if let suffix = value.removingPrefix("成功检测 ") {
            return "Successfully checked \(suffix)"
                .replacingOccurrences(of: " 个模型", with: " models")
        }
        if let suffix = value.removingPrefix("正在检测 ") {
            return "Checking \(suffix)"
        }
        if let suffix = value.removingPrefix("安全预览：") {
            return "Safe preview: \(dynamic(suffix))"
        }
        if let suffix = value.removingPrefix("部分服务未停止：仍在运行 ") {
            return "Some services did not stop: still running \(suffix)"
        }
        if let suffix = value.removingPrefix("部分服务未启动：缺少 ") {
            return "Some services did not start: missing \(suffix)"
        }
        if let suffix = value.removingPrefix("缺少 ") {
            return "Missing \(suffix)"
        }
        if let suffix = value.removingPrefix("仍在运行 ") {
            return "Still running \(suffix)"
        }
        if let suffix = value.removingPrefix("已复制") {
            return "Copied \(suffix)"
        }
        if let suffix = value.removingPrefix("正式使用时会打开 ") {
            return "When enabled, this opens \(suffix)"
        }

        return value
            .replacingOccurrences(of: " 个目标预览可用", with: " preview targets available")
            .replacingOccurrences(of: " 个模型接口可用", with: " model endpoints available")
            .replacingOccurrences(of: "，请查看日志或重新启动", with: "; check logs or restart")
            .replacingOccurrences(of: "，请查看日志", with: "; check logs")
            .replacingOccurrences(of: "OpenHuman 已作为 Hermes 长期记忆库", with: "OpenHuman is the Hermes long-term memory store")
            .replacingOccurrences(of: "Web UI 与 CLI 都是", with: "Web UI and CLI both use")
            .replacingOccurrences(of: "已校准", with: "Calibrated")
            .replacingOccurrences(of: "配置完成后打开 App 自动启动服务，关闭 App 自动停止服务", with: "After setup, opening the app starts services and quitting stops them")
            .replacingOccurrences(of: "显式点击后才启动服务", with: "Services start only after an explicit click")
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }

    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

struct AppToast: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let accent: Color
    let duration: TimeInterval
}

private struct CLIModelSnapshot {
    let providerKey: String
    let providerLabel: String
    let model: String
    let providerCount: Int
    let modelCount: Int
}

private struct WebUIModelSnapshot {
    let available: Bool
    let providerKey: String
    let providerLabel: String
    let model: String
    let providerCount: Int
    let modelCount: Int
    let presetProviderCount: Int
    let models: Set<String>
    let providerModels: Set<String>
    let error: String?
}

private struct ModelInventorySnapshot {
    var providerLabels: [String: String] = [:]
    var providerKeys: Set<String> = []
    var models: Set<String> = []
    var providerModels: Set<String> = []

    mutating func addProvider(key: String, label: String = "") {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        providerKeys.insert(normalized)
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanLabel.isEmpty {
            providerLabels[normalized] = cleanLabel
        }
    }

    mutating func addModel(_ model: String, provider: String = "") {
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanModel.isEmpty else { return }
        models.insert(cleanModel)
        let cleanProvider = provider.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanProvider.isEmpty {
            providerModels.insert("\(cleanProvider)|\(cleanModel)")
        }
    }

    mutating func merge(_ other: ModelInventorySnapshot) {
        providerLabels.merge(other.providerLabels) { current, _ in current }
        providerKeys.formUnion(other.providerKeys)
        models.formUnion(other.models)
        providerModels.formUnion(other.providerModels)
    }
}

struct HermesModelProviderPreset: Identifiable, Hashable {
    let label: String
    let value: String
    let baseURL: String
    let models: [String]

    var id: String { value }

    static let all: [HermesModelProviderPreset] = [
        HermesModelProviderPreset(label: "Anthropic", value: "anthropic", baseURL: "https://api.anthropic.com", models: ["claude-opus-4-7", "claude-opus-4-6", "claude-sonnet-4-6", "claude-opus-4-5-20251101", "claude-sonnet-4-5-20250929", "claude-opus-4-20250514", "claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"]),
        HermesModelProviderPreset(label: "Google AI Studio", value: "gemini", baseURL: "https://generativelanguage.googleapis.com/v1beta/openai", models: ["gemini-3.1-pro-preview", "gemini-3-flash-preview", "gemini-3.1-flash-lite-preview", "gemini-2.5-pro", "gemini-2.5-flash", "gemini-2.5-flash-lite", "gemma-4-31b-it", "gemma-4-26b-it"]),
        HermesModelProviderPreset(label: "DeepSeek", value: "deepseek", baseURL: "https://api.deepseek.com", models: ["deepseek-chat", "deepseek-reasoner"]),
        HermesModelProviderPreset(label: "Z.AI / GLM", value: "zai", baseURL: "https://api.z.ai/api/paas/v4", models: ["glm-5.1", "glm-5", "glm-5v-turbo", "glm-5-turbo", "glm-4.7", "glm-4.5", "glm-4.5-flash"]),
        HermesModelProviderPreset(label: "Kimi for Coding", value: "kimi-coding-cn", baseURL: "https://api.kimi.com/coding/v1", models: ["kimi-for-coding", "kimi-k2.5", "kimi-k2-thinking", "kimi-k2-turbo-preview", "kimi-k2-0905-preview"]),
        HermesModelProviderPreset(label: "Moonshot", value: "moonshot", baseURL: "https://api.moonshot.cn/v1", models: ["kimi-k2.5", "kimi-k2-thinking", "kimi-k2-turbo-preview", "kimi-k2-0905-preview"]),
        HermesModelProviderPreset(label: "xAI", value: "xai", baseURL: "https://api.x.ai/v1", models: ["grok-4.20-reasoning", "grok-4-1-fast-reasoning"]),
        HermesModelProviderPreset(label: "MiniMax", value: "minimax", baseURL: "https://api.minimax.io/anthropic/v1", models: ["MiniMax-M2.7", "MiniMax-M2.7-highspeed", "MiniMax-M2.5", "MiniMax-M2.5-highspeed", "MiniMax-M2.1", "MiniMax-M2.1-highspeed", "MiniMax-M2", "MiniMax-M2-highspeed"]),
        HermesModelProviderPreset(label: "MiniMax (China)", value: "minimax-cn", baseURL: "https://api.minimaxi.com/v1", models: ["MiniMax-M2.7", "MiniMax-M2.7-highspeed", "MiniMax-M2.5", "MiniMax-M2.5-highspeed", "MiniMax-M2.1", "MiniMax-M2.1-highspeed", "MiniMax-M2", "MiniMax-M2-highspeed"]),
        HermesModelProviderPreset(label: "Alibaba Cloud", value: "alibaba", baseURL: "https://dashscope-intl.aliyuncs.com/compatible-mode/v1", models: ["qwen3.5-plus", "qwen3-coder-plus", "qwen3-coder-next", "glm-5", "glm-4.7", "kimi-k2.5", "MiniMax-M2.5"]),
        HermesModelProviderPreset(label: "Hugging Face", value: "huggingface", baseURL: "https://router.huggingface.co/v1", models: ["Qwen/Qwen3.5-397B-A17B", "Qwen/Qwen3.5-35B-A3B", "deepseek-ai/DeepSeek-V3.2", "moonshotai/Kimi-K2.5", "MiniMaxAI/MiniMax-M2.5", "zai-org/GLM-5", "XiaomiMiMo/MiMo-V2-Flash", "moonshotai/Kimi-K2-Thinking"]),
        HermesModelProviderPreset(label: "Xiaomi MiMo", value: "xiaomi", baseURL: "https://api.xiaomimimo.com/v1", models: ["mimo-v2-pro", "mimo-v2-omni", "mimo-v2-flash"]),
        HermesModelProviderPreset(label: "Kilo Code", value: "kilocode", baseURL: "https://api.kilo.ai/api/gateway", models: ["anthropic/claude-opus-4.6", "anthropic/claude-sonnet-4.6", "openai/gpt-5.4", "google/gemini-3-pro-preview", "google/gemini-3-flash-preview"]),
        HermesModelProviderPreset(label: "Vercel AI Gateway", value: "ai-gateway", baseURL: "https://ai-gateway.vercel.sh/v1", models: ["anthropic/claude-opus-4.6", "anthropic/claude-sonnet-4.6", "anthropic/claude-sonnet-4.5", "anthropic/claude-haiku-4.5", "openai/gpt-5", "openai/gpt-4.1", "openai/gpt-4.1-mini", "google/gemini-3-pro-preview", "google/gemini-3-flash", "google/gemini-2.5-pro", "google/gemini-2.5-flash", "deepseek/deepseek-v3.2"]),
        HermesModelProviderPreset(label: "OpenCode Zen", value: "opencode-zen", baseURL: "https://opencode.ai/zen/v1", models: ["gpt-5.4-pro", "gpt-5.4", "gpt-5.3-codex", "gpt-5.3-codex-spark", "gpt-5.2", "gpt-5.2-codex", "gpt-5.1", "gpt-5.1-codex", "gpt-5.1-codex-max", "gpt-5.1-codex-mini", "gpt-5", "gpt-5-codex", "gpt-5-nano", "claude-opus-4-6", "claude-opus-4-5", "claude-opus-4-1", "claude-sonnet-4-6", "claude-sonnet-4-5", "claude-sonnet-4", "claude-haiku-4-5", "claude-3-5-haiku", "gemini-3.1-pro", "gemini-3-pro", "gemini-3-flash", "minimax-m2.7", "minimax-m2.5", "minimax-m2.5-free", "minimax-m2.1", "glm-5", "glm-4.7", "glm-4.6", "kimi-k2.5", "kimi-k2-thinking", "kimi-k2", "qwen3-coder", "big-pickle"]),
        HermesModelProviderPreset(label: "OpenCode Go", value: "opencode-go", baseURL: "https://opencode.ai/zen/go/v1", models: ["glm-5.1", "glm-5", "kimi-k2.5", "mimo-v2-pro", "mimo-v2-omni", "minimax-m2.7", "minimax-m2.5"]),
        HermesModelProviderPreset(label: "OpenAI Codex", value: "openai-codex", baseURL: "https://chatgpt.com/backend-api/codex", models: ["gpt-5.4-mini", "gpt-5.4", "gpt-5.3-codex", "gpt-5.2-codex", "gpt-5.1-codex-max", "gpt-5.1-codex-mini"]),
        HermesModelProviderPreset(label: "Arcee AI", value: "arcee", baseURL: "https://api.arcee.ai/v1", models: ["trinity-large-thinking", "trinity-large-preview", "trinity-mini"]),
        HermesModelProviderPreset(label: "OpenRouter", value: "openrouter", baseURL: "https://openrouter.ai/api/v1", models: []),
    ]

    static func preset(for key: String) -> HermesModelProviderPreset? {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return all.first { $0.value.lowercased() == normalized }
    }
}

struct ModelHealthResult: Identifiable, Equatable {
    let id = UUID()
    let provider: String
    let model: String
    let ok: Bool
    let latencyMS: Int?
    let detail: String
}

private struct ModelProbeTarget: Hashable {
    let providerKey: String
    let providerLabel: String
    let baseURL: String
    let apiKey: String
    let model: String
}

private struct ResolvedModelProviderSource {
    var providerKey: String
    var label: String
    var kind: ModelProviderKind
    var baseURL: String
    var apiKey: String
    var models: Set<String>
    var headersPreview: String
    var timeoutSeconds: Int
    var retryCount: Int
}

private struct CurrentCLIModelBlock {
    var providerKey: String
    var baseURL: String
    var defaultModel: String
}

// MARK: - Service Manager

class ServiceManager: ObservableObject {
    @Published var webUIRunning = false
    @Published var gatewayRunning = false
    @Published var openHumanMemoryLinked = false
    @Published var migratedMemoryAvailable = false
    @Published var memoryBridgeIssues: [String] = []
    @Published var memoryBridgeWarnings: [String] = []
    @Published var memoryBridgeSummary = "等待检测"
    @Published var openHumanDocumentCount = 0
    @Published var migratedMemoryDocumentCount = 0
    @Published var legacyHermesMemoryCount = 0
    @Published var logLines: [String] = []
    @Published var gatewayLogLines: [String] = []
    @Published var statusMessage = "就绪"
    @Published var isLoading = false
    @Published var autoStartDone = false
    @Published var webUIToken: String = ""
    @Published var webUITokenPath: String = ""
    @Published var webUIDataDirectory: String = ""
    @Published var currentModelProvider: String = ""
    @Published var currentModelName: String = ""
    @Published var modelCalibrationSummary: String = "等待校准"
    @Published var modelCalibrationHealthy = false
    @Published var detectedProviderCount: Int = 0
    @Published var detectedModelCount: Int = 0
    @Published var modelStatusUpdatedAt: String = ""
    @Published var modelHealthResults: [ModelHealthResult] = []
    @Published var modelDetectionHistory: [ModelDetectionRecord] = []
    @Published var modelHealthSummary: String = "尚未检测"
    @Published var isCheckingModelHealth = false
    @Published private(set) var cachedModelSystemSnapshot: ModelSystemSnapshot?
    @Published var webUIURL = "http://localhost:8648"
    @Published var toast: AppToast?

    let appVersion = "v0.2.0"
    @Published var remoteManifest: RemoteVersionManifest = .bundled
    @Published var remoteManifestSource = "内置离线清单"
    @Published var remoteManifestStatus = "等待检测"
    @Published var remoteManifestLoading = false

    var appTargetVersion: String {
        remoteManifest.appTargetVersion(includePreview: UserDefaults.standard.bool(forKey: "includePreviewAppUpdates"))
    }

    var webUITestedTargetVersion: String {
        VersionFormatting.displayVersion(remoteManifest.components.hermesWebUI.version)
    }

    var hermesTestedTargetVersion: String {
        remoteManifest.components.hermes.displayVersion
    }

    var openHumanTestedTargetVersion: String {
        remoteManifest.components.openHuman.displayVersion
    }

    var compatibilityBundleTargetVersion: String {
        remoteManifest.compatibilityBundle.displayVersion(
            hermes: hermesTestedTargetVersion,
            openHuman: openHumanTestedTargetVersion
        )
    }

    var compatibilityBundleLabel: String {
        remoteManifest.compatibilityBundle.displayLabel(
            hermes: hermesTestedTargetVersion,
            openHuman: openHumanTestedTargetVersion
        )
    }

    private var logTimer: Timer?
    private var statusTimer: Timer?
    private var lastTokenPathScan = Date.distantPast
    private var lastStatusRefresh = Date.distantPast
    private var lastModelRefresh = Date.distantPast
    private var lastLogRefresh = Date.distantPast
    private var statusRefreshInFlight = false
    private var modelRefreshInFlight = false
    private var logRefreshInFlight = false
    private var cachedWebUIRunning: Bool?
    private var cachedGatewayRunning: Bool?
    private var cachedWebUIURL = ""
    private var appStartedWebUI = false
    private var appStartedGateway = false

    private var managerHome: String {
        NSHomeDirectory() + "/.hermes-manager"
    }

    private var hermesHome: String {
        NSHomeDirectory() + "/.hermes"
    }

    var activeHermesProfileHome: String {
        let activeFile = hermesHome + "/active_profile"
        guard let raw = try? String(contentsOfFile: activeFile, encoding: .utf8) else {
            return hermesHome
        }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != "default" else {
            return hermesHome
        }
        let profileHome = hermesHome + "/profiles/" + name
        return FileManager.default.fileExists(atPath: profileHome) ? profileHome : hermesHome
    }

    var activeHermesConfigPath: String {
        activeHermesProfileHome + "/config.yaml"
    }

    private var activeHermesEnvPath: String {
        activeHermesProfileHome + "/.env"
    }

    private var webUIRuntimeHome: String {
        managerHome + "/runtime/hermes-web-ui"
    }

    private var privateWebUIExecutable: String {
        webUIRuntimeHome + "/node_modules/.bin/hermes-web-ui"
    }

    private var webUICommand: String {
        if FileManager.default.fileExists(atPath: privateWebUIExecutable) {
            return shellQuote(privateWebUIExecutable)
        }
        return "hermes-web-ui"
    }

    init() {
        if AppRuntimeMode.documentationScreenshot {
            applyDocumentationSnapshot()
        } else {
            checkStatus()
            readToken()
            refreshModelStatus()
            loadRemoteVersionManifest()
            startMonitoring()
        }
    }

    private func applyDocumentationSnapshot() {
        webUIRunning = true
        gatewayRunning = true
        openHumanMemoryLinked = true
        migratedMemoryAvailable = true
        memoryBridgeIssues = []
        memoryBridgeWarnings = []
        memoryBridgeSummary = "OpenHuman 已作为 Hermes 长期记忆库"
        openHumanDocumentCount = 24
        migratedMemoryDocumentCount = 8
        legacyHermesMemoryCount = 0
        statusMessage = "服务已就绪"
        webUIToken = "hm_preview_token_hidden_for_docs"
        webUITokenPath = "~/.hermes-web-ui/.token"
        webUIDataDirectory = "~/.hermes-web-ui"
        currentModelProvider = "OpenAI Compatible"
        currentModelName = "未配置"
        modelCalibrationSummary = "可在完成安装后配置模型"
        modelCalibrationHealthy = true
        detectedProviderCount = 0
        detectedModelCount = 0
        modelStatusUpdatedAt = "文档示例"
        webUIURL = "http://localhost:8648"
        remoteManifest = .bundled
        remoteManifestSource = "内置离线清单"
        remoteManifestStatus = "版本清单已就绪"
    }

    func loadRemoteVersionManifest(completion: (() -> Void)? = nil) {
        if AppRuntimeMode.uiPrototype {
            remoteManifest = RemoteVersionManifest.bundled
            remoteManifestSource = "内置离线清单"
            remoteManifestStatus = "安全预览：已使用内置离线清单"
            completion?()
            return
        }

        remoteManifestLoading = true
        remoteManifestStatus = "正在读取版本清单..."
        RemoteVersionManifestService.fetch { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.remoteManifestLoading = false
                switch result {
                case .success(let value):
                    self.remoteManifest = value.0
                    self.remoteManifestSource = value.1
                    self.remoteManifestStatus = "版本清单已更新"
                case .failure(let error):
                    self.remoteManifest = .bundled
                    self.remoteManifestSource = "内置离线清单"
                    self.remoteManifestStatus = "远程清单读取失败，已回退内置清单：\(error.localizedDescription)"
                }
                completion?()
            }
        }
    }

    func autoStart() {
        if AppRuntimeMode.uiPrototype {
            autoStartDone = true
            statusMessage = "安全预览：不会自动启动服务"
            return
        }
        if autoStartDone { return }
        autoStartDone = true

        guard AppRuntimeMode.autoStartServicesOnLaunch else {
            checkStatus()
            readToken()
            refreshModelStatus()
            statusMessage = "控制面板就绪，服务仅在用户点击后启动"
            return
        }
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            let memory = self?.detectMemoryBridgeStatus()
                ?? MemoryBridgeDiagnosticSnapshot(linked: false, migrated: false, issues: ["等待检测"], warnings: [], openHumanDocumentCount: 0, migratedDocumentCount: 0, legacyHermesMemoryCount: 0)
            guard memory.linked && memory.migrated else {
                DispatchQueue.main.async {
                    self?.openHumanMemoryLinked = memory.linked
                    self?.migratedMemoryAvailable = memory.migrated
                    self?.memoryBridgeIssues = memory.issues
                    self?.memoryBridgeWarnings = memory.warnings
                    self?.memoryBridgeSummary = memory.summary
                    self?.openHumanDocumentCount = memory.openHumanDocumentCount
                    self?.migratedMemoryDocumentCount = memory.migratedDocumentCount
                    self?.legacyHermesMemoryCount = memory.legacyHermesMemoryCount
                    self?.statusMessage = "记忆连接未完成：\(memory.summary)"
                    self?.showToast(title: "需要先修复记忆连接", message: memory.summary, icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
                }
                return
            }
            let webUIWasRunning = self?.isWebUIRunning() ?? false
            let gatewayWasRunning = self?.isGatewayRunning() ?? false
            
            if !webUIWasRunning {
                _ = self?.runWebUICommand("start")
                sleep(1)
            }
            if !gatewayWasRunning {
                _ = self?.runCommand("hermes gateway start")
            }
            
            sleep(2)
            let webUIRunning = self?.isWebUIRunning() ?? false
            let gatewayRunning = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                guard let self else { return }
                if webUIRunning && !webUIWasRunning { self.appStartedWebUI = true }
                if gatewayRunning && !gatewayWasRunning { self.appStartedGateway = true }
                self.applyServiceStatus(
                    webUIRunning: webUIRunning,
                    gatewayRunning: gatewayRunning,
                    successMessage: webUIWasRunning && gatewayWasRunning ? "服务已就绪" : "服务已自动启动",
                    partialMessage: "部分服务未启动",
                    failureMessage: "服务自动启动失败",
                    successToastTitle: webUIWasRunning && gatewayWasRunning ? "服务已就绪" : "服务已自动启动",
                    openBrowserIfWebUIRunning: true
                )
            }
        }
    }

    func stopAllForAppQuit() {
        guard AppRuntimeMode.stopServicesOnAppQuit, !AppRuntimeMode.uiPrototype else { return }
        if appStartedGateway {
            _ = runCommand("hermes gateway stop")
            appStartedGateway = false
        }
        if appStartedWebUI {
            _ = runWebUICommand("stop")
            appStartedWebUI = false
        }
    }

    func checkStatus(force: Bool = false) {
        let now = Date()
        guard force || (!statusRefreshInFlight && now.timeIntervalSince(lastStatusRefresh) >= 8) else { return }
        statusRefreshInFlight = true
        DispatchQueue.global(qos: .background).async { [weak self] in
            let webUIRunning = self?.isWebUIRunning(useCache: !force) ?? false
            let gatewayRunning = self?.isGatewayRunning(useCache: !force) ?? false
            let memory = self?.detectMemoryBridgeStatus()
                ?? MemoryBridgeDiagnosticSnapshot(linked: false, migrated: false, issues: ["等待检测"], warnings: [], openHumanDocumentCount: 0, migratedDocumentCount: 0, legacyHermesMemoryCount: 0)
            let detectedWebURL = self?.detectWebUIURL() ?? "http://localhost:8648"

            DispatchQueue.main.async {
                guard let self else { return }
                self.statusRefreshInFlight = false
                self.lastStatusRefresh = Date()
                self.applyIfChanged(&self.webUIRunning, webUIRunning)
                self.applyIfChanged(&self.gatewayRunning, gatewayRunning)
                self.applyIfChanged(&self.openHumanMemoryLinked, memory.linked)
                self.applyIfChanged(&self.migratedMemoryAvailable, memory.migrated)
                self.applyIfChanged(&self.memoryBridgeIssues, memory.issues)
                self.applyIfChanged(&self.memoryBridgeWarnings, memory.warnings)
                self.applyIfChanged(&self.memoryBridgeSummary, memory.summary)
                self.applyIfChanged(&self.openHumanDocumentCount, memory.openHumanDocumentCount)
                self.applyIfChanged(&self.migratedMemoryDocumentCount, memory.migratedDocumentCount)
                self.applyIfChanged(&self.legacyHermesMemoryCount, memory.legacyHermesMemoryCount)
                self.applyIfChanged(&self.webUIURL, detectedWebURL)
                self.cachedWebUIRunning = webUIRunning
                self.cachedGatewayRunning = gatewayRunning
                self.cachedWebUIURL = detectedWebURL
            }
        }
    }

    private func isProcessRunning(_ name: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "pgrep -f '\(name)'"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !output.isEmpty
        } catch {
            return false
        }
    }

    private func isWebUIRunning(useCache: Bool = true) -> Bool {
        if useCache, let cachedWebUIRunning, Date().timeIntervalSince(lastStatusRefresh) < 8 {
            return cachedWebUIRunning
        }
        let output = runWebUICommand("status").lowercased()
        let running: Bool
        if output.contains("is not running") || output.contains("not running") {
            running = false
        } else if output.contains("is running") || output.contains("running (pid") {
            running = true
        } else {
            running = isProcessRunning("hermes-web-ui/dist/server/index.js")
        }
        cachedWebUIRunning = running
        return running
    }

    private func isGatewayRunning(useCache: Bool = true) -> Bool {
        if useCache, let cachedGatewayRunning, Date().timeIntervalSince(lastStatusRefresh) < 8 {
            return cachedGatewayRunning
        }
        let output = runCommand("hermes gateway status").lowercased()
        let processRunning = isProcessRunning("hermes_cli.main.*gateway.*run")
        let running: Bool
        if output.contains("gateway process is running") || processRunning {
            running = true
        } else if output.contains("not loaded") || output.contains("not running") || output.contains("could not find service") {
            running = false
        } else if output.contains("gateway service is loaded") || output.contains("service is loaded") {
            running = true
        } else {
            running = false
        }
        cachedGatewayRunning = running
        return running
    }

    private func missingServicesDescription(webUIRunning: Bool, gatewayRunning: Bool) -> String {
        var missing: [String] = []
        if !webUIRunning { missing.append("Hermes Web UI") }
        if !gatewayRunning { missing.append("Hermes Gateway") }
        return missing.isEmpty ? "无" : missing.joined(separator: "、")
    }

    private func runningServicesDescription(webUIRunning: Bool, gatewayRunning: Bool) -> String {
        var running: [String] = []
        if webUIRunning { running.append("Hermes Web UI") }
        if gatewayRunning { running.append("Hermes Gateway") }
        return running.isEmpty ? "无" : running.joined(separator: "、")
    }

    private func applyServiceStatus(
        webUIRunning: Bool,
        gatewayRunning: Bool,
        successMessage: String,
        partialMessage: String,
        failureMessage: String,
        successToastTitle: String,
        openBrowserIfWebUIRunning: Bool = false
    ) {
        self.webUIRunning = webUIRunning
        self.gatewayRunning = gatewayRunning
        isLoading = false

        if webUIRunning && gatewayRunning {
            statusMessage = successMessage
            showToast(title: successToastTitle, message: "Web UI 和 Gateway 均已运行", icon: "bolt.fill", accent: SetupPalette.emerald)
        } else if webUIRunning || gatewayRunning {
            let missing = missingServicesDescription(webUIRunning: webUIRunning, gatewayRunning: gatewayRunning)
            statusMessage = "\(partialMessage)：缺少 \(missing)"
            showToast(title: partialMessage, message: "缺少 \(missing)，请查看日志或重新启动", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
        } else {
            statusMessage = failureMessage
            showToast(title: failureMessage, message: "Web UI 和 Gateway 均未运行，请查看日志", icon: "xmark.octagon.fill", accent: DesignTokens.error)
        }

        if openBrowserIfWebUIRunning, webUIRunning {
            openWebUIInBrowser()
        }
    }

    func startWebUI() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览启动 Web UI"
            showToast(title: "已预览启动 Web UI", message: "安全预览不会启动本机服务", icon: "play.fill", accent: SetupPalette.emerald)
            return
        }
        isLoading = true
        statusMessage = "正在启动 Web UI..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            let wasRunning = self?.isWebUIRunning() ?? false
            _ = self?.runWebUICommand("start")
            sleep(1)
            let running = self?.isWebUIRunning() ?? false
            DispatchQueue.main.async {
                if running && !wasRunning { self?.appStartedWebUI = true }
                self?.webUIRunning = running
                self?.isLoading = false
                self?.statusMessage = running ? "Web UI 已启动" : "Web UI 启动失败"
                self?.showToast(
                    title: running ? "Web UI 已启动" : "Web UI 启动失败",
                    message: running ? "可以打开控制台地址继续使用" : "请到日志页查看详细输出",
                    icon: running ? "play.fill" : "exclamationmark.triangle.fill",
                    accent: running ? SetupPalette.emerald : DesignTokens.error
                )
                self?.checkStatus(force: true)
            }
        }
    }

    func stopWebUI() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览停止 Web UI"
            showToast(title: "已预览停止 Web UI", message: "安全预览不会停止本机服务", icon: "stop.fill", accent: SetupPalette.amber)
            return
        }
        isLoading = true
        statusMessage = "正在停止 Web UI..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            _ = self?.runWebUICommand("stop")
            sleep(1)
            let running = self?.isWebUIRunning() ?? false
            DispatchQueue.main.async {
                let succeeded = !running
                if succeeded { self?.appStartedWebUI = false }
                self?.webUIRunning = running
                self?.statusMessage = succeeded ? "Web UI 已停止" : "Web UI 停止失败"
                self?.isLoading = false
                self?.checkStatus(force: true)
                self?.showToast(
                    title: succeeded ? "Web UI 已停止" : "Web UI 停止失败",
                    message: succeeded ? "服务已关闭" : "请到日志页查看详细输出",
                    icon: succeeded ? "stop.fill" : "exclamationmark.triangle.fill",
                    accent: succeeded ? SetupPalette.amber : DesignTokens.error
                )
            }
        }
    }

    func startGateway() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览启动 Gateway"
            showToast(title: "已预览启动 Gateway", message: "安全预览不会启动本机服务", icon: "play.fill", accent: SetupPalette.emerald)
            return
        }
        isLoading = true
        statusMessage = "正在启动 Gateway..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            let wasRunning = self?.isGatewayRunning() ?? false
            _ = self?.runCommand("hermes gateway start")
            sleep(1)
            let running = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                if running && !wasRunning { self?.appStartedGateway = true }
                self?.gatewayRunning = running
                self?.statusMessage = running ? "Gateway 已启动" : "Gateway 启动失败"
                self?.isLoading = false
                self?.checkStatus(force: true)
                self?.showToast(
                    title: running ? "Gateway 已启动" : "Gateway 启动失败",
                    message: running ? "Hermes 主控链路已打开" : "请到日志页查看详细输出",
                    icon: running ? "play.fill" : "exclamationmark.triangle.fill",
                    accent: running ? SetupPalette.emerald : DesignTokens.error
                )
            }
        }
    }

    func stopGateway() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览停止 Gateway"
            showToast(title: "已预览停止 Gateway", message: "安全预览不会停止本机服务", icon: "stop.fill", accent: SetupPalette.amber)
            return
        }
        isLoading = true
        statusMessage = "正在停止 Gateway..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            _ = self?.runCommand("hermes gateway stop")
            sleep(1)
            let running = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                let succeeded = !running
                if succeeded { self?.appStartedGateway = false }
                self?.gatewayRunning = running
                self?.statusMessage = succeeded ? "Gateway 已停止" : "Gateway 停止失败"
                self?.isLoading = false
                self?.checkStatus(force: true)
                self?.showToast(
                    title: succeeded ? "Gateway 已停止" : "Gateway 停止失败",
                    message: succeeded ? "Hermes 主控链路已关闭" : "请到日志页查看详细输出",
                    icon: succeeded ? "stop.fill" : "exclamationmark.triangle.fill",
                    accent: succeeded ? SetupPalette.amber : DesignTokens.error
                )
            }
        }
    }

    func startAll(openBrowserIfWebUIRunning: Bool = false) {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览启动所有服务"
            showToast(title: "已预览启动全部", message: "Web UI + Gateway 已进入预览状态", icon: "bolt.fill", accent: SetupPalette.emerald)
            return
        }
        isLoading = true
        statusMessage = "正在启动所有服务..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            let webUIWasRunning = self?.isWebUIRunning() ?? false
            if !webUIWasRunning { _ = self?.runWebUICommand("start") }
            sleep(1)
            let gatewayWasRunning = self?.isGatewayRunning() ?? false
            if !gatewayWasRunning { _ = self?.runCommand("hermes gateway start") }
            sleep(2)
            let webUIRunning = self?.isWebUIRunning() ?? false
            let gatewayRunning = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                guard let self else { return }
                if webUIRunning && !webUIWasRunning { self.appStartedWebUI = true }
                if gatewayRunning && !gatewayWasRunning { self.appStartedGateway = true }
                self.applyServiceStatus(
                    webUIRunning: webUIRunning,
                    gatewayRunning: gatewayRunning,
                    successMessage: "所有服务已启动",
                    partialMessage: "部分服务未启动",
                    failureMessage: "服务启动失败",
                    successToastTitle: "已启动全部服务",
                    openBrowserIfWebUIRunning: openBrowserIfWebUIRunning
                )
            }
        }
    }

    func stopAll() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览停止所有服务"
            showToast(title: "已预览停止全部", message: "安全预览不会修改本机进程", icon: "pause.fill", accent: SetupPalette.amber)
            return
        }
        isLoading = true
        statusMessage = "正在停止所有服务..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            _ = self?.runCommand("hermes gateway stop")
            _ = self?.runWebUICommand("stop")
            sleep(2)
            let webUIRunning = self?.isWebUIRunning() ?? false
            let gatewayRunning = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                guard let self else { return }
                self.webUIRunning = webUIRunning
                self.gatewayRunning = gatewayRunning
                self.isLoading = false
                if !webUIRunning { self.appStartedWebUI = false }
                if !gatewayRunning { self.appStartedGateway = false }
                if webUIRunning || gatewayRunning {
                    let running = self.runningServicesDescription(webUIRunning: webUIRunning, gatewayRunning: gatewayRunning)
                    self.statusMessage = "部分服务未停止：仍在运行 \(running)"
                    self.showToast(title: "部分服务未停止", message: "仍在运行 \(running)，请查看日志", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
                } else {
                    self.statusMessage = "所有服务已停止"
                    self.showToast(title: "已停止全部服务", message: "Web UI 和 Gateway 已关闭", icon: "pause.fill", accent: SetupPalette.amber)
                }
            }
        }
    }

    func restartAll() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览重启所有服务"
            showToast(title: "已预览重启全部", message: "Web UI + Gateway 已重新进入预览状态", icon: "arrow.clockwise", accent: SetupPalette.cyan)
            return
        }
        isLoading = true
        statusMessage = "正在重启所有服务..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            _ = self?.runCommand("hermes gateway stop")
            _ = self?.runWebUICommand("stop")
            sleep(1)
            _ = self?.runWebUICommand("start")
            sleep(1)
            _ = self?.runCommand("hermes gateway start")
            sleep(2)
            let webUIRunning = self?.isWebUIRunning() ?? false
            let gatewayRunning = self?.isGatewayRunning() ?? false
            DispatchQueue.main.async {
                guard let self else { return }
                if webUIRunning { self.appStartedWebUI = true }
                if gatewayRunning { self.appStartedGateway = true }
                self.applyServiceStatus(
                    webUIRunning: webUIRunning,
                    gatewayRunning: gatewayRunning,
                    successMessage: "所有服务已重启",
                    partialMessage: "部分服务重启失败",
                    failureMessage: "服务重启失败",
                    successToastTitle: "已重启全部服务"
                )
            }
        }
    }

    func updateHermes() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览 Hermes 核心组件更新"
            return
        }
        isLoading = true
        statusMessage = "正在更新 Hermes 兼容包..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            let result = self?.runCommand("hermes update") ?? "失败"
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.statusMessage = result.lowercased().contains("error") ? "Hermes 更新可能失败" : "Hermes 更新命令已完成"
                self?.showToast(
                    title: "Hermes 更新完成",
                    message: "请查看日志确认版本和重启提示",
                    icon: "arrow.down.circle.fill",
                    accent: SetupPalette.cyan
                )
            }
        }
    }

    func updateWebUI() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览 Web UI 更新"
            return
        }
        isLoading = true
        statusMessage = "正在执行 Hermes Web UI 更新..."
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            let result = self.runWebUICommand("update")
            DispatchQueue.main.async {
                self.isLoading = false
                self.statusMessage = result.lowercased().contains("error") ? "Web UI 更新可能失败" : "Web UI 更新命令已完成"
                self.showToast(
                    title: "Web UI 更新完成",
                    message: "已执行 hermes-web-ui update，请查看日志确认版本",
                    icon: "arrow.down.circle.fill",
                    accent: SetupPalette.cyan
                )
            }
        }
    }

    func downloadAppUpdate(release: AppReleaseManifest, completion: @escaping (Result<URL, Error>) -> Void) {
        if AppRuntimeMode.uiPrototype {
            completion(.success(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads/HermesManager-ui-preview.dmg")))
            return
        }
        isLoading = true
        statusMessage = "正在下载 Hermes Manager 更新..."
        AppUpdateDownloadService.download(release: release) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let fileURL):
                    self?.statusMessage = "Hermes Manager 更新包已下载"
                    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                    NSWorkspace.shared.open(fileURL)
                    self?.showToast(title: "更新包已下载", message: "已保存到 Downloads，并打开 DMG 安装包", icon: "arrow.down.circle.fill", accent: SetupPalette.emerald)
                case .failure(let error):
                    self?.statusMessage = "Hermes Manager 更新下载失败"
                    self?.showToast(title: "下载失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: DesignTokens.error)
                }
                completion(result)
            }
        }
    }

    func updateCompatibilityBundle(completion: @escaping (Result<Void, Error>) -> Void) {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：已预览 Hermes + OpenHuman 核心组件更新"
            completion(.success(()))
            return
        }
        isLoading = true
        statusMessage = "正在更新 Hermes + OpenHuman 核心组件..."
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let manifest = self.remoteManifest
            let result = SetupExecutionService(versionManifest: manifest).updateCompatibilityBundle(manifest: manifest) { line in
                DispatchQueue.main.async {
                    self.logLines.append(line)
                }
            }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    self.statusMessage = "Hermes + OpenHuman 核心组件更新完成"
                    self.showToast(title: "核心组件更新完成", message: manifest.compatibilityBundle.label, icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
                case .failure(let error):
                    self.statusMessage = "Hermes + OpenHuman 核心组件更新失败"
                    self.showToast(title: "核心组件更新失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: DesignTokens.error)
                }
                completion(result)
            }
        }
    }

    func detectedHermesVersion() -> String {
        let output = runReadOnlyCommand("hermes --version 2>/dev/null || hermes version 2>/dev/null || true")
        return normalizedVersionOutput(output)
    }

    func detectedWebUIVersion() -> String {
        let output = runReadOnlyCommand("\(webUICommand) --version 2>/dev/null || \(webUICommand) version 2>/dev/null || true")
        return normalizedVersionOutput(output)
    }

    func detectedOpenHumanVersion() -> String {
        let output = runReadOnlyCommand("openhuman --version 2>/dev/null || python3 - <<'PY'\nimport importlib.metadata as m\nfor name in ['openhuman','open-human','tinyhumansai-openhuman']:\n    try:\n        print(name + ' ' + m.version(name))\n        raise SystemExit\n    except Exception:\n        pass\nPY")
        let detected = normalizedVersionOutput(output, fallback: "")
        return detected.isEmpty ? openHumanTestedTargetVersion : detected
    }

    private func normalizedVersionOutput(_ output: String, fallback: String = "未检测") -> String {
        let lines = output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.lowercased().contains("skipped:") }
        for line in lines {
            let version = VersionFormatting.displayVersion(line, fallback: "")
            if !version.isEmpty { return version }
        }
        return fallback
    }

    func copyToClipboard(_ value: String, label: String, message: String = "已写入剪贴板，可直接粘贴使用") {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showToast(title: "\(label)为空", message: "当前没有可复制内容", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)
        showToast(title: "已复制\(label)", message: message, icon: "doc.on.doc.fill", accent: SetupPalette.emerald)
    }

    func openWebUIInBrowser() {
        if AppRuntimeMode.uiPrototype {
            statusMessage = "安全预览：不会打开浏览器"
            showToast(title: "已预览打开 Web UI", message: "正式使用时会打开 \(webUIURL)", icon: "safari", accent: SetupPalette.cyan)
            return
        }
        let detectedURL = detectWebUIURL()
        webUIURL = detectedURL
        if let url = URL(string: detectedURL) {
            NSWorkspace.shared.open(url)
        }
    }

    func readLogs() {
        refreshLogsIfNeeded(force: true)
    }

    private func refreshLogsIfNeeded(force: Bool = false) {
        let now = Date()
        guard force || (!logRefreshInFlight && now.timeIntervalSince(lastLogRefresh) >= 8) else { return }
        logRefreshInFlight = true
        lastLogRefresh = now
        let knownDataDir = webUIDataDirectory

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let dataDir = knownDataDir.isEmpty ? self.locateWebUIDataDirectory() : knownDataDir
            let webLogPath = (dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui" : dataDir) + "/logs/server.log"
            let gatewayLogPath = NSHomeDirectory() + "/.hermes/logs/gateway.log"
            let webLines = self.tailLogLines(at: webLogPath, fallback: "[暂无服务器日志]")
            let gatewayLines = self.tailLogLines(at: gatewayLogPath, fallback: "[暂无 Gateway 日志]")

            DispatchQueue.main.async {
                self.logRefreshInFlight = false
                self.applyIfChanged(&self.logLines, webLines)
                self.applyIfChanged(&self.gatewayLogLines, gatewayLines)
            }
        }
    }

    func readToken() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let tokenPath = self.locateWebUITokenPath()
            let token = (FileManager.default.contents(atPath: tokenPath)
                .flatMap { String(data: $0, encoding: .utf8) } ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let dataDirectory = token.isEmpty ? self.webUIDataDirectory : URL(fileURLWithPath: tokenPath).deletingLastPathComponent().path

            DispatchQueue.main.async {
                self.applyIfChanged(&self.webUIToken, token)
                self.applyIfChanged(&self.webUITokenPath, tokenPath)
                self.applyIfChanged(&self.webUIDataDirectory, dataDirectory)
            }
        }
    }

    func refreshModelStatus() {
        let now = Date()
        guard !modelRefreshInFlight, now.timeIntervalSince(lastModelRefresh) >= 8 else { return }
        modelRefreshInFlight = true
        lastModelRefresh = now
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let cli = self.detectCLIModelStatus()
            let web = self.detectWebUIModelStatus()
            let snapshot = self.buildModelSystemSnapshot(cli: cli, web: web)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            DispatchQueue.main.async {
                self.modelRefreshInFlight = false
                let display = web.available ? web : WebUIModelSnapshot(
                    available: false,
                    providerKey: cli.providerKey,
                    providerLabel: cli.providerLabel,
                    model: cli.model,
                    providerCount: 0,
                    modelCount: 0,
                    presetProviderCount: 0,
                    models: [],
                    providerModels: [],
                    error: web.error
                )
                self.applyIfChanged(&self.currentModelProvider, self.displayProviderName(label: display.providerLabel, key: display.providerKey))
                self.applyIfChanged(&self.currentModelName, display.model)

                let cliPair = "\(cli.providerKey)|\(cli.model)"
                let webPair = "\(web.providerKey)|\(web.model)"
                let webContainsCurrent = web.models.contains(web.model) || web.providerModels.contains(webPair)
                let cliMatchesWeb = !cli.model.isEmpty
                    && !web.model.isEmpty
                    && cli.model == web.model
                    && self.normalizedProviderKey(cli.providerKey) == self.normalizedProviderKey(web.providerKey)
                let cliVisibleInWeb = web.models.contains(cli.model) || web.providerModels.contains(cliPair)
                self.applyIfChanged(&self.modelCalibrationHealthy, web.available && webContainsCurrent && (cli.model.isEmpty || cliMatchesWeb || cliVisibleInWeb))

                let summary: String
                if web.available && cliMatchesWeb {
                    summary = "已校准：Web UI 与 CLI 都是 \(web.providerLabel.isEmpty ? web.providerKey : web.providerLabel) / \(web.model)"
                } else if web.available && cli.model.isEmpty {
                    summary = "Web UI 已读取，CLI 当前模型未检测到"
                } else if web.available && cliVisibleInWeb {
                    summary = "Web UI 当前 \(web.providerKey)/\(web.model)，CLI 配置 \(cli.providerKey)/\(cli.model)"
                } else if web.available {
                    summary = "需要同步：CLI 当前模型不在 Web UI 可用清单"
                } else if !cli.model.isEmpty {
                    summary = "Web UI API 未响应，已回退读取 CLI 配置"
                } else {
                    summary = web.error ?? "未检测到 Hermes 当前模型"
                }
                self.applyIfChanged(&self.modelCalibrationSummary, summary)
                self.applyIfChanged(&self.detectedProviderCount, max(web.providerCount, cli.providerCount))
                self.applyIfChanged(&self.detectedModelCount, max(web.modelCount, cli.modelCount))
                self.cachedModelSystemSnapshot = snapshot
                self.applyIfChanged(&self.modelStatusUpdatedAt, formatter.string(from: Date()))
            }
        }
    }

    func configureModelProvider(_ configuration: ModelProviderConfiguration) {
        let provider = configuration.providerKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = configuration.defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !provider.isEmpty, !model.isEmpty else {
            showToast(title: "模型配置不完整", message: "Provider 和默认模型不能为空", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }

        if AppRuntimeMode.uiPrototype {
            currentModelProvider = displayProviderName(label: configuration.providerLabel, key: provider)
            currentModelName = model
            detectedProviderCount = max(detectedProviderCount, 1)
            detectedModelCount = max(detectedModelCount, configuration.models.count)
            modelCalibrationHealthy = true
            modelCalibrationSummary = "安全预览：已预览同步 \(provider) / \(model)"
            modelStatusUpdatedAt = currentTimeString()
            modelDetectionHistory.insert(
                ModelDetectionRecord(
                    id: UUID(),
                    targetType: "provider",
                    title: "模型配置已更新",
                    detail: "已预览同步 \(displayProviderName(label: configuration.providerLabel, key: provider)) / \(model)",
                    status: .warning,
                    latencyMS: nil,
                    availabilityPercent: nil,
                    checkedAt: modelStatusUpdatedAt
                ),
                at: 0
            )
            modelDetectionHistory = Array(modelDetectionHistory.prefix(36))
            showToast(title: "安全预览：已预览添加", message: "不会写入 Hermes 或 Hermes Web UI 本机配置", icon: "paintbrush.fill", accent: SetupPalette.cyan)
            return
        }

        isLoading = true
        statusMessage = "正在同步模型 Provider..."
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = SetupExecutionService().configureModelProvider(configuration) { _ in }
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.statusMessage = "模型 Provider 已同步"
                    self.refreshModelStatus()
                    let checkedAt = self.currentTimeString()
                    self.modelDetectionHistory.insert(
                        ModelDetectionRecord(
                            id: UUID(),
                            targetType: "provider",
                            title: "模型配置已更新",
                            detail: "已同步 \(self.displayProviderName(label: configuration.providerLabel, key: provider)) / \(model)",
                            status: .healthy,
                            latencyMS: nil,
                            availabilityPercent: nil,
                            checkedAt: checkedAt
                        ),
                        at: 0
                    )
                    self.modelDetectionHistory = Array(self.modelDetectionHistory.prefix(36))
                    self.showToast(title: "Provider 已添加", message: "已同步到 Hermes CLI 和 Hermes Web UI", icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
                case .failure(let error):
                    self.statusMessage = "模型 Provider 添加失败"
                    self.showToast(title: "Provider 添加失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: DesignTokens.error)
                }
            }
        }
    }

    func checkAllModelHealth(completion: (() -> Void)? = nil) {
        let targets = detectModelProbeTargets()
        runModelHealthCheck(
            targets: targets,
            title: "全部模型",
            targetType: "all",
            completion: completion
        )
    }

    func showToast(
        title: String,
        message: String,
        icon: String = "checkmark",
        accent: Color = SetupPalette.emerald,
        duration: TimeInterval = 2.6
    ) {
        let nextToast = AppToast(title: title, message: message, icon: icon, accent: accent, duration: duration)
        toast = nextToast
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.toast?.id == nextToast.id {
                self?.toast = nil
            }
        }
    }

    func readGatewayLogs() {
        refreshLogsIfNeeded(force: true)
    }

    func runCommand(_ command: String) -> String {
        if AppRuntimeMode.uiPrototype {
            return "[SAFE PREVIEW] skipped: \(command)"
        }
        return runShellCommand(command)
    }

    func runReadOnlyCommand(_ command: String) -> String {
        runShellCommand(command)
    }

    private func runShellCommand(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "export PATH=\"\(shellDoubleQuote(webUIRuntimeHome))/node_modules/.bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH\" && \(command)"]
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return "错误：\(error.localizedDescription)"
        }
    }

    func runWebUICommand(_ subcommand: String) -> String {
        runCommand("\(webUICommand) \(subcommand)")
    }

    func runHermesCLI(_ commandLine: String) -> String {
        if AppRuntimeMode.uiPrototype {
            return "[SAFE PREVIEW] skipped: hermes \(commandLine)"
        }
        let arguments = shellLikeSplit(commandLine)
        guard !arguments.isEmpty else { return "" }
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["hermes"] + arguments
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "\(webUIRuntimeHome)/node_modules/.bin:/opt/homebrew/bin:/usr/local/bin:\(NSHomeDirectory())/.local/bin:\(NSHomeDirectory())/.cargo/bin:" + (env["PATH"] ?? "")
        task.environment = env
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return "错误：\(error.localizedDescription)"
        }
    }

    private func runAppleScript(_ script: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        do {
            try task.run()
        } catch {
            print("AppleScript 错误：\(error)")
        }
    }

    private func shellLikeSplit(_ input: String) -> [String] {
        var result: [String] = []
        var current = ""
        var quote: Character?
        var escaping = false

        for character in input {
            if escaping {
                current.append(character)
                escaping = false
                continue
            }
            if character == "\\" {
                escaping = true
                continue
            }
            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }
            if character == "'" || character == "\"" {
                quote = character
                continue
            }
            if character.isWhitespace {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                continue
            }
            current.append(character)
        }
        if escaping {
            current.append("\\")
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }

    private func startMonitoring() {
        logTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.refreshLogsIfNeeded()
            self?.readToken()
        }
        statusTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: true) { [weak self] _ in
            self?.checkStatus()
            self?.refreshModelStatus()
        }
    }

    private func locateWebUITokenPath() -> String {
        if !webUITokenPath.isEmpty, FileManager.default.fileExists(atPath: webUITokenPath) {
            return webUITokenPath
        }

        let dataDir = locateWebUIDataDirectory()
        if !dataDir.isEmpty {
            let tokenPath = dataDir + "/.token"
            if FileManager.default.fileExists(atPath: tokenPath) {
                return tokenPath
            }
        }

        let home = NSHomeDirectory()
        let candidates = webUIDataDirectoryCandidates().map { $0 + "/.token" }
        if let found = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) {
            return found
        }

        if Date().timeIntervalSince(lastTokenPathScan) > 30 {
            lastTokenPathScan = Date()
            let command = "find \(shellQuote(home)) -maxdepth 5 \\( -path '*/.hermes-web-ui/.token' -o -path '*/hermes-web-ui/.token' -o -path '*/Hermes Web UI/.token' \\) -print 2>/dev/null | head -1"
            let output = runReadOnlyShell(command)
            let found = output
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && isUsableTokenPath($0) }
                .first
            if let found {
                return found
            }
        }

        return home + "/.hermes-web-ui/.token"
    }

    private func locateWebUIDataDirectory() -> String {
        if !webUIDataDirectory.isEmpty, FileManager.default.fileExists(atPath: webUIDataDirectory) {
            return webUIDataDirectory
        }

        if let found = webUIDataDirectoryCandidates().first(where: { directory in
            FileManager.default.fileExists(atPath: directory + "/.token")
                || FileManager.default.fileExists(atPath: directory + "/hermes-web-ui.db")
                || FileManager.default.fileExists(atPath: directory + "/config.json")
        }) {
            return found
        }

        return ""
    }

    private func webUIDataDirectoryCandidates() -> [String] {
        let home = NSHomeDirectory()
        let env = ProcessInfo.processInfo.environment
        return [
            env["HERMES_WEB_UI_HOME"],
            env["HERMES_WEB_UI_DATA_DIR"],
            env["HERMES_WEB_UI_DIR"],
            home + "/.hermes-web-ui",
            home + "/Library/Application Support/Hermes Web UI",
            home + "/Library/Application Support/hermes-web-ui",
            home + "/.config/hermes-web-ui",
            home + "/.local/share/hermes-web-ui",
            home + "/.hermes/web-ui",
            home + "/.hermes/hermes-web-ui",
        ].compactMap { $0 }.filter { !$0.isEmpty }
    }

    private func isUsableTokenPath(_ path: String) -> Bool {
        let lower = path.lowercased()
        let blocked = ["/.trash/", "/backups/", "/backup/", "/.hermes-manager/backups/", "/node_modules/"]
        return !blocked.contains { lower.contains($0) }
    }

    private func detectCLIModelStatus() -> CLIModelSnapshot {
        if let profile = detectCLIModelStatusFromProfileShow(), !profile.model.isEmpty {
            let config = detectCLIModelStatusFromConfig()
            return CLIModelSnapshot(
                providerKey: profile.providerKey,
                providerLabel: profile.providerLabel,
                model: profile.model,
                providerCount: max(profile.providerCount, config.providerCount),
                modelCount: max(profile.modelCount, config.modelCount)
            )
        }
        return detectCLIModelStatusFromConfig()
    }

    private func detectCLIModelStatusFromProfileShow() -> CLIModelSnapshot? {
        let activeName = activeHermesProfileName()
        let output = runReadOnlyShell("hermes profile show \(shellQuote(activeName)) 2>/dev/null")
        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        var model = ""
        var provider = ""
        for rawLine in output.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.localizedCaseInsensitiveContains("model:") else { continue }
            let value = line
                .replacingOccurrences(of: #"^Model:\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let match = value.range(of: #"\(([^)]+)\)\s*$"#, options: .regularExpression) {
                provider = String(value[match])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "() "))
                model = String(value[..<match.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                model = value
            }
            break
        }

        guard !model.isEmpty else { return nil }
        return CLIModelSnapshot(
            providerKey: provider,
            providerLabel: providerDisplayName(for: provider),
            model: model,
            providerCount: provider.isEmpty ? 0 : 1,
            modelCount: 1
        )
    }

    private func activeHermesProfileName() -> String {
        let activeFile = hermesHome + "/active_profile"
        guard let raw = try? String(contentsOfFile: activeFile, encoding: .utf8) else {
            return "default"
        }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "default" : name
    }

    private func detectCLIModelStatusFromConfig() -> CLIModelSnapshot {
        let configPath = activeHermesConfigPath
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return CLIModelSnapshot(providerKey: "", providerLabel: "", model: "", providerCount: 0, modelCount: 0)
        }

        var provider = ""
        var model = ""
        var inTopModel = false
        var providers = Set<String>()
        var models = Set<String>()

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if rawLine == "model:" {
                inTopModel = true
                continue
            }
            if inTopModel, !rawLine.hasPrefix(" "), !rawLine.hasPrefix("\t"), rawLine != "model:" {
                inTopModel = false
            }
            if inTopModel {
                if line.hasPrefix("default:") {
                    model = yamlValue(from: line)
                    if !model.isEmpty { models.insert(model) }
                } else if line.hasPrefix("provider:") {
                    provider = yamlValue(from: line)
                    if !provider.isEmpty { providers.insert(provider) }
                } else if line.hasPrefix("base_url:") {
                    if provider.isEmpty {
                        provider = providerKeyFromBaseURL(yamlValue(from: line))
                        if !provider.isEmpty { providers.insert(provider) }
                    }
                }
            }

            if line.hasPrefix("name:") || line.hasPrefix("- name:") {
                let value = yamlValue(from: line.replacingOccurrences(of: "- ", with: ""))
                if !value.isEmpty { providers.insert(value) }
            }
            if line.hasPrefix("model:") {
                let value = yamlValue(from: line)
                if !value.isEmpty { models.insert(value) }
            }
        }

        return CLIModelSnapshot(
            providerKey: provider,
            providerLabel: providerDisplayName(for: provider),
            model: model,
            providerCount: providers.count,
            modelCount: models.count
        )
    }

    private func detectWebUIModelStatus() -> WebUIModelSnapshot {
        if let apiSnapshot = detectWebUIModelStatusFromAPI() {
            return apiSnapshot
        }

        let dataDir = locateWebUIDataDirectory()
        let dbPath = dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui/hermes-web-ui.db" : dataDir + "/hermes-web-ui.db"
        var inventory = ModelInventorySnapshot()
        var recentProvider = ""
        var recentModel = ""

        if FileManager.default.fileExists(atPath: dbPath) {
            let rows = runReadOnlyShell("sqlite3 \(shellQuote(dbPath)) \"SELECT provider || '|' || model FROM model_context WHERE model != '';\"")
            for row in rows.components(separatedBy: .newlines) {
                let parts = row.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "|")
                guard parts.count >= 2, !parts[1].isEmpty else { continue }
                inventory.addProvider(key: parts[0], label: providerDisplayName(for: parts[0]))
                inventory.addModel(parts[1], provider: parts[0])
            }

            if let recent = detectRecentWebUISessionModel(dbPath: dbPath) {
                recentProvider = recent.provider
                recentModel = recent.model
                inventory.addProvider(key: recent.provider, label: providerDisplayName(for: recent.provider))
                inventory.addModel(recent.model, provider: recent.provider)
            }
        }

        inventory.merge(detectWebUIConfigInventory(dataDir: dataDir))

        let cli = detectCLIModelStatus()
        if !cli.providerKey.isEmpty {
            inventory.addProvider(key: cli.providerKey, label: cli.providerLabel)
        }
        if !cli.model.isEmpty {
            inventory.addModel(cli.model, provider: cli.providerKey)
        }

        let displayProvider = recentProvider.isEmpty ? cli.providerKey : recentProvider
        let displayModel = recentModel.isEmpty ? cli.model : recentModel

        return WebUIModelSnapshot(
            available: !displayModel.isEmpty,
            providerKey: displayProvider,
            providerLabel: providerDisplayName(for: displayProvider),
            model: displayModel,
            providerCount: inventory.providerKeys.count,
            modelCount: inventory.models.count,
            presetProviderCount: 0,
            models: inventory.models,
            providerModels: inventory.providerModels,
            error: displayModel.isEmpty ? "Web UI API 未响应，已尝试读取本地缓存" : "Web UI API 未响应，已读取本地配置/会话缓存"
        )
    }

    private func detectWebUIModelStatusFromAPI() -> WebUIModelSnapshot? {
        guard let token = readWebUITokenValue(), !token.isEmpty else { return nil }
        let urls = candidateWebUIAPIURLs(path: "/api/hermes/available-models")

        for url in urls {
            var request = URLRequest(url: url, timeoutInterval: 8)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            guard let (data, response) = performSynchronousRequest(request),
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }
            return parseWebUIAvailableModels(json)
        }

        return nil
    }

    private func parseWebUIAvailableModels(_ json: [String: Any]) -> WebUIModelSnapshot {
        let defaultModel = stringValue(json, keys: ["default", "default_model", "defaultModel", "model", "current_model", "currentModel"])
        let defaultProvider = stringValue(json, keys: ["default_provider", "defaultProvider", "provider", "current_provider", "currentProvider"])
        let groups = arrayOfDictionaries(json, keys: ["groups", "providers", "configuredProviders", "configured_providers"])
        let allProviders = arrayOfDictionaries(json, keys: ["allProviders", "all_providers", "availableProviders", "available_providers"])
        let visibility = dictionaryValue(json, keys: ["model_visibility", "modelVisibility", "visibility"])

        var inventory = ModelInventorySnapshot()

        func ingestProvider(_ item: [String: Any], countAsConfigured: Bool) {
            guard let key = (item["provider"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !key.isEmpty else { return }
            if let label = (item["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !label.isEmpty {
                inventory.addProvider(key: key, label: label)
            } else if countAsConfigured {
                inventory.addProvider(key: key, label: providerDisplayName(for: key))
            }
            if countAsConfigured {
                inventory.addProvider(key: key, label: providerDisplayName(for: key))
            }
            let directModels = stringArrayValue(item, keys: ["models"])
            let availableModels = stringArrayValue(item, keys: ["available_models", "availableModels"])
            for model in directModels + availableModels {
                let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                inventory.addModel(trimmed, provider: key)
            }
        }

        for item in allProviders {
            guard let key = (item["provider"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !key.isEmpty else { continue }
            if let label = (item["label"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !label.isEmpty {
                inventory.providerLabels[key] = label
            }
        }
        for item in groups {
            ingestProvider(item, countAsConfigured: true)
        }

        for (provider, value) in visibility {
            guard let dict = value as? [String: Any],
                  !dict.isEmpty else { continue }
            inventory.addProvider(key: provider, label: inventory.providerLabels[provider] ?? providerDisplayName(for: provider))
            let models = stringArrayValue(dict, keys: ["models", "available_models", "availableModels"])
            for model in models {
                let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                inventory.addModel(trimmed, provider: provider)
            }
        }

        let configInventory = detectWebUIConfigInventory(dataDir: locateWebUIDataDirectory())
        inventory.merge(configInventory)

        let providerLabel = inventory.providerLabels[defaultProvider] ?? providerDisplayName(for: defaultProvider)
        return WebUIModelSnapshot(
            available: true,
            providerKey: defaultProvider,
            providerLabel: providerLabel,
            model: defaultModel,
            providerCount: inventory.providerKeys.count,
            modelCount: inventory.models.count,
            presetProviderCount: allProviders.count,
            models: inventory.models,
            providerModels: inventory.providerModels,
            error: nil
        )
    }

    private func stringValue(_ dictionary: [String: Any], keys: [String]) -> String {
        for key in keys {
            if let value = dictionary[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        }
        return ""
    }

    private func dictionaryValue(_ dictionary: [String: Any], keys: [String]) -> [String: Any] {
        for key in keys {
            if let value = dictionary[key] as? [String: Any] {
                return value
            }
        }
        return [:]
    }

    private func stringArrayValue(_ dictionary: [String: Any], keys: [String]) -> [String] {
        for key in keys {
            if let values = dictionary[key] as? [String] {
                return values
            }
            if let values = dictionary[key] as? [[String: Any]] {
                let names = values.compactMap { item in
                    stringValue(item, keys: ["id", "name", "model", "value"])
                }.filter { !$0.isEmpty }
                if !names.isEmpty { return names }
            }
        }
        return []
    }

    private func arrayOfDictionaries(_ dictionary: [String: Any], keys: [String]) -> [[String: Any]] {
        for key in keys {
            if let values = dictionary[key] as? [[String: Any]] {
                return values
            }
        }
        return []
    }

    private func detectWebUIURL() -> String {
        let env = ProcessInfo.processInfo.environment
        let envPort = firstPort(from: [
            env["HERMES_WEB_UI_PORT"],
            env["HERMES_WEBUI_PORT"],
            env["WEB_UI_PORT"],
            env["PORT"],
        ])
        for key in ["HERMES_WEB_UI_URL", "HERMES_WEBUI_URL", "WEB_UI_URL"] {
            if let value = env[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               let normalized = normalizedLocalWebUIURL(from: value, fallbackPort: envPort) {
                return normalized
            }
        }

        let dataDir = locateWebUIDataDirectory()
        let configPath = (dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui" : dataDir) + "/config.json"
        var configURLWithoutPort: String?
        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let configPort = portValue(json["port"])
            for key in ["url", "baseURL", "baseUrl", "webURL", "webUrl", "publicUrl"] {
                guard let value = json[key] as? String else { continue }
                if hasExplicitPort(value),
                   let normalized = normalizedLocalWebUIURL(from: value) {
                    return normalized
                }
                if let normalized = normalizedLocalWebUIURL(from: value, fallbackPort: configPort) {
                    configURLWithoutPort = normalized
                }
            }
            if let configPort {
                return configURLWithoutPort ?? "http://localhost:\(configPort)"
            }
        }

        let logPath = (dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui" : dataDir) + "/logs/server.log"
        if let content = try? String(contentsOfFile: logPath, encoding: .utf8),
           let match = firstHTTPURL(in: content),
           let normalized = normalizedLocalWebUIURL(from: match) {
            return normalized
        }

        if let configURLWithoutPort {
            return configURLWithoutPort
        }

        return "http://localhost:8648"
    }

    private func candidateWebUIAPIURLs(path: String) -> [URL] {
        let normalizedPath = path.hasPrefix("/") ? path : "/" + path
        let baseValues = [
            webUIURL,
            detectWebUIURL(),
            "http://127.0.0.1:8648",
            "http://localhost:8648",
        ]
        var seen = Set<String>()
        var urls: [URL] = []

        for value in baseValues {
            guard var components = URLComponents(string: value),
                  let scheme = components.scheme,
                  scheme == "http" || scheme == "https" else {
                continue
            }
            if components.host == "localhost" || components.host == "0.0.0.0" || components.host == "::1" {
                components.host = "127.0.0.1"
            }
            components.path = normalizedPath
            components.query = nil
            components.fragment = nil
            guard let url = components.url else { continue }
            let key = url.absoluteString
            if seen.insert(key).inserted {
                urls.append(url)
            }
        }
        return urls
    }

    private func readWebUITokenValue() -> String? {
        let tokenPath = locateWebUITokenPath()
        guard let content = try? String(contentsOfFile: tokenPath, encoding: .utf8) else {
            return webUIToken.isEmpty ? nil : webUIToken
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func performSynchronousRequest(_ request: URLRequest) -> (Data, URLResponse)? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [:]
        configuration.timeoutIntervalForRequest = request.timeoutInterval
        configuration.timeoutIntervalForResource = request.timeoutInterval
        let session = URLSession(configuration: configuration)
        let semaphore = DispatchSemaphore(value: 0)
        var result: (Data, URLResponse)?

        let task = session.dataTask(with: request) { data, response, _ in
            if let data, let response {
                result = (data, response)
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + request.timeoutInterval + 1)
        task.cancel()
        session.invalidateAndCancel()
        return result
    }

    private func normalizedLocalWebUIURL(from value: String, fallbackPort: Int? = nil) -> String? {
        guard var components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        if components.port == nil {
            let port = fallbackPort ?? 8648
            components.port = port
            if scheme == "https", port != 443 {
                components.scheme = "http"
            }
        }
        components.host = "localhost"
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.string
    }

    private func hasExplicitPort(_ value: String) -> Bool {
        URLComponents(string: value)?.port != nil
    }

    private func firstPort(from values: [String?]) -> Int? {
        for value in values {
            if let port = portValue(value) {
                return port
            }
        }
        return nil
    }

    private func portValue(_ value: Any?) -> Int? {
        if let intValue = value as? Int, (1...65535).contains(intValue) {
            return intValue
        }
        if let number = value as? NSNumber {
            let intValue = number.intValue
            return (1...65535).contains(intValue) ? intValue : nil
        }
        if let string = value as? String,
           let intValue = Int(string.trimmingCharacters(in: .whitespacesAndNewlines)),
           (1...65535).contains(intValue) {
            return intValue
        }
        return nil
    }

    private func firstHTTPURL(in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"https?://[A-Za-z0-9._:-]+"#) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.matches(in: text, range: range).last,
              let swiftRange = Range(match.range, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }

    private func detectMemoryBridgeStatus() -> MemoryBridgeDiagnosticSnapshot {
        MemoryBridgeDiagnosticService.diagnose()
    }

    private func detectRecentWebUISessionModel(dbPath: String) -> (provider: String, model: String)? {
        let sql = "SELECT COALESCE(provider, '') || '|' || COALESCE(model, '') FROM sessions WHERE COALESCE(model, '') != '' ORDER BY last_active DESC LIMIT 1;"
        let row = runReadOnlyShell("sqlite3 \(shellQuote(dbPath)) \(shellQuote(sql))")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = row.components(separatedBy: "|")
        guard parts.count >= 2, !parts[1].isEmpty else { return nil }
        return (parts[0], parts[1])
    }

    private func detectWebUIConfigInventory(dataDir: String) -> ModelInventorySnapshot {
        let configPath = (dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui" : dataDir) + "/config.json"
        var inventory = ModelInventorySnapshot()
        guard let data = FileManager.default.contents(atPath: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return inventory
        }

        if let visibility = json["modelVisibility"] as? [String: Any] {
            for key in visibility.keys.sorted() {
                inventory.addProvider(key: key, label: providerDisplayName(for: key))
                let value = visibility[key]
                if let dict = value as? [String: Any] {
                    for model in stringArrayValue(dict, keys: ["models", "available_models", "availableModels"]) {
                        inventory.addModel(model, provider: key)
                    }
                }
            }
        }

        for key in ["selectedProvider", "currentProvider", "defaultProvider", "provider"] {
            if let provider = json[key] as? String {
                inventory.addProvider(key: provider, label: providerDisplayName(for: provider))
            }
        }
        for key in ["selectedModel", "currentModel", "defaultModel", "model"] {
            if let model = json[key] as? String {
                let provider = stringValue(json, keys: ["selectedProvider", "currentProvider", "defaultProvider", "provider"])
                inventory.addModel(model, provider: provider)
            }
        }

        return inventory
    }

    private func detectModelProbeTargets() -> [ModelProbeTarget] {
        let configPath = activeHermesConfigPath
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return []
        }

        let env = readHermesEnvValues()
        let current = detectCLIModelStatusFromConfig()
        var targets: [ModelProbeTarget] = []
        var seen = Set<ModelProbeTarget>()

        func appendTarget(providerKey: String, providerLabel: String, baseURL: String, apiKey: String, model: String) {
            let target = ModelProbeTarget(
                providerKey: providerKey.trimmingCharacters(in: .whitespacesAndNewlines),
                providerLabel: providerLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
                apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                model: model.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            guard !target.providerKey.isEmpty, !target.baseURL.isEmpty, !target.apiKey.isEmpty, !target.model.isEmpty else {
                return
            }
            if seen.insert(target).inserted {
                targets.append(target)
            }
        }

        for provider in parseCustomProviders(from: content) {
            let providerKey = customProviderKey(forName: provider.name)
            let models = provider.models.isEmpty ? [provider.model] : provider.models
            for model in models {
                appendTarget(
                    providerKey: providerKey,
                    providerLabel: provider.name,
                    baseURL: provider.baseURL,
                    apiKey: provider.apiKey,
                    model: model
                )
            }
        }

        if let preset = HermesModelProviderPreset.preset(for: current.providerKey),
           let apiKey = firstEnvValue(keys: providerEnvKeys(for: preset.value), in: env),
           !current.model.isEmpty {
            appendTarget(
                providerKey: preset.value,
                providerLabel: preset.label,
                baseURL: preset.baseURL,
                apiKey: apiKey,
                model: current.model
            )
        }

        return Array(targets.prefix(20))
    }

    private struct ParsedCustomProvider {
        let name: String
        let baseURL: String
        let apiKey: String
        let keyEnv: String
        let model: String
        let models: [String]
    }

    private func parseCustomProviders(from yaml: String) -> [ParsedCustomProvider] {
        let lines = yaml.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0 == "custom_providers:" }) else { return [] }
        var end = start + 1
        while end < lines.count {
            let line = lines[end]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            end += 1
        }

        var providers: [ParsedCustomProvider] = []
        var index = start + 1
        while index < end {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- name:") else {
                index += 1
                continue
            }

            var itemEnd = index + 1
            while itemEnd < end {
                let itemTrimmed = lines[itemEnd].trimmingCharacters(in: .whitespaces)
                if itemTrimmed.hasPrefix("- name:") { break }
                itemEnd += 1
            }

            let item = Array(lines[index..<itemEnd])
            let name = yamlValue(from: trimmed.replacingOccurrences(of: "- ", with: ""))
            var baseURL = ""
            var apiKey = ""
            var keyEnv = ""
            var model = ""
            var models: [String] = []
            var inModels = false

            for rawLine in item.dropFirst() {
                let line = rawLine.trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("base_url:") {
                    baseURL = yamlValue(from: line)
                    inModels = false
                } else if line.hasPrefix("api_key:") {
                    apiKey = yamlValue(from: line)
                    inModels = false
                } else if line.hasPrefix("key_env:") || line.hasPrefix("api_key_env:") {
                    keyEnv = yamlValue(from: line)
                    inModels = false
                } else if line.hasPrefix("model:") {
                    model = yamlValue(from: line)
                    inModels = false
                } else if line == "models:" {
                    inModels = true
                } else if inModels, line.hasSuffix(":") {
                    let key = line.dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
                    let clean = key.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    if !clean.isEmpty {
                        models.append(clean)
                    }
                }
            }

            let resolvedAPIKey = resolvedCustomProviderAPIKey(apiKey: apiKey, keyEnv: keyEnv)
            providers.append(ParsedCustomProvider(name: name, baseURL: baseURL, apiKey: resolvedAPIKey, keyEnv: keyEnv, model: model, models: models))
            index = itemEnd
        }

        return providers
    }

    private func resolvedCustomProviderAPIKey(apiKey: String, keyEnv: String) -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if let envName = environmentReferenceName(from: cleanKey),
           let resolved = envValue(for: envName) {
            return resolved
        }
        if !cleanKey.isEmpty {
            return cleanKey
        }
        return envValue(for: keyEnv) ?? ""
    }

    private func environmentReferenceName(from value: String) -> String? {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.hasPrefix("${"), clean.hasSuffix("}") else { return nil }
        let start = clean.index(clean.startIndex, offsetBy: 2)
        let end = clean.index(before: clean.endIndex)
        let name = String(clean[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    private func envValue(for key: String) -> String? {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        return readHermesEnvValues()[clean] ?? ProcessInfo.processInfo.environment[clean]
    }

    private func firstEnvValue(keys: [String], in env: [String: String]) -> String? {
        for key in keys {
            let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { continue }
            if let value = env[clean]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
            if let value = ProcessInfo.processInfo.environment[clean]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func readHermesEnvValues() -> [String: String] {
        let envPath = activeHermesEnvPath
        guard let content = try? String(contentsOfFile: envPath, encoding: .utf8) else { return [:] }
        var values: [String: String] = [:]
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#"), let equals = line.firstIndex(of: "=") else { continue }
            let key = String(line[..<equals]).trimmingCharacters(in: .whitespacesAndNewlines)
            let value = String(line[line.index(after: equals)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !key.isEmpty, !value.isEmpty {
                values[key] = value
            }
        }
        return values
    }

    private func providerEnvKey(for provider: String) -> String? {
        providerEnvKeys(for: provider).first
    }

    private func providerEnvKeys(for provider: String) -> [String] {
        switch normalizedProviderKey(provider) {
        case "openrouter": return ["OPENROUTER_API_KEY"]
        case "zai": return ["GLM_API_KEY", "ZAI_API_KEY", "Z_AI_API_KEY"]
        case "kimi-coding": return ["KIMI_API_KEY", "KIMI_CODING_API_KEY"]
        case "kimi-coding-cn": return ["KIMI_CN_API_KEY"]
        case "moonshot": return ["MOONSHOT_API_KEY", "KIMI_API_KEY"]
        case "minimax": return ["MINIMAX_API_KEY"]
        case "minimax-cn": return ["MINIMAX_CN_API_KEY"]
        case "deepseek": return ["DEEPSEEK_API_KEY"]
        case "alibaba": return ["DASHSCOPE_API_KEY"]
        case "alibaba-coding-plan": return ["ALIBABA_CODING_PLAN_API_KEY", "DASHSCOPE_API_KEY"]
        case "anthropic": return ["ANTHROPIC_API_KEY"]
        case "xai": return ["XAI_API_KEY"]
        case "xiaomi", "xiaomi-token-plan": return ["XIAOMI_API_KEY"]
        case "gemini": return ["GOOGLE_API_KEY", "GEMINI_API_KEY"]
        case "kilocode": return ["KILOCODE_API_KEY", "KILO_API_KEY"]
        case "ai-gateway": return ["AI_GATEWAY_API_KEY"]
        case "opencode-zen": return ["OPENCODE_ZEN_API_KEY", "OPENCODE_API_KEY"]
        case "opencode-go": return ["OPENCODE_GO_API_KEY", "OPENCODE_API_KEY"]
        case "huggingface": return ["HF_TOKEN"]
        case "arcee": return ["ARCEEAI_API_KEY", "ARCEE_API_KEY"]
        case "longcat": return ["LONGCAT_API_KEY"]
        case "nous": return ["NOUS_API_KEY"]
        case "stepfun": return ["STEPFUN_API_KEY"]
        case "ollama-cloud": return ["OLLAMA_API_KEY"]
        default: return []
        }
    }

    private func probeModelTarget(_ target: ModelProbeTarget) -> ModelHealthResult {
        guard let url = modelsURL(from: target.baseURL) else {
            return ModelHealthResult(provider: target.providerLabel.isEmpty ? target.providerKey : target.providerLabel, model: target.model, ok: false, latencyMS: nil, detail: "Base URL 无效")
        }

        var request = URLRequest(url: url, timeoutInterval: 12)
        request.httpMethod = "GET"
        request.setValue("Bearer \(target.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let started = Date()
        guard let (data, response) = performSynchronousRequest(request),
              let http = response as? HTTPURLResponse else {
            return ModelHealthResult(provider: target.providerLabel.isEmpty ? target.providerKey : target.providerLabel, model: target.model, ok: false, latencyMS: nil, detail: "请求超时或无响应")
        }

        let latency = Int(Date().timeIntervalSince(started) * 1000)
        guard (200..<300).contains(http.statusCode) else {
            return ModelHealthResult(provider: target.providerLabel.isEmpty ? target.providerKey : target.providerLabel, model: target.model, ok: false, latencyMS: latency, detail: "HTTP \(http.statusCode)")
        }

        let containsModel: Bool
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let ids = extractModelIDs(from: json)
            containsModel = ids.isEmpty || ids.contains(target.model)
        } else {
            containsModel = true
        }

        return ModelHealthResult(
            provider: target.providerLabel.isEmpty ? target.providerKey : target.providerLabel,
            model: target.model,
            ok: containsModel,
            latencyMS: latency,
            detail: containsModel ? "/models 可用" : "/models 可用，但未返回该模型"
        )
    }

    private func modelsURL(from baseURL: String) -> URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        if normalized.hasSuffix("/models") {
            return URL(string: normalized)
        }
        if normalized.range(of: #"/v\d+$"#, options: .regularExpression) != nil {
            return URL(string: normalized + "/models")
        }
        return URL(string: normalized + "/v1/models")
    }

    private func extractModelIDs(from json: [String: Any]) -> Set<String> {
        let data = json["data"] as? [[String: Any]] ?? []
        let ids = data.compactMap { item in
            (item["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Set(ids.filter { !$0.isEmpty })
    }

    private func yamlScalarIsFalse(in text: String, key: String) -> Bool {
        text.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            return trimmed == "\(key): false" || trimmed == "\(key): no" || trimmed == "\(key): 0"
        }
    }

    private func yamlNestedScalarEquals(in text: String, block blockName: String, key: String, value: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard let blockStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).lowercased() == "\(blockName):" }) else {
            return false
        }
        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            blockEnd += 1
        }
        guard let keyLine = lines[blockStart..<blockEnd].first(where: {
            $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("\(key):")
        }) else {
            return false
        }
        let raw = keyLine
            .trimmingCharacters(in: .whitespaces)
            .dropFirst("\(key):".count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            .lowercased()
        return raw == value.lowercased()
    }

    private func yamlListContains(in text: String, block blockName: String, key: String, value: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard let blockStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "\(blockName):" }) else {
            return false
        }
        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            blockEnd += 1
        }
        guard let keyIndex = lines[blockStart..<blockEnd].firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(key):")
        }) else {
            return false
        }
        let lowerValue = value.lowercased()
        let keyLine = lines[keyIndex].trimmingCharacters(in: .whitespaces).lowercased()
        if keyLine.contains("[") && keyLine.contains(lowerValue) {
            return true
        }
        var index = keyIndex + 1
        while index < blockEnd {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            if !line.isEmpty && !line.hasPrefix("    ") && !line.hasPrefix("\t") && trimmed.hasSuffix(":") {
                break
            }
            if trimmed == "- \(lowerValue)" || trimmed == "- \"\(lowerValue)\"" || trimmed == "- '\(lowerValue)'" {
                return true
            }
            index += 1
        }
        return false
    }

    private func countMemoryFiles(in root: String) -> Int {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: root),
              let enumerator = fileManager.enumerator(atPath: root) else {
            return 0
        }
        var count = 0
        while let item = enumerator.nextObject() as? String {
            let path = root + "/" + item
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                if shouldSkipMemoryPath(path) { enumerator.skipDescendants() }
                continue
            }
            if shouldCountMemoryPath(path), !shouldSkipMemoryPath(path) {
                count += 1
            }
        }
        return count
    }

    private func countLongTermHermesMemoryFiles() -> Int {
        let profileHome = activeHermesProfileHome
        return countMemoryFiles(in: profileHome + "/memories")
            + countLongTermTopLevelHermesNotes(in: profileHome)
            + countLongTermHermesMemoryDirectoryFiles(in: profileHome + "/memory")
    }

    private func countLongTermTopLevelHermesNotes(in root: String) -> Int {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermTopLevelHermesNote(entry), !shouldSkipMemoryPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private func countLongTermHermesMemoryDirectoryFiles(in root: String) -> Int {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermMemoryDirectoryFile(entry), !shouldSkipMemoryPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private func isLongTermTopLevelHermesNote(_ name: String) -> Bool {
        let upper = name.uppercased()
        let allowlist = [
            "MEMORY.MD", "USER.MD", "SOUL.MD", "IDENTITY.MD",
            "MEMORY-HUB.MD", "SESSION-STATE.MD", "HEARTBEAT.MD",
            "BOOTSTRAP.MD", "AGENTS.MD", "TOOLS.MD",
        ]
        return allowlist.contains(upper) || upper.hasPrefix("PERSONAL-MODEL-")
    }

    private func isLongTermMemoryDirectoryFile(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.range(of: #"^\d{4}-\d{2}-\d{2}\."#, options: .regularExpression) != nil {
            return false
        }
        return lower.hasPrefix("personal-model-")
            || lower == "user-model.md"
            || lower == "preferences.md"
            || lower == "learning.md"
            || lower == "memory.md"
            || lower == "user.md"
            || lower == "soul.md"
            || lower == "identity.md"
            || lower.hasSuffix("-preferences.md")
            || lower.hasSuffix("-model.md")
    }

    private func countTopLevelMarkdownFiles(in root: String) -> Int {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, entry.lowercased().hasSuffix(".md"), !shouldSkipMemoryPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private func shouldCountMemoryPath(_ path: String) -> Bool {
        let lower = path.lowercased()
        return lower.hasSuffix(".md")
            || lower.hasSuffix(".json")
            || lower.hasSuffix(".jsonl")
            || lower.hasSuffix(".txt")
            || lower.hasSuffix(".yaml")
            || lower.hasSuffix(".yml")
            || lower.hasSuffix(".toml")
    }

    private func shouldSkipMemoryPath(_ path: String) -> Bool {
        let normalized = path.replacingOccurrences(of: "\\", with: "/").lowercased()
        let directoryMarkers = [
            "/.git/", "/node_modules/", "/.venv/", "/venv/", "/__pycache__/", "/.dreams/",
        ]
        if directoryMarkers.contains(where: { normalized.contains($0) }) {
            return true
        }
        let name = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        if name.hasSuffix(".db") || name.hasSuffix(".sqlite") || name.hasSuffix(".sqlite3") {
            return true
        }
        if name.hasPrefix("cost-") || name.hasPrefix("dream-") {
            return true
        }
        let sensitiveFilenameMarkers = [
            "token", "secret", "apikey", "api_key", "credential", "password", "cookie",
        ]
        if sensitiveFilenameMarkers.contains(where: { name.contains($0) }) {
            return true
        }
        return name == "auth" || name.hasPrefix("auth.")
    }

    private func providerDisplayName(for provider: String) -> String {
        switch normalizedProviderKey(provider) {
        case "opencode-go": return "OpenCode Go"
        case "opencode-zen": return "OpenCode Zen"
        case "xiaomi": return "Xiaomi MiMo"
        case "xiaomi-token-plan": return "Xiaomi Token Plan"
        case "custom:opencode.ai": return "opencode.ai"
        case "custom:xunfei": return "xunfei"
        case "deepseek": return "DeepSeek"
        case "zai": return "Z.AI / GLM"
        case "glm-coding-plan": return "GLM-Coding-Plan"
        case "kimi-coding-cn": return "Kimi for Coding"
        case "moonshot": return "Moonshot"
        case "anthropic": return "Anthropic"
        case "gemini": return "Google AI Studio"
        case "openai-codex": return "OpenAI Codex"
        case "copilot": return "GitHub Copilot"
        default:
            if provider.hasPrefix("custom:") {
                return String(provider.dropFirst("custom:".count))
            }
            return provider
        }
    }

    private func displayProviderName(label: String, key: String) -> String {
        let providerKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let providerLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !providerKey.isEmpty else { return providerLabel }
        guard !providerLabel.isEmpty, providerLabel != providerKey else { return providerKey }
        return "\(providerLabel) (\(providerKey))"
    }

    private func normalizedProviderKey(_ provider: String) -> String {
        provider.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func providerKeyFromBaseURL(_ baseURL: String) -> String {
        let normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.contains("opencode.ai/zen/go") { return "opencode-go" }
        if normalized.contains("opencode.ai/zen") { return "opencode-zen" }
        if normalized.contains("xiaomimimo.com") { return "xiaomi" }
        if normalized.contains("deepseek.com") { return "deepseek" }
        if normalized.contains("z.ai") { return "zai" }
        if normalized.contains("kimi.com") || normalized.contains("moonshot.cn") { return "moonshot" }
        if normalized.contains("dashscope") { return "alibaba" }
        if normalized.contains("anthropic.com") { return "anthropic" }
        if normalized.contains("generativelanguage.googleapis.com") { return "gemini" }
        if normalized.contains("openrouter.ai") { return "openrouter" }
        if normalized.contains("xf-yun.com") { return "xunfei" }
        return ""
    }

    private func customProviderKey(forName name: String) -> String {
        let normalized = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return "custom:\(normalized.isEmpty ? "provider" : normalized)"
    }

    private func yamlValue(from line: String) -> String {
        guard let colonIndex = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colonIndex)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func applyIfChanged<T: Equatable>(_ target: inout T, _ value: T) {
        if target != value {
            target = value
        }
    }

    private func tailLogLines(at path: String, fallback: String) -> [String] {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return [fallback]
        }
        return Array(content.components(separatedBy: .newlines).suffix(100))
    }

    private func runReadOnlyShell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "export PATH=\"/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\(NSHomeDirectory())/.local/bin:$PATH\" && \(command)"]
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            let deadline = Date().addingTimeInterval(4)
            while task.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }
            if task.isRunning {
                task.terminate()
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                    if task.isRunning {
                        task.interrupt()
                    }
                }
            }
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func shellDoubleQuote(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "$", with: "\\$").replacingOccurrences(of: "`", with: "\\`"))\""
    }
}

extension ServiceManager {
    func modelSystemSnapshot(preferMockWhenEmpty: Bool = true) -> ModelSystemSnapshot {
        if let cachedModelSystemSnapshot {
            return cachedModelSystemSnapshot
        }
        let snapshot = lightweightModelSystemSnapshot()
        if preferMockWhenEmpty && snapshot.providers.isEmpty && snapshot.models.isEmpty {
            return ModelSystemSnapshot.mock(
                currentModelName: currentModelName,
                currentProviderName: currentModelProvider,
                updatedAt: modelStatusUpdatedAt
            )
        }
        return snapshot
    }

    func applyCurrentModelSelection(providerKey: String, modelName: String) {
        guard let configuration = resolvedModelProviderConfiguration(
            providerKey: providerKey,
            preferredModel: modelName
        ) else {
            showToast(title: "无法切换模型", message: "当前 Provider 缺少完整配置，无法同步到 Hermes/Web UI", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        configureModelProvider(configuration)
    }

    func applyDefaultProvider(providerKey: String) {
        guard let configuration = resolvedModelProviderConfiguration(
            providerKey: providerKey,
            preferredModel: nil
        ) else {
            showToast(title: "无法设为默认", message: "当前 Provider 缺少模型或鉴权信息", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        configureModelProvider(configuration)
    }

    func saveModelProviderDraft(_ draft: ModelProviderEditDraft) {
        let provider = draft.providerKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = draft.providerLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = resolvedModelProviderConfiguration(providerKey: provider, preferredModel: draft.defaultModel)
        let baseURL = draft.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(existing?.baseURL ?? "")
        let apiKey = draft.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty(existing?.apiKey ?? "")
        let defaultModel = draft.defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let models = normalizedModelNames(draft.models + [defaultModel])

        guard !provider.isEmpty, !label.isEmpty, !baseURL.isEmpty, !apiKey.isEmpty, !defaultModel.isEmpty else {
            showToast(title: "Provider 配置不完整", message: "名称、Base URL、API Key 和当前模型都不能为空", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }

        let configuration = ModelProviderConfiguration(
            providerKey: provider,
            providerLabel: label,
            baseURL: baseURL,
            apiKey: apiKey,
            defaultModel: defaultModel,
            models: models,
            contextLength: max(draft.contextLength, 8192)
        )
        configureModelProvider(configuration)
    }

    func syncProviderConfiguration(providerKey: String) {
        guard let configuration = resolvedModelProviderConfiguration(providerKey: providerKey, preferredModel: nil) else {
            showToast(title: "无法同步 Provider", message: "当前 Provider 缺少 Base URL、API Key 或模型列表", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        configureModelProvider(configuration)
    }

    func applyModelVisibility(providerKey: String, visibleModels: [String], defaultModel: String? = nil, pruneDatabase: Bool = true) {
        let normalized = normalizedProviderKey(providerKey)
        guard var configuration = resolvedModelProviderConfiguration(providerKey: normalized, preferredModel: defaultModel) else {
            showToast(title: "无法更新模型可见性", message: "当前 Provider 缺少完整连接配置", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }

        let models = normalizedModelNames(visibleModels)
        guard !models.isEmpty else {
            showToast(title: "至少保留一个模型", message: "Hermes/Web UI 需要至少一个可见模型作为当前模型候选", icon: "lock.fill", accent: SetupPalette.amber)
            return
        }

        let preferred = (defaultModel ?? configuration.defaultModel).trimmingCharacters(in: .whitespacesAndNewlines)
        configuration = ModelProviderConfiguration(
            providerKey: configuration.providerKey,
            providerLabel: configuration.providerLabel,
            baseURL: configuration.baseURL,
            apiKey: configuration.apiKey,
            defaultModel: models.contains(preferred) ? preferred : models[0],
            models: models,
            contextLength: configuration.contextLength
        )

        if AppRuntimeMode.uiPrototype {
            currentModelProvider = displayProviderName(label: configuration.providerLabel, key: normalized)
            currentModelName = configuration.defaultModel
            modelCalibrationHealthy = true
            modelStatusUpdatedAt = currentTimeString()
            showToast(title: "安全预览：已更新可见模型", message: "\(providerDisplayName(for: normalized)) 保留 \(models.count) 个可见模型", icon: "paintbrush.fill", accent: SetupPalette.cyan)
            return
        }

        isLoading = true
        statusMessage = "正在更新模型可见性..."
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let service = SetupExecutionService()
            let result = pruneDatabase
                ? service.configureModelProviderExact(configuration) { _ in }
                : service.configureModelProvider(configuration) { _ in }
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.statusMessage = "模型可见性已更新"
                    self.refreshModelStatus()
                    let checkedAt = self.currentTimeString()
                    self.modelDetectionHistory.insert(
                        ModelDetectionRecord(
                            id: UUID(),
                            targetType: "provider",
                            title: "可见模型已更新",
                            detail: "\(self.providerDisplayName(for: normalized)) 当前可见 \(models.count) 个模型",
                            status: .healthy,
                            latencyMS: nil,
                            availabilityPercent: nil,
                            checkedAt: checkedAt
                        ),
                        at: 0
                    )
                    self.modelDetectionHistory = Array(self.modelDetectionHistory.prefix(36))
                    self.showToast(title: "模型可见性已同步", message: "已写入 Hermes CLI 与 Hermes Web UI", icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
                case .failure(let error):
                    self.statusMessage = "模型可见性更新失败"
                    self.showToast(title: "更新失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
                }
            }
        }
    }

    func saveModelCatalog(providerKey: String, models: [String], defaultModel: String, contextLength: Int) {
        let normalized = normalizedProviderKey(providerKey)
        guard let existing = resolvedModelProviderConfiguration(providerKey: normalized, preferredModel: defaultModel) else {
            showToast(title: "无法保存模型", message: "当前 Provider 缺少 Base URL、API Key 或模型列表", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        let modelList = normalizedModelNames(models + [defaultModel])
        guard !modelList.isEmpty else {
            showToast(title: "模型列表不能为空", message: "至少需要保留一个可见模型", icon: "lock.fill", accent: SetupPalette.amber)
            return
        }
        let configuration = ModelProviderConfiguration(
            providerKey: existing.providerKey,
            providerLabel: existing.providerLabel,
            baseURL: existing.baseURL,
            apiKey: existing.apiKey,
            defaultModel: modelList.contains(defaultModel) ? defaultModel : modelList[0],
            models: modelList,
            contextLength: max(contextLength, 8192)
        )

        if AppRuntimeMode.uiPrototype {
            showToast(title: "安全预览：已保存模型", message: "\(configuration.defaultModel) 已加入 \(providerDisplayName(for: normalized))", icon: "paintbrush.fill", accent: SetupPalette.cyan)
            return
        }

        isLoading = true
        statusMessage = "正在保存模型配置..."
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = SetupExecutionService().configureModelProviderExact(configuration) { _ in }
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.statusMessage = "模型配置已保存"
                    self.refreshModelStatus()
                    let checkedAt = self.currentTimeString()
                    self.modelDetectionHistory.insert(
                        ModelDetectionRecord(
                            id: UUID(),
                            targetType: "model",
                            title: "模型配置已保存",
                            detail: "\(self.providerDisplayName(for: normalized)) / \(configuration.defaultModel)",
                            status: .healthy,
                            latencyMS: nil,
                            availabilityPercent: nil,
                            checkedAt: checkedAt
                        ),
                        at: 0
                    )
                    self.modelDetectionHistory = Array(self.modelDetectionHistory.prefix(36))
                    self.showToast(title: "模型已同步", message: "已更新 Hermes CLI 与 Hermes Web UI 模型库", icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
                case .failure(let error):
                    self.statusMessage = "模型保存失败"
                    self.showToast(title: "保存失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
                }
            }
        }
    }

    private func normalizedModelNames(_ models: [String]) -> [String] {
        var seen = Set<String>()
        var values: [String] = []
        for model in models {
            let clean = model.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, seen.insert(clean).inserted else { continue }
            values.append(clean)
        }
        return values
    }

    func removeCustomProvider(providerKey: String) {
        guard !AppRuntimeMode.uiPrototype else {
            showToast(title: "安全预览：已预览删除", message: "当前不会触碰 Hermes/Web UI 本机配置", icon: "trash.fill", accent: DesignTokens.error)
            return
        }

        isLoading = true
        statusMessage = "正在删除自定义 Provider..."
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = SetupExecutionService().removeCustomModelProvider(providerKey: providerKey) { _ in }
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success:
                    self.statusMessage = "自定义 Provider 已删除"
                    self.refreshModelStatus()
                    let checkedAt = self.currentTimeString()
                    self.modelDetectionHistory.insert(
                        ModelDetectionRecord(
                            id: UUID(),
                            targetType: "provider",
                            title: "Provider 已删除",
                            detail: "已移除 \(self.providerDisplayName(for: providerKey))",
                            status: .warning,
                            latencyMS: nil,
                            availabilityPercent: nil,
                            checkedAt: checkedAt
                        ),
                        at: 0
                    )
                    self.modelDetectionHistory = Array(self.modelDetectionHistory.prefix(36))
                    self.showToast(title: "Provider 已删除", message: "已同步移除 Hermes CLI 和 Hermes Web UI 中的自定义 Provider", icon: "trash.fill", accent: DesignTokens.error)
                case .failure(let error):
                    self.statusMessage = "Provider 删除失败"
                    self.showToast(title: "删除失败", message: error.localizedDescription, icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
                }
            }
        }
    }

    func modelProviderConfiguration(providerKey: String) -> ModelProviderConfiguration? {
        resolvedModelProviderConfiguration(providerKey: providerKey, preferredModel: nil)
    }

    func checkProviderHealth(providerKey: String, completion: (() -> Void)? = nil) {
        let normalized = normalizedProviderKey(providerKey)
        let targets = detectModelProbeTargets().filter { normalizedProviderKey($0.providerKey) == normalized }
        runModelHealthCheck(
            targets: targets,
            title: providerDisplayName(for: providerKey),
            targetType: "provider",
            providerKey: providerKey,
            completion: completion
        )
    }

    func checkModelHealth(providerKey: String, modelName: String, completion: (() -> Void)? = nil) {
        let normalized = normalizedProviderKey(providerKey)
        let targets = detectModelProbeTargets().filter {
            normalizedProviderKey($0.providerKey) == normalized
                && $0.model == modelName
        }
        runModelHealthCheck(
            targets: targets,
            title: modelName,
            targetType: "model",
            providerKey: providerKey,
            modelName: modelName,
            completion: completion
        )
    }

    private func runModelHealthCheck(
        targets: [ModelProbeTarget],
        title: String,
        targetType: String,
        providerKey: String? = nil,
        modelName: String? = nil,
        completion: (() -> Void)? = nil
    ) {
        if isCheckingModelHealth {
            completion?()
            return
        }

        isCheckingModelHealth = true
        modelHealthResults = []
        modelHealthSummary = AppRuntimeMode.uiPrototype ? "安全预览：正在检测" : "正在检测 \(title)"

        if AppRuntimeMode.uiPrototype {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                let previewModel = modelName ?? self.currentModelName.ifEmpty("ui-preview-model")
                let previewProvider = providerKey.map { self.providerDisplayName(for: $0) }
                    ?? self.currentModelProvider.ifEmpty("OpenCode Go")
                let previewResults = targets.isEmpty
                    ? [
                        ModelHealthResult(provider: previewProvider, model: previewModel, ok: true, latencyMS: 142, detail: "安全预览：/models 可用")
                    ]
                    : targets.prefix(4).enumerated().map { index, target in
                        ModelHealthResult(
                            provider: target.providerLabel.ifEmpty(self.providerDisplayName(for: target.providerKey)),
                            model: target.model,
                            ok: true,
                            latencyMS: 142 + (index * 19),
                            detail: "安全预览：/models 可用"
                        )
                    }
                self.modelHealthResults = previewResults
                self.modelHealthSummary = "安全预览：\(previewResults.count) 个目标预览可用"
                self.recordDetectionHistory(
                    title: title,
                    targetType: targetType,
                    providerKey: providerKey,
                    modelName: modelName,
                    results: previewResults
                )
                self.isCheckingModelHealth = false
                self.showToast(title: "模型检测完成", message: "安全预览仅展示交互，不消耗真实 API", icon: "waveform.path.ecg", accent: SetupPalette.cyan)
                completion?()
            }
            return
        }

        guard !targets.isEmpty else {
            isCheckingModelHealth = false
            modelHealthSummary = "没有检测到可测试模型"
            showToast(title: "没有可检测目标", message: "请先配置 Provider、API Key 和模型列表", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            completion?()
            return
        }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let results = targets.map { self.probeModelTarget($0) }
            DispatchQueue.main.async {
                self.modelHealthResults = results
                let okCount = results.filter(\.ok).count
                self.modelHealthSummary = "\(okCount)/\(results.count) 个模型接口可用"
                self.recordDetectionHistory(
                    title: title,
                    targetType: targetType,
                    providerKey: providerKey,
                    modelName: modelName,
                    results: results
                )
                self.isCheckingModelHealth = false
                self.showToast(
                    title: "模型检测完成",
                    message: self.modelHealthSummary,
                    icon: "waveform.path.ecg",
                    accent: okCount == results.count && !results.isEmpty ? SetupPalette.emerald : SetupPalette.amber
                )
                completion?()
            }
        }
    }

    private func recordDetectionHistory(
        title: String,
        targetType: String,
        providerKey: String?,
        modelName: String?,
        results: [ModelHealthResult]
    ) {
        let checkedAt = currentTimeString()
        let okCount = results.filter(\.ok).count
        let aggregateStatus: ModelHealthStatus
        if results.isEmpty {
            aggregateStatus = .warning
        } else if okCount == results.count {
            aggregateStatus = .healthy
        } else if okCount == 0 {
            aggregateStatus = .unavailable
        } else {
            aggregateStatus = .warning
        }

        let summaryDetail: String
        switch targetType {
        case "provider":
            summaryDetail = results.isEmpty ? "没有可检测模型" : "成功检测 \(okCount)/\(results.count) 个模型"
        case "model":
            summaryDetail = results.first?.detail ?? "没有可检测模型"
        default:
            summaryDetail = results.isEmpty ? "没有可检测模型" : "成功检测 \(okCount)/\(results.count) 个模型"
        }

        var newRecords: [ModelDetectionRecord] = [
            ModelDetectionRecord(
                id: UUID(),
                targetType: targetType,
                title: "\(title) 检测完成",
                detail: summaryDetail,
                status: aggregateStatus,
                latencyMS: averageLatency(from: results),
                availabilityPercent: results.isEmpty ? nil : Int((Double(okCount) / Double(results.count) * 100).rounded()),
                checkedAt: checkedAt
            )
        ]

        for result in results.prefix(4) {
            let detail = result.latencyMS.map { "延迟 \($0)ms，\(result.detail)" } ?? result.detail
            let resultType = targetType == "provider" ? "model" : targetType
            newRecords.append(
                ModelDetectionRecord(
                    id: UUID(),
                    targetType: resultType,
                    title: "\(result.provider) / \(result.model)",
                    detail: detail,
                    status: result.ok ? .healthy : .unavailable,
                    latencyMS: result.latencyMS,
                    availabilityPercent: result.ok ? 100 : 0,
                    checkedAt: checkedAt
                )
            )
        }

        modelDetectionHistory.insert(contentsOf: newRecords, at: 0)
        modelDetectionHistory = Array(modelDetectionHistory.prefix(36))
    }

    private func averageLatency(from results: [ModelHealthResult]) -> Int? {
        let values = results.compactMap(\.latencyMS)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / values.count
    }

    private func lightweightModelSystemSnapshot() -> ModelSystemSnapshot {
        let cli = detectCLIModelStatusFromConfig()
        let web = WebUIModelSnapshot(
            available: !currentModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            providerKey: currentModelProvider,
            providerLabel: currentModelProvider,
            model: currentModelName,
            providerCount: detectedProviderCount,
            modelCount: detectedModelCount,
            presetProviderCount: 0,
            models: currentModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [currentModelName],
            providerModels: [],
            error: nil
        )
        return buildModelSystemSnapshot(cli: cli, web: web, includeSlowContextLookup: false)
    }

    private func buildModelSystemSnapshot(
        cli: CLIModelSnapshot,
        web: WebUIModelSnapshot,
        includeSlowContextLookup: Bool = true
    ) -> ModelSystemSnapshot {
        let currentBlock = currentCLIModelBlock()
        let currentProviderKey = normalizedProviderKey(!web.providerKey.isEmpty ? web.providerKey : cli.providerKey)
        let currentModel = !web.model.isEmpty ? web.model : cli.model
        let contextMap = includeSlowContextLookup ? modelContextLengthMap() : [:]
        let sources = resolvedModelProviderSources(
            cli: cli,
            web: web,
            currentBlock: currentBlock,
            includeSlowLookups: includeSlowContextLookup
        )

        var providers: [ModelProviderItem] = []
        var models: [ModelInfoItem] = []

        for key in sources.keys.sorted() {
            guard let source = sources[key] else { continue }
            let providerStatus = providerStatusFor(providerKey: key, source: source, currentProviderKey: currentProviderKey, currentModel: currentModel)
            let providerLatency = averageLatency(
                from: modelHealthResults.filter {
                    providerResultMatches(providerKey: key, providerLabel: source.label, result: $0)
                }
            )
            let isDefault = normalizedProviderKey(key) == currentProviderKey
            let modelNames = source.models.sorted()

            providers.append(
                ModelProviderItem(
                    id: key,
                    name: displayProviderName(label: source.label, key: key),
                    kind: source.kind,
                    baseURL: source.baseURL,
                    apiKeyConfigured: !source.apiKey.isEmpty,
                    apiKeyMasked: maskAPIKey(source.apiKey),
                    headersPreview: source.headersPreview,
                    timeoutSeconds: source.timeoutSeconds,
                    retryCount: source.retryCount,
                    enabled: !modelNames.isEmpty,
                    syncToCLI: true,
                    syncToWebUI: true,
                    isDefault: isDefault,
                    status: providerStatus,
                    modelCount: modelNames.count,
                    lastCheckedAt: latestCheckedAt(for: key).ifEmpty(modelStatusUpdatedAt.ifEmpty("未检测")),
                    latencyMS: providerLatency
                )
            )

            for modelName in modelNames {
                let isCurrent = normalizedProviderKey(key) == currentProviderKey && modelName == currentModel
                let explicitResult = modelHealthResults.first {
                    providerResultMatches(providerKey: key, providerLabel: source.label, result: $0)
                        && $0.model == modelName
                }
                let status: ModelHealthStatus
                if let explicitResult {
                    status = explicitResult.ok ? .healthy : .unavailable
                } else if isCurrent {
                    status = modelCalibrationHealthy ? .healthy : .warning
                } else {
                    status = .warning
                }
                let availability: Int
                if let explicitResult {
                    availability = explicitResult.ok ? 100 : 0
                } else {
                    availability = isCurrent ? (modelCalibrationHealthy ? 100 : 72) : 70
                }

                let contextLength = contextMap["\(key)|\(modelName)"].map { "\($0 / 1000)K" }
                    ?? contextMap["\(normalizedProviderKey(key))|\(modelName)"].map { "\($0 / 1000)K" }
                    ?? (isCurrent ? "128K" : "未检测")

                models.append(
                    ModelInfoItem(
                        id: "\(key)|\(modelName)",
                        name: modelName,
                        alias: modelAlias(for: modelName),
                        providerID: key,
                        providerName: displayProviderName(label: source.label, key: key),
                        baseURL: source.baseURL,
                        visible: true,
                        enabled: status != .unavailable || isCurrent,
                        isCurrent: isCurrent,
                        contextLength: contextLength,
                        priceLevel: priceLevel(for: modelName),
                        status: status,
                        latencyMS: explicitResult?.latencyMS,
                        availabilityPercent: availability,
                        lastCheckedAt: latestCheckedAt(for: key).ifEmpty(modelStatusUpdatedAt.ifEmpty("未检测"))
                    )
                )
            }
        }

        let detections = detectionHistoryFallback(currentProviderKey: currentProviderKey, currentModel: currentModel)
        return ModelSystemSnapshot(providers: providers, models: models, detections: detections)
    }

    private func detectionHistoryFallback(currentProviderKey: String, currentModel: String) -> [ModelDetectionRecord] {
        if !modelDetectionHistory.isEmpty {
            return Array(modelDetectionHistory.prefix(8))
        }
        if !modelHealthResults.isEmpty {
            let checkedAt = currentTimeString()
            return modelHealthResults.prefix(5).map { result in
                ModelDetectionRecord(
                    id: UUID(),
                    targetType: "model",
                    title: "\(result.provider) / \(result.model)",
                    detail: result.detail,
                    status: result.ok ? .healthy : .unavailable,
                    latencyMS: result.latencyMS,
                    availabilityPercent: result.ok ? 100 : 0,
                    checkedAt: checkedAt
                )
            }
        }
        guard !currentProviderKey.isEmpty || !currentModel.isEmpty else { return [] }
        return [
            ModelDetectionRecord(
                id: UUID(),
                targetType: "model",
                title: "\(providerDisplayName(for: currentProviderKey)) / \(currentModel)",
                detail: modelCalibrationSummary,
                status: modelCalibrationHealthy ? .healthy : .warning,
                latencyMS: nil,
                availabilityPercent: modelCalibrationHealthy ? 100 : 72,
                checkedAt: modelStatusUpdatedAt.ifEmpty(currentTimeString())
            )
        ]
    }

    private func resolvedModelProviderSources(
        cli: CLIModelSnapshot,
        web: WebUIModelSnapshot,
        currentBlock: CurrentCLIModelBlock,
        includeSlowLookups: Bool = true
    ) -> [String: ResolvedModelProviderSource] {
        let config = (try? String(contentsOfFile: activeHermesConfigPath, encoding: .utf8)) ?? ""
        let env = readHermesEnvValues()
        let visibilityInventory = includeSlowLookups ? detectWebUIConfigInventory(dataDir: locateWebUIDataDirectory()) : ModelInventorySnapshot()
        let targets = includeSlowLookups ? detectModelProbeTargets() : []
        let customProviders = parseCustomProviders(from: config)
        var sources: [String: ResolvedModelProviderSource] = [:]

        func mergeSource(
            providerKey: String,
            label: String,
            kind: ModelProviderKind,
            baseURL: String,
            apiKey: String,
            models: [String]
        ) {
            let normalized = normalizedProviderKey(providerKey)
            guard !normalized.isEmpty else { return }
            var source = sources[normalized] ?? ResolvedModelProviderSource(
                providerKey: normalized,
                label: label,
                kind: kind,
                baseURL: baseURL,
                apiKey: apiKey,
                models: [],
                headersPreview: "{}",
                timeoutSeconds: 60,
                retryCount: 3
            )
            if !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                source.label = label
            }
            if !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                source.baseURL = baseURL
            }
            if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                source.apiKey = apiKey
            }
            source.kind = kind
            source.models.formUnion(models.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            sources[normalized] = source
        }

        for provider in customProviders {
            let key = customProviderKey(forName: provider.name)
            let modelList = provider.models.isEmpty ? [provider.model] : provider.models
            mergeSource(
                providerKey: key,
                label: provider.name,
                kind: .custom,
                baseURL: provider.baseURL,
                apiKey: provider.apiKey,
                models: modelList
            )
        }

        for key in visibilityInventory.providerKeys {
            let label = visibilityInventory.providerLabels[key] ?? providerDisplayName(for: key)
            let models = visibilityInventory.providerModels
                .compactMap { pair -> String? in
                    let parts = pair.components(separatedBy: "|")
                    guard parts.count == 2, normalizedProviderKey(parts[0]) == normalizedProviderKey(key) else { return nil }
                    return parts[1]
                }
            let presetBaseURL = HermesModelProviderPreset.preset(for: key)?.baseURL ?? ""
            let currentBaseURL = normalizedProviderKey(currentBlock.providerKey) == normalizedProviderKey(key) ? currentBlock.baseURL : ""
            let apiKey = firstEnvValue(keys: providerEnvKeys(for: key), in: env) ?? ""
            mergeSource(
                providerKey: key,
                label: label,
                kind: normalizedProviderKey(key).hasPrefix("custom:") ? .custom : .builtin,
                baseURL: currentBaseURL.ifEmpty(presetBaseURL),
                apiKey: apiKey,
                models: models
            )
        }

        for target in targets {
            mergeSource(
                providerKey: target.providerKey,
                label: target.providerLabel.ifEmpty(providerDisplayName(for: target.providerKey)),
                kind: normalizedProviderKey(target.providerKey).hasPrefix("custom:") ? .custom : .builtin,
                baseURL: target.baseURL,
                apiKey: target.apiKey,
                models: [target.model]
            )
        }

        if !currentBlock.providerKey.isEmpty {
            let currentKey = normalizedProviderKey(currentBlock.providerKey)
            let label = currentKey == normalizedProviderKey(cli.providerKey)
                ? cli.providerLabel.ifEmpty(providerDisplayName(for: currentKey))
                : providerDisplayName(for: currentKey)
            let apiKey = firstEnvValue(keys: providerEnvKeys(for: currentKey), in: env) ?? ""
            mergeSource(
                providerKey: currentKey,
                label: label,
                kind: currentKey.hasPrefix("custom:") ? .custom : .builtin,
                baseURL: currentBlock.baseURL,
                apiKey: apiKey,
                models: [currentBlock.defaultModel]
            )
        }

        if !web.providerKey.isEmpty && !web.model.isEmpty {
            let label = web.providerLabel.ifEmpty(providerDisplayName(for: web.providerKey))
            let apiKey = firstEnvValue(keys: providerEnvKeys(for: web.providerKey), in: env) ?? ""
            mergeSource(
                providerKey: web.providerKey,
                label: label,
                kind: normalizedProviderKey(web.providerKey).hasPrefix("custom:") ? .custom : .builtin,
                baseURL: HermesModelProviderPreset.preset(for: web.providerKey)?.baseURL ?? "",
                apiKey: apiKey,
                models: [web.model]
            )
        }

        return sources
    }

    private func currentCLIModelBlock() -> CurrentCLIModelBlock {
        let content = (try? String(contentsOfFile: activeHermesConfigPath, encoding: .utf8)) ?? ""
        guard !content.isEmpty else {
            return CurrentCLIModelBlock(providerKey: "", baseURL: "", defaultModel: "")
        }

        var providerKey = ""
        var baseURL = ""
        var defaultModel = ""
        var inModelBlock = false

        for rawLine in content.components(separatedBy: CharacterSet.newlines) {
            let line = rawLine.trimmingCharacters(in: CharacterSet.whitespaces)
            if rawLine == "model:" {
                inModelBlock = true
                continue
            }
            if inModelBlock, !rawLine.hasPrefix(" "), !rawLine.hasPrefix("\t"), rawLine != "model:" {
                break
            }
            guard inModelBlock else { continue }
            if line.hasPrefix("provider:") {
                providerKey = yamlValue(from: line)
            } else if line.hasPrefix("base_url:") {
                baseURL = yamlValue(from: line)
            } else if line.hasPrefix("default:") {
                defaultModel = yamlValue(from: line)
            }
        }

        return CurrentCLIModelBlock(providerKey: providerKey, baseURL: baseURL, defaultModel: defaultModel)
    }

    private func modelContextLengthMap() -> [String: Int] {
        let dataDir = locateWebUIDataDirectory()
        let dbPath = dataDir.isEmpty ? NSHomeDirectory() + "/.hermes-web-ui/hermes-web-ui.db" : dataDir + "/hermes-web-ui.db"
        guard FileManager.default.fileExists(atPath: dbPath) else { return [:] }
        let sql = "SELECT provider || '|' || model || '|' || COALESCE(context_length, context_limit, 0) FROM model_context;"
        let output = runReadOnlyShell("sqlite3 \(shellQuote(dbPath)) \(shellQuote(sql))")
        var mapping: [String: Int] = [:]
        for row in output.components(separatedBy: .newlines) {
            let parts = row.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "|")
            guard parts.count >= 3, let length = Int(parts[2]), length > 0 else { continue }
            mapping["\(normalizedProviderKey(parts[0]))|\(parts[1])"] = length
        }
        return mapping
    }

    private func resolvedModelProviderConfiguration(providerKey: String, preferredModel: String?) -> ModelProviderConfiguration? {
        let cli = detectCLIModelStatus()
        let web = detectWebUIModelStatus()
        let currentBlock = currentCLIModelBlock()
        let sources = resolvedModelProviderSources(cli: cli, web: web, currentBlock: currentBlock)
        let normalized = normalizedProviderKey(providerKey)
        guard let source = sources[normalized] else { return nil }

        let chosenModel = preferredModel?.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentProvider = normalizedProviderKey(!web.providerKey.isEmpty ? web.providerKey : cli.providerKey)
        let currentModel = !web.model.isEmpty ? web.model : cli.model
        let defaultModel = chosenModel?.isEmpty == false
            ? chosenModel!
            : (currentProvider == normalized && !currentModel.isEmpty ? currentModel : source.models.sorted().first ?? "")

        guard !defaultModel.isEmpty, !source.baseURL.isEmpty, !source.apiKey.isEmpty else { return nil }

        let contextLength = modelContextLengthMap()["\(normalized)|\(defaultModel)"] ?? 128000
        return ModelProviderConfiguration(
            providerKey: normalized,
            providerLabel: source.label,
            baseURL: source.baseURL,
            apiKey: source.apiKey,
            defaultModel: defaultModel,
            models: source.models.sorted(),
            contextLength: contextLength
        )
    }

    private func providerStatusFor(
        providerKey: String,
        source: ResolvedModelProviderSource,
        currentProviderKey: String,
        currentModel: String
    ) -> ModelHealthStatus {
        let matches = modelHealthResults.filter {
            providerResultMatches(providerKey: providerKey, providerLabel: source.label, result: $0)
        }
        let okCount = matches.filter(\.ok).count
        if !matches.isEmpty {
            if okCount == matches.count { return .healthy }
            if okCount == 0 { return .unavailable }
            return .warning
        }
        if normalizedProviderKey(providerKey) == currentProviderKey {
            return modelCalibrationHealthy && !currentModel.isEmpty ? .healthy : .warning
        }
        return source.models.isEmpty ? .unavailable : .warning
    }

    private func providerResultMatches(providerKey: String, providerLabel: String, result: ModelHealthResult) -> Bool {
        let normalizedResult = normalizedProviderKey(result.provider)
        let normalizedKey = normalizedProviderKey(providerKey)
        if normalizedResult == normalizedKey {
            return true
        }
        let labelDisplay = displayProviderName(label: providerLabel, key: providerKey).lowercased()
        let resultProvider = result.provider.lowercased()
        return resultProvider == providerLabel.lowercased()
            || resultProvider == labelDisplay
            || resultProvider.contains(providerLabel.lowercased())
    }

    private func latestCheckedAt(for providerKey: String) -> String {
        for record in modelDetectionHistory {
            if record.title.lowercased().contains(providerKey.lowercased()) {
                return record.checkedAt
            }
        }
        return ""
    }

    private func maskAPIKey(_ apiKey: String) -> String {
        let clean = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "未配置" }
        if clean.count <= 8 {
            return String(repeating: "•", count: clean.count)
        }
        let suffix = clean.suffix(4)
        return "sk-••••••••••••\(suffix)"
    }

    private func modelAlias(for model: String) -> String {
        let clean = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "未命名模型" }
        return clean
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { segment in
                let lower = segment.lowercased()
                guard let first = lower.first else { return "" }
                return String(first).uppercased() + lower.dropFirst()
            }
            .joined(separator: " ")
    }

    private func priceLevel(for model: String) -> String {
        let lower = model.lowercased()
        if lower.contains("free") || lower.contains("mini") || lower.contains("flash") || lower.contains("lite") {
            return "$"
        }
        if lower.contains("ultra") || lower.contains("max") || lower.contains("opus") || lower.contains("pro") {
            return "$$$"
        }
        return "$$"
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @ObservedObject var manager: ServiceManager
    @AppStorage("setupCompleted") private var setupCompleted = false
    @AppStorage(L10n.languageKey) private var appLanguage = AppLanguage.zh.rawValue
    @State private var selectedTab = 0
    @State private var showSetupWizard = false

    private var language: AppLanguage {
        AppLanguage.normalized(appLanguage)
    }

    var body: some View {
        Group {
            if AppRuntimeMode.documentationScreenshot || !setupCompleted || showSetupWizard {
                SetupWizardView(manager: manager) {
                    setupCompleted = true
                    showSetupWizard = false
                    manager.readLogs()
                    manager.readGatewayLogs()
                    manager.readToken()
                    manager.autoStart()
                }
            } else {
                mainShell
            }
        }
        .background(DesignTokens.canvas)
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: language == .en ? "en" : "zh-Hans"))
        .id(appLanguage)
        .overlay(alignment: .top) {
            if let toast = manager.toast {
                ToastBanner(toast: toast)
                    .id(toast.id)
                    .padding(.top, 18)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: manager.toast?.id)
        .onAppear {
            manager.readLogs()
            manager.readGatewayLogs()
            manager.readToken()
            if setupCompleted {
                manager.autoStart()
            }
        }
    }

    private var mainShell: some View {
        Group {
            if selectedTab == 4 {
                SettingsView(
                    manager: manager,
                    onBack: { selectedTab = 0 },
                    onOpenSetup: {
                        selectedTab = 0
                        showSetupWizard = true
                    },
                    onOpenCLI: { selectedTab = 3 }
                )
            } else {
                HStack(spacing: 0) {
                    SidebarView(selectedTab: $selectedTab, manager: manager) {
                        showSetupWizard = true
                    }
                    .frame(width: 200)

                    Rectangle()
                        .fill(DesignTokens.borderSubtle)
                        .frame(width: 1)

                    Group {
                        switch selectedTab {
                        case 0:
                            DashboardView(
                                manager: manager,
                                onOpenSetup: { showSetupWizard = true },
                                onOpenCLI: { selectedTab = 3 }
                            )
                        case 1:
                            LogsView(manager: manager)
                        case 2:
                            QuickActionsView(
                                manager: manager,
                                onOpenSetup: { showSetupWizard = true },
                                onOpenCLI: { selectedTab = 3 }
                            )
                        case 3:
                            EmbeddedTerminalView(manager: manager)
                        default:
                            DashboardView(
                                manager: manager,
                                onOpenSetup: { showSetupWizard = true },
                                onOpenCLI: { selectedTab = 3 }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

struct ToastBanner: View {
    let toast: AppToast
    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(toast.accent.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: toast.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(toast.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.dynamic(toast.title))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(L10n.dynamic(toast.message))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                    Rectangle()
                        .fill(toast.accent)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .frame(width: 430)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(toast.accent.opacity(0.34), lineWidth: 1)
        )
        .cornerRadius(18)
        .shadow(color: toast.accent.opacity(0.22), radius: 24, x: 0, y: 14)
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: toast.duration)) {
                progress = 1
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selectedTab: Int
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    HermesSidebarMark()
                        .frame(width: 60, height: 56)
                    VStack(alignment: .leading, spacing: -1) {
                        Text("Hermes")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.86, green: 0.90, blue: 0.91),
                                        Color(red: 0.66, green: 0.72, blue: 0.74)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.white.opacity(0.16), radius: 2, x: 0, y: 0)
                            .lineLimit(1)
                        Text("Manager")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.16, green: 1.0, blue: 0.86),
                                        Color(red: 0.02, green: 0.78, blue: 0.72),
                                        Color(red: 0.02, green: 0.45, blue: 0.46)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: SetupPalette.cyan.opacity(0.18), radius: 3, x: 0, y: 0)
                            .lineLimit(1)
                    }
                    .layoutPriority(1)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("MAINFRAME")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignTokens.textMuted)
                        .tracking(1.1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 22)

            VStack(alignment: .leading, spacing: 8) {
                SidebarItem(icon: "square.grid.2x2", title: L10n.t("控制面板", "Dashboard"), accent: SetupPalette.cyan, isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                SidebarItem(icon: "doc.text", title: L10n.t("日志", "Logs"), accent: SetupPalette.emerald, isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                SidebarItem(icon: "bolt", title: L10n.t("快捷操作", "Actions"), accent: SetupPalette.amber, isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                SidebarItem(icon: "terminal", title: L10n.t("内置 CLI", "Embedded CLI"), accent: SetupPalette.cyan, isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
                SidebarItem(icon: "wand.and.stars", title: L10n.t("安装向导", "Setup Wizard"), accent: SetupPalette.emerald, isSelected: false) {
                    onOpenSetup()
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            SidebarSettingsButton(isSelected: selectedTab == 4) {
                selectedTab = 4
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 14)
        }
        .background(
            LinearGradient(
                colors: [SetupPalette.ink, SetupPalette.panel.opacity(0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HermesSidebarMark: View {
    var body: some View {
        SidebarLogoImage(name: "HermesSidebarMark")
            .aspectRatio(contentMode: .fit)
            .shadow(color: SetupPalette.cyan.opacity(0.30), radius: 7, x: 0, y: 0)
            .shadow(color: SetupPalette.emerald.opacity(0.16), radius: 12, x: 0, y: 3)
        .accessibilityLabel(Text("Hermes Manager"))
    }
}

struct SidebarLogoImage: View {
    let name: String

    var body: some View {
        if let image = Self.loadImage(named: name) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            Image(name)
                .resizable()
                .interpolation(.high)
        }
    }

    private static func loadImage(named name: String) -> NSImage? {
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "png"),
           let packageImage = NSImage(contentsOf: url) {
            return packageImage
        }
        #endif
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let bundledImage = NSImage(contentsOf: url) {
            return bundledImage
        }
        return NSImage(named: name)
    }
}

struct SidebarSettingsButton: View {
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                    .frame(width: 24, height: 24)
                Text(L10n.t("设置", "Settings"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? DesignTokens.surface2.opacity(0.58) : (hovering ? DesignTokens.surface2.opacity(0.34) : Color.clear))
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { action() })
        .onHover { hovering = $0 }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let accent: Color
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? accent : DesignTokens.textTertiary)
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                Spacer()
                if isSelected {
                    Circle()
                        .fill(accent)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? DesignTokens.surface2.opacity(0.88) : (hovering ? DesignTokens.surface2.opacity(0.38) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? accent.opacity(0.24) : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct SidebarStatusLine: View {
    let title: String
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
            Spacer()
            Text(isRunning ? L10n.t("运行中", "Running") : L10n.t("停止", "Stopped"))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isRunning ? SetupPalette.emerald : DesignTokens.textMuted)
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void

    var body: some View {
        ZStack {
            SetupBackground()

            GeometryReader { proxy in
                let compact = proxy.size.width < 900

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ConsoleHeader(manager: manager, onOpenSetup: onOpenSetup)

                        if compact {
                            VStack(spacing: 16) {
                                dashboardMainColumn
                                ConsoleCommandRail(
                                    manager: manager,
                                    onOpenSetup: onOpenSetup,
                                    onOpenCLI: onOpenCLI
                                )
                            }
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                dashboardMainColumn
                                    .frame(maxHeight: .infinity, alignment: .top)

                                ConsoleCommandRail(
                                    manager: manager,
                                    onOpenSetup: onOpenSetup,
                                    onOpenCLI: onOpenCLI
                                )
                                .frame(width: min(380, max(330, proxy.size.width * 0.28)))
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                            .frame(minHeight: max(0, proxy.size.height - 40), alignment: .top)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }

    private var dashboardMainColumn: some View {
        VStack(spacing: 16) {
            ConsoleRuntimeBoard(manager: manager)
            ConsoleAccessBoard(manager: manager)
            ConsoleModelBoard(manager: manager)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ConsoleRuntimeBoard: View {
    @ObservedObject var manager: ServiceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ConsoleSectionTitle(title: "Runtime", subtitle: "Hermes -> OpenHuman -> Web UI")

            VStack(alignment: .leading, spacing: 14) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 210), spacing: 10, alignment: .top)],
                    spacing: 10
                ) {
                    ConsoleTableRow(title: "Hermes Gateway", value: manager.gatewayRunning ? L10n.t("运行中", "Running") : L10n.t("未运行", "Stopped"), detail: L10n.t("主控进程", "Brain process"), isOn: manager.gatewayRunning)
                    ConsoleTableRow(title: "Hermes Web UI", value: manager.webUIRunning ? L10n.t("运行中", "Running") : L10n.t("未运行", "Stopped"), detail: L10n.t("控制台服务", "Console service"), isOn: manager.webUIRunning)
                    ConsoleTableRow(
                        title: "OpenHuman",
                        value: manager.openHumanMemoryLinked ? L10n.t("已连接", "Connected") : L10n.t("未连接", "Disconnected"),
                        detail: L10n.t("长期记忆库", "Long-term memory"),
                        isOn: manager.openHumanMemoryLinked
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Memory Pipeline")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignTokens.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.7)

                    HStack(spacing: 10) {
                        ConsolePipelineStep(title: "Hermes", detail: L10n.t("主控", "Brain"), icon: "bolt.fill", accent: SetupPalette.cyan, isOn: manager.gatewayRunning)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignTokens.textMuted)
                        ConsolePipelineStep(title: "OpenHuman", detail: L10n.t("记忆", "Memory"), icon: "externaldrive.connected.to.line.below", accent: SetupPalette.emerald, isOn: manager.openHumanMemoryLinked)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignTokens.textMuted)
                        ConsolePipelineStep(title: "Web UI", detail: L10n.t("控制", "Control"), icon: "rectangle.on.rectangle", accent: SetupPalette.amber, isOn: manager.webUIRunning)
                    }

                    Text(L10n.t("目标状态：Hermes 不写入自带长期记忆，所有长期记忆统一进入 OpenHuman。", "Target state: Hermes does not write native long-term memory; all long-term memory goes to OpenHuman."))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineSpacing(3)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(L10n.t("诊断", "Diagnostics")): \(L10n.dynamic(manager.memoryBridgeSummary))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(manager.memoryBridgeIssues.isEmpty ? SetupPalette.emerald : SetupPalette.amber)
                        if !manager.memoryBridgeIssues.isEmpty || !manager.memoryBridgeWarnings.isEmpty {
                            ForEach(Array((manager.memoryBridgeIssues + manager.memoryBridgeWarnings).prefix(4)), id: \.self) { issue in
                                Text("• \(L10n.dynamic(issue))")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(DesignTokens.textTertiary)
                                .lineLimit(1)
                            }
                        }
                        Text(L10n.t("OpenHuman 文档 \(manager.openHumanDocumentCount) 条；Hermes 待迁移长期记忆 \(manager.legacyHermesMemoryCount) 个；已迁移文档 \(manager.migratedMemoryDocumentCount) 条。", "OpenHuman docs: \(manager.openHumanDocumentCount); Hermes long-term items pending: \(manager.legacyHermesMemoryCount); migrated docs: \(manager.migratedMemoryDocumentCount)."))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignTokens.textMuted)
                            .lineLimit(2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(DesignTokens.surface2.opacity(0.34))
                .cornerRadius(16)
            }
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ConsoleAccessBoard: View {
    @ObservedObject var manager: ServiceManager
    @State private var tokenHidden = true

    private var tokenText: String {
        if manager.webUIToken.isEmpty { return L10n.t("未检测到登录 Token", "Login token not detected") }
        if tokenHidden { return String(repeating: "•", count: max(24, manager.webUIToken.count)) }
        return manager.webUIToken
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConsoleSectionTitle(title: "Access", subtitle: L10n.t("地址与凭证", "URL and credentials"))

            ConsoleCopyLine(
                icon: "globe",
                title: L10n.t("Web UI 地址", "Web UI URL"),
                value: manager.webUIURL,
                accent: SetupPalette.cyan,
                onCopy: { manager.copyToClipboard(manager.webUIURL, label: L10n.t("Web 地址", "Web URL"), message: L10n.t("可粘贴到浏览器打开 Hermes Web UI", "Paste it into a browser to open Hermes Web UI")) }
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SetupPalette.emerald)
                        .frame(width: 30, height: 30)
                        .background(SetupPalette.emerald.opacity(0.12))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.t("登录 Token", "Login Token"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DesignTokens.textPrimary)
                        Text(manager.webUITokenPath.isEmpty ? L10n.t("自动检测 token 文件", "Auto-detect token file") : compactPath(manager.webUITokenPath))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignTokens.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    ConsoleIconButton(icon: tokenHidden ? "eye.slash" : "eye", help: tokenHidden ? L10n.t("显示 Token", "Show token") : L10n.t("隐藏 Token", "Hide token")) {
                        tokenHidden.toggle()
                    }
                    ConsoleIconButton(icon: "doc.on.doc", help: L10n.t("复制 Token", "Copy token")) {
                        manager.copyToClipboard(manager.webUIToken, label: L10n.t("登录 Token", "Login token"), message: L10n.t("可粘贴到 Hermes Web UI 登录页", "Paste it into the Hermes Web UI login page"))
                    }
                    .disabled(manager.webUIToken.isEmpty)
                }

                Text(tokenText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(manager.webUIToken.isEmpty ? DesignTokens.textMuted : DesignTokens.textPrimary)
                    .lineLimit(tokenHidden ? 1 : 3)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.surface2.opacity(0.38))
                    .cornerRadius(12)
            }
            .padding(12)
            .background(DesignTokens.surface2.opacity(0.30))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(SetupPalette.emerald.opacity(0.16), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ConsoleModelBoard: View {
    @ObservedObject var manager: ServiceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConsoleSectionTitle(title: "Model", subtitle: manager.modelStatusUpdatedAt.isEmpty ? L10n.t("等待校准", "Waiting for calibration") : manager.modelStatusUpdatedAt)

            ConsoleModelLine(
                title: L10n.t("当前模型", "Current model"),
                model: manager.currentModelName,
                provider: manager.currentModelProvider,
                icon: "cpu",
                accent: manager.modelCalibrationHealthy ? SetupPalette.emerald : SetupPalette.amber
            )

            HStack(spacing: 8) {
                Image(systemName: manager.modelCalibrationHealthy ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(manager.modelCalibrationHealthy ? SetupPalette.emerald : SetupPalette.amber)
                Text(L10n.dynamic(manager.modelCalibrationSummary))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(12)
            .background(DesignTokens.surface2.opacity(0.30))
            .cornerRadius(12)

            HStack(spacing: 10) {
                ConsoleMiniStat(title: L10n.t("供应商", "Providers"), value: "\(manager.detectedProviderCount)", accent: SetupPalette.emerald)
                ConsoleMiniStat(title: L10n.t("模型", "Models"), value: "\(manager.detectedModelCount)", accent: DesignTokens.textSecondary)
            }
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ConsoleCommandRail: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ConsoleSectionTitle(title: "Command Center", subtitle: L10n.t("操作", "Actions"))

            Button(action: {
                if !manager.webUIRunning {
                    manager.startWebUI()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    manager.openWebUIInBrowser()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("打开 Web UI", "Open Web UI"))
                            .font(.system(size: 15, weight: .bold))
                        Text(L10n.t("启动后进入控制平台", "Open the control panel after startup"))
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.72)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.black.opacity(0.86))
                .padding(16)
                .background(LinearGradient(colors: [SetupPalette.cyan, SetupPalette.emerald], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                ConsoleActionButton(icon: "play.fill", title: L10n.t("启动全部", "Start All"), detail: "Web UI + Gateway", accent: SetupPalette.emerald, isLoading: manager.isLoading) { manager.startAll() }
                ConsoleActionButton(icon: "pause.fill", title: L10n.t("停止全部", "Stop All"), detail: L10n.t("关闭 Web UI + Gateway", "Stop Web UI + Gateway"), accent: SetupPalette.amber, isLoading: manager.isLoading) { manager.stopAll() }
                ConsoleActionButton(icon: "arrow.clockwise", title: L10n.t("重启全部", "Restart All"), detail: L10n.t("先停止再启动", "Stop, then start"), accent: SetupPalette.cyan, isLoading: manager.isLoading) { manager.restartAll() }
                ConsoleActionButton(icon: "terminal", title: L10n.t("内置 CLI", "Embedded CLI"), detail: L10n.t("应用内命令行", "In-app terminal"), accent: DesignTokens.textSecondary, isLoading: false) { onOpenCLI() }
                ConsoleActionButton(icon: "wand.and.stars", title: L10n.t("安装 / 修复向导", "Install / Repair Wizard"), detail: L10n.t("重新检测、补装、修复", "Re-detect, install, repair"), accent: SetupPalette.emerald, isLoading: false) { onOpenSetup() }
            }
            .frame(maxWidth: .infinity)

            Divider().background(DesignTokens.borderSubtle)

            VStack(alignment: .leading, spacing: 10) {
                ConsoleHealthRow(title: L10n.t("记忆策略", "Memory policy"), detail: L10n.dynamic(manager.memoryBridgeSummary), isOn: manager.openHumanMemoryLinked)
                ConsoleHealthRow(title: L10n.t("长期记忆迁移", "Long-term migration"), detail: manager.migratedMemoryAvailable ? L10n.t("Hermes 长期记忆已进入 OpenHuman 或无长期记忆", "Hermes long-term memory is in OpenHuman, or none exists") : L10n.t("检测到 Hermes 长期记忆未完成迁移", "Hermes long-term memory migration is incomplete"), isOn: manager.migratedMemoryAvailable)
                if !manager.memoryBridgeIssues.isEmpty {
                    ConsoleHealthRow(title: L10n.t("待修复项", "Repair needed"), detail: manager.memoryBridgeIssues.prefix(2).joined(separator: " / "), isOn: false)
                }
                ConsoleHealthRow(title: L10n.t("版本策略", "Version policy"), detail: L10n.t("先使用本机验证版本，更新在控制台内执行", "Use the verified local version first; update from the console"), isOn: true)
                ConsoleHealthRow(title: L10n.t("运行模式", "Run mode"), detail: AppRuntimeMode.autoStartServicesOnLaunch ? L10n.t("配置完成后打开 App 自动启动服务，关闭 App 自动停止服务", "After setup, opening the app starts services and quitting stops them") : L10n.t("显式点击后才启动服务", "Services start only after an explicit click"), isOn: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ConsoleHeader: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hermes Admin Console")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(L10n.t("服务状态、访问凭证、模型同步和修复入口集中管理。", "Manage service status, access credentials, model sync, and repair entry points in one place."))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                    ConsoleStatusChip(title: "Web UI", isOn: manager.webUIRunning)
                    ConsoleStatusChip(title: "Gateway", isOn: manager.gatewayRunning)
                    ConsoleStatusChip(title: L10n.t("OpenHuman 记忆", "OpenHuman Memory"), isOn: manager.openHumanMemoryLinked)
                }
                .frame(maxWidth: 520, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 10) {
                Text(L10n.dynamic(manager.statusMessage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SetupPalette.emerald)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                Button(action: onOpenSetup) {
                    Label(L10n.t("重新检测", "Re-detect"), systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(DesignTokens.surface2.opacity(0.78))
                        .cornerRadius(DesignTokens.radiusPill)
                }
                .buttonStyle(.plain)
            }
            .frame(minWidth: 150, maxWidth: 220, alignment: .trailing)
        }
        .padding(18)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(SetupPalette.emerald.opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct ConsoleSystemPanel: View {
    @ObservedObject var manager: ServiceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConsoleSectionTitle(title: L10n.t("服务总览", "Service Overview"), subtitle: L10n.t("运行状态", "Runtime status"))

            HStack(spacing: 8) {
                ConsoleMetricBlock(title: "Web UI", value: manager.webUIRunning ? L10n.t("运行中", "Running") : L10n.t("已停止", "Stopped"), icon: "globe", accent: manager.webUIRunning ? SetupPalette.emerald : DesignTokens.textMuted)
                ConsoleMetricBlock(title: "Gateway", value: manager.gatewayRunning ? L10n.t("运行中", "Running") : L10n.t("已停止", "Stopped"), icon: "bolt.horizontal", accent: manager.gatewayRunning ? SetupPalette.emerald : DesignTokens.textMuted)
                ConsoleMetricBlock(title: L10n.t("记忆库", "Memory DB"), value: manager.openHumanMemoryLinked ? "OpenHuman" : L10n.t("未连接", "Disconnected"), icon: "brain.head.profile", accent: SetupPalette.cyan)
            }

            VStack(spacing: 8) {
                ConsoleServiceLine(title: L10n.t("Hermes 主控", "Hermes Brain"), detail: manager.gatewayRunning ? L10n.t("Gateway 进程运行中", "Gateway process is running") : L10n.t("等待启动 Gateway", "Waiting to start Gateway"), isOn: manager.gatewayRunning)
                ConsoleServiceLine(title: "Hermes Web UI", detail: manager.webUIRunning ? L10n.t("控制台服务运行中", "Console service is running") : L10n.t("等待启动 Web UI", "Waiting to start Web UI"), isOn: manager.webUIRunning)
                ConsoleServiceLine(title: L10n.t("长期记忆", "Long-term memory"), detail: L10n.t("目标：Hermes 使用 OpenHuman，不写入自带长期记忆", "Target: Hermes uses OpenHuman and does not write native long-term memory"), isOn: manager.openHumanMemoryLinked)
            }
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct ConsoleAccessPanel: View {
    @ObservedObject var manager: ServiceManager
    @State private var tokenHidden = true

    private var tokenText: String {
        guard !manager.webUIToken.isEmpty else { return L10n.t("未检测到登录 Token", "Login token not detected") }
        if tokenHidden {
            return String(repeating: "•", count: max(24, manager.webUIToken.count))
        }
        return manager.webUIToken
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConsoleSectionTitle(title: L10n.t("访问入口", "Access"), subtitle: L10n.t("地址与凭证", "URL and credentials"))

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ConsoleCopyRow(
                        icon: "globe",
                        title: L10n.t("Web UI 地址", "Web UI URL"),
                        value: manager.webUIURL,
                        accent: SetupPalette.cyan,
                        onCopy: {
                            manager.copyToClipboard(manager.webUIURL, label: L10n.t("Web 地址", "Web URL"), message: L10n.t("可粘贴到浏览器打开 Hermes Web UI", "Paste it into a browser to open Hermes Web UI"))
                        }
                    )

                    ConsoleCopyRow(
                        icon: "folder",
                        title: L10n.t("Token 位置", "Token location"),
                        value: manager.webUITokenPath.isEmpty ? L10n.t("自动检测 Web UI 数据目录", "Auto-detect Web UI data directory") : manager.webUITokenPath,
                        accent: DesignTokens.textSecondary,
                        onCopy: {
                            manager.copyToClipboard(manager.webUITokenPath, label: L10n.t("Token 路径", "Token path"), message: L10n.t("已复制当前检测到的 token 文件路径", "Copied the detected token file path"))
                        }
                    )
                }
                .frame(width: 360)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(SetupPalette.emerald)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.t("登录 Token", "Login Token"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(DesignTokens.textPrimary)
                            Text(manager.webUITokenPath.isEmpty ? L10n.t("自动检测 Web UI 数据目录", "Auto-detect Web UI data directory") : manager.webUITokenPath)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(DesignTokens.textMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        ConsoleIconButton(icon: tokenHidden ? "eye.slash" : "eye", help: tokenHidden ? L10n.t("显示 Token", "Show token") : L10n.t("隐藏 Token", "Hide token")) {
                            tokenHidden.toggle()
                        }
                        ConsoleIconButton(icon: "doc.on.doc", help: L10n.t("复制 Token", "Copy token")) {
                            manager.copyToClipboard(manager.webUIToken, label: L10n.t("登录 Token", "Login token"), message: L10n.t("可粘贴到 Hermes Web UI 登录页", "Paste it into the Hermes Web UI login page"))
                        }
                        .disabled(manager.webUIToken.isEmpty)
                    }

                    Text(tokenText)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(manager.webUIToken.isEmpty ? DesignTokens.textMuted : DesignTokens.textPrimary)
                        .lineLimit(tokenHidden ? 1 : 3)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(DesignTokens.surface2.opacity(0.42))
                        .cornerRadius(12)
                }
                .padding(14)
                .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SetupPalette.emerald.opacity(0.16), lineWidth: 1)
                )
                .cornerRadius(14)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct ConsoleModelPanel: View {
    @ObservedObject var manager: ServiceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConsoleSectionTitle(title: L10n.t("模型配置", "Model Config"), subtitle: manager.modelStatusUpdatedAt.isEmpty ? L10n.t("等待校准", "Waiting for calibration") : L10n.t("上次校准 \(manager.modelStatusUpdatedAt)", "Last calibrated \(manager.modelStatusUpdatedAt)"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ConsoleMetricBlock(title: L10n.t("当前模型", "Current model"), value: manager.currentModelName.isEmpty ? L10n.t("未检测", "Not detected") : manager.currentModelName, icon: "cpu", accent: SetupPalette.cyan)
                ConsoleMetricBlock(title: L10n.t("供应商", "Provider"), value: manager.currentModelProvider.isEmpty ? L10n.t("未检测", "Not detected") : manager.currentModelProvider, icon: "square.stack.3d.up", accent: SetupPalette.emerald)
                ConsoleMetricBlock(title: L10n.t("校准状态", "Calibration"), value: manager.modelCalibrationHealthy ? L10n.t("已校准", "Calibrated") : L10n.t("需同步", "Needs sync"), icon: manager.modelCalibrationHealthy ? "checkmark.seal" : "exclamationmark.triangle", accent: manager.modelCalibrationHealthy ? SetupPalette.emerald : SetupPalette.amber)
                ConsoleMetricBlock(title: L10n.t("模型数量", "Models"), value: "\(manager.detectedModelCount)", icon: "cpu", accent: DesignTokens.textSecondary)
            }
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct ConsoleOperatorPanel: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ConsoleSectionTitle(title: L10n.t("操作台", "Operator Panel"), subtitle: L10n.t("高频命令", "Frequent commands"))

            VStack(spacing: 10) {
                ConsoleActionButton(icon: "play.fill", title: L10n.t("启动全部", "Start All"), detail: "Web UI + Gateway", accent: SetupPalette.emerald, isLoading: manager.isLoading) {
                    manager.startAll()
                }
                ConsoleActionButton(icon: "pause.fill", title: L10n.t("停止全部", "Stop All"), detail: L10n.t("关闭 Web UI + Gateway", "Stop Web UI + Gateway"), accent: SetupPalette.amber, isLoading: manager.isLoading) {
                    manager.stopAll()
                }
                ConsoleActionButton(icon: "arrow.clockwise", title: L10n.t("重启全部", "Restart All"), detail: L10n.t("先停止再启动", "Stop, then start"), accent: SetupPalette.cyan, isLoading: manager.isLoading) {
                    manager.restartAll()
                }
                ConsoleActionButton(icon: "safari", title: L10n.t("打开 Web UI", "Open Web UI"), detail: L10n.t("必要时先启动服务", "Start services first if needed"), accent: SetupPalette.cyan, isLoading: false) {
                    if !manager.webUIRunning {
                        manager.startWebUI()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        manager.openWebUIInBrowser()
                    }
                }
                ConsoleActionButton(icon: "terminal", title: L10n.t("内置 CLI", "Embedded CLI"), detail: L10n.t("应用内命令行", "In-app terminal"), accent: DesignTokens.textSecondary, isLoading: false) {
                    onOpenCLI()
                }
                ConsoleActionButton(icon: "wand.and.stars", title: L10n.t("安装 / 修复向导", "Install / Repair Wizard"), detail: L10n.t("重新检测、补装、修复", "Re-detect, install, repair"), accent: SetupPalette.emerald, isLoading: false) {
                    onOpenSetup()
                }
            }

            Divider().background(DesignTokens.borderSubtle)

            VStack(alignment: .leading, spacing: 10) {
                ConsoleHealthRow(title: L10n.t("记忆策略", "Memory policy"), detail: L10n.t("Hermes 主控，OpenHuman 作为长期记忆库", "Hermes is the brain; OpenHuman is the long-term memory store"), isOn: manager.openHumanMemoryLinked)
                ConsoleHealthRow(title: L10n.t("长期记忆迁移", "Long-term migration"), detail: manager.migratedMemoryAvailable ? L10n.t("迁移检查通过，短期日志保留本地", "Migration check passed; short-term logs remain local") : L10n.t("需要进入安装向导修复", "Open setup wizard to repair"), isOn: manager.migratedMemoryAvailable)
                ConsoleHealthRow(title: L10n.t("版本策略", "Version policy"), detail: L10n.t("先使用本机验证版本，更新在控制台内执行", "Use the verified local version first; update from the console"), isOn: true)
                ConsoleHealthRow(title: L10n.t("运行模式", "Run mode"), detail: AppRuntimeMode.autoStartServicesOnLaunch ? L10n.t("配置完成后打开 App 自动启动服务，关闭 App 自动停止服务", "After setup, opening the app starts services and quitting stops them") : L10n.t("显式点击后才启动服务", "Services start only after an explicit click"), isOn: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct ConsoleStatusChip: View {
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
                .minimumScaleFactor(0.86)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isOn ? SetupPalette.emerald : DesignTokens.textMuted).opacity(0.10))
        .cornerRadius(DesignTokens.radiusPill)
    }
}

struct ConsoleSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)
            Spacer()
            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignTokens.textMuted)
                .lineLimit(1)
        }
    }
}

struct ConsoleMetricBlock: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accent)
                    .frame(width: 24, height: 24)
                    .background(accent.opacity(0.12))
                    .cornerRadius(8)
                Spacer()
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(DesignTokens.textMuted)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(DesignTokens.surface2.opacity(0.42))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct ConsoleTableRow: View {
    let title: String
    let value: String
    let detail: String
    let isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.88)
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
        .cornerRadius(12)
    }
}

struct ConsolePipelineStep: View {
    let title: String
    let detail: String
    let icon: String
    let accent: Color
    let isOn: Bool

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 38, height: 38)
                .background(accent.opacity(0.12))
                .cornerRadius(12)
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(1)
            Text(detail)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
            Circle()
                .fill(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConsoleCopyLine: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(value.isEmpty ? L10n.t("未检测到", "Not detected") : compactPath(value))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignTokens.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Spacer()

            ConsoleIconButton(icon: "doc.on.doc", help: L10n.t("复制\(title)", "Copy \(title)"), action: onCopy)
                .disabled(value.isEmpty)
        }
        .padding(12)
        .background(DesignTokens.surface2.opacity(0.34))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct ConsoleModelLine: View {
    let title: String
    let model: String
    let provider: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 34, height: 34)
                .background(accent.opacity(0.12))
                .cornerRadius(11)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
                Text(model.isEmpty ? L10n.t("未检测", "Not detected") : model)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(provider.isEmpty ? L10n.t("provider 未检测", "provider not detected") : "provider: \(provider)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(DesignTokens.surface2.opacity(0.34))
        .cornerRadius(14)
    }
}

struct ConsoleMiniStat: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surface2.opacity(0.34))
        .cornerRadius(12)
    }
}

func compactPath(_ path: String) -> String {
    let home = NSHomeDirectory()
    var value = path.replacingOccurrences(of: home, with: "~")
    if value.count > 42 {
        let suffix = value.suffix(32)
        value = "..." + suffix
    }
    return value
}

struct ConsoleServiceLine: View {
    let title: String
    let detail: String
    let isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(11)
        .background(DesignTokens.surface2.opacity(0.38))
        .cornerRadius(12)
    }
}

struct ConsoleCopyRow: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.12))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(DesignTokens.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }

            Spacer()

            ConsoleIconButton(icon: "doc.on.doc", help: "复制\(title)", action: onCopy)
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct ConsoleIconButton: View {
    let icon: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
                .frame(width: 32, height: 32)
                .background(DesignTokens.surface3.opacity(0.78))
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

struct ConsoleActionButton: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    let isLoading: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.58)
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accent)
                    }
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .lineLimit(1)
                    Text(detail)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
                    .frame(width: 18, alignment: .trailing)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(hovering ? DesignTokens.surface2.opacity(0.72) : DesignTokens.surface2.opacity(0.42))
            .cornerRadius(14)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { hovering = $0 }
    }
}

struct ConsoleHealthRow: View {
    let title: String
    let detail: String
    let isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
                .frame(width: 18, alignment: .center)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
    }
}

struct DashboardHeroPanel: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Hermes Control Deck")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(L10n.t("主控大脑、外置记忆、Web UI 和模型配置都在这里统一管理。", "Manage the brain, external memory, Web UI, and model config from one place."))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)

                HStack(spacing: 8) {
                    SetupHealthChip(title: L10n.t("Hermes 主控", "Hermes Brain"), isOn: manager.gatewayRunning)
                    SetupHealthChip(title: "Web UI", isOn: manager.webUIRunning)
                    SetupHealthChip(title: L10n.t("OpenHuman 记忆", "OpenHuman Memory"), isOn: manager.openHumanMemoryLinked)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Text(L10n.dynamic(manager.statusMessage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(SetupPalette.emerald)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                Button(action: onOpenSetup) {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                        Text(L10n.t("重新检测", "Re-detect"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(DesignTokens.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(DesignTokens.surface2.opacity(0.78))
                    .cornerRadius(DesignTokens.radiusPill)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(22)
        .background(DiffusePanelBackground(cornerRadius: 24, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(SetupPalette.emerald.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(24)
    }
}

struct DashboardSignalCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(accent.opacity(0.13))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(accent)
                }
                Spacer()
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct DashboardTokenCard: View {
    @ObservedObject var manager: ServiceManager
    @State private var isHidden = true
    @State private var copied = false

    private var tokenText: String {
        if manager.webUIToken.isEmpty { return L10n.t("未检测到登录 Token", "Login token not detected") }
        if isHidden {
            return String(repeating: "•", count: max(24, manager.webUIToken.count))
        }
        return manager.webUIToken
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(SetupPalette.emerald.opacity(0.13))
                        .frame(width: 42, height: 42)
                    Image(systemName: "key.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(SetupPalette.emerald)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("登录 Token", "Login Token"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(DesignTokens.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(manager.webUITokenPath.isEmpty ? L10n.t("自动检测 Web UI 数据目录", "Auto-detect Web UI data directory") : manager.webUITokenPath)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                Button(action: { isHidden.toggle() }) {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(DesignTokens.surface2.opacity(0.78))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .help(isHidden ? L10n.t("显示 Token", "Show token") : L10n.t("隐藏 Token", "Hide token"))

                Button(action: copyToken) {
                    HStack(spacing: 5) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .bold))
                        Text(copied ? L10n.t("已复制", "Copied") : L10n.t("复制", "Copy"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(copied ? SetupPalette.emerald : DesignTokens.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(DesignTokens.surface2.opacity(0.78))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(manager.webUIToken.isEmpty)
            }

            Text(tokenText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(manager.webUIToken.isEmpty ? DesignTokens.textMuted : DesignTokens.textPrimary)
                .textSelection(.enabled)
                .lineLimit(isHidden ? 1 : nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(DesignTokens.surface2.opacity(0.42))
                .cornerRadius(12)
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(SetupPalette.emerald.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(18)
    }

    private func copyToken() {
        guard !manager.webUIToken.isEmpty else { return }
        manager.copyToClipboard(manager.webUIToken, label: L10n.t("登录 Token", "Login token"), message: L10n.t("可粘贴到 Hermes Web UI 登录页", "Paste it into the Hermes Web UI login page"))
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }
}

struct DashboardFlowPanel: View {
    @ObservedObject var manager: ServiceManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.t("运行链路", "Runtime Pipeline"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Spacer()
                Text("Hermes -> OpenHuman -> Web UI")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignTokens.textMuted)
            }

            HStack(spacing: 12) {
                DashboardNode(title: "Hermes", detail: L10n.t("主控大脑", "Brain"), icon: "bolt.fill", isOn: manager.gatewayRunning, accent: SetupPalette.cyan)
                DashboardConnector()
                DashboardNode(title: "OpenHuman", detail: L10n.t("长期记忆库", "Long-term memory"), icon: "externaldrive.connected.to.line.below", isOn: manager.openHumanMemoryLinked, accent: SetupPalette.emerald)
                DashboardConnector()
                DashboardNode(title: "Web UI", detail: L10n.t("控制平台", "Control panel"), icon: "rectangle.on.rectangle", isOn: manager.webUIRunning, accent: SetupPalette.amber)
            }
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct DashboardNode: View {
    let title: String
    let detail: String
    let icon: String
    let isOn: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accent.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accent)
            }
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(DesignTokens.textPrimary)
            Text(detail)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
            HStack(spacing: 5) {
                Circle()
                    .fill(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                    .frame(width: 6, height: 6)
                Text(isOn ? L10n.t("就绪", "Ready") : L10n.t("待启动", "Pending"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textTertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surface2.opacity(0.42))
        .cornerRadius(16)
    }
}

struct DashboardConnector: View {
    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(DesignTokens.textMuted)
    }
}

struct DashboardActionPanel: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("快捷操作", "Quick Actions"))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                DashboardActionTile(icon: "safari", title: L10n.t("打开 Web UI", "Open Web UI"), detail: manager.webUIURL, accent: SetupPalette.cyan) {
                    if !manager.webUIRunning {
                        manager.startWebUI()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        manager.openWebUIInBrowser()
                    }
                }
                DashboardActionTile(icon: "terminal", title: L10n.t("内置 CLI", "Embedded CLI"), detail: L10n.t("应用内命令行", "In-app terminal"), accent: DesignTokens.textSecondary) {
                    onOpenCLI()
                }
                DashboardActionTile(icon: "wand.and.stars", title: L10n.t("安装向导", "Setup Wizard"), detail: L10n.t("重新检测/修复", "Re-detect / repair"), accent: SetupPalette.amber) {
                    onOpenSetup()
                }
            }
        }
        .padding(16)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct DashboardActionTile: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(detail)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovering ? DesignTokens.surface2.opacity(0.75) : DesignTokens.surface2.opacity(0.42))
            .cornerRadius(14)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct DashboardSideRail: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("健康检查", "Health Check"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)

            VStack(spacing: 10) {
                DashboardCheckRow(title: L10n.t("Hermes 主控", "Hermes Brain"), detail: manager.gatewayRunning ? L10n.t("Gateway 运行中", "Gateway running") : L10n.t("等待启动", "Waiting to start"), isOn: manager.gatewayRunning)
                DashboardCheckRow(title: L10n.t("OpenHuman 记忆", "OpenHuman Memory"), detail: L10n.dynamic(manager.memoryBridgeSummary), isOn: manager.openHumanMemoryLinked)
                DashboardCheckRow(title: L10n.t("Hermes 自带记忆", "Hermes Native Memory"), detail: manager.openHumanMemoryLinked ? L10n.t("已关闭自带长期记忆写入", "Native long-term writes disabled") : L10n.t("未完全关闭或未检测到", "Not fully disabled or not detected"), isOn: manager.openHumanMemoryLinked)
                DashboardCheckRow(title: L10n.t("长期记忆迁移", "Long-term Migration"), detail: manager.migratedMemoryAvailable ? L10n.t("检查通过，短期日志保留本地", "Check passed; short-term logs remain local") : L10n.t("需要迁移或确认无长期记忆", "Migration needed, or confirm none exists"), isOn: manager.migratedMemoryAvailable)
                DashboardCheckRow(title: L10n.t("当前模型", "Current Model"), detail: manager.currentModelName.isEmpty ? L10n.t("暂未检测到", "Not detected yet") : "\(manager.currentModelProvider) / \(manager.currentModelName)", isOn: !manager.currentModelName.isEmpty)
                DashboardCheckRow(title: L10n.t("模型校准", "Model Calibration"), detail: L10n.dynamic(manager.modelCalibrationSummary), isOn: manager.modelCalibrationHealthy)
            }

            Divider().background(DesignTokens.borderSubtle)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("版本策略", "Version Policy"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                Text(L10n.t("默认安装本机验证版本；如果用户想要最新版，先完成安装，再在这里执行更新。", "Install the locally verified version by default. If users want a newer build, finish setup first, then update here."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(3)
            }

            Spacer()

            Button(action: onOpenSetup) {
                HStack {
                    Text(L10n.t("重新检测配置", "Re-detect Config"))
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.black.opacity(0.86))
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(LinearGradient(colors: [SetupPalette.cyan, SetupPalette.emerald], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(22)
    }
}

struct DashboardCheckRow: View {
    let title: String
    let detail: String
    let isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(11)
        .background(DesignTokens.surface2.opacity(0.46))
        .cornerRadius(13)
    }
}

struct UnifiedServiceCard: View {
    @ObservedObject var manager: ServiceManager
    @State private var hoverStart = false
    @State private var hoverStop = false

    var allRunning: Bool { manager.webUIRunning && manager.gatewayRunning }
    var noneRunning: Bool { !manager.webUIRunning && !manager.gatewayRunning }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区
            HStack(spacing: DesignTokens.spaceSM) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMD)
                        .fill(allRunning ? DesignTokens.success.opacity(0.12) : DesignTokens.surface3)
                        .frame(width: 40, height: 40)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(allRunning ? DesignTokens.success : DesignTokens.textTertiary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("Hermes 服务", "Hermes Services"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    HStack(spacing: DesignTokens.spaceXS) {
                        Circle()
                            .fill(allRunning ? DesignTokens.success : (noneRunning ? DesignTokens.textMuted : DesignTokens.warning))
                            .frame(width: 7, height: 7)
                        Text(allRunning ? L10n.t("全部运行中", "All running") : (noneRunning ? L10n.t("全部已停止", "All stopped") : L10n.t("部分运行中", "Partially running")))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(allRunning ? DesignTokens.success : (noneRunning ? DesignTokens.textTertiary : DesignTokens.warning))
                    }
                }
                Spacer()
            }

            Spacer().frame(height: DesignTokens.spaceLG)

            // 服务详情行
            HStack(spacing: DesignTokens.spaceXL) {
                ServiceDetailRow(icon: "globe", name: "Web UI", isRunning: manager.webUIRunning)
                ServiceDetailRow(icon: "network", name: "Gateway", isRunning: manager.gatewayRunning)
            }

            Spacer().frame(height: DesignTokens.spaceLG)

            // 按钮区
            HStack(spacing: DesignTokens.spaceSM) {
                if !noneRunning {
                    Button(action: { manager.stopAll() }) {
                        HStack(spacing: DesignTokens.spaceXS) {
                            if manager.isLoading {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            }
                            Text(L10n.t("全部停止", "Stop All"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(hoverStop ? DesignTokens.error.opacity(0.20) : DesignTokens.error.opacity(0.12))
                        .foregroundColor(DesignTokens.error)
                        .cornerRadius(DesignTokens.radiusPill)
                    }
                    .buttonStyle(.plain)
                    .disabled(manager.isLoading)
                    .onHover { hoverStop = $0 }
                }
                if !allRunning {
                    Button(action: { manager.startAll() }) {
                        HStack(spacing: DesignTokens.spaceXS) {
                            if manager.isLoading {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            }
                            Text(L10n.t("全部启动", "Start All"))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(hoverStart ? DesignTokens.success.opacity(0.20) : DesignTokens.success.opacity(0.12))
                        .foregroundColor(DesignTokens.success)
                        .cornerRadius(DesignTokens.radiusPill)
                    }
                    .buttonStyle(.plain)
                    .disabled(manager.isLoading)
                    .onHover { hoverStart = $0 }
                }
            }
        }
        .padding(DesignTokens.spaceXL)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surface1)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(DesignTokens.radiusLG)
    }
}

struct ServiceDetailRow: View {
    let icon: String
    let name: String
    let isRunning: Bool

    var body: some View {
        HStack(spacing: DesignTokens.spaceSM) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isRunning ? DesignTokens.success : DesignTokens.textMuted)
                .frame(width: 16)
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.textSecondary)
            Spacer().frame(width: 4)
            Circle()
                .fill(isRunning ? DesignTokens.success : DesignTokens.textMuted)
                .frame(width: 6, height: 6)
            Text(isRunning ? L10n.t("运行中", "Running") : L10n.t("已停止", "Stopped"))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isRunning ? DesignTokens.success : DesignTokens.textTertiary)
        }
    }
}

struct TokenDisplayView: View {
    let token: String
    @State private var isHidden = true
    @State private var copied = false

    var displayToken: String {
        if token.isEmpty { return L10n.t("未找到 Token", "Token not found") }
        if isHidden { return String(repeating: "•", count: min(token.count, 40)) }
        return token
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spaceSM) {
            HStack(spacing: DesignTokens.spaceSM) {
                Text(L10n.t("登录 Token", "Login Token"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
            }

            HStack(spacing: DesignTokens.spaceSM) {
                Image(systemName: "key.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.accent.opacity(0.7))

                Text(displayToken)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(token.isEmpty ? DesignTokens.textMuted : DesignTokens.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: { isHidden.toggle() }) {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(DesignTokens.surface3)
                        .cornerRadius(DesignTokens.radiusSM)
                }
                .buttonStyle(.plain)
                .help(isHidden ? L10n.t("显示 Token", "Show token") : L10n.t("隐藏 Token", "Hide token"))

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(token, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                        if !copied {
                            Text(L10n.t("复制", "Copy"))
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundColor(copied ? DesignTokens.success : DesignTokens.textTertiary)
                    .frame(height: 28)
                    .padding(.horizontal, 10)
                    .background(DesignTokens.surface3)
                    .cornerRadius(DesignTokens.radiusSM)
                }
                .buttonStyle(.plain)
                .disabled(token.isEmpty)
                .help(L10n.t("复制 Token", "Copy token"))
            }
        }
        .padding(DesignTokens.spaceLG)
        .background(DesignTokens.surface1)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(DesignTokens.radiusLG)
    }
}

struct StatusCard: View {
    let title: String
    let icon: String
    let isRunning: Bool
    let onStart: (() -> Void)?
    let onStop: (() -> Void)?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spaceMD) {
            HStack(spacing: DesignTokens.spaceSM) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMD)
                        .fill(isRunning ? DesignTokens.success.opacity(0.12) : DesignTokens.surface3)
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isRunning ? DesignTokens.success : DesignTokens.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    HStack(spacing: DesignTokens.spaceXS) {
                        Circle()
                            .fill(isRunning ? DesignTokens.success : DesignTokens.textMuted)
                            .frame(width: 6, height: 6)
                        Text(isRunning ? L10n.t("运行中", "Running") : L10n.t("已停止", "Stopped"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isRunning ? DesignTokens.success : DesignTokens.textTertiary)
                    }
                }

                Spacer()
            }

            if let onStart = onStart, let onStop = onStop {
                HStack(spacing: DesignTokens.spaceSM) {
                    if isRunning {
                        SmallButton(title: L10n.t("停止", "Stop"), color: DesignTokens.error, isLoading: isLoading) {
                            onStop()
                        }
                    } else {
                        SmallButton(title: L10n.t("启动", "Start"), color: DesignTokens.success, isLoading: isLoading) {
                            onStart()
                        }
                    }
                }
            }
        }
        .padding(DesignTokens.spaceLG)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.surface1)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusLG)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(DesignTokens.radiusLG)
    }
}

struct SmallButton: View {
    let title: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spaceXS) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, DesignTokens.spaceMD)
            .padding(.vertical, DesignTokens.spaceXS)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(DesignTokens.radiusPill)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct ActionPillButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.spaceXS) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, DesignTokens.spaceMD)
            .padding(.vertical, DesignTokens.spaceSM)
            .background(DesignTokens.surface2)
            .foregroundColor(color)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusPill)
                    .stroke(DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(DesignTokens.radiusPill)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var manager: ServiceManager
    let onBack: () -> Void
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void
    @AppStorage(L10n.languageKey) private var appLanguage = AppLanguage.zh.rawValue
    @AppStorage("launchWebUIOnOpen") private var launchWebUIOnOpen = true
    @AppStorage("openBrowserOnLaunch") private var openBrowserOnLaunch = true
    @AppStorage("stopManagedServicesOnQuit") private var stopManagedServicesOnQuit = true
    @AppStorage("matchTerminalProfile") private var matchTerminalProfile = true
    @AppStorage("hideTokenByDefault") private var hideTokenByDefault = true
    @AppStorage("publicLogsOnly") private var publicLogsOnly = true
    @AppStorage("includePreviewAppUpdates") private var includePreviewAppUpdates = false
    @State private var showAddProviderSheet = false
    @State private var addProviderSeed: ModelProviderConfiguration?
    @State private var selectedSection: SettingsSection = .general
    @State private var updateDialog: UpdateDialogState?
    @State private var detectedWebUIVersionLabel = ""
    @State private var detectedCompatibilityVersionLabel = ""
    @State private var detectedAppTargetVersionLabel = ""
    @State private var detectedWebUITargetVersionLabel = ""
    @State private var detectedCompatibilityTargetVersionLabel = ""

    private var language: AppLanguage {
        AppLanguage.normalized(appLanguage)
    }

    private var isEnglish: Bool {
        language == .en
    }

    private func text(_ zh: String, _ en: String) -> String {
        isEnglish ? en : zh
    }

    var body: some View {
        ZStack {
            SetupBackground()

            HStack(spacing: 0) {
                settingsSidebar
                    .frame(width: 228)

                Rectangle()
                    .fill(DesignTokens.borderSubtle.opacity(0.72))
                    .frame(width: 1)

                settingsContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showAddProviderSheet) {
            AddModelProviderSheet(manager: manager, initialConfiguration: addProviderSeed) {
                addProviderSeed = nil
                showAddProviderSheet = false
            }
            .frame(minWidth: 760, idealWidth: 860, minHeight: 680, idealHeight: 760)
        }
        .sheet(item: $updateDialog) { dialog in
            UpdateDialogView(
                state: dialog,
                isEnglish: isEnglish,
                onCancel: { updateDialog = nil },
                onInstall: { startUpdate(dialog.target) },
                onDone: { updateDialog = nil }
            )
            .frame(width: 620, height: 650)
        }
        .onAppear {
            manager.checkStatus()
            manager.readToken()
            manager.refreshModelStatus()
        }
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onBack) {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(text("返回应用", "Back"))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(DesignTokens.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                .padding(.horizontal, 10)
                .background(DesignTokens.surface2.opacity(0.28))
                .cornerRadius(12)
                .contentShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            VStack(alignment: .leading, spacing: 5) {
                Text(text("设置", "Settings"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(text("只管理公开配置，不展示私有 Token 或记忆正文。", "Public-safe configuration only."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(2)
            }
            .padding(.bottom, 2)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(SettingsSection.visibleCases) { section in
                SettingsSidebarRow(
                    section: section,
                    language: language,
                    isSelected: selectedSection == section
                ) {
                    selectedSection = section
                    }
                }
            }

            Spacer()

            settingsSidebarFooter
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SetupPalette.ink.opacity(0.56))
    }

    private var settingsSidebarFooter: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(SetupPalette.emerald)
                .frame(width: 7, height: 7)

            Text(manager.appVersion)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(SetupPalette.emerald)

            Spacer()

            Button {
                if let url = URL(string: "https://github.com/Averionx/HermesManager") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                GitHubMarkIcon(color: SetupPalette.emerald)
                    .frame(width: 25, height: 25)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(text("打开 GitHub 仓库", "Open GitHub repository"))
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }

    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if selectedSection != .models {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 10) {
                            Image(systemName: selectedSection.icon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(selectedSection.accent)
                                .frame(width: 34, height: 34)
                                .background(selectedSection.accent.opacity(0.12))
                                .cornerRadius(12)

                            Text(selectedSection.title(language: language))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(DesignTokens.textPrimary)
                        }

                        Text(selectedSection.subtitle(language: language))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignTokens.textTertiary)
                            .lineSpacing(3)
                    }
                    .padding(.top, 20)
                }

                switch selectedSection {
                case .general:
                    generalSettings
                case .appearance:
                    appearanceSettings
                case .terminal:
                    terminalSettings
                case .configuration:
                    configurationSettings
                case .models:
                    modelSettings
                case .memory:
                    memorySettings
                case .diagnostics:
                    diagnosticsSettings
                case .updates:
                    updatesSettings
                }
            }
            .frame(maxWidth: selectedSection == .models ? 1320 : 1040, alignment: .topLeading)
            .padding(.horizontal, 34)
            .padding(.top, selectedSection == .models ? 28 : 0)
            .padding(.bottom, 60)
        }
        .background(
            LinearGradient(
                colors: [
                    SetupPalette.panel.opacity(0.50),
                    SetupPalette.ink.opacity(0.12),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(
                title: text("启动行为", "Startup"),
                subtitle: text("控制 App 打开、启动服务和退出时做什么", "Control what happens when the app opens or quits.")
            )
            SettingsLightGroup {
                SettingsLightPickerRow(
                    title: text("语言", "Language"),
                    detail: text("切换 Hermes Manager 界面显示语言", "Switch the display language for Hermes Manager."),
                    selection: $appLanguage,
                    options: AppLanguage.allCases.map { ($0.rawValue, $0.displayName) }
                )
                SettingsLightToggleRow(
                    title: text("打开 App 后启动 Web UI", "Start Web UI on launch"),
                    detail: text("配置完成的用户进入控制台后自动启动服务", "After setup is complete, start services when entering the console."),
                    isOn: $launchWebUIOnOpen
                )
                SettingsLightToggleRow(
                    title: text("启动后打开浏览器", "Open browser after startup"),
                    detail: text("Web UI 就绪后自动跳转到浏览器", "Open the browser automatically when Web UI is ready."),
                    isOn: $openBrowserOnLaunch
                )
                SettingsLightToggleRow(
                    title: text("关闭 App 时停止服务", "Stop services on quit"),
                    detail: text("只停止由 Hermes Manager 启动的子进程", "Only stop child processes launched by Hermes Manager."),
                    isOn: $stopManagedServicesOnQuit
                )
            }

        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(
                title: text("外观", "Appearance"),
                subtitle: text("外观设置会在后续阶段开发。", "Appearance settings will be developed later.")
            )
            SettingsLightNotice(
                title: text("暂未开放", "Coming later"),
                detail: text("当前版本先隐藏外观入口，保留接口方便后续接入主题和布局设置。", "This section is hidden for now; the interface is kept for future theme and layout controls."),
                isPositive: true
            )
        }
    }

    private var terminalSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(
                title: text("终端", "Terminal"),
                subtitle: text("只调整内置 Hermes CLI 的显示和入口。", "Only controls the embedded Hermes CLI experience.")
            )
            SettingsLightGroup {
                SettingsLightToggleRow(
                    title: text("同步 Terminal 颜色和字体", "Match Terminal colors and font"),
                    detail: text("读取 macOS Terminal 默认 Profile，不同步背景图", "Reads the default macOS Terminal profile, excluding background image."),
                    isOn: $matchTerminalProfile
                )
                SettingsLightValueRow(title: text("终端模式", "Terminal mode"), detail: text("内置终端类型", "Embedded terminal type"), value: text("Hermes 真 PTY", "Hermes real PTY"))
                SettingsLightValueRow(title: text("Web UI 地址", "Web UI URL"), detail: text("当前检测到的访问地址", "Currently detected access URL"), value: manager.webUIURL)
            }

            SettingsLightSectionTitle(title: text("终端入口", "Terminal Entry"), subtitle: text("打开应用内部 Hermes CLI", "Open Hermes CLI inside the app."))
            SettingsLightActionRow(title: text("进入内置 CLI", "Open Embedded CLI"), detail: text("在 Hermes Manager 内部打开真实 PTY 终端", "Open a real PTY terminal inside Hermes Manager."), buttonTitle: text("打开", "Open")) {
                onOpenCLI()
            }
        }
    }

    private var configurationSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(title: text("隐私与公开版", "Privacy"), subtitle: text("默认不暴露用户私有信息", "Do not expose private user data by default."))
            SettingsLightGroup {
                SettingsLightToggleRow(title: text("默认隐藏 Token", "Hide token by default"), detail: text("Token 只在用户主动点击时显示/复制", "Token is shown or copied only after user action."), isOn: $hideTokenByDefault)
                SettingsLightToggleRow(title: text("日志只显示公开信息", "Public-safe logs"), detail: text("安装日志不打印 API Key、Token 和记忆正文", "Install logs do not print API keys, tokens, or memory content."), isOn: $publicLogsOnly)
                SettingsLightValueRow(title: text("Token 路径", "Token path"), detail: text("Web UI token 自动检测结果", "Detected Web UI token location"), value: manager.webUITokenPath.isEmpty ? text("未检测", "Not detected") : text("已检测", "Detected"))
            }

            SettingsLightSectionTitle(title: text("配置文件", "Config Files"), subtitle: text("当前 Hermes active profile", "Current Hermes active profile."))
            SettingsLightGroup {
                SettingsLightValueRow(title: "Hermes", detail: "config.yaml / .env", value: compactPath(manager.activeHermesProfileHome))
                SettingsLightValueRow(title: "Web UI", detail: text("自动检测 .hermes-web-ui 数据目录", "Auto-detected .hermes-web-ui data directory"), value: manager.webUIDataDirectory.isEmpty ? text("自动检测", "Auto detect") : manager.webUIDataDirectory)
            }
        }
    }

    private var modelSettings: some View {
        ModelSystemView(manager: manager) {
            addProviderSeed = nil
            showAddProviderSheet = true
        } onOpenEditProvider: { providerKey in
            addProviderSeed = manager.modelProviderConfiguration(providerKey: providerKey)
            showAddProviderSheet = true
        }
    }

    private var memorySettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(title: text("记忆链路", "Memory Bridge"), subtitle: "Hermes -> OpenHuman")
            SettingsLightGroup {
                SettingsLightCheckRow(title: text("OpenHuman 接管", "OpenHuman takeover"), detail: L10n.dynamic(manager.memoryBridgeSummary), isOn: manager.openHumanMemoryLinked)
                SettingsLightCheckRow(title: text("长期记忆迁移", "Long-term migration"), detail: manager.migratedMemoryAvailable ? text("Hermes 长期记忆已迁移或无需迁移", "Hermes long-term memory migrated or not needed") : text("需要迁移或重新校验", "Migration or verification required"), isOn: manager.migratedMemoryAvailable)
                SettingsLightCheckRow(title: text("Hermes 自带记忆", "Hermes native memory"), detail: manager.openHumanMemoryLinked ? text("长期记忆写入目标为 OpenHuman", "Long-term memory writes target OpenHuman") : text("需要修复 provider 配置", "Provider configuration needs repair"), isOn: manager.openHumanMemoryLinked)
            }

            SettingsLightGroup {
                SettingsLightValueRow(title: text("OpenHuman 文档", "OpenHuman docs"), detail: text("OpenHuman SQLite 长期记忆文档数", "Long-term memory docs in OpenHuman SQLite"), value: "\(manager.openHumanDocumentCount)")
                SettingsLightValueRow(title: text("Hermes 迁移项", "Hermes migrated"), detail: text("已从 Hermes 长期记忆迁移的数量", "Migrated from Hermes long-term memory"), value: "\(manager.migratedMemoryDocumentCount)")
                SettingsLightValueRow(title: text("本地长期项", "Local long-term items"), detail: text("仍检测到的 Hermes 长期记忆源", "Detected Hermes long-term memory sources"), value: "\(manager.legacyHermesMemoryCount)")
            }
        }
    }

    private var diagnosticsSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(title: text("检测与修复入口", "Diagnostics"), subtitle: text("进入安装向导重新判断机器状态", "Open setup wizard to re-detect the machine state."))
            SettingsLightActionRow(title: text("安装向导", "Setup wizard"), detail: text("重新检测 Hermes、OpenHuman、Web UI 和记忆连接", "Re-detect Hermes, OpenHuman, Web UI, and memory bridge."), buttonTitle: text("进入", "Open")) {
                onOpenSetup()
            }

            SettingsLightActionRow(title: text("刷新状态", "Refresh status"), detail: text("重新读取服务和记忆链路状态", "Read service and memory bridge status again."), buttonTitle: text("刷新", "Refresh")) {
                refreshEverything()
            }

            SettingsLightNotice(title: text("当前状态", "Current status"), detail: L10n.dynamic(manager.statusMessage), isPositive: manager.openHumanMemoryLinked)
        }
    }

    private var updatesSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            SettingsLightSectionTitle(
                title: text("更新中心", "Update Center"),
                subtitle: text("更新只使用开发者验证过的版本；Web UI 与核心组件分开管理。", "Updates use developer-tested versions; Web UI and core components are managed separately.")
            )
            SettingsLightGroup {
                SettingsLightToggleRow(
                    title: text("App 更新检测预览版", "Check preview app builds"),
                    detail: includePreviewAppUpdates
                        ? text("Hermes Manager 会优先检测 preview 通道；没有预览版时回退稳定版。", "Hermes Manager checks the preview channel first; falls back to stable if unavailable.")
                        : text("默认只检测稳定版，避免普通用户误装未验证预览包。", "Only stable builds are checked by default to avoid accidental preview installs."),
                    isOn: $includePreviewAppUpdates
                )
                SettingsUpdateRow(
                    title: "Hermes Manager",
                    detail: includePreviewAppUpdates
                        ? text("应用本体更新：已允许检测预览版。", "App updates: preview channel enabled.")
                        : text("应用本体更新：只检测稳定版。", "App updates: stable channel only."),
                    currentVersion: manager.appVersion,
                    targetVersion: detectedAppTargetVersionLabel.ifEmpty(text("自动检测", "Auto detect")),
                    buttonTitle: manager.remoteManifestLoading ? text("检测中", "Checking") : text("检测", "Check"),
                    accent: SetupPalette.emerald
                ) {
                    checkUpdate(.app)
                }
                SettingsUpdateRow(
                    title: "Hermes Web UI",
                    detail: text("使用官方 hermes-web-ui update，不删除重装。", "Uses the official hermes-web-ui update command; no delete/reinstall."),
                    currentVersion: detectedWebUIVersionLabel.ifEmpty(text("自动检测", "Auto detect")),
                    targetVersion: detectedWebUITargetVersionLabel.ifEmpty(text("自动检测", "Auto detect")),
                    buttonTitle: manager.remoteManifestLoading ? text("检测中", "Checking") : text("检测", "Check"),
                    accent: SetupPalette.cyan
                ) {
                    checkUpdate(.webUI)
                }
                SettingsUpdateRow(
                    title: text("核心组件", "Core Components"),
                    detail: manager.compatibilityBundleLabel,
                    currentVersion: detectedCompatibilityVersionLabel.ifEmpty(text("自动检测", "Auto detect")),
                    targetVersion: detectedCompatibilityTargetVersionLabel.ifEmpty(text("自动检测", "Auto detect")),
                    buttonTitle: manager.remoteManifestLoading ? text("检测中", "Checking") : text("检测", "Check"),
                    accent: SetupPalette.amber
                ) {
                    checkUpdate(.compatibilityBundle)
                }
            }

            SettingsLightNotice(
                title: text("安全说明", "Safety"),
                detail: AppRuntimeMode.uiPrototype
                    ? text("当前为安全预览，检测和更新不会安装或修改你的 Hermes/OpenHuman。", "Safe preview is active, so checks and updates will not install or modify Hermes/OpenHuman.")
                    : text("Web UI 更新会执行 hermes-web-ui update；核心组件只包含 Hermes 和 OpenHuman。", "Web UI runs hermes-web-ui update; core components only include Hermes and OpenHuman."),
                isPositive: true
            )
        }
    }

    private func refreshEverything() {
        manager.checkStatus(force: true)
        manager.readLogs()
        manager.readGatewayLogs()
        manager.readToken()
        manager.refreshModelStatus()
        manager.showToast(title: text("已刷新设置", "Settings refreshed"), message: text("服务和记忆链路状态已重新检测", "Service and memory bridge status have been re-detected"), icon: "arrow.clockwise", accent: SetupPalette.emerald)
    }

    private func checkUpdate(_ target: UpdateTarget) {
        manager.loadRemoteVersionManifest {
            presentUpdateDialog(for: target)
        }
    }

    private func presentUpdateDialog(for target: UpdateTarget) {
        let currentVersion: String
        let targetVersion: String
        let hasUpdate: Bool
        let message: String

        switch target {
        case .app:
            currentVersion = manager.appVersion
            guard let release = manager.remoteManifest.appRelease(includePreview: includePreviewAppUpdates) else {
                targetVersion = text("未配置", "Not configured")
                detectedAppTargetVersionLabel = targetVersion
                updateDialog = UpdateDialogState(
                    target: target,
                    phase: .upToDate,
                    currentVersion: currentVersion,
                    targetVersion: targetVersion,
                    message: text("当前清单没有启用可检测的 App 更新通道。", "The manifest has no enabled app update channel.")
                )
                return
            }
            targetVersion = VersionFormatting.displayVersion(release.version)
            detectedAppTargetVersionLabel = targetVersion
            let compare = compareVersions(targetVersion, currentVersion)
            hasUpdate = compare == .orderedDescending
            if hasUpdate {
                message = release.hasDownload
                    ? text("检测到 \(includePreviewAppUpdates ? "预览版" : "稳定版") 更新，点击更新会在 App 内下载 DMG。", "A \(includePreviewAppUpdates ? "preview" : "stable") update is available. Update downloads the DMG in-app.")
                    : text("检测到更高版本，但清单还没有配置下载地址。", "A newer version is listed, but the manifest has no download URL yet.")
            } else if compare == .orderedAscending {
                message = text("远程目标版本低于当前版本，已忽略，不会降级。", "The remote target is older than the current version and will be ignored.")
            } else {
                message = text("当前是最新版本。", "You are up to date.")
            }
        case .webUI:
            currentVersion = manager.detectedWebUIVersion()
            detectedWebUIVersionLabel = currentVersion
            targetVersion = manager.webUITestedTargetVersion
            detectedWebUITargetVersionLabel = targetVersion
            let compare = compareVersions(targetVersion, currentVersion)
            hasUpdate = compare == .orderedDescending && currentVersion != "未检测"
            if hasUpdate {
                message = text("检测到开发者验证版本，可以点击更新。", "A developer-tested version is available.")
            } else if compare == .orderedAscending {
                message = text("远程 Web UI 目标版本低于当前版本，已忽略，不会降级。", "The remote Web UI target is older than the current version and will be ignored.")
            } else {
                message = text("已读取本机 Hermes Web UI 版本；当前已经是目标版本。", "Detected local Hermes Web UI version; already on the target version.")
            }
        case .compatibilityBundle:
            let hermes = manager.detectedHermesVersion()
            let openHuman = manager.detectedOpenHumanVersion()
            currentVersion = "Hermes \(hermes) / OpenHuman \(openHuman)"
            detectedCompatibilityVersionLabel = currentVersion
            targetVersion = manager.compatibilityBundleTargetVersion
            detectedCompatibilityTargetVersionLabel = targetVersion
            let needsHermes = compareVersions(manager.hermesTestedTargetVersion, hermes) == .orderedDescending
            let needsOpenHuman = compareVersions(manager.openHumanTestedTargetVersion, openHuman) == .orderedDescending
            hasUpdate = AppRuntimeMode.uiPrototype || needsHermes || needsOpenHuman
            if hasUpdate {
                message = AppRuntimeMode.uiPrototype
                    ? text("安全预览：已发现一个开发者验证核心组件更新，可点击更新查看安装流程。", "Safe preview: a developer-tested core component update is available so you can preview the install flow.")
                    : text("检测到开发者验证的核心组件版本，可点击更新。", "Developer-tested core component versions are available.")
            } else {
                message = text("Hermes 和 OpenHuman 当前已经是目标版本。", "Hermes and OpenHuman are already on the target versions.")
            }
        }

        updateDialog = UpdateDialogState(
            target: target,
            phase: hasUpdate ? .available : .upToDate,
            currentVersion: currentVersion,
            targetVersion: targetVersion,
            message: message
        )
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        VersionFormatting.compare(lhs, rhs)
    }

    private func startUpdate(_ target: UpdateTarget) {
        guard var dialog = updateDialog else { return }
        dialog.phase = .installing
        dialog.message = target.installingMessage(isEnglish: isEnglish, prototype: AppRuntimeMode.uiPrototype)
        updateDialog = dialog

        if AppRuntimeMode.uiPrototype {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                updateDialog = dialog.completed(isEnglish: isEnglish, prototype: true)
            }
            return
        }

        switch target {
        case .app:
            guard let release = manager.remoteManifest.appRelease(includePreview: includePreviewAppUpdates) else {
                var completed = dialog.completed(isEnglish: isEnglish, prototype: false)
                completed.message = text("当前清单没有启用可下载的 App 更新通道。", "The manifest has no enabled downloadable app update channel.")
                updateDialog = completed
                return
            }
            manager.downloadAppUpdate(release: release) { result in
                var completed = dialog.completed(isEnglish: isEnglish, prototype: false)
                if case .failure(let error) = result {
                    completed.message = error.localizedDescription
                }
                updateDialog = completed
            }
        case .webUI:
            manager.updateWebUI()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                updateDialog = dialog.completed(isEnglish: isEnglish, prototype: false)
            }
        case .compatibilityBundle:
            manager.updateCompatibilityBundle { result in
                var completed = dialog.completed(isEnglish: isEnglish, prototype: false)
                if case .failure(let error) = result {
                    completed.message = error.localizedDescription
                }
                updateDialog = completed
            }
        }
    }
}

enum UpdateTarget: String, Identifiable {
    case app
    case webUI
    case compatibilityBundle

    var id: String { rawValue }

    func title(isEnglish: Bool) -> String {
        switch self {
        case .app:
            return "Hermes Manager"
        case .webUI:
            return "Hermes Web UI"
        case .compatibilityBundle:
            return isEnglish ? "Core Components" : "核心组件"
        }
    }

    func subtitle(isEnglish: Bool) -> String {
        switch self {
        case .app:
            return isEnglish ? "App release channel" : "应用本体更新通道"
        case .webUI:
            return isEnglish ? "Official hermes-web-ui update" : "官方 hermes-web-ui update"
        case .compatibilityBundle:
            return isEnglish ? "Developer-tested core versions" : "开发者验证的核心版本"
        }
    }

    func installingMessage(isEnglish: Bool, prototype: Bool) -> String {
        if prototype {
            return isEnglish ? "Previewing the update. No local install will run." : "正在预览更新，不会执行本机安装。"
        }
        switch self {
        case .app:
            return isEnglish ? "Preparing app update placeholder." : "正在准备应用更新占位流程。"
        case .webUI:
            return isEnglish ? "Running hermes-web-ui update." : "正在执行 hermes-web-ui update。"
        case .compatibilityBundle:
            return isEnglish ? "Preparing developer-tested core component update." : "正在准备开发者验证核心组件更新。"
        }
    }
}

enum UpdateDialogPhase {
    case upToDate
    case available
    case installing
    case completed
}

struct UpdateDialogState: Identifiable {
    let id = UUID()
    let target: UpdateTarget
    var phase: UpdateDialogPhase
    let currentVersion: String
    let targetVersion: String
    var message: String

    func completed(isEnglish: Bool, prototype: Bool) -> UpdateDialogState {
        var next = self
        next.phase = .completed
        next.message = prototype
            ? (isEnglish ? "Preview complete. No local files were changed." : "预览完成，没有修改本机文件。")
            : (isEnglish ? "Update flow finished. Check logs for exact command output." : "更新流程已完成，请查看日志确认命令输出。")
        return next
    }
}

struct UpdateDialogView: View {
    let state: UpdateDialogState
    let isEnglish: Bool
    let onCancel: () -> Void
    let onInstall: () -> Void
    let onDone: () -> Void

    private var isBusy: Bool { state.phase == .installing }
    private var isCompleteState: Bool { state.phase == .completed || state.phase == .upToDate }
    private var ringSize: CGFloat { isCompleteState ? 126 : 116 }

    var body: some View {
        ZStack {
            SetupBackground()

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .stroke(SetupPalette.emerald.opacity(0.18), lineWidth: 12)
                        .frame(width: ringSize, height: ringSize)

                    if isCompleteState {
                        Circle()
                            .stroke(
                                AngularGradient(colors: [SetupPalette.emerald, SetupPalette.cyan, SetupPalette.emerald], center: .center),
                                style: StrokeStyle(lineWidth: 12, lineCap: .butt)
                            )
                            .frame(width: ringSize, height: ringSize)
                    } else {
                        Circle()
                            .trim(from: 0, to: 0.76)
                            .stroke(
                                AngularGradient(colors: [SetupPalette.emerald, SetupPalette.cyan, SetupPalette.emerald], center: .center),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: ringSize, height: ringSize)
                            .rotationEffect(.degrees(isBusy ? 360 : 28))
                            .animation(isBusy ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .spring(response: 0.35, dampingFraction: 0.8), value: isBusy)
                    }

                    Image(systemName: state.phase == .completed || state.phase == .upToDate ? "checkmark" : "arrow.down")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(SetupPalette.emerald)
                }
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text(dialogTitle)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(state.target.subtitle(isEnglish: isEnglish))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textTertiary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 0) {
                    UpdateInfoLine(title: isEnglish ? "Current version" : "当前版本", value: state.currentVersion)
                    UpdateInfoLine(title: isEnglish ? "Target version" : "检测版本", value: state.targetVersion)
                    UpdateInfoLine(title: isEnglish ? "Version policy" : "版本策略", value: isEnglish ? "Developer-tested, not automatic latest" : "开发者验证，不自动追最新版")
                }
                .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DesignTokens.borderSubtle, lineWidth: 1))
                .cornerRadius(18)

                Text(state.message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 470, minHeight: 42)

                HStack(spacing: 12) {
                    if state.phase == .available {
                        SettingsDialogButton(title: isEnglish ? "Cancel" : "取消", style: .secondary, action: onCancel)
                        SettingsDialogButton(title: isEnglish ? "Update" : "更新", style: .primary, action: onInstall)
                    } else if state.phase == .installing {
                        SettingsDialogButton(title: isEnglish ? "Installing..." : "正在安装...", style: .disabled, action: {})
                    } else {
                        SettingsDialogButton(title: isEnglish ? "Got it" : "我知道了", style: .primary, action: onDone)
                    }
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, 42)
            .padding(.vertical, 42)
        }
    }

    private var dialogTitle: String {
        switch state.phase {
        case .upToDate:
            return isEnglish ? "Already Up To Date" : "当前是最新版本"
        case .available:
            return isEnglish ? "Update Available" : "发现可用更新"
        case .installing:
            return isEnglish ? "Installing" : "正在安装"
        case .completed:
            return isEnglish ? "Update Complete" : "安装完成"
        }
    }
}

struct UpdateInfoLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
                .frame(width: 86, alignment: .leading)
            Spacer(minLength: 14)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(minHeight: 54)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DesignTokens.borderSubtle.opacity(0.7)).frame(height: 1).padding(.leading, 18)
        }
    }
}

enum SettingsDialogButtonStyle {
    case primary
    case secondary
    case disabled
}

struct SettingsDialogButton: View {
    let title: String
    let style: SettingsDialogButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(style == .primary ? .black.opacity(0.82) : DesignTokens.textSecondary)
                .frame(width: 126, height: 38)
                .background(background)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusPill)
                        .stroke(style == .secondary ? DesignTokens.borderDefault : Color.clear, lineWidth: 1)
                )
                .cornerRadius(DesignTokens.radiusPill)
        }
        .buttonStyle(.plain)
        .disabled(style == .disabled)
    }

    private var background: Color {
        switch style {
        case .primary:
            return SetupPalette.emerald
        case .secondary:
            return DesignTokens.surface2.opacity(0.82)
        case .disabled:
            return DesignTokens.surface2.opacity(0.38)
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case appearance
    case terminal
    case configuration
    case models
    case memory
    case diagnostics
    case updates

    var id: String { rawValue }

    static var visibleCases: [SettingsSection] {
        [.general, .terminal, .configuration, .memory, .diagnostics, .updates]
    }

    func title(language: AppLanguage = L10n.current) -> String {
        switch self {
        case .general:
            return language == .en ? "General" : "常规"
        case .appearance:
            return language == .en ? "Appearance" : "外观"
        case .terminal:
            return language == .en ? "Terminal" : "终端"
        case .configuration:
            return language == .en ? "Configuration" : "配置"
        case .models:
            return language == .en ? "Models" : "模型"
        case .memory:
            return language == .en ? "Memory" : "记忆"
        case .diagnostics:
            return language == .en ? "Diagnostics" : "检测"
        case .updates:
            return language == .en ? "Updates" : "更新"
        }
    }

    var title: String { title() }

    func subtitle(language: AppLanguage = L10n.current) -> String {
        switch self {
        case .general:
            return language == .en ? "Startup, browser, language, and service behavior." : "控制 App 启动服务、打开浏览器和退出时的行为。"
        case .appearance:
            return language == .en ? "Theme and visual controls, planned for a later phase." : "外观主题设置后续开发，当前暂时隐藏。"
        case .terminal:
            return language == .en ? "Adjust the embedded Hermes CLI terminal only." : "只调整内置 Hermes CLI 的终端显示和入口。"
        case .configuration:
            return language == .en ? "Review Hermes, Web UI, and public-safe privacy settings." : "查看 Hermes、Web UI 与公开版隐私配置。"
        case .models:
            return language == .en ? "Model management is deferred to the Agent phase." : "模型管理暂时隐藏，后续 Agent 阶段开发。"
        case .memory:
            return language == .en ? "Validate the Hermes brain and OpenHuman long-term memory bridge." : "校验 Hermes 主控与 OpenHuman 长期记忆链路。"
        case .diagnostics:
            return language == .en ? "Re-detect, refresh, or open the setup/repair wizard." : "重新检测、刷新状态或进入安装修复向导。"
        case .updates:
            return language == .en ? "Check developer-tested app, Web UI, and core component updates." : "检测开发者验证过的 App、Web UI 和核心组件版本。"
        }
    }

    var subtitle: String { subtitle() }

    var icon: String {
        switch self {
        case .general:
            return "switch.2"
        case .appearance:
            return "paintbrush"
        case .terminal:
            return "terminal"
        case .configuration:
            return "slider.horizontal.3"
        case .models:
            return "cpu"
        case .memory:
            return "brain.head.profile"
        case .diagnostics:
            return "stethoscope"
        case .updates:
            return "arrow.down.circle"
        }
    }

    var accent: Color {
        switch self {
        case .general:
            return SetupPalette.emerald
        case .appearance:
            return SetupPalette.amber
        case .terminal:
            return SetupPalette.cyan
        case .configuration:
            return DesignTokens.textSecondary
        case .models:
            return SetupPalette.amber
        case .memory:
            return SetupPalette.emerald
        case .diagnostics:
            return SetupPalette.cyan
        case .updates:
            return SetupPalette.emerald
        }
    }
}

struct GitHubMarkIcon: View {
    let color: Color

    var body: some View {
        GitHubMarkShape()
            .fill(color)
            .accessibilityLabel(Text("GitHub"))
    }
}

struct GitHubMarkShape: Shape {
    private let pathData = "M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.807 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"

    func path(in rect: CGRect) -> Path {
        SVGPathParser(data: pathData, viewBox: CGSize(width: 24, height: 24)).path(in: rect)
    }
}

private struct SVGPathParser {
    private enum Token {
        case command(Character)
        case number(CGFloat)
    }

    let data: String
    let viewBox: CGSize

    func path(in rect: CGRect) -> Path {
        let tokens = tokenize(data)
        let rawPath = buildPath(tokens: tokens)
        let scale = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let xOffset = rect.midX - viewBox.width * scale / 2
        let yOffset = rect.midY - viewBox.height * scale / 2
        let transform = CGAffineTransform(translationX: xOffset, y: yOffset).scaledBy(x: scale, y: scale)
        return rawPath.applying(transform)
    }

    private func tokenize(_ string: String) -> [Token] {
        var tokens: [Token] = []
        var index = string.startIndex
        let numberPattern = #"^[+-]?(?:(?:\d*\.\d+)|(?:\d+\.?))(?:[eE][+-]?\d+)?"#
        let numberRegex = try? NSRegularExpression(pattern: numberPattern)

        while index < string.endIndex {
            let character = string[index]
            if character.isWhitespace || character == "," {
                index = string.index(after: index)
                continue
            }
            if character.isLetter {
                tokens.append(.command(character))
                index = string.index(after: index)
                continue
            }

            let remaining = String(string[index...])
            let range = NSRange(remaining.startIndex..., in: remaining)
            if let match = numberRegex?.firstMatch(in: remaining, range: range),
               match.range.location == 0,
               let matchRange = Range(match.range, in: remaining) {
                let raw = String(remaining[matchRange])
                if let value = Double(raw) {
                    tokens.append(.number(CGFloat(value)))
                }
                index = string.index(index, offsetBy: raw.count)
            } else {
                index = string.index(after: index)
            }
        }

        return tokens
    }

    private func buildPath(tokens: [Token]) -> Path {
        var path = Path()
        var index = 0
        var command: Character?
        var currentPoint = CGPoint.zero
        var subpathStart = CGPoint.zero

        func nextNumber() -> CGFloat? {
            guard index < tokens.count else { return nil }
            if case .number(let value) = tokens[index] {
                index += 1
                return value
            }
            return nil
        }

        func hasNumberAhead() -> Bool {
            guard index < tokens.count else { return false }
            if case .number = tokens[index] { return true }
            return false
        }

        while index < tokens.count {
            if case .command(let value) = tokens[index] {
                command = value
                index += 1
            }
            guard let command else { break }

            switch command {
            case "M", "m":
                guard let x = nextNumber(), let y = nextNumber() else { break }
                currentPoint = point(x: x, y: y, relativeTo: command == "m" ? currentPoint : nil)
                path.move(to: currentPoint)
                subpathStart = currentPoint
                while hasNumberAhead(), let lineX = nextNumber(), let lineY = nextNumber() {
                    currentPoint = point(x: lineX, y: lineY, relativeTo: command == "m" ? currentPoint : nil)
                    path.addLine(to: currentPoint)
                }
            case "L", "l":
                while let x = nextNumber(), let y = nextNumber() {
                    currentPoint = point(x: x, y: y, relativeTo: command == "l" ? currentPoint : nil)
                    path.addLine(to: currentPoint)
                }
            case "H", "h":
                while let x = nextNumber() {
                    currentPoint = CGPoint(x: command == "h" ? currentPoint.x + x : x, y: currentPoint.y)
                    path.addLine(to: currentPoint)
                }
            case "V", "v":
                while let y = nextNumber() {
                    currentPoint = CGPoint(x: currentPoint.x, y: command == "v" ? currentPoint.y + y : y)
                    path.addLine(to: currentPoint)
                }
            case "C", "c":
                while let x1 = nextNumber(), let y1 = nextNumber(), let x2 = nextNumber(), let y2 = nextNumber(), let x = nextNumber(), let y = nextNumber() {
                    let relativeBase = command == "c" ? currentPoint : nil
                    let control1 = point(x: x1, y: y1, relativeTo: relativeBase)
                    let control2 = point(x: x2, y: y2, relativeTo: relativeBase)
                    currentPoint = point(x: x, y: y, relativeTo: relativeBase)
                    path.addCurve(to: currentPoint, control1: control1, control2: control2)
                }
            case "Z", "z":
                path.closeSubpath()
                currentPoint = subpathStart
            default:
                break
            }
        }

        return path
    }

    private func point(x: CGFloat, y: CGFloat, relativeTo base: CGPoint?) -> CGPoint {
        guard let base else { return CGPoint(x: x, y: y) }
        return CGPoint(x: base.x + x, y: base.y + y)
    }
}

struct SettingsSidebarRow: View {
    let section: SettingsSection
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? section.accent : DesignTokens.textTertiary)
                .frame(width: 24, height: 24)

            Text(section.title(language: language))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textTertiary)

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? DesignTokens.surface2.opacity(0.82) : (hovering ? DesignTokens.surface2.opacity(0.34) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? section.accent.opacity(0.22) : Color.clear, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture(perform: action)
        .onHover { hovering = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(section.title(language: language))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text(language == .en ? "Open" : "打开")) { action() }
    }
}

struct SettingsLightSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
                .lineSpacing(3)
        }
    }
}

struct SettingsLightRowShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            content
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(DesignTokens.surface2.opacity(0.18))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.borderSubtle.opacity(0.80))
                .frame(height: 1)
                .padding(.leading, 16)
        }
    }
}

struct SettingsLightGroup<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.075))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct SettingsLightToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsLightRowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .frame(width: 72, alignment: .trailing)
        }
    }
}

struct SettingsLightPickerRow: View {
    let title: String
    let detail: String
    @Binding var selection: String
    let options: [(value: String, label: String)]

    var body: some View {
        SettingsLightRowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("", selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 180, alignment: .trailing)
        }
    }
}

struct SettingsLightValueRow: View {
    let title: String
    let detail: String
    let value: String

    var body: some View {
        SettingsLightRowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(value.isEmpty ? L10n.t("未检测", "Not detected") : value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.trailing)
                .frame(width: 240, alignment: .trailing)
        }
    }
}

struct SettingsLightActionRow: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        SettingsLightRowShell {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black.opacity(0.78))
                    .padding(.horizontal, 15)
                    .frame(width: 96, height: 32)
                    .background(hovering ? SetupPalette.emerald.opacity(0.92) : SetupPalette.emerald)
                    .cornerRadius(DesignTokens.radiusPill)
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
        }
    }
}

struct SettingsUpdateRow: View {
    let title: String
    let detail: String
    let currentVersion: String
    let targetVersion: String
    let buttonTitle: String
    let accent: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        SettingsLightRowShell {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(accent)
                    .frame(width: 34, height: 34)
                    .background(accent.opacity(0.12))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                    Text("\(L10n.t("当前", "Current")) \(currentVersion)  ->  \(L10n.t("目标", "Target")) \(targetVersion)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(DesignTokens.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black.opacity(0.78))
                    .frame(width: 96, height: 32)
                    .background(hovering ? accent.opacity(0.92) : accent)
                    .cornerRadius(DesignTokens.radiusPill)
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
        }
    }
}

struct SettingsLightCheckRow: View {
    let title: String
    let detail: String
    let isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: isOn ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isOn ? SetupPalette.emerald : SetupPalette.amber)
                .frame(width: 34, height: 34)
                .background((isOn ? SetupPalette.emerald : SetupPalette.amber).opacity(0.10))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(DesignTokens.surface2.opacity(0.34))
        .cornerRadius(14)
    }
}

struct SettingsLightNotice: View {
    let title: String
    let detail: String
    let isPositive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isPositive ? SetupPalette.emerald : SetupPalette.amber)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background((isPositive ? SetupPalette.emerald : SetupPalette.amber).opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((isPositive ? SetupPalette.emerald : SetupPalette.amber).opacity(0.16), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct SettingsChoiceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? SetupPalette.emerald : SetupPalette.cyan)
                    .frame(width: 38, height: 38)
                    .background((isSelected ? SetupPalette.emerald : SetupPalette.cyan).opacity(0.12))
                    .cornerRadius(13)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
            .background(DiffusePanelBackground(cornerRadius: 18, tint: isSelected ? SetupPalette.emerald : SetupPalette.cyan, opacity: hovering ? 0.11 : 0.075))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke((isSelected ? SetupPalette.emerald : DesignTokens.borderSubtle).opacity(isSelected ? 0.24 : 1), lineWidth: 1)
            )
            .cornerRadius(18)
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct SettingsModelHealthLightList: View {
    let results: [ModelHealthResult]
    let summary: String
    let isChecking: Bool

    var body: some View {
        SettingsModelHealthList(results: results, summary: summary, isChecking: isChecking)
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            ConsoleSectionTitle(title: title, subtitle: subtitle)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let detail: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill((isOn ? SetupPalette.emerald : DesignTokens.textMuted).opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(detail)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(11)
        .background(DesignTokens.surface2.opacity(0.34))
        .cornerRadius(14)
    }
}

struct SettingsInfoStrip: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 26, height: 26)
                .background(accent.opacity(0.10))
                .cornerRadius(9)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignTokens.textTertiary)

            Spacer(minLength: 10)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .background(DesignTokens.surface2.opacity(0.34))
        .cornerRadius(13)
    }
}

struct SettingsMiniButton: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(DesignTokens.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(hovering ? accent.opacity(0.20) : accent.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
            .cornerRadius(12)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(DesignTokens.surface2.opacity(0.68))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(DesignTokens.surface2.opacity(0.38))
        .cornerRadius(15)
    }
}

struct SettingsStatusNote: View {
    let icon: String
    let text: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignTokens.textTertiary)
                .lineLimit(3)
            Spacer()
        }
        .padding(12)
        .background(accent.opacity(0.08))
        .cornerRadius(13)
    }
}

struct SettingsModelHealthList: View {
    let results: [ModelHealthResult]
    let summary: String
    let isChecking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Image(systemName: isChecking ? "arrow.triangle.2.circlepath" : "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isChecking ? SetupPalette.cyan : SetupPalette.emerald)
                Text(summary)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                Spacer()
            }

            if results.isEmpty {
                Text(isChecking ? "正在读取 Hermes/Web UI 模型配置并请求 /models..." : "点击“检测模型”后会显示 Provider、模型、延迟和可用性。")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.textMuted)
                    .lineLimit(2)
            } else {
                ForEach(results.prefix(4)) { result in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(result.ok ? SetupPalette.emerald : SetupPalette.amber)
                            .frame(width: 7, height: 7)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.model)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(DesignTokens.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(result.provider)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DesignTokens.textMuted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        Text(result.latencyMS.map { "\($0)ms" } ?? "--")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(result.ok ? SetupPalette.emerald : SetupPalette.amber)
                        Text(result.detail)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(DesignTokens.textMuted)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .background(DesignTokens.surface2.opacity(0.30))
                    .cornerRadius(12)
                }
            }
        }
        .padding(12)
        .background(DesignTokens.surface2.opacity(0.26))
        .cornerRadius(14)
    }
}

struct AddModelProviderSheet: View {
    @ObservedObject var manager: ServiceManager
    let initialConfiguration: ModelProviderConfiguration?
    let onClose: () -> Void

    enum ProviderMode: String, CaseIterable, Identifiable {
        case preset = "预设"
        case custom = "自定义"
        var id: String { rawValue }
    }

    @State private var providerMode: ProviderMode = .preset
    @State private var selectedPreset = HermesModelProviderPreset.all.first!
    @State private var customName = ""
    @State private var customProviderKey = ""
    @State private var baseURL = HermesModelProviderPreset.all.first?.baseURL ?? ""
    @State private var apiKey = ""
    @State private var manualModel = ""
    @State private var selectedModels: Set<String> = []
    @State private var fetchedModels: [String] = []
    @State private var fetchMessage = ""
    @State private var isFetching = false
    @State private var contextLength = "128000"

    init(
        manager: ServiceManager,
        initialConfiguration: ModelProviderConfiguration? = nil,
        onClose: @escaping () -> Void
    ) {
        self.manager = manager
        self.initialConfiguration = initialConfiguration
        self.onClose = onClose

        let preset = initialConfiguration.flatMap { configuration in
            HermesModelProviderPreset.preset(for: configuration.providerKey)
        } ?? HermesModelProviderPreset.all.first!
        let isCustom = initialConfiguration?.providerKey.hasPrefix("custom:") == true

        _providerMode = State(initialValue: isCustom ? .custom : .preset)
        _selectedPreset = State(initialValue: preset)
        _customName = State(initialValue: isCustom ? (initialConfiguration?.providerLabel ?? "") : "")
        _customProviderKey = State(initialValue: isCustom ? (initialConfiguration?.providerKey ?? "") : "")
        _baseURL = State(initialValue: initialConfiguration?.baseURL ?? preset.baseURL)
        _apiKey = State(initialValue: initialConfiguration?.apiKey ?? "")
        _manualModel = State(initialValue: initialConfiguration?.defaultModel ?? "")
        _selectedModels = State(initialValue: Set(initialConfiguration?.models ?? []))
        _contextLength = State(initialValue: "\(initialConfiguration?.contextLength ?? 128000)")
    }

    private var availableModels: [String] {
        var seen = Set<String>()
        var values: [String] = []
        for model in fetchedModels {
            let clean = model.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, seen.insert(clean).inserted else { continue }
            values.append(clean)
        }
        return values
    }

    private var providerKey: String {
        switch providerMode {
        case .preset:
            return selectedPreset.value
        case .custom:
            let clean = customProviderKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.hasPrefix("custom:") {
                return "custom:\(slugify(String(clean.dropFirst("custom:".count))))"
            }
            if !clean.isEmpty { return "custom:\(slugify(clean))" }
            return "custom:\(slugify(customName))"
        }
    }

    private var providerLabel: String {
        switch providerMode {
        case .preset:
            return selectedPreset.label
        case .custom:
            return customName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var defaultModel: String {
        return manualModel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var modelsToSave: [String] {
        var values = Array(selectedModels).sorted()
        let manual = manualModel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty, !values.contains(manual) {
            values.append(manual)
        }
        return values
    }

    private var canAdd: Bool {
        !providerKey.isEmpty
            && !providerLabel.isEmpty
            && !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !defaultModel.isEmpty
    }

    var body: some View {
        ZStack {
            SetupBackground()
            VStack(spacing: 0) {
                header
                Divider().background(DesignTokens.borderSubtle)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        typePicker
                        providerSection
                        credentialSection
                        modelSection
                        footerNote
                    }
                    .padding(22)
                }
                footer
            }
            .background(DiffusePanelBackground(cornerRadius: 24, tint: SetupPalette.emerald, opacity: 0.10))
        }
        .onAppear {
            if initialConfiguration == nil {
                applyPreset(selectedPreset)
            }
        }
        .onChange(of: selectedPreset) { _, newValue in
            applyPreset(newValue)
        }
        .onChange(of: baseURL) { _, _ in
            clearFetchedModels(keepDefaultModel: true)
        }
        .onChange(of: apiKey) { _, _ in
            clearFetchedModels(keepDefaultModel: true)
        }
        .onChange(of: providerMode) { _, mode in
            if mode == .preset {
                applyPreset(selectedPreset)
            } else {
                customName = customName.isEmpty ? "" : customName
                customProviderKey = customProviderKey.isEmpty ? "" : customProviderKey
                clearFetchedModels(keepDefaultModel: false)
                manualModel = ""
                baseURL = ""
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(SetupPalette.emerald.opacity(0.14))
                    .frame(width: 46, height: 46)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(SetupPalette.emerald)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(initialConfiguration == nil ? "添加 Provider" : "编辑 Provider")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(initialConfiguration == nil ? "同步到 Hermes CLI 与 Hermes Web UI；API Key 只写入本机配置。" : "基于当前配置重新保存到 Hermes CLI 与 Hermes Web UI。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.textTertiary)
                    .frame(width: 38, height: 38)
                    .background(DesignTokens.surface2.opacity(0.48))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(22)
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Provider 类型")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
            Picker("", selection: $providerMode) {
                ForEach(ProviderMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
        }
    }

    private var providerSection: some View {
        SettingsCard(title: "Provider", subtitle: providerMode == .preset ? "来自 Hermes Web UI 预设" : "自定义 OpenAI 兼容 Provider") {
            VStack(spacing: 12) {
                if providerMode == .preset {
                    Picker("选择 Provider", selection: $selectedPreset) {
                        ForEach(HermesModelProviderPreset.all) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    SettingsInfoStrip(title: "Provider Key", value: selectedPreset.value, icon: "tag", accent: SetupPalette.cyan)
                } else {
                    SettingsTextField(title: "Provider 名称", placeholder: "例如 My Gateway", text: $customName)
                    SettingsTextField(title: "Provider Key", placeholder: "custom:my-gateway，可不填自动生成", text: $customProviderKey)
                }
                SettingsTextField(title: "Base URL", placeholder: "https://api.example.com/v1", text: $baseURL)
            }
        }
    }

    private var credentialSection: some View {
        SettingsCard(title: "鉴权", subtitle: "公开版不会内置任何私有 Key") {
            VStack(spacing: 12) {
                SettingsSecureField(title: "API Key", placeholder: "sk-...", text: $apiKey)
                SettingsInfoStrip(title: "写入位置", value: "Hermes .env / config.yaml + Web UI", icon: "lock.shield", accent: SetupPalette.amber)
            }
        }
    }

    private var modelSection: some View {
        SettingsCard(title: "模型", subtitle: "填写 API 和 API Key 后点击获取，返回的模型会显示在下方") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    SettingsTextField(title: "当前模型", placeholder: "获取后默认使用第一个，也可手动输入", text: $manualModel)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("上下文")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DesignTokens.textTertiary)
                        TextField("128000", text: $contextLength)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(DesignTokens.textPrimary)
                            .padding(12)
                            .frame(width: 110)
                            .background(DesignTokens.surface2)
                            .cornerRadius(12)
                    }
                    SettingsMiniButton(title: isFetching ? "获取中..." : "获取", icon: "arrow.down.circle", accent: SetupPalette.cyan) { fetchModels() }
                        .frame(width: 110)
                        .disabled(isFetching || baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !fetchMessage.isEmpty {
                    SettingsStatusNote(icon: fetchedModels.isEmpty ? "info.circle" : "checkmark.circle.fill", text: fetchMessage, accent: fetchedModels.isEmpty ? SetupPalette.amber : SetupPalette.emerald)
                } else if fetchedModels.isEmpty {
                    SettingsStatusNote(icon: "arrow.down.circle", text: "填写 Base URL 和 API Key 后点击“获取”，模型列表会出现在这里。", accent: SetupPalette.cyan)
                }

                if !availableModels.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 10)], alignment: .leading, spacing: 10) {
                        ForEach(availableModels.prefix(48), id: \.self) { model in
                            ModelSelectionChip(
                                title: model,
                                isSelected: selectedModels.contains(model)
                            ) {
                                toggleModel(model)
                            }
                        }
                    }
                }
            }
        }
    }

    private var footerNote: some View {
        SettingsStatusNote(
            icon: AppRuntimeMode.uiPrototype ? "paintbrush.fill" : "checkmark.shield.fill",
            text: AppRuntimeMode.uiPrototype ? "当前为安全预览：点击添加只会预览同步，不会写入你的 Hermes/Web UI 本机配置。" : "保存后会同步 Hermes CLI、Hermes Web UI config.json 和 Web UI 模型数据库；不会打印 API Key。",
            accent: AppRuntimeMode.uiPrototype ? SetupPalette.cyan : SetupPalette.emerald
        )
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text(defaultModel.isEmpty ? "请先获取模型或手动填写当前模型" : "将添加：\(providerKey) / \(defaultModel)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(defaultModel.isEmpty ? DesignTokens.textMuted : DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: onClose) {
                Text("取消")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                    .frame(width: 84, height: 40)
                    .background(DesignTokens.surface2.opacity(0.64))
                    .cornerRadius(13)
            }
            .buttonStyle(.plain)
            Button(action: addProvider) {
                Text(initialConfiguration == nil ? "添加" : "保存")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(canAdd ? .black.opacity(0.86) : DesignTokens.textMuted)
                    .frame(width: 92, height: 40)
                    .background(canAdd ? SetupPalette.emerald : DesignTokens.surface3)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
        .padding(18)
        .background(DesignTokens.surface1.opacity(0.72))
    }

    private func applyPreset(_ preset: HermesModelProviderPreset) {
        guard providerMode == .preset else { return }
        baseURL = preset.baseURL
        clearFetchedModels(keepDefaultModel: false)
        selectedModels = []
        manualModel = ""
    }

    private func fetchModels() {
        isFetching = true
        fetchMessage = AppRuntimeMode.uiPrototype ? "安全预览：正在读取 /models..." : "正在请求 /models..."
        fetchedModels = []
        ModelCatalogService.fetchOpenAICompatibleModels(baseURL: baseURL, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                isFetching = false
                switch result {
                case .success(let models):
                    fetchedModels = models
                    fetchMessage = models.isEmpty ? "接口没有返回模型，请手动输入。" : "已获取 \(models.count) 个模型，可选择后添加。"
                    selectedModels = []
                    if let first = models.first {
                        manualModel = first
                        selectedModels.insert(first)
                    }
                case .failure(let error):
                    fetchMessage = "获取失败：\(error.localizedDescription)"
                }
            }
        }
    }

    private func clearFetchedModels(keepDefaultModel: Bool) {
        fetchedModels = []
        selectedModels = []
        fetchMessage = ""
        if !keepDefaultModel {
            manualModel = ""
        }
    }

    private func toggleModel(_ model: String) {
        if selectedModels.contains(model) {
            selectedModels.remove(model)
        } else {
            selectedModels.insert(model)
            if manualModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                manualModel = model
            }
        }
    }

    private func addProvider() {
        let configuration = ModelProviderConfiguration(
            providerKey: providerKey,
            providerLabel: providerLabel,
            baseURL: baseURL,
            apiKey: apiKey,
            defaultModel: defaultModel,
            models: modelsToSave.isEmpty ? [defaultModel] : modelsToSave,
            contextLength: Int(contextLength.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 128000
        )
        manager.configureModelProvider(configuration)
        onClose()
    }

    private func slugify(_ value: String) -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return normalized.isEmpty ? "provider" : normalized
    }
}

struct ModelSelectionChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected ? SetupPalette.emerald : DesignTokens.textMuted)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(DesignTokens.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(isSelected ? SetupPalette.emerald.opacity(0.12) : DesignTokens.surface2.opacity(0.38))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? SetupPalette.emerald.opacity(0.32) : DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SettingsTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
                .padding(12)
                .background(DesignTokens.surface2)
                .cornerRadius(12)
        }
    }
}

struct SettingsSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
                .padding(12)
                .background(DesignTokens.surface2)
                .cornerRadius(12)
        }
    }
}

struct SettingsCounterRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(DesignTokens.surface2.opacity(0.38))
        .cornerRadius(12)
    }
}

struct SettingsBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(SetupPalette.emerald)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
                .lineSpacing(3)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Logs View

struct LogsView: View {
    @ObservedObject var manager: ServiceManager
    @State private var selectedLogType = 0
    @State private var autoScroll = true

    var displayedLogs: [String] {
        selectedLogType == 0 ? manager.logLines : manager.gatewayLogLines
    }

    var body: some View {
        ZStack {
            SetupBackground()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hermes Log Console")
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .foregroundColor(DesignTokens.textPrimary)
                        Text(L10n.t("集中查看 Hermes Web UI 与 Gateway 的运行输出。", "View Hermes Web UI and Gateway runtime output in one place."))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(DesignTokens.textTertiary)

                        HStack(spacing: 8) {
                            ConsoleStatusChip(title: "Server Logs", isOn: selectedLogType == 0)
                            ConsoleStatusChip(title: "Gateway Logs", isOn: selectedLogType == 1)
                            ConsoleStatusChip(title: autoScroll ? "Auto Scroll" : "Manual Scroll", isOn: autoScroll)
                        }
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            LogTypeButton(title: L10n.t("服务器", "Server"), isSelected: selectedLogType == 0) {
                                selectedLogType = 0
                            }
                            LogTypeButton(title: "Gateway", isSelected: selectedLogType == 1) {
                                selectedLogType = 1
                            }
                        }
                        .padding(4)
                        .background(DesignTokens.surface2.opacity(0.72))
                        .cornerRadius(14)

                        Button(action: { manager.readLogs(); manager.readGatewayLogs() }) {
                            Label(L10n.t("刷新", "Refresh"), systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(DesignTokens.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(DesignTokens.surface2.opacity(0.78))
                                .cornerRadius(DesignTokens.radiusPill)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                )
                .cornerRadius(20)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Circle().fill(Color(red: 1.0, green: 0.36, blue: 0.32)).frame(width: 10, height: 10)
                        Circle().fill(Color(red: 1.0, green: 0.77, blue: 0.25)).frame(width: 10, height: 10)
                        Circle().fill(SetupPalette.emerald).frame(width: 10, height: 10)
                        Text(selectedLogType == 0 ? "hermes-web-ui/server.log" : "hermes/gateway.log")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(DesignTokens.textMuted)
                            .padding(.leading, 8)
                        Spacer()
                        Toggle(isOn: $autoScroll) {
                            Text(L10n.t("自动滚动", "Auto scroll"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignTokens.textTertiary)
                        }
                        .toggleStyle(.checkbox)
                        .controlSize(.mini)
                        Text(L10n.t("\(displayedLogs.count) 行", "\(displayedLogs.count) lines"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(SetupPalette.emerald)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(SetupPalette.emerald.opacity(0.10))
                            .cornerRadius(DesignTokens.radiusPill)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(DesignTokens.surface2.opacity(0.72))

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 1) {
                                ForEach(Array(displayedLogs.enumerated()), id: \.offset) { index, line in
                                    LogLine(text: line, index: index)
                                        .id(index)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(SetupPalette.ink.opacity(0.90))
                        .onChange(of: displayedLogs.count) {
                            if autoScroll, let lastIndex = displayedLogs.indices.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(lastIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .background(SetupPalette.ink.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .padding(20)
        }
    }
}

struct LogTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                .padding(.horizontal, DesignTokens.spaceMD)
                .padding(.vertical, DesignTokens.spaceXS)
                .background(isSelected ? DesignTokens.surface3 : Color.clear)
                .cornerRadius(DesignTokens.radiusSM)
        }
        .buttonStyle(.plain)
    }
}

struct LogLine: View {
    let text: String
    let index: Int

    var lineColor: Color {
        let lower = text.lowercased()
        if lower.contains("error") || lower.contains("fail") || text.contains("❌") {
            return DesignTokens.error
        } else if lower.contains("warn") || text.contains("⚠️") {
            return DesignTokens.warning
        } else if lower.contains("info") || text.contains("✅") || lower.contains("started") {
            return DesignTokens.success
        }
        return DesignTokens.textSecondary
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.spaceSM) {
            Text("\(index)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(DesignTokens.textMuted)
                .frame(width: 28, alignment: .trailing)
            Text(text)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(lineColor)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(.vertical, 1)
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    @ObservedObject var manager: ServiceManager
    let onOpenSetup: () -> Void
    let onOpenCLI: () -> Void

    var body: some View {
        ZStack {
            SetupBackground()

            GeometryReader { proxy in
                let compact = proxy.size.width < 980

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Operations Console")
                                    .font(.system(size: 27, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignTokens.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)
                                Text(L10n.t("高频操作集中入口；所有服务操作只会在用户点击后执行。", "Central entry for frequent actions; service operations only run after user clicks."))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DesignTokens.textTertiary)
                                    .lineLimit(2)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                                    ConsoleStatusChip(title: "Web UI", isOn: manager.webUIRunning)
                                    ConsoleStatusChip(title: "Gateway", isOn: manager.gatewayRunning)
                                    ConsoleStatusChip(title: L10n.t("OpenHuman 记忆", "OpenHuman Memory"), isOn: manager.openHumanMemoryLinked)
                                }
                                .frame(maxWidth: 420, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text(L10n.dynamic(manager.statusMessage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(SetupPalette.emerald)
                                .lineLimit(2)
                                .multilineTextAlignment(.trailing)
                                .frame(minWidth: 150, maxWidth: 220, alignment: .trailing)
                        }
                        .padding(18)
                        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(SetupPalette.emerald.opacity(0.16), lineWidth: 1)
                        )
                        .cornerRadius(20)

                        quickActionGrid(compact: compact)

                        VStack(alignment: .leading, spacing: 12) {
                            ConsoleSectionTitle(title: "Files", subtitle: L10n.t("配置与数据目录", "Config and data folders"))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                                QuickActionRow(
                                    icon: "doc.text",
                                    title: L10n.t("编辑配置文件", "Edit config file"),
                                    description: compactPath(manager.activeHermesConfigPath),
                                    accent: DesignTokens.textSecondary
                                ) {
                                    let configPath = manager.activeHermesConfigPath
                                    if AppRuntimeMode.uiPrototype {
                                        manager.showToast(title: L10n.t("安全预览", "Safe Preview"), message: L10n.t("已预览打开配置文件：\(compactPath(configPath))", "Opening config file previewed: \(compactPath(configPath))"), icon: "doc.text", accent: SetupPalette.cyan)
                                        return
                                    }
                                    NSWorkspace.shared.open(URL(fileURLWithPath: configPath))
                                }

                                QuickActionRow(
                                    icon: "folder",
                                    title: L10n.t("打开数据目录", "Open data folder"),
                                    description: compactPath(manager.activeHermesProfileHome),
                                    accent: DesignTokens.textSecondary
                                ) {
                                    let hermesPath = manager.activeHermesProfileHome
                                    if AppRuntimeMode.uiPrototype {
                                        manager.showToast(title: L10n.t("安全预览", "Safe Preview"), message: L10n.t("已预览打开数据目录：\(compactPath(hermesPath))", "Opening data folder previewed: \(compactPath(hermesPath))"), icon: "folder", accent: SetupPalette.cyan)
                                        return
                                    }
                                    NSWorkspace.shared.open(URL(fileURLWithPath: hermesPath))
                                }
                            }
                        }
                        .padding(16)
                        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
                        )
                        .cornerRadius(20)
                    }
                    .padding(20)
                }
            }
        }
    }

    @ViewBuilder
    private func quickActionGrid(compact: Bool) -> some View {
        let columns = [GridItem(.adaptive(minimum: compact ? 260 : 320), spacing: 16)]
        LazyVGrid(columns: columns, spacing: 12) {
            QuickActionRow(
                icon: "globe",
                title: L10n.t("启动 Web UI 并打开浏览器", "Start Web UI and Open Browser"),
                description: L10n.t("必要时先启动 Web UI，再打开控制台地址。", "Start Web UI if needed, then open the console URL."),
                accent: SetupPalette.cyan
            ) {
                if !manager.webUIRunning {
                    manager.startWebUI()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    manager.openWebUIInBrowser()
                }
            }

            QuickActionRow(
                icon: "terminal",
                title: L10n.t("打开内置 CLI", "Open Embedded CLI"),
                description: L10n.t("在应用内部进入 Hermes CLI 预览页，不新开 Terminal。", "Open Hermes CLI inside the app without launching Terminal."),
                accent: SetupPalette.emerald
            ) {
                onOpenCLI()
            }

            QuickActionRow(
                icon: "wand.and.stars",
                title: L10n.t("重新检测 / 安装向导", "Re-detect / Setup Wizard"),
                description: L10n.t("重新检查 Hermes、OpenHuman、Web UI 和记忆连接。", "Re-check Hermes, OpenHuman, Web UI, and the memory bridge."),
                accent: SetupPalette.amber
            ) {
                onOpenSetup()
            }

            QuickActionRow(
                icon: "arrow.clockwise",
                title: L10n.t("重启全部服务", "Restart All Services"),
                description: L10n.t("先停止再启动 Web UI + Gateway。", "Stop, then start Web UI + Gateway."),
                accent: SetupPalette.cyan
            ) {
                manager.restartAll()
            }

        }
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let description: String
    let accent: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accent)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .lineLimit(1)
                    Text(description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textMuted)
                    .frame(width: 18, alignment: .trailing)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(isHovering ? DesignTokens.surface2.opacity(0.74) : DesignTokens.surface2.opacity(0.38))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovering ? accent.opacity(0.28) : DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(16)
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
