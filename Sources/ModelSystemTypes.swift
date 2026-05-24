import SwiftUI

enum ModelSystemRoute: String, CaseIterable, Identifiable {
    case overview = "models-overview"
    case providers = "model-providers"
    case management = "model-management"
    case detection = "model-detection"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "模型概览"
        case .providers: return "配置供应商"
        case .management: return "模型管理"
        case .detection: return "检测中心"
        }
    }

    var subtitle: String {
        switch self {
        case .overview: return "当前模型、供应商状态与可用性总览"
        case .providers: return "添加、编辑、测试和同步供应商"
        case .management: return "查看、筛选、启用并切换模型"
        case .detection: return "统一执行模型与供应商可用性检测"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "cube.transparent"
        case .providers: return "building.2"
        case .management: return "square.grid.3x3"
        case .detection: return "waveform.path.ecg"
        }
    }

    var accent: Color {
        switch self {
        case .overview: return SetupPalette.emerald
        case .providers: return SetupPalette.cyan
        case .management: return Color(red: 0.43, green: 0.53, blue: 1.0)
        case .detection: return SetupPalette.amber
        }
    }
}

enum ModelProviderKind: String, CaseIterable, Identifiable {
    case builtin = "内置"
    case custom = "自定义"

    var id: String { rawValue }
}

enum ModelHealthStatus: String, CaseIterable, Identifiable {
    case healthy = "健康"
    case warning = "警告"
    case unavailable = "不可用"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .healthy: return SetupPalette.emerald
        case .warning: return SetupPalette.amber
        case .unavailable: return DesignTokens.error
        }
    }

    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .unavailable: return "xmark.circle.fill"
        }
    }
}

enum ModelStatusFilter: String, CaseIterable, Identifiable {
    case all = "全部状态"
    case healthy = "健康"
    case warning = "警告"
    case unavailable = "连接失败"

    var id: String { rawValue }

    func matches(_ status: ModelHealthStatus) -> Bool {
        switch self {
        case .all: return true
        case .healthy: return status == .healthy
        case .warning: return status == .warning
        case .unavailable: return status == .unavailable
        }
    }
}

struct ModelProviderItem: Identifiable, Hashable {
    let id: String
    var name: String
    var kind: ModelProviderKind
    var baseURL: String
    var apiKeyConfigured: Bool
    var apiKeyMasked: String
    var headersPreview: String
    var timeoutSeconds: Int
    var retryCount: Int
    var enabled: Bool
    var syncToCLI: Bool
    var syncToWebUI: Bool
    var isDefault: Bool
    var status: ModelHealthStatus
    var modelCount: Int
    var lastCheckedAt: String
    var latencyMS: Int?
}

struct ModelInfoItem: Identifiable, Hashable {
    let id: String
    var name: String
    var alias: String
    var providerID: String
    var providerName: String
    var baseURL: String
    var visible: Bool
    var enabled: Bool
    var isCurrent: Bool
    var contextLength: String
    var priceLevel: String
    var status: ModelHealthStatus
    var latencyMS: Int?
    var availabilityPercent: Int
    var lastCheckedAt: String
}

struct ModelDetectionRecord: Identifiable, Hashable {
    let id: UUID
    var targetType: String
    var title: String
    var detail: String
    var status: ModelHealthStatus
    var latencyMS: Int?
    var availabilityPercent: Int?
    var checkedAt: String
}

struct ModelProviderEditDraft {
    var providerKey: String
    var providerLabel: String
    var baseURL: String
    var apiKey: String
    var models: [String]
    var defaultModel: String
    var contextLength: Int
    var enabled: Bool
    var syncToCLI: Bool
    var syncToWebUI: Bool
}

struct ModelSystemSnapshot {
    var providers: [ModelProviderItem]
    var models: [ModelInfoItem]
    var detections: [ModelDetectionRecord]

    static func mock(
        currentModelName: String,
        currentProviderName: String,
        updatedAt: String
    ) -> ModelSystemSnapshot {
        let displayModel = currentModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "deepseek-v4-flash" : currentModelName
        let displayProvider = currentProviderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "OpenCode Go" : currentProviderName
        let checkedAt = updatedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "18:15:29" : updatedAt

        let providers = [
            ModelProviderItem(
                id: "opencode-go",
                name: displayProvider,
                kind: .builtin,
                baseURL: "https://api.opencode.com/v1",
                apiKeyConfigured: true,
                apiKeyMasked: "sk-••••••••••••••••••••••••",
                headersPreview: #"{"X-Client": "Hermes-Manager"}"#,
                timeoutSeconds: 60,
                retryCount: 3,
                enabled: true,
                syncToCLI: true,
                syncToWebUI: true,
                isDefault: true,
                status: .healthy,
                modelCount: 12,
                lastCheckedAt: checkedAt,
                latencyMS: 142
            ),
            ModelProviderItem(
                id: "xiaomi-mimo",
                name: "Xiaomi MiMo",
                kind: .custom,
                baseURL: "https://api.mimo.xiaomi.com/v1",
                apiKeyConfigured: true,
                apiKeyMasked: "sk-••••••••••••••",
                headersPreview: #"{"Authorization": "Bearer sk-••••"}"#,
                timeoutSeconds: 45,
                retryCount: 2,
                enabled: true,
                syncToCLI: true,
                syncToWebUI: true,
                isDefault: false,
                status: .healthy,
                modelCount: 5,
                lastCheckedAt: "18:14:58",
                latencyMS: 218
            ),
            ModelProviderItem(
                id: "xunfei",
                name: "xunfei",
                kind: .custom,
                baseURL: "https://spark-api.xf-yun.com/v1",
                apiKeyConfigured: true,
                apiKeyMasked: "sk-••••••••••••••",
                headersPreview: "{}",
                timeoutSeconds: 60,
                retryCount: 3,
                enabled: true,
                syncToCLI: true,
                syncToWebUI: false,
                isDefault: false,
                status: .warning,
                modelCount: 19,
                lastCheckedAt: "18:12:33",
                latencyMS: 632
            ),
            ModelProviderItem(
                id: "opencode-ai",
                name: "opencode.ai",
                kind: .custom,
                baseURL: "https://api.opencode.ai/v1",
                apiKeyConfigured: true,
                apiKeyMasked: "sk-••••••••••••••",
                headersPreview: "{}",
                timeoutSeconds: 60,
                retryCount: 3,
                enabled: true,
                syncToCLI: false,
                syncToWebUI: true,
                isDefault: false,
                status: .unavailable,
                modelCount: 37,
                lastCheckedAt: "18:05:02",
                latencyMS: nil
            )
        ]

        let models = [
            ModelInfoItem(id: "opencode-go|\(displayModel)", name: displayModel, alias: "DeepSeek V4 Flash", providerID: "opencode-go", providerName: displayProvider, baseURL: "https://api.opencode.com/v1", visible: true, enabled: true, isCurrent: true, contextLength: "128K", priceLevel: "$$", status: .healthy, latencyMS: 142, availabilityPercent: 100, lastCheckedAt: checkedAt),
            ModelInfoItem(id: "opencode-go|deepseek-v4-pro", name: "deepseek-v4-pro", alias: "DeepSeek V4 Pro", providerID: "opencode-go", providerName: displayProvider, baseURL: "https://api.opencode.com/v1", visible: true, enabled: true, isCurrent: false, contextLength: "128K", priceLevel: "$$$", status: .healthy, latencyMS: 176, availabilityPercent: 100, lastCheckedAt: checkedAt),
            ModelInfoItem(id: "opencode-go|qwen3.6-plus", name: "qwen3.6-plus", alias: "Qwen 3.6 Plus", providerID: "opencode-go", providerName: displayProvider, baseURL: "https://api.opencode.com/v1", visible: true, enabled: true, isCurrent: false, contextLength: "256K", priceLevel: "$$", status: .unavailable, latencyMS: nil, availabilityPercent: 0, lastCheckedAt: "18:12:33"),
            ModelInfoItem(id: "xiaomi-mimo|mimo-v2.5-pro", name: "mimo-v2.5-pro", alias: "MiMo V2.5 Pro", providerID: "xiaomi-mimo", providerName: "Xiaomi MiMo", baseURL: "https://api.mimo.xiaomi.com/v1", visible: true, enabled: true, isCurrent: false, contextLength: "128K", priceLevel: "$$", status: .healthy, latencyMS: 218, availabilityPercent: 100, lastCheckedAt: "18:14:58"),
            ModelInfoItem(id: "xiaomi-mimo|mimo-v2-omni", name: "mimo-v2-omni", alias: "MiMo V2 Omni", providerID: "xiaomi-mimo", providerName: "Xiaomi MiMo", baseURL: "https://api.mimo.xiaomi.com/v1", visible: true, enabled: true, isCurrent: false, contextLength: "64K", priceLevel: "$", status: .healthy, latencyMS: 241, availabilityPercent: 98, lastCheckedAt: "18:14:58"),
            ModelInfoItem(id: "xunfei|astron-code-latest", name: "astron-code-latest", alias: "Astron Code", providerID: "xunfei", providerName: "xunfei", baseURL: "https://spark-api.xf-yun.com/v1", visible: true, enabled: true, isCurrent: false, contextLength: "64K", priceLevel: "$$", status: .warning, latencyMS: 632, availabilityPercent: 90, lastCheckedAt: "18:12:33"),
            ModelInfoItem(id: "opencode-ai|deepseek-v4-flash-free", name: "deepseek-v4-flash-free", alias: "DeepSeek Free", providerID: "opencode-ai", providerName: "opencode.ai", baseURL: "https://api.opencode.ai/v1", visible: false, enabled: false, isCurrent: false, contextLength: "64K", priceLevel: "$", status: .unavailable, latencyMS: nil, availabilityPercent: 0, lastCheckedAt: "18:05:02")
        ]

        let detections = [
            ModelDetectionRecord(id: UUID(), targetType: "all", title: "一键检测完成", detail: "成功检测 50/50 个模型", status: .healthy, latencyMS: 142, availabilityPercent: 94, checkedAt: checkedAt),
            ModelDetectionRecord(id: UUID(), targetType: "model", title: "\(displayModel) 检测通过", detail: "延迟 142ms，可用率 100%", status: .healthy, latencyMS: 142, availabilityPercent: 100, checkedAt: "18:15:27"),
            ModelDetectionRecord(id: UUID(), targetType: "provider", title: "\(displayProvider) 连接正常", detail: "可用模型 12 个", status: .healthy, latencyMS: 142, availabilityPercent: 100, checkedAt: "18:15:21"),
            ModelDetectionRecord(id: UUID(), targetType: "all", title: "开始检测所有模型", detail: "触发方式：手动", status: .warning, latencyMS: nil, availabilityPercent: nil, checkedAt: "18:14:58"),
            ModelDetectionRecord(id: UUID(), targetType: "provider", title: "模型配置已更新", detail: "添加模型 qwen3.6-plus", status: .warning, latencyMS: nil, availabilityPercent: nil, checkedAt: "18:12:33")
        ]

        return ModelSystemSnapshot(providers: providers, models: models, detections: detections)
    }
}
