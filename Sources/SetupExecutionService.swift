import Foundation
import AppKit

struct SetupExecutionOptions {
    let scenario: SetupScenario
    let reinstall: Bool
    let clearExisting: Bool
    let migrateMemory: Bool
    let reinstallHermes: Bool
    let reinstallOpenHuman: Bool
    let clearHermes: Bool
    let clearOpenHuman: Bool
    let startWebUIAfterRun: Bool
}

struct ModelAPIConfiguration {
    let baseURL: String
    let apiKey: String
    let modelName: String
}

struct ModelProviderConfiguration {
    let providerKey: String
    let providerLabel: String
    let baseURL: String
    let apiKey: String
    let defaultModel: String
    let models: [String]
    let contextLength: Int
}

struct SetupExecutionUpdate {
    let step: String
    let logLine: String
    let progress: Double
}

enum SetupExecutionError: LocalizedError {
    case commandFailed(String)
    case invalidModelConfiguration
    case invalidModelCatalogURL

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .invalidModelConfiguration:
            return "API Base URL、API Key、模型名称需要同时填写才会写入配置。"
        case .invalidModelCatalogURL:
            return "API Base URL 无法解析，不能拉取模型列表。"
        }
    }
}

enum ModelCatalogService {
    static func fetchOpenAICompatibleModels(
        baseURL: String,
        apiKey: String,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        if AppRuntimeMode.uiPrototype {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                completion(.success(["ui-preview-model", "deepseek-v4-flash", "gpt-4.1"]))
            }
            return
        }

        guard let url = modelsURL(from: baseURL) else {
            completion(.failure(SetupExecutionError.invalidModelCatalogURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                completion(.failure(SetupExecutionError.commandFailed("模型列表请求失败：HTTP \(http.statusCode)")))
                return
            }

            guard let data else {
                completion(.success([]))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data)
                let models = extractModelIDs(from: json)
                completion(.success(models))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private static func modelsURL(from baseURL: String) -> URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        if normalized.hasSuffix("/models"), let url = URL(string: normalized) {
            return url
        }
        if normalized.range(of: #"/v\d+$"#, options: .regularExpression) != nil {
            return URL(string: normalized + "/models")
        }
        return URL(string: normalized + "/v1/models")
    }

    private static func extractModelIDs(from json: Any) -> [String] {
        guard let object = json as? [String: Any] else { return [] }
        let data = object["data"] as? [[String: Any]] ?? []
        let ids = data.compactMap { item in
            (item["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Array(Set(ids.filter { !$0.isEmpty })).sorted()
    }
}

final class SetupExecutionService {
    static let verifiedHermesRef = "43e566f77eaf01293086eb7cb99a21e240d60634"
    static let verifiedOpenHumanRef = "48548a223bbf71fded61d43ff1b4de15bc34979b"
    static let verifiedWebUIVersion = "0.5.28"

    private let fileManager = FileManager.default
    private let versionManifest: RemoteVersionManifest
    private let home: String
    private let hermesHome: String
    private let openHumanHome: String
    private let openHumanVault: String
    private let openHumanWorkspace: String
    private let webUIHome: String
    private let managerHome: String
    private let webUIRuntimeHome: String
    private var activeHermesProfileHome: String {
        let activeFile = "\(hermesHome)/active_profile"
        guard let raw = try? String(contentsOfFile: activeFile, encoding: .utf8) else {
            return hermesHome
        }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != "default" else {
            return hermesHome
        }
        let profileHome = "\(hermesHome)/profiles/\(name)"
        return fileManager.fileExists(atPath: profileHome) ? profileHome : hermesHome
    }
    private var activeHermesConfigPath: String { "\(activeHermesProfileHome)/config.yaml" }
    private var activeHermesEnvPath: String { "\(activeHermesProfileHome)/.env" }
    private lazy var backupRoot: String = "\(home)/.hermes-manager/backups/\(timestamp())"

    init(home: String = NSHomeDirectory(), versionManifest: RemoteVersionManifest = .bundled) {
        self.versionManifest = versionManifest
        self.home = home
        self.hermesHome = "\(home)/.hermes"
        self.openHumanHome = "\(home)/.openhuman"
        self.openHumanVault = "\(home)/.openhuman/vault"
        self.openHumanWorkspace = "\(home)/.openhuman/users/local/workspace"
        self.webUIHome = "\(home)/.hermes-web-ui"
        self.managerHome = "\(home)/.hermes-manager"
        self.webUIRuntimeHome = "\(home)/.hermes-manager/runtime/hermes-web-ui"
    }

    func run(options: SetupExecutionOptions, onUpdate: @escaping (SetupExecutionUpdate) -> Void) -> Result<Void, Error> {
        let steps = buildSteps(options: options)
        var completed = 0
        let minimumStepDisplayTime: TimeInterval = 0.28

        func emit(_ step: String, _ line: String) {
            onUpdate(SetupExecutionUpdate(
                step: step,
                logLine: line,
                progress: steps.isEmpty ? 1 : min(1, Double(completed) / Double(steps.count))
            ))
        }

        if AppRuntimeMode.uiPrototype {
            emit("安全预览", "[SAFE] SetupExecutionService 已进入硬保护：安装、清除、迁移、配置、启动全部跳过。")
            for step in steps {
                completed += 1
                emit(step.title, "[SAFE STEP] 已预览：\(step.title)")
            }
            emit("完成", "[SAFE DONE] 安全预览执行完成，未触碰 Hermes/OpenHuman/Web UI。")
            return .success(())
        }

        do {
            emit("准备执行", "[INFO] 所有操作只会使用当前用户 HOME 下的 Hermes/OpenHuman 路径。")

            for step in steps {
                let startedAt = Date()
                emit(step.title, "[STEP] \(step.title)")
                try step.action { output in
                    emit(step.title, output)
                }
                let elapsed = Date().timeIntervalSince(startedAt)
                if elapsed < minimumStepDisplayTime {
                    Thread.sleep(forTimeInterval: minimumStepDisplayTime - elapsed)
                }
                completed += 1
                emit(step.title, "[OK] \(step.title)")
            }

            completed = steps.count
            emit("完成", "[OK] 执行完成。")
            return .success(())
        } catch {
            emit("失败", "[ERROR] \(error.localizedDescription)")
            return .failure(error)
        }
    }

    func configureModelAPI(_ configuration: ModelAPIConfiguration, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        let baseURL = configuration.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let modelName = configuration.modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = ModelProviderConfiguration(
            providerKey: "custom:hermes-manager",
            providerLabel: "hermes-manager",
            baseURL: baseURL,
            apiKey: apiKey,
            defaultModel: modelName,
            models: [modelName],
            contextLength: 128000
        )
        return configureModelProvider(provider, onLog: onLog)
    }

    func configureModelProvider(_ configuration: ModelProviderConfiguration, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        configureModelProvider(configuration, pruneWebUIModels: false, onLog: onLog)
    }

    func configureModelProviderExact(_ configuration: ModelProviderConfiguration, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        configureModelProvider(configuration, pruneWebUIModels: true, onLog: onLog)
    }

    private func configureModelProvider(_ configuration: ModelProviderConfiguration, pruneWebUIModels: Bool, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        let providerKey = normalizedProviderKey(configuration.providerKey, label: configuration.providerLabel)
        let providerLabel = configuration.providerLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseURL = configuration.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = configuration.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultModel = configuration.defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let models = normalizedModelList(configuration.models + [defaultModel])
        let providerName = providerNameForCustomProvider(providerKey: providerKey, label: providerLabel)
        let contextLength = max(configuration.contextLength, 8192)
        let apiMode = inferredAPIMode(providerKey: providerKey, baseURL: baseURL, model: defaultModel)
        let customKeyEnv = providerKey.hasPrefix("custom:") ? customProviderAPIKeyEnvName(providerKey: providerKey) : ""

        guard !providerKey.isEmpty, !baseURL.isEmpty, !apiKey.isEmpty, !defaultModel.isEmpty else {
            return .failure(SetupExecutionError.invalidModelConfiguration)
        }

        if AppRuntimeMode.uiPrototype {
            onLog("[SAFE] 已预览同步 Provider：\(providerKey) / \(defaultModel)；未写入 ~/.hermes、Hermes Web UI 或环境变量。")
            return .success(())
        }

        do {
            let profileHome = activeHermesProfileHome
            try fileManager.createDirectory(atPath: profileHome, withIntermediateDirectories: true)
            let configPath = activeHermesConfigPath
            try backupIfExists(configPath, onLog: onLog)
            var config = readText(configPath)
            config = upsertTopLevelBlock(
                named: "model",
                in: config,
                replacement: modelConfigBlock(
                    providerKey: providerKey,
                    baseURL: baseURL,
                    defaultModel: defaultModel,
                    apiMode: apiMode
                )
            )
            if providerKey.hasPrefix("custom:") {
                try writeProviderEnv(keys: [customKeyEnv], baseURLKeys: [], baseURL: baseURL, apiKey: apiKey, onLog: onLog)
                config = upsertCustomProvider(
                    in: config,
                    providerKey: providerKey,
                    providerName: providerName,
                    baseURL: baseURL,
                    apiKey: apiKey,
                    keyEnv: customKeyEnv,
                    defaultModel: defaultModel,
                    models: models,
                    apiMode: apiMode,
                    contextLength: contextLength
                )
            }
            try writeText(config, to: configPath)
            try restrictOwnerAccess(configPath)
            onLog("[OK] 已写入 Hermes CLI 模型配置：\(compactHome(configPath))")

            try writeProviderEnvIfKnown(providerKey: providerKey, baseURL: baseURL, apiKey: apiKey, onLog: onLog)
            if !providerKey.hasPrefix("custom:") {
                onLog("[OK] 内置 Provider 使用 Hermes 官方 provider key：\(providerKey)，不会额外写入 custom_providers。")
            }
            try updateWebUIModelVisibility(providerKey: providerKey, modelNames: models, defaultModel: defaultModel)
            onLog("[OK] 已更新 Hermes Web UI 模型可见性配置：\(providerKey)")
            try updateWebUIModelContextDatabase(providerKey: providerKey, modelNames: models, contextLength: contextLength, onLog: onLog)
            try validateModelProviderConfiguration(
                providerKey: providerKey,
                providerName: providerName,
                baseURL: baseURL,
                defaultModel: defaultModel,
                modelNames: models,
                keyEnv: customKeyEnv,
                onLog: onLog
            )
            if pruneWebUIModels {
                try pruneWebUIModelContextDatabase(providerKey: providerKey, allowedModels: models, onLog: onLog)
            }
            restartModelConsumersIfRunning(onLog: onLog)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func removeCustomModelProvider(providerKey: String, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        let normalizedKey = normalizedProviderKey(providerKey, label: providerKey)
        guard normalizedKey.hasPrefix("custom:") else {
            return .failure(SetupExecutionError.commandFailed("只允许删除自定义 Provider，内置 Provider 不会从公开版里直接移除。"))
        }

        do {
            let configPath = activeHermesConfigPath
            let providerName = providerNameForCustomProvider(providerKey: normalizedKey, label: "")
            let config = readText(configPath)
            guard !config.isEmpty else {
                return .failure(SetupExecutionError.commandFailed("没有检测到 Hermes 配置文件，无法删除 Provider。"))
            }
            if yamlNestedScalarEquals(config, block: "model", key: "provider", value: normalizedKey) {
                return .failure(SetupExecutionError.commandFailed("当前 Provider 正在被 Hermes 使用，不能直接删除。请先切换到别的 Provider。"))
            }

            let updated = removeCustomProviderFromConfig(config, providerKey: normalizedKey, providerName: providerName)
            guard updated != config else {
                return .failure(SetupExecutionError.commandFailed("没有在 custom_providers 中找到要删除的 Provider。"))
            }
            try backupIfExists(configPath, onLog: onLog)
            try writeText(updated, to: configPath)
            try restrictOwnerAccess(configPath)
            onLog("[OK] 已从 Hermes config.yaml 删除自定义 Provider：\(normalizedKey)")

            try removeProviderFromWebUI(providerKey: normalizedKey, onLog: onLog)
            restartModelConsumersIfRunning(onLog: onLog)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private struct ExecutionStep {
        let title: String
        let action: (@escaping (String) -> Void) throws -> Void
    }

    private func buildSteps(options: SetupExecutionOptions) -> [ExecutionStep] {
        var steps: [ExecutionStep] = [
            ExecutionStep(title: "检测运行环境") { [self] log in
                try ensureBaseDirectories(log)
                log("[INFO] 默认使用官方安装脚本安装本机验证版本；需要最新版请安装完成后在控制面板更新。")
            },
        ]

        if options.scenario == .ready && !options.reinstall && !options.clearExisting {
            steps.append(ExecutionStep(title: "说明当前执行类型") { log in
                log("[INFO] 当前状态已完成配置，本页执行的是健康检查，不会重新安装 Hermes/OpenHuman，也不会迁移或覆盖记忆。")
            })
            steps.append(ExecutionStep(title: "检查 Hermes/OpenHuman 记忆配置") { [self] log in
                try verifyOpenHumanConfiguration(log)
            })
            steps.append(ExecutionStep(title: "检查长期记忆迁移状态") { [self] log in
                try verifyMemoryMigrationState(log)
            })
            steps.append(ExecutionStep(title: "读取 Web UI 状态") { log in
                log("[INFO] Web UI token 和模型状态会在完成页由控制面板实时读取。")
            })
            return steps
        }

        if options.clearExisting {
            steps.append(ExecutionStep(title: "备份并清理选中组件") { [self] log in
                try backupAndMoveSelectedData(options: options, log)
            })
        }

        let shouldInstallHermes = options.scenario == .freshInstall
            || !hermesLooksInstalled()
            || (options.reinstall && options.reinstallHermes)
        let shouldInstallOpenHuman = options.scenario == .freshInstall
            || options.scenario == .addOpenHuman
            || !openHumanLooksInstalled()
            || (options.reinstall && options.reinstallOpenHuman)

        if shouldInstallHermes {
            steps.append(ExecutionStep(title: "安装 Hermes 主控") { [self] log in
                try installHermes(log)
            })
        } else {
            steps.append(ExecutionStep(title: "确认 Hermes 主控") { log in
                log("[INFO] 已检测到 Hermes 安装，保留现有安装。")
            })
        }

        if shouldInstallOpenHuman {
            steps.append(ExecutionStep(title: "安装 OpenHuman 记忆库") { [self] log in
                try installOpenHuman(log)
                try initializeOpenHumanVault(log)
            })
        }

        if options.scenario == .freshInstall || !webUICommandAvailable() {
            steps.append(ExecutionStep(title: "安装 Hermes Web UI") { [self] log in
                try installHermesWebUI(log)
            })
        }

        steps.append(ExecutionStep(title: "配置 Hermes 使用 OpenHuman 记忆") { [self] log in
            try installOpenHumanMemoryPlugin(log)
            try configureOpenHumanMemory(log)
        })

        if options.migrateMemory {
            steps.append(ExecutionStep(title: "迁移现有记忆到 OpenHuman") { [self] log in
                try migrateExistingMemories(log)
            })
        } else if options.scenario == .addOpenHuman || options.scenario == .repairLink {
            steps.append(ExecutionStep(title: "跳过长期记忆迁移") { log in
                log("[WARN] 用户已关闭长期记忆迁移；仍会关闭 Hermes 自带长期记忆写入，并改用 OpenHuman 作为记忆库。短期日志保留本地。")
            })
        }

        steps.append(ExecutionStep(title: "验证记忆连接") { [self] log in
            try verifyOpenHumanConfiguration(log)
            try verifyMemoryMigrationState(log, requireMigration: options.migrateMemory)
        })

        if options.startWebUIAfterRun && options.scenario != .ready {
            steps.append(ExecutionStep(title: "启动 Hermes Web UI") { [self] log in
                try startWebUIAndOpenBrowser(log)
            })
        }

        return steps
    }

    private func ensureBaseDirectories(_ log: (String) -> Void) throws {
        try fileManager.createDirectory(atPath: managerHome, withIntermediateDirectories: true)
        try restrictOwnerAccess(managerHome)
        log("[OK] Hermes Manager 工作目录已准备。")
        log("[INFO] 当前开发者验证版本：Hermes \(versionManifest.components.hermes.displayVersion)，OpenHuman \(versionManifest.components.openHuman.displayVersion)，Hermes Web UI \(VersionFormatting.displayVersion(versionManifest.components.hermesWebUI.version))。")
    }

    private func installHermes(_ log: (String) -> Void) throws {
        let repo = "\(hermesHome)/hermes-agent"
        let hermesRef = versionManifest.components.hermes.ref
        let installer = try downloadInstaller(
            url: "https://raw.githubusercontent.com/NousResearch/hermes-agent/\(hermesRef)/scripts/install.sh",
            name: "hermes-install.sh",
            log
        )
        try runShell("bash \(shellQuote(installer)) --skip-setup --branch main --dir \(shellQuote(repo)) --hermes-home \(shellQuote(hermesHome))", log)
        try runShell("cd \(shellQuote(repo)) && git remote set-url origin \(shellQuote(versionManifest.components.hermes.repo)) && git fetch --tags origin main && git checkout \(shellQuote(hermesRef))", log)
        try refreshHermesEditableInstall(repo: repo, log)
        log("[OK] Hermes 已安装为开发者验证版本：\(versionManifest.components.hermes.displayVersion)。")
    }

    private func refreshHermesEditableInstall(repo: String, _ log: (String) -> Void) throws {
        let venv = "\(repo)/venv"
        if fileManager.fileExists(atPath: "\(repo)/uv.lock"), commandExists("uv") {
            do {
                try runShell("cd \(shellQuote(repo)) && UV_PROJECT_ENVIRONMENT=\(shellQuote(venv)) uv sync --extra all --locked", log)
                return
            } catch {
                log("[WARN] uv locked 同步失败，可能是当前验证版本的 uv.lock 与项目元数据不一致；改用非 locked 同步继续安装。")
                try runShell("cd \(shellQuote(repo)) && UV_PROJECT_ENVIRONMENT=\(shellQuote(venv)) uv sync --extra all", log)
                return
            }
        }
        let python = fileManager.fileExists(atPath: "\(venv)/bin/python") ? "\(venv)/bin/python" : "python3"
        try runShell("cd \(shellQuote(repo)) && \(shellQuote(python)) -m pip install -e '.[all]'", log)
    }

    private func initializeOpenHumanVault(_ log: (String) -> Void) throws {
        try fileManager.createDirectory(atPath: openHumanVault, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: "\(openHumanVault)/Hermes/Inbox", withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: "\(openHumanVault)/Imported", withIntermediateDirectories: true)
        try initializeOpenHumanMemoryStore(log)
        let readmePath = "\(openHumanVault)/README.md"
        if !fileManager.fileExists(atPath: readmePath) {
            try writeText("# OpenHuman Vault\n\nThis vault is used by Hermes as an external long-term memory store.\n", to: readmePath)
        }
        log("[OK] OpenHuman Vault 已初始化：~/.openhuman/vault")
        log("[INFO] OpenHuman 长期记忆工作区已准备：~/.openhuman/users/local/workspace/memory/memory.db")
        log("[INFO] 如果用户需要 OpenHuman GUI，请在日志提示后手动安装 OpenHuman App；Hermes 记忆连接优先使用 OpenHuman SQLite 记忆库，Vault 只作为可读兼容层。")
    }

    private func installOpenHuman(_ log: (String) -> Void) throws {
        if openHumanLooksInstalled() {
            log("[INFO] 已检测到 OpenHuman 或 OpenHuman Vault，保留现有安装。")
            return
        }
        log("[INFO] 正在使用 OpenHuman 官方安装脚本安装开发者验证版本：\(versionManifest.components.openHuman.displayVersion)。")
        do {
            let openHumanRef = versionManifest.components.openHuman.ref
            let installer = try downloadInstaller(
                url: "https://raw.githubusercontent.com/tinyhumansai/openhuman/\(openHumanRef)/scripts/install.sh",
                name: "openhuman-install.sh",
                log
            )
            try runShell("bash \(shellQuote(installer))", log)
            log("[OK] OpenHuman 官方安装脚本执行完成。")
        } catch {
            log("[WARN] OpenHuman 自动安装未完成：\(error.localizedDescription)")
            log("[ACTION] 请按日志提示完成 OpenHuman 安装；本工具会继续初始化 Vault，并保证 Hermes 可使用 Vault 作为记忆库。")
        }
    }

    private func installHermesWebUI(_ log: (String) -> Void) throws {
        if fileManager.fileExists(atPath: privateWebUIExecutable) {
            log("[INFO] 已检测到 Hermes Manager 私有 hermes-web-ui，保留现有安装。")
            return
        }
        if !commandExists("npm") {
            throw SetupExecutionError.commandFailed("未找到 npm。请先安装 Node.js，或在日志提示后手动安装 Hermes Web UI。")
        }
        try fileManager.createDirectory(atPath: webUIRuntimeHome, withIntermediateDirectories: true)
        try restrictOwnerAccess(managerHome)
        let webUIPackage = versionManifest.components.hermesWebUI.package
        let webUIVersion = versionManifest.components.hermesWebUI.version
        try runShell("cd \(shellQuote(webUIRuntimeHome)) && npm init -y >/dev/null 2>&1 && npm install --save-exact \(shellQuote("\(webUIPackage)@\(webUIVersion)"))", log)
        log("[OK] Hermes Web UI \(webUIVersion) 已安装到 App 私有运行目录：~/.hermes-manager/runtime/hermes-web-ui")
    }

    func updateCompatibilityBundle(manifest: RemoteVersionManifest, onLog: @escaping (String) -> Void) -> Result<Void, Error> {
        guard !AppRuntimeMode.uiPrototype else {
            onLog("[SAFE] 已预览更新 Hermes + OpenHuman 核心组件；没有执行本机安装。")
            return .success(())
        }

        do {
            try ensureBaseDirectories(onLog)
            onLog("[INFO] 将更新到开发者验证核心组件：\(manifest.compatibilityBundle.displayLabel(hermes: manifest.components.hermes.displayVersion, openHuman: manifest.components.openHuman.displayVersion))。")
            try updateHermesToPinnedRef(manifest: manifest, onLog)
            try updateOpenHumanToPinnedRef(manifest: manifest, onLog)
            try updateWebUIToPinnedVersion(manifest: manifest, onLog)
            try installOpenHumanMemoryPlugin(onLog)
            try configureOpenHumanMemory(onLog)
            try verifyOpenHumanConfiguration(onLog)
            onLog("[OK] 核心组件更新完成。")
            return .success(())
        } catch {
            onLog("[ERROR] \(error.localizedDescription)")
            return .failure(error)
        }
    }

    private func updateHermesToPinnedRef(manifest: RemoteVersionManifest, _ log: (String) -> Void) throws {
        let repo = "\(hermesHome)/hermes-agent"
        if !fileManager.fileExists(atPath: repo) {
            log("[INFO] 未检测到 Hermes 仓库，进入安装流程。")
            try SetupExecutionService(home: home, versionManifest: manifest).installHermes(log)
            return
        }
        let ref = manifest.components.hermes.ref
        try runShell("cd \(shellQuote(repo)) && git remote set-url origin \(shellQuote(manifest.components.hermes.repo)) && git fetch --tags origin main && git checkout \(shellQuote(ref))", log)
        try refreshHermesEditableInstall(repo: repo, log)
        log("[OK] Hermes 已切换到开发者验证版本：\(manifest.components.hermes.displayVersion)。")
    }

    private func updateOpenHumanToPinnedRef(manifest: RemoteVersionManifest, _ log: (String) -> Void) throws {
        let ref = manifest.components.openHuman.ref
        log("[INFO] OpenHuman 目标版本：\(manifest.components.openHuman.displayVersion)。如本机没有标准 CLI，会只初始化/保留 Vault 与 SQLite 长期记忆库。")
        if commandExists("openhuman") || fileManager.fileExists(atPath: openHumanHome) {
            try initializeOpenHumanVault(log)
            log("[OK] 已保留现有 OpenHuman 数据并校验长期记忆目录；不会覆盖 OpenHuman 既有记忆。")
            return
        }

        do {
            let installer = try downloadInstaller(
                url: "https://raw.githubusercontent.com/tinyhumansai/openhuman/\(ref)/scripts/install.sh",
                name: "openhuman-install.sh",
                log
            )
            try runShell("bash \(shellQuote(installer))", log)
        } catch {
            log("[WARN] OpenHuman 固定版本安装未完成：\(error.localizedDescription)")
        }
        try initializeOpenHumanVault(log)
    }

    private func updateWebUIToPinnedVersion(manifest: RemoteVersionManifest, _ log: (String) -> Void) throws {
        guard commandExists("npm") else {
            throw SetupExecutionError.commandFailed("未找到 npm，无法更新 Hermes Web UI。")
        }
        let webUIPackage = manifest.components.hermesWebUI.package
        let webUIVersion = manifest.components.hermesWebUI.version
        try fileManager.createDirectory(atPath: webUIRuntimeHome, withIntermediateDirectories: true)
        try restrictOwnerAccess(managerHome)
        try runShell("cd \(shellQuote(webUIRuntimeHome)) && npm init -y >/dev/null 2>&1 && npm install --save-exact \(shellQuote("\(webUIPackage)@\(webUIVersion)"))", log)
        log("[OK] Hermes Web UI 已更新到开发者验证版本：\(VersionFormatting.displayVersion(webUIVersion))。")
    }

    private func installOpenHumanMemoryPlugin(_ log: (String) -> Void) throws {
        var pluginDirs = ["\(activeHermesProfileHome)/plugins/openhuman", "\(hermesHome)/plugins/openhuman"]
        pluginDirs = Array(Set(pluginDirs)).sorted()
        for pluginDir in pluginDirs {
            try writeOpenHumanMemoryPlugin(to: pluginDir)
            log("[OK] OpenHuman memory provider 插件已写入：\(compactHome(pluginDir))")
        }
    }

    private func writeOpenHumanMemoryPlugin(to pluginDir: String) throws {
        try fileManager.createDirectory(atPath: pluginDir, withIntermediateDirectories: true)
        try writeText(openHumanPluginYAML, to: "\(pluginDir)/plugin.yaml")
        try writeText(openHumanPluginInit, to: "\(pluginDir)/__init__.py")
        try writeText(openHumanAdapterPython, to: "\(pluginDir)/adapter.py")
        try writeText(openHumanPluginReadme, to: "\(pluginDir)/README.md")
    }

    private func configureOpenHumanMemory(_ log: (String) -> Void) throws {
        try initializeOpenHumanMemoryStore(log)

        let envPath = activeHermesEnvPath
        try backupIfExists(envPath, onLog: log)
        var env = readText(envPath)
        env = upsertEnvValue(in: env, key: "OPENHUMAN_VAULT", value: openHumanVault)
        env = upsertEnvValue(in: env, key: "OPENHUMAN_WORKSPACE", value: openHumanWorkspace)
        try writeText(env, to: envPath)
        try restrictOwnerAccess(envPath)

        let configPath = activeHermesConfigPath
        try backupIfExists(configPath, onLog: log)
        var config = readText(configPath)
        config = upsertNestedScalar(in: config, block: "memory", key: "provider", value: "openhuman")
        config = upsertNestedScalar(in: config, block: "memory", key: "memory_enabled", value: "false")
        config = upsertNestedScalar(in: config, block: "memory", key: "user_profile_enabled", value: "false")
        config = ensureNestedListValue(in: config, block: "agent", key: "disabled_toolsets", value: "memory")
        try writeText(config, to: configPath)
        try restrictOwnerAccess(configPath)
        log("[OK] Hermes 已配置为 OpenHuman memory provider，已关闭内置 MEMORY/USER 注入，并禁用内置 memory toolset。")
    }

    private func migrateExistingMemories(_ log: (String) -> Void) throws {
        try initializeOpenHumanMemoryStore(log)

        var imported = 0
        let stamp = timestamp()
        let importRoot = "\(openHumanVault)/Imported/Hermes/\(stamp)"
        var openHumanDocs = 0
        let profileHome = activeHermesProfileHome
        imported += try importDirectoryIfPresent(
            source: "\(profileHome)/memories",
            target: "\(importRoot)/memories",
            namespace: "hermes_migrated",
            importRoot: importRoot,
            log
        ) { openHumanDocs += 1 }
        imported += try importSelectedLongTermHermesMemoryFiles(
            sourceRoot: profileHome,
            target: "\(importRoot)/long-term",
            namespace: "hermes_migrated",
            importRoot: importRoot,
            log
        ) { openHumanDocs += 1 }
        log("[OK] 长期记忆迁移完成，共复制 \(imported) 个文件，并写入 OpenHuman 长期记忆库 \(openHumanDocs) 条；短期日志保留在 Hermes 本地，源文件未删除。")
    }

    private func verifyOpenHumanConfiguration(_ log: (String) -> Void) throws {
        let profileHome = activeHermesProfileHome
        let config = readText(activeHermesConfigPath).lowercased()
        let env = readText(activeHermesEnvPath)
        guard fileManager.fileExists(atPath: openHumanVault) else {
            throw SetupExecutionError.commandFailed("OpenHuman Vault 不存在。")
        }
        guard fileManager.fileExists(atPath: openHumanMemoryDatabasePath) else {
            throw SetupExecutionError.commandFailed("OpenHuman 长期记忆数据库不存在。")
        }
        guard yamlNestedScalarEquals(config, block: "memory", key: "provider", value: "openhuman") else {
            throw SetupExecutionError.commandFailed("Hermes config.yaml 未指向 OpenHuman memory provider。")
        }
        guard yamlScalarIsFalse(config, key: "memory_enabled"),
              yamlScalarIsFalse(config, key: "user_profile_enabled") else {
            throw SetupExecutionError.commandFailed("Hermes config.yaml 未关闭内置 MEMORY/USER 记忆配置。")
        }
        guard yamlListContains(config, block: "agent", key: "disabled_toolsets", value: "memory") else {
            throw SetupExecutionError.commandFailed("Hermes config.yaml 未禁用内置 memory toolset，provider memory 工具可能被内置工具遮蔽。")
        }
        guard env.contains("OPENHUMAN_VAULT=") else {
            throw SetupExecutionError.commandFailed("Hermes .env 未设置 OPENHUMAN_VAULT。")
        }
        guard env.contains("OPENHUMAN_WORKSPACE=") else {
            throw SetupExecutionError.commandFailed("Hermes .env 未设置 OPENHUMAN_WORKSPACE。")
        }
        let pluginPaths = [
            "\(profileHome)/plugins/openhuman/plugin.yaml",
            "\(profileHome)/plugins/memory/openhuman/plugin.yaml",
            "\(hermesHome)/plugins/openhuman/plugin.yaml",
            "\(hermesHome)/plugins/memory/openhuman/plugin.yaml",
        ]
        guard pluginPaths.contains(where: { fileManager.fileExists(atPath: $0) }) else {
            throw SetupExecutionError.commandFailed("OpenHuman memory provider 插件不存在。")
        }
        log("[OK] 验证通过：Hermes memory provider = openhuman，内置 memory 工具已禁用，OpenHuman SQLite 记忆库和插件已配置。")
    }

    private func verifyMemoryMigrationState(_ log: (String) -> Void, requireMigration: Bool = true) throws {
        let hermesLegacyCount = countLongTermHermesMemoryFiles()

        let hermesImported = countMemoryFiles(in: "\(openHumanVault)/Imported/Hermes")
        let openHumanImported = countOpenHumanDocuments(namespace: "hermes_migrated")

        if requireMigration && hermesLegacyCount > 0 && hermesImported == 0 && openHumanImported == 0 {
            throw SetupExecutionError.commandFailed("检测到 Hermes 长期记忆，但 OpenHuman 中没有 Hermes 长期记忆迁移记录。")
        }

        if hermesLegacyCount == 0 {
            log("[OK] 未检测到需要迁移的 Hermes 长期记忆；短期日志会保留在本地。")
        } else if !requireMigration && hermesImported == 0 && openHumanImported == 0 {
            log("[WARN] 检测到 Hermes 长期记忆但本次已跳过迁移；之后 Hermes 会只使用 OpenHuman 作为长期记忆后端。")
        } else {
            log("[OK] 长期记忆迁移检查通过：Hermes 长期记忆源 \(hermesLegacyCount) 个，OpenHuman 文档 \(openHumanImported) 条。")
        }
    }

    private func startWebUIAndOpenBrowser(_ log: (String) -> Void) throws {
        if let command = webUICommand() {
            try runShell("\(command) start", log)
        } else {
            throw SetupExecutionError.commandFailed("未找到 hermes-web-ui 命令，无法自动启动。")
        }
        guard waitForWebUIReady(log) else {
            throw SetupExecutionError.commandFailed("Hermes Web UI 启动命令已执行，但本地服务未在预期时间内就绪。")
        }
        let webURL = resolveWebUIURL()
        if let url = URL(string: webURL) {
            NSWorkspace.shared.open(url)
        }
        log("[OK] Hermes Web UI 已就绪并打开：\(webURL)")
    }

    private func waitForWebUIReady(_ log: (String) -> Void, timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        var lastStatus = ""
        while Date() < deadline {
            if isWebUIRunning(log, lastStatus: &lastStatus) {
                return true
            }
            Thread.sleep(forTimeInterval: 1)
        }
        if !lastStatus.isEmpty {
            log("[WARN] Web UI 状态检测未通过：\(redactSensitiveContent(lastStatus).text)")
        }
        return false
    }

    private func isWebUIRunning(_ log: (String) -> Void, lastStatus: inout String) -> Bool {
        guard let command = webUICommand() else { return false }
        guard let output = try? runShell("\(command) status", { _ in }) else { return false }
        lastStatus = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = output.lowercased()
        if lower.contains("is not running") || lower.contains("not running") {
            return false
        }
        return lower.contains("is running") || lower.contains("running (pid")
    }

    private func downloadInstaller(url: String, name: String, _ log: (String) -> Void) throws -> String {
        let directory = "\(managerHome)/installers"
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try restrictOwnerAccess(directory)
        let path = "\(directory)/\(timestamp())-\(name)"
        log("[INFO] 正在下载安装脚本：\(url)")
        try runShell("curl -fsSL \(shellQuote(url)) -o \(shellQuote(path))", log)
        try restrictOwnerAccess(path)
        log("[OK] 安装脚本已下载到 Hermes Manager 私有目录，随后执行本地副本。")
        return path
    }

    private func backupAndMoveSelectedData(options: SetupExecutionOptions, _ log: (String) -> Void) throws {
        try fileManager.createDirectory(atPath: backupRoot, withIntermediateDirectories: true)
        if options.clearHermes {
            try moveIfExists(hermesHome, to: "\(backupRoot)/.hermes", log)
        }
        if options.clearOpenHuman {
            try moveIfExists(openHumanHome, to: "\(backupRoot)/.openhuman", log)
        }
        log("[OK] 选中数据已移动到备份目录：~/.hermes-manager/backups/\(URL(fileURLWithPath: backupRoot).lastPathComponent)")
    }

    private func moveIfExists(_ path: String, to target: String, _ log: (String) -> Void) throws {
        guard fileManager.fileExists(atPath: path) else { return }
        try fileManager.createDirectory(atPath: URL(fileURLWithPath: target).deletingLastPathComponent().path, withIntermediateDirectories: true)
        try fileManager.moveItem(atPath: path, toPath: target)
        log("[INFO] 已备份并移走 \(compactHome(path))")
    }

    private func importSelectedLongTermHermesMemoryFiles(
        sourceRoot: String,
        target: String,
        namespace: String,
        importRoot: String,
        _ log: (String) -> Void,
        onOpenHumanDocument: () -> Void
    ) throws -> Int {
        var count = 0
        count += try importSelectedTopLevelHermesNotes(
            sourceRoot: sourceRoot,
            target: "\(target)/root",
            namespace: namespace,
            importRoot: importRoot,
            log,
            onOpenHumanDocument: onOpenHumanDocument
        )
        count += try importPersonalModelFiles(
            sourceRoot: "\(sourceRoot)/memory",
            target: "\(target)/personal-models",
            namespace: namespace,
            importRoot: importRoot,
            log,
            onOpenHumanDocument: onOpenHumanDocument
        )
        return count
    }

    private func importSelectedTopLevelHermesNotes(
        sourceRoot: String,
        target: String,
        namespace: String,
        importRoot: String,
        _ log: (String) -> Void,
        onOpenHumanDocument: () -> Void
    ) throws -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: sourceRoot) else { return 0 }
        var count = 0
        for entry in entries where isLongTermTopLevelHermesNote(entry) {
            let source = "\(sourceRoot)/\(entry)"
            if shouldSkipMigration(path: source) { continue }
            let copied = try copyMigratedFile(source: source, target: "\(target)/\(entry)", log)
            try ingestMigratedOpenHumanDocument(
                source: source,
                copiedPath: copied,
                importRoot: importRoot,
                namespace: namespace,
                title: entry,
                log
            )
            onOpenHumanDocument()
            count += 1
        }
        return count
    }

    private func importPersonalModelFiles(
        sourceRoot: String,
        target: String,
        namespace: String,
        importRoot: String,
        _ log: (String) -> Void,
        onOpenHumanDocument: () -> Void
    ) throws -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: sourceRoot) else { return 0 }
        var count = 0
        for entry in entries where isLongTermMemoryDirectoryFile(entry) {
            let source = "\(sourceRoot)/\(entry)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: source, isDirectory: &isDirectory)
            if isDirectory.boolValue || shouldSkipMigration(path: source) { continue }
            let copied = try copyMigratedFile(source: source, target: "\(target)/\(entry)", log)
            try ingestMigratedOpenHumanDocument(
                source: source,
                copiedPath: copied,
                importRoot: importRoot,
                namespace: namespace,
                title: entry,
                log
            )
            onOpenHumanDocument()
            count += 1
        }
        if count > 0 {
            try writeMigrationManifest(targetRoot: target, copiedCount: count)
            log("[INFO] 已导入 \(count) 个长期画像文件：\(compactHome(target))")
        }
        return count
    }

    private func importDirectoryIfPresent(
        source: String,
        target: String,
        namespace: String,
        importRoot: String,
        _ log: (String) -> Void,
        onOpenHumanDocument: () -> Void
    ) throws -> Int {
        guard fileManager.fileExists(atPath: source) else { return 0 }
        var copied = 0
        guard let enumerator = fileManager.enumerator(atPath: source) else { return 0 }
        while let item = enumerator.nextObject() as? String {
            let sourcePath = "\(source)/\(item)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: sourcePath, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                if shouldSkipMigration(path: sourcePath) { enumerator.skipDescendants() }
                continue
            }
            guard shouldCopyMemoryFile(path: sourcePath), !shouldSkipMigration(path: sourcePath) else { continue }
            let copiedPath = try copyMigratedFile(source: sourcePath, target: "\(target)/\(item)", log)
            try ingestMigratedOpenHumanDocument(
                source: sourcePath,
                copiedPath: copiedPath,
                importRoot: importRoot,
                namespace: namespace,
                title: URL(fileURLWithPath: item).lastPathComponent,
                log
            )
            onOpenHumanDocument()
            copied += 1
        }
        if copied > 0 {
            try writeMigrationManifest(targetRoot: target, copiedCount: copied)
            log("[INFO] 已导入 \(copied) 个文件：\(compactHome(target))")
        }
        return copied
    }

    @discardableResult
    private func copyMigratedFile(source: String, target: String, _ log: (String) -> Void) throws -> String {
        let finalTarget = nonDestructiveTargetPath(target)
        try fileManager.createDirectory(atPath: URL(fileURLWithPath: finalTarget).deletingLastPathComponent().path, withIntermediateDirectories: true)
        if shouldCopyAsText(path: source),
           let text = try? String(contentsOfFile: source, encoding: .utf8) {
            try writeText(text, to: finalTarget)
        } else {
            try fileManager.copyItem(atPath: source, toPath: finalTarget)
        }
        return finalTarget
    }

    private func nonDestructiveTargetPath(_ path: String) -> String {
        guard fileManager.fileExists(atPath: path) else { return path }
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var index = 2
        while true {
            let name = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            let candidate = directory.appendingPathComponent(name).path
            if !fileManager.fileExists(atPath: candidate) {
                return candidate
            }
            index += 1
        }
    }

    private func writeMigrationManifest(targetRoot: String, copiedCount: Int) throws {
        let manifest = """
        # Migration Manifest

        - created_at: \(timestamp())
        - copied_files: \(copiedCount)
        - source_policy: source files are copied, never deleted
        - secret_policy: token/auth/key files are skipped by filename
        """
        try writeText(manifest, to: "\(targetRoot)/migration-manifest.md")
    }

    private func shouldCopyMemoryFile(path: String) -> Bool {
        let lower = path.lowercased()
        return lower.hasSuffix(".md")
            || lower.hasSuffix(".json")
            || lower.hasSuffix(".jsonl")
            || lower.hasSuffix(".txt")
            || lower.hasSuffix(".yaml")
            || lower.hasSuffix(".yml")
            || lower.hasSuffix(".toml")
    }

    private func countLongTermHermesMemoryFiles() -> Int {
        let profileHome = activeHermesProfileHome
        return countMemoryFiles(in: "\(profileHome)/memories")
            + countSelectedTopLevelHermesNotes(in: profileHome)
            + countPersonalModelFiles(in: "\(profileHome)/memory")
    }

    private func countSelectedTopLevelHermesNotes(in root: String) -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = "\(root)/\(entry)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermTopLevelHermesNote(entry), !shouldSkipMigration(path: path) else {
                return partial
            }
            return partial + 1
        }
    }

    private func countPersonalModelFiles(in root: String) -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = "\(root)/\(entry)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermMemoryDirectoryFile(entry), !shouldSkipMigration(path: path) else {
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

    private func shouldCopyAsText(path: String) -> Bool {
        shouldCopyMemoryFile(path: path)
    }

    private func shouldSkipMigration(path: String) -> Bool {
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

    private func redactSensitiveContent(_ text: String) -> (text: String, count: Int) {
        var output = text
        var count = 0
        let patterns = [
            #"(?i)(api[_-]?key|apikey|access[_-]?token|refresh[_-]?token|auth[_-]?token|bearer|secret|client[_-]?secret|password|cookie)\s*[:=]\s*["']?[^"'\s,}]{8,}"#,
            #"sk-[A-Za-z0-9_\-]{16,}"#,
            #"(?i)bearer\s+[A-Za-z0-9_\-\.]{20,}"#,
            #"(?i)(feishu|lark|slack|github|openai|anthropic)[A-Za-z0-9_\-]{16,}"#,
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(output.startIndex..<output.endIndex, in: output)
            let matches = regex.numberOfMatches(in: output, range: range)
            if matches > 0 {
                output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: "[REDACTED_BY_HERMES_MANAGER]")
                count += matches
            }
        }
        return (output, count)
    }

    private func countMemoryFiles(in root: String) -> Int {
        guard fileManager.fileExists(atPath: root),
              let enumerator = fileManager.enumerator(atPath: root) else {
            return 0
        }
        var count = 0
        while let item = enumerator.nextObject() as? String {
            let path = "\(root)/\(item)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            if isDirectory.boolValue {
                if shouldSkipMigration(path: path) { enumerator.skipDescendants() }
                continue
            }
            if shouldCopyMemoryFile(path: path), !shouldSkipMigration(path: path) {
                count += 1
            }
        }
        return count
    }

    private func countTopLevelMemoryNotes(in root: String) -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = "\(root)/\(entry)"
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, entry.lowercased().hasSuffix(".md"), !shouldSkipMigration(path: path) else {
                return partial
            }
            return partial + 1
        }
    }

    private var openHumanMemoryDatabasePath: String {
        "\(openHumanWorkspace)/memory/memory.db"
    }

    private func initializeOpenHumanMemoryStore(_ log: (String) -> Void) throws {
        try fileManager.createDirectory(atPath: "\(openHumanWorkspace)/memory/namespaces", withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: "\(openHumanWorkspace)/memory_tree", withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: "\(openHumanWorkspace)/wiki", withIntermediateDirectories: true)
        try restrictOwnerAccess(openHumanHome)

        let script = openHumanStoreBootstrapPython
        _ = try runPythonScript(script, "", log)
    }

    private func ingestMigratedOpenHumanDocument(
        source: String,
        copiedPath: String,
        importRoot: String,
        namespace: String,
        title: String,
        _ log: (String) -> Void
    ) throws {
        guard let content = try? String(contentsOfFile: copiedPath, encoding: .utf8) else { return }
        let relativeSource = relativePath(source, base: hermesHome) ?? URL(fileURLWithPath: source).lastPathComponent
        let relativeCopy = relativePath(copiedPath, base: importRoot) ?? URL(fileURLWithPath: copiedPath).lastPathComponent
        let key = "migration/\(sanitizeMemoryKey(relativeSource))"
        let metadata: [String: Any] = [
            "source": "hermes_migration",
            "source_path": relativeSource,
            "imported_copy": "Imported/Hermes/\(URL(fileURLWithPath: importRoot).lastPathComponent)/\(relativeCopy)",
            "source_kind": "hermes_long_term",
        ]
        try upsertOpenHumanDocument(
            namespace: namespace,
            key: key,
            title: title,
            content: content,
            sourceType: "hermes_migration",
            priority: "high",
            tags: ["hermes", "migration", "long_term"],
            metadata: metadata,
            category: "long_term",
            sessionID: "hermes-manager-migration"
        )
        log("[INFO] 已写入 OpenHuman 长期记忆库：\(relativeSource)")
    }

    private func upsertOpenHumanDocument(
        namespace: String,
        key: String,
        title: String,
        content: String,
        sourceType: String,
        priority: String,
        tags: [String],
        metadata: [String: Any],
        category: String,
        sessionID: String
    ) throws {
        let payload: [String: Any] = [
            "workspace": openHumanWorkspace,
            "namespace": namespace,
            "key": key,
            "title": title,
            "content": content,
            "source_type": sourceType,
            "priority": priority,
            "tags": tags,
            "metadata": metadata,
            "category": category,
            "session_id": sessionID,
        ]
        let json = String(data: try JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8) ?? "{}"
        _ = try runPythonScript(openHumanDocumentUpsertPython, json, { _ in })
    }

    private func countOpenHumanDocuments(namespace: String) -> Int {
        if let count = countOpenHumanDocumentsWithSQLite(namespace: namespace) {
            return count
        }
        let payload = #"{"workspace": "\#(jsonEscaped(openHumanWorkspace))", "namespace": "\#(jsonEscaped(namespace))"}"#
        guard let output = try? runPythonScript(openHumanDocumentCountPython, payload, { _ in }),
              let count = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return 0
        }
        return count
    }

    private func countOpenHumanDocumentsWithSQLite(namespace: String) -> Int? {
        guard fileManager.fileExists(atPath: openHumanMemoryDatabasePath) else { return nil }
        let sql: String
        if namespace.isEmpty {
            sql = "SELECT COUNT(*) FROM memory_docs;"
        } else {
            sql = "SELECT COUNT(*) FROM memory_docs WHERE namespace = '\(namespace.replacingOccurrences(of: "'", with: "''"))';"
        }
        let task = Process()
        let output = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["sqlite3", openHumanMemoryDatabasePath, sql]
        task.standardOutput = output
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return Int(text)
        } catch {
            return nil
        }
    }

    @discardableResult
    private func runPythonScript(_ script: String, _ stdin: String = "", _ log: (String) -> Void) throws -> String {
        let task = Process()
        let input = Pipe()
        let output = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["python3", "-c", script]
        task.environment = shellEnvironment
        task.standardInput = input
        task.standardOutput = output
        task.standardError = output
        try task.run()
        if !stdin.isEmpty, let data = stdin.data(using: .utf8) {
            input.fileHandleForWriting.write(data)
        }
        input.fileHandleForWriting.closeFile()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        task.waitUntilExit()
        if task.terminationStatus != 0 {
            throw SetupExecutionError.commandFailed(redactSensitiveContent(text).text)
        }
        for line in text.split(separator: "\n").suffix(20) {
            log("[CMD] \(redactSensitiveContent(String(line)).text)")
        }
        return text
    }

    private func relativePath(_ path: String, base: String) -> String? {
        let baseURL = URL(fileURLWithPath: base).standardizedFileURL
        let pathURL = URL(fileURLWithPath: path).standardizedFileURL
        let baseComponents = baseURL.pathComponents
        let pathComponents = pathURL.pathComponents
        guard pathComponents.count >= baseComponents.count,
              Array(pathComponents.prefix(baseComponents.count)) == baseComponents else {
            return nil
        }
        return pathComponents.dropFirst(baseComponents.count).joined(separator: "/")
    }

    private func sanitizeMemoryKey(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_./"))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let key = String(scalars).replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        return key.trimmingCharacters(in: CharacterSet(charactersIn: "-/")).isEmpty ? "memory" : key
    }

    @discardableResult
    private func runShell(_ command: String, _ log: (String) -> Void) throws -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", pathExport + command]
        task.environment = shellEnvironment
        task.standardOutput = pipe
        task.standardError = pipe
        try task.run()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        task.waitUntilExit()
        for line in output.split(separator: "\n").suffix(40) {
            log("[CMD] \(redactSensitiveContent(String(line)).text)")
        }
        if task.terminationStatus != 0 {
            let safeOutput = redactSensitiveContent(output).text
            throw SetupExecutionError.commandFailed(safeOutput.isEmpty ? "命令失败：\(command)" : safeOutput)
        }
        return output
    }

    private var pathExport: String {
        "export PATH=\"\(shellDoubleQuote(webUIRuntimeHome))/node_modules/.bin:/opt/homebrew/bin:/usr/local/bin:\(shellDoubleQuote(home))/.local/bin:\(shellDoubleQuote(home))/.cargo/bin:$PATH\"; "
    }

    private var shellEnvironment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = home
        env["HERMES_HOME"] = hermesHome
        env["OPENHUMAN_VAULT"] = openHumanVault
        env["OPENHUMAN_WORKSPACE"] = openHumanWorkspace
        env["HERMES_WEB_UI_HOME"] = resolveWebUIHome()
        return env
    }

    private var privateWebUIExecutable: String {
        "\(webUIRuntimeHome)/node_modules/.bin/hermes-web-ui"
    }

    private func webUICommandAvailable() -> Bool {
        webUICommand() != nil
    }

    private func webUICommand() -> String? {
        if fileManager.fileExists(atPath: privateWebUIExecutable) {
            return shellQuote(privateWebUIExecutable)
        }
        if commandExists("hermes-web-ui") {
            return "hermes-web-ui"
        }
        return nil
    }

    private func commandExists(_ command: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "\(pathExport) command -v \(command) >/dev/null 2>&1"]
        task.environment = shellEnvironment
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func hermesLooksInstalled() -> Bool {
        commandExists("hermes")
            || fileManager.fileExists(atPath: hermesHome)
            || fileManager.fileExists(atPath: "\(hermesHome)/hermes-agent")
            || fileManager.fileExists(atPath: "\(hermesHome)/config.yaml")
    }

    private func openHumanLooksInstalled() -> Bool {
        commandExists("openhuman")
            || fileManager.fileExists(atPath: openHumanHome)
            || fileManager.fileExists(atPath: openHumanVault)
    }

    private func backupIfExists(_ path: String, onLog log: (String) -> Void) throws {
        guard fileManager.fileExists(atPath: path) else { return }
        try fileManager.createDirectory(atPath: backupRoot, withIntermediateDirectories: true)
        try restrictOwnerAccess(backupRoot)
        let target = "\(backupRoot)/\(URL(fileURLWithPath: path).lastPathComponent).bak"
        if fileManager.fileExists(atPath: target) { try fileManager.removeItem(atPath: target) }
        try fileManager.copyItem(atPath: path, toPath: target)
        try restrictOwnerAccess(target)
        log("[INFO] 已备份 \(compactHome(path))")
    }

    private func readText(_ path: String) -> String {
        (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
    }

    private func writeText(_ text: String, to path: String) throws {
        try fileManager.createDirectory(atPath: URL(fileURLWithPath: path).deletingLastPathComponent().path, withIntermediateDirectories: true)
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func upsertEnvValue(in text: String, key: String, value: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        let replacement = "\(key)=\(envFileValue(value))"
        var replaced = false
        for index in lines.indices {
            if lines[index].hasPrefix("\(key)=") || lines[index].hasPrefix("#\(key)=") {
                lines[index] = replacement
                replaced = true
            }
        }
        if !replaced {
            if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
            lines.append("# Hermes Manager")
            lines.append(replacement)
        }
        return lines.joined(separator: "\n")
    }

    private func envFileValue(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }

    private func upsertNestedScalar(in text: String, block blockName: String, key: String, value: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        if lines == [""] { lines = [] }

        guard let blockStart = lines.firstIndex(where: { $0 == "\(blockName):" }) else {
            if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
            lines.append("\(blockName):")
            lines.append("  \(key): \(value)")
            return lines.joined(separator: "\n")
        }

        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            blockEnd += 1
        }

        if let keyIndex = lines[blockStart..<blockEnd].firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(key):")
        }) {
            lines[keyIndex] = "  \(key): \(value)"
        } else {
            lines.insert("  \(key): \(value)", at: blockEnd)
        }

        return lines.joined(separator: "\n")
    }

    private func ensureNestedListValue(in text: String, block blockName: String, key: String, value: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        if lines == [""] { lines = [] }

        guard let blockStart = lines.firstIndex(where: { $0 == "\(blockName):" }) else {
            if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
            lines.append("\(blockName):")
            lines.append("  \(key):")
            lines.append("    - \(value)")
            return lines.joined(separator: "\n")
        }

        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            blockEnd += 1
        }

        if let keyIndex = lines[blockStart..<blockEnd].firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(key):")
        }) {
            let trimmed = lines[keyIndex].trimmingCharacters(in: .whitespaces)
            if trimmed == "\(key): []" {
                lines[keyIndex] = "  \(key):"
                lines.insert("    - \(value)", at: keyIndex + 1)
                return lines.joined(separator: "\n")
            }
            if trimmed == "\(key): [\(value)]" || trimmed == "\(key): [\"\(value)\"]" || trimmed == "\(key): ['\(value)']" {
                return lines.joined(separator: "\n")
            }
            if trimmed.hasPrefix("\(key): [") {
                let prefix = "  \(key): ["
                let suffix = trimmed.hasSuffix("]") ? "]" : ""
                if trimmed.contains(value) { return lines.joined(separator: "\n") }
                let current = trimmed
                    .replacingOccurrences(of: "\(key): [", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                let next = current.isEmpty ? value : "\(current), \(value)"
                lines[keyIndex] = "\(prefix)\(next)\(suffix)"
                return lines.joined(separator: "\n")
            }

            var listEnd = keyIndex + 1
            var found = false
            while listEnd < blockEnd {
                let line = lines[listEnd]
                let trimmedItem = line.trimmingCharacters(in: .whitespaces)
                if !line.isEmpty && !line.hasPrefix("    ") && !line.hasPrefix("\t") && trimmedItem.hasSuffix(":") {
                    break
                }
                if trimmedItem == "- \(value)" || trimmedItem == "- \"\(value)\"" || trimmedItem == "- '\(value)'" {
                    found = true
                }
                listEnd += 1
            }
            if !found {
                lines.insert("    - \(value)", at: listEnd)
            }
        } else {
            lines.insert(contentsOf: ["  \(key):", "    - \(value)"], at: blockEnd)
        }

        return lines.joined(separator: "\n")
    }

    private func upsertTopLevelBlock(named name: String, in text: String, replacement: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        if lines == [""] { lines = [] }
        guard let start = lines.firstIndex(where: { $0 == "\(name):" }) else {
            if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
            lines.append(contentsOf: replacement.components(separatedBy: .newlines))
            return lines.joined(separator: "\n")
        }
        var end = start + 1
        while end < lines.count {
            let line = lines[end]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            end += 1
        }
        lines.replaceSubrange(start..<end, with: replacement.components(separatedBy: .newlines))
        return lines.joined(separator: "\n")
    }

    private func upsertCustomProvider(
        in text: String,
        providerKey: String,
        providerName: String,
        baseURL: String,
        apiKey: String,
        keyEnv: String,
        defaultModel: String,
        models: [String],
        apiMode: String,
        contextLength: Int
    ) -> String {
        let modelCatalog = normalizedModelList([defaultModel] + models)
        let providerBlocks = modelCatalog.map { model in
            customProviderBlock(
                providerName: providerName,
                baseURL: baseURL,
                apiKey: apiKey,
                keyEnv: keyEnv,
                model: model,
                models: modelCatalog,
                apiMode: apiMode,
                contextLength: contextLength
            )
        }.joined(separator: "\n")
        var lines = text.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0 == "custom_providers:" }) else {
            if !lines.isEmpty && !lines.last!.isEmpty { lines.append("") }
            lines.append("custom_providers:")
            lines.append(contentsOf: providerBlocks.components(separatedBy: .newlines))
            return lines.joined(separator: "\n")
        }

        var end = start + 1
        while end < lines.count {
            let line = lines[end]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            end += 1
        }

        var block = removeCustomProviderItems(from: Array(lines[start..<end]), providerKey: providerKey, providerName: providerName)
        block.append(contentsOf: providerBlocks.components(separatedBy: .newlines))
        lines.replaceSubrange(start..<end, with: block)
        return lines.joined(separator: "\n")
    }

    private func customProviderBlock(
        providerName: String,
        baseURL: String,
        apiKey: String,
        keyEnv: String,
        model: String,
        models: [String],
        apiMode: String,
        contextLength: Int
    ) -> String {
        let modelLines = normalizedModelList(models).flatMap { model in
            [
                "      \(yamlQuote(model)):",
                "        context_length: \(contextLength)",
            ]
        }
        return ([
            "  - name: \(yamlQuote(providerName))",
            "    base_url: \(yamlQuote(baseURL))",
            "    key_env: \(yamlQuote(keyEnv))",
            "    api_key: \(yamlQuote(apiKey))",
            "    model: \(yamlQuote(model))",
            "    api_mode: \(apiMode)",
            "    models:",
        ] + modelLines).joined(separator: "\n")
    }

    private func customProviderItemStart(in block: [String], providerKey: String, providerName: String) -> Int? {
        for (index, line) in block.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- name:") else { continue }
            let name = yamlValue(from: trimmed.replacingOccurrences(of: "- ", with: ""))
            let key = customProviderKey(forName: name)
            if name == providerName || key == providerKey {
                return index
            }
        }
        return nil
    }

    private func removeCustomProviderItems(from block: [String], providerKey: String, providerName: String) -> [String] {
        var output: [String] = []
        var index = 0
        while index < block.count {
            let trimmed = block[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- name:") else {
                output.append(block[index])
                index += 1
                continue
            }
            var itemEnd = index + 1
            while itemEnd < block.count {
                if block[itemEnd].trimmingCharacters(in: .whitespaces).hasPrefix("- name:") { break }
                itemEnd += 1
            }
            let name = yamlValue(from: trimmed.replacingOccurrences(of: "- ", with: ""))
            let key = customProviderKey(forName: name)
            if name != providerName && key != providerKey {
                output.append(contentsOf: block[index..<itemEnd])
            }
            index = itemEnd
        }
        return output
    }

    private func removeCustomProviderFromConfig(_ text: String, providerKey: String, providerName: String) -> String {
        var lines = text.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0 == "custom_providers:" }) else {
            return text
        }

        var end = start + 1
        while end < lines.count {
            let line = lines[end]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            end += 1
        }

        let block = removeCustomProviderItems(from: Array(lines[start..<end]), providerKey: providerKey, providerName: providerName)
        if block.count == 1, block.first == "custom_providers:" {
            if start > 0, lines[start - 1].isEmpty {
                lines.removeSubrange((start - 1)..<end)
            } else {
                lines.removeSubrange(start..<end)
            }
        } else {
            lines.replaceSubrange(start..<end, with: block)
        }
        return lines.joined(separator: "\n")
    }

    private func updateWebUIModelVisibility(providerKey: String, modelNames: [String], defaultModel: String) throws {
        let dataDirectory = resolveWebUIHome()
        try fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        let path = "\(dataDirectory)/config.json"
        var root: [String: Any] = [:]
        if let data = fileManager.contents(atPath: path),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            root = json
        }
        var visibility = root["modelVisibility"] as? [String: Any] ?? [:]
        visibility[providerKey] = ["mode": "include", "models": normalizedModelList(modelNames)]
        root["modelVisibility"] = visibility
        root["selectedProvider"] = providerKey
        root["currentProvider"] = providerKey
        root["defaultProvider"] = providerKey
        root["selectedModel"] = defaultModel
        root["currentModel"] = defaultModel
        root["defaultModel"] = defaultModel
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        try restrictOwnerAccess(path)
    }

    private func removeProviderFromWebUI(providerKey: String, onLog log: (String) -> Void) throws {
        let dataDirectory = resolveWebUIHome()
        try fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        let path = "\(dataDirectory)/config.json"
        if let data = fileManager.contents(atPath: path),
           var root = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) {
            var visibility = root["modelVisibility"] as? [String: Any] ?? [:]
            visibility.removeValue(forKey: providerKey)
            root["modelVisibility"] = visibility
            for key in ["selectedProvider", "currentProvider", "defaultProvider"] {
                if (root[key] as? String) == providerKey {
                    root[key] = ""
                }
            }
            for key in ["selectedModel", "currentModel", "defaultModel"] {
                if root[key] != nil {
                    root[key] = ""
                }
            }
            let next = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try next.write(to: URL(fileURLWithPath: path), options: .atomic)
            try restrictOwnerAccess(path)
            log("[OK] 已从 Hermes Web UI config.json 移除 Provider：\(providerKey)")
        }

        let dbPath = "\(dataDirectory)/hermes-web-ui.db"
        if fileManager.fileExists(atPath: dbPath) {
            let sql = "DELETE FROM model_context WHERE provider = '\(providerKey.replacingOccurrences(of: "'", with: "''"))';"
            _ = try runShell("sqlite3 \(shellQuote(dbPath)) \(shellQuote(sql))", log)
            try restrictOwnerAccess(dbPath)
            log("[OK] 已从 Hermes Web UI model_context 删除 Provider：\(providerKey)")
        }
    }

    private func updateWebUIModelContextDatabase(
        providerKey: String,
        modelNames: [String],
        contextLength: Int,
        onLog log: (String) -> Void
    ) throws {
        let dataDirectory = resolveWebUIHome()
        try fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true)
        let dbPath = "\(dataDirectory)/hermes-web-ui.db"
        let dbExisted = fileManager.fileExists(atPath: dbPath)

        let payload: [String: Any] = [
            "db_path": dbPath,
            "provider": providerKey,
            "models": normalizedModelList(modelNames),
            "context_length": max(contextLength, 8192),
        ]
        let json = String(data: try JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8) ?? "{}"
        _ = try runPythonScript(webUIModelContextUpsertPython, json, { _ in })
        try restrictOwnerAccess(dbPath)
        if !dbExisted {
            log("[OK] Hermes Web UI 数据库不存在，已创建并写入模型上下文。")
        }
        log("[OK] 已同步 Hermes Web UI 模型数据库：\(providerKey) / \(normalizedModelList(modelNames).count) 个模型")
    }

    private func pruneWebUIModelContextDatabase(
        providerKey: String,
        allowedModels: [String],
        onLog log: (String) -> Void
    ) throws {
        let dataDirectory = resolveWebUIHome()
        let dbPath = "\(dataDirectory)/hermes-web-ui.db"
        guard fileManager.fileExists(atPath: dbPath) else { return }

        let payload: [String: Any] = [
            "db_path": dbPath,
            "provider": providerKey,
            "models": normalizedModelList(allowedModels),
        ]
        let json = String(data: try JSONSerialization.data(withJSONObject: payload, options: []), encoding: .utf8) ?? "{}"
        _ = try runPythonScript(webUIModelContextPrunePython, json, { _ in })
        try restrictOwnerAccess(dbPath)
        log("[OK] 已修剪 Hermes Web UI 模型数据库，仅保留可见模型：\(providerKey)")
    }

    private func writeProviderEnvIfKnown(providerKey: String, baseURL: String, apiKey: String, onLog log: (String) -> Void) throws {
        let envMapping: [String: (apiKeys: [String], baseURLKeys: [String])] = [
            "openrouter": (["OPENROUTER_API_KEY"], ["OPENROUTER_BASE_URL"]),
            "zai": (["GLM_API_KEY", "ZAI_API_KEY", "Z_AI_API_KEY"], ["GLM_BASE_URL"]),
            "kimi-coding": (["KIMI_API_KEY", "KIMI_CODING_API_KEY"], ["KIMI_BASE_URL"]),
            "kimi-coding-cn": (["KIMI_CN_API_KEY"], []),
            "moonshot": (["MOONSHOT_API_KEY", "KIMI_API_KEY"], ["KIMI_BASE_URL"]),
            "minimax": (["MINIMAX_API_KEY"], ["MINIMAX_BASE_URL"]),
            "minimax-cn": (["MINIMAX_CN_API_KEY"], ["MINIMAX_CN_BASE_URL"]),
            "deepseek": (["DEEPSEEK_API_KEY"], ["DEEPSEEK_BASE_URL"]),
            "alibaba": (["DASHSCOPE_API_KEY"], ["DASHSCOPE_BASE_URL"]),
            "alibaba-coding-plan": (["ALIBABA_CODING_PLAN_API_KEY", "DASHSCOPE_API_KEY"], ["ALIBABA_CODING_PLAN_BASE_URL"]),
            "anthropic": (["ANTHROPIC_API_KEY"], ["ANTHROPIC_BASE_URL"]),
            "xai": (["XAI_API_KEY"], ["XAI_BASE_URL"]),
            "xiaomi": (["XIAOMI_API_KEY"], ["XIAOMI_BASE_URL"]),
            "xiaomi-token-plan": (["XIAOMI_API_KEY"], ["XIAOMI_BASE_URL"]),
            "gemini": (["GOOGLE_API_KEY", "GEMINI_API_KEY"], ["GEMINI_BASE_URL"]),
            "kilocode": (["KILOCODE_API_KEY", "KILO_API_KEY"], ["KILOCODE_BASE_URL"]),
            "ai-gateway": (["AI_GATEWAY_API_KEY"], ["AI_GATEWAY_BASE_URL"]),
            "opencode-zen": (["OPENCODE_ZEN_API_KEY", "OPENCODE_API_KEY"], ["OPENCODE_ZEN_BASE_URL"]),
            "opencode-go": (["OPENCODE_GO_API_KEY", "OPENCODE_API_KEY"], ["OPENCODE_GO_BASE_URL"]),
            "huggingface": (["HF_TOKEN"], ["HF_BASE_URL"]),
            "arcee": (["ARCEEAI_API_KEY", "ARCEE_API_KEY"], ["ARCEE_BASE_URL"]),
            "longcat": (["LONGCAT_API_KEY"], ["LONGCAT_BASE_URL"]),
            "nous": (["NOUS_API_KEY"], ["NOUS_BASE_URL"]),
            "stepfun": (["STEPFUN_API_KEY"], ["STEPFUN_BASE_URL"]),
            "ollama-cloud": (["OLLAMA_API_KEY"], ["OLLAMA_BASE_URL"]),
        ]
        guard let mapping = envMapping[providerKey] else {
            return
        }

        try writeProviderEnv(keys: mapping.apiKeys, baseURLKeys: mapping.baseURLKeys, baseURL: baseURL, apiKey: apiKey, onLog: log)
    }

    private func writeProviderEnv(keys: [String], baseURLKeys: [String], baseURL: String, apiKey: String, onLog log: (String) -> Void) throws {
        let apiKeys = keys.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let baseKeys = baseURLKeys.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !apiKeys.isEmpty || !baseKeys.isEmpty else { return }

        let envPath = activeHermesEnvPath
        try backupIfExists(envPath, onLog: log)
        var env = readText(envPath)
        for key in apiKeys {
            env = upsertEnvValue(in: env, key: key, value: apiKey)
        }
        for key in baseKeys {
            env = upsertEnvValue(in: env, key: key, value: baseURL)
        }
        try writeText(env, to: envPath)
        try restrictOwnerAccess(envPath)
        let written = (apiKeys + baseKeys).joined(separator: ", ")
        log("[OK] 已写入 Provider 环境变量：\(written)")
    }

    private func normalizedModelList(_ models: [String]) -> [String] {
        var seen = Set<String>()
        var normalized: [String] = []
        for model in models {
            let clean = model.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, seen.insert(clean).inserted else { continue }
            normalized.append(clean)
        }
        return normalized
    }

    private func normalizedProviderKey(_ value: String, label: String) -> String {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            if clean.hasPrefix("custom:") {
                return customProviderKey(forName: String(clean.dropFirst("custom:".count)))
            }
            return clean.lowercased()
        }
        return customProviderKey(forName: label)
    }

    private func providerNameForCustomProvider(providerKey: String, label: String) -> String {
        let cleanLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLabel.isEmpty else {
            if providerKey.hasPrefix("custom:") {
                return String(providerKey.dropFirst("custom:".count))
            }
            return providerKey
        }
        if providerKey.hasPrefix("custom:"),
           customProviderKey(forName: cleanLabel) != providerKey {
            return String(providerKey.dropFirst("custom:".count))
        }
        return cleanLabel
    }

    private func customProviderKey(forName name: String) -> String {
        let normalized = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
        return "custom:\(normalized.isEmpty ? "provider" : normalized)"
    }

    private func customProviderAPIKeyEnvName(providerKey: String) -> String {
        let raw = providerKey.hasPrefix("custom:")
            ? String(providerKey.dropFirst("custom:".count))
            : providerKey
        let allowed = CharacterSet.alphanumerics
        let scalars = raw.uppercased().unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let suffix = String(scalars)
            .replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return "HERMES_MANAGER_CUSTOM_\(suffix.isEmpty ? "PROVIDER" : suffix)_API_KEY"
    }

    private func modelConfigBlock(providerKey: String, baseURL: String, defaultModel: String, apiMode: String) -> String {
        var lines = [
            "model:",
            "  default: \(yamlQuote(defaultModel))",
            "  provider: \(yamlQuote(providerKey))",
            "  base_url: \(yamlQuote(baseURL))",
        ]
        if !apiMode.isEmpty {
            lines.append("  api_mode: \(apiMode)")
        }
        return lines.joined(separator: "\n")
    }

    private func inferredAPIMode(providerKey: String, baseURL: String, model: String) -> String {
        let provider = providerKey.lowercased()
        let normalizedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let normalizedModel = model.lowercased()
        if provider == "anthropic" || normalizedURL.hasSuffix("/anthropic") || normalizedURL.contains("/anthropic/") || normalizedURL.contains("api.anthropic.com") {
            return "anthropic_messages"
        }
        if provider == "xai" || normalizedURL.contains("api.x.ai") || normalizedURL.contains("api.openai.com") {
            return "codex_responses"
        }
        if provider == "opencode-zen" {
            return normalizedModel.hasPrefix("claude-") || normalizedModel.hasPrefix("minimax-") ? "anthropic_messages" : "chat_completions"
        }
        if provider == "opencode-go" {
            return normalizedModel.hasPrefix("minimax-") ? "anthropic_messages" : "chat_completions"
        }
        if provider == "kimi-coding-cn" || (normalizedURL.contains("api.kimi.com") && normalizedURL.contains("/coding")) {
            return "anthropic_messages"
        }
        return "chat_completions"
    }

    private func validateModelProviderConfiguration(
        providerKey: String,
        providerName: String,
        baseURL: String,
        defaultModel: String,
        modelNames: [String],
        keyEnv: String,
        onLog log: (String) -> Void
    ) throws {
        let configPath = activeHermesConfigPath
        let config = readText(configPath)
        guard yamlNestedScalarEquals(config, block: "model", key: "provider", value: providerKey),
              yamlNestedScalarEquals(config, block: "model", key: "default", value: defaultModel),
              yamlNestedScalarEquals(config, block: "model", key: "base_url", value: baseURL) else {
            throw SetupExecutionError.commandFailed("模型配置写入后校验失败：Hermes config.yaml 的 provider/default/base_url 不一致。")
        }

        if providerKey.hasPrefix("custom:") {
            guard customProviderExists(in: config, providerKey: providerKey, providerName: providerName, baseURL: baseURL, defaultModel: defaultModel, keyEnv: keyEnv) else {
                throw SetupExecutionError.commandFailed("模型配置写入后校验失败：custom_providers 中没有可被 Hermes 识别的 Provider。")
            }
            let env = readText(activeHermesEnvPath)
            guard !keyEnv.isEmpty, env.contains("\(keyEnv)=") else {
                throw SetupExecutionError.commandFailed("模型配置写入后校验失败：自定义 Provider 的 key_env 没有写入 .env。")
            }
        }

        let dataDirectory = resolveWebUIHome()
        let configJSONPath = "\(dataDirectory)/config.json"
        guard webUIVisibilityContains(path: configJSONPath, providerKey: providerKey, modelNames: modelNames) else {
            throw SetupExecutionError.commandFailed("模型配置写入后校验失败：Hermes Web UI modelVisibility 中没有该 Provider/模型。")
        }

        let dbPath = "\(dataDirectory)/hermes-web-ui.db"
        guard webUIModelContextContains(dbPath: dbPath, providerKey: providerKey, modelNames: modelNames) else {
            throw SetupExecutionError.commandFailed("模型配置写入后校验失败：Hermes Web UI model_context 数据库没有该 Provider/模型。")
        }
        log("[OK] 写后校验通过：Hermes CLI、Web UI config.json、Web UI model_context 已一致。")
    }

    private func customProviderExists(
        in config: String,
        providerKey: String,
        providerName: String,
        baseURL: String,
        defaultModel: String,
        keyEnv: String
    ) -> Bool {
        let lines = config.components(separatedBy: .newlines)
        guard let start = lines.firstIndex(where: { $0 == "custom_providers:" }) else { return false }
        var end = start + 1
        while end < lines.count {
            let line = lines[end]
            if !line.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !line.hasPrefix("#") {
                break
            }
            end += 1
        }

        var index = start + 1
        while index < end {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- name:") else {
                index += 1
                continue
            }
            var itemEnd = index + 1
            while itemEnd < end {
                if lines[itemEnd].trimmingCharacters(in: .whitespaces).hasPrefix("- name:") { break }
                itemEnd += 1
            }
            let item = Array(lines[index..<itemEnd])
            let name = yamlValue(from: trimmed.replacingOccurrences(of: "- ", with: ""))
            let slug = customProviderKey(forName: name)
            if (name == providerName || slug == providerKey),
               item.contains(where: { $0.trimmingCharacters(in: .whitespaces) == "base_url: \(yamlQuote(baseURL))" }),
               item.contains(where: { $0.trimmingCharacters(in: .whitespaces) == "model: \(yamlQuote(defaultModel))" }),
               item.contains(where: { $0.trimmingCharacters(in: .whitespaces) == "key_env: \(yamlQuote(keyEnv))" }),
               item.contains(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("api_key:") }) {
                return true
            }
            index = itemEnd
        }
        return false
    }

    private func webUIVisibilityContains(path: String, providerKey: String, modelNames: [String]) -> Bool {
        guard let data = fileManager.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let visibility = json["modelVisibility"] as? [String: Any],
              let provider = visibility[providerKey] as? [String: Any],
              let models = provider["models"] as? [String] else {
            return false
        }
        let modelSet = Set(models)
        return normalizedModelList(modelNames).allSatisfy { modelSet.contains($0) }
    }

    private func webUIModelContextContains(dbPath: String, providerKey: String, modelNames: [String]) -> Bool {
        guard fileManager.fileExists(atPath: dbPath) else { return false }
        let payload: [String: Any] = [
            "db_path": dbPath,
            "provider": providerKey,
            "models": normalizedModelList(modelNames),
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8),
              let output = try? runPythonScript(webUIModelContextCheckPython, json, { _ in }) else {
            return false
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines) == "OK"
    }

    private func restartModelConsumersIfRunning(onLog log: (String) -> Void) {
        guard home == NSHomeDirectory() else {
            log("[INFO] 当前是隔离 HOME，已跳过 Web UI/Gateway 重启，避免影响真实服务。")
            return
        }

        if let command = webUICommand(),
           let status = try? runShell("\(command) status", { _ in }),
           commandStatusLooksRunning(status) {
            do {
                _ = try runShell("\(command) restart", log)
                log("[OK] Hermes Web UI 已重启以加载模型配置。")
            } catch {
                log("[WARN] Hermes Web UI 重启失败，请手动重启后使用新模型。")
            }
        }

        if commandExists("hermes"),
           let output = try? runShell("hermes gateway status", { _ in }),
           commandStatusLooksRunning(output) {
            do {
                _ = try runShell("hermes gateway restart", log)
                log("[OK] Hermes Gateway 已重启以加载模型配置。")
            } catch {
                log("[WARN] Hermes Gateway 重启失败，请手动重启后使用新模型。")
            }
        }
    }

    private func commandStatusLooksRunning(_ output: String) -> Bool {
        let lower = output.lowercased()
        if lower.contains("not running") || lower.contains("is not running") {
            return false
        }
        return lower.contains("running") || lower.contains("pid")
    }

    private func yamlValue(from line: String) -> String {
        guard let colonIndex = line.firstIndex(of: ":") else { return "" }
        return String(line[line.index(after: colonIndex)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func yamlQuote(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    private func yamlScalarIsFalse(_ text: String, key: String) -> Bool {
        text.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            return trimmed == "\(key): false" || trimmed == "\(key): no" || trimmed == "\(key): 0"
        }
    }

    private func yamlNestedScalarEquals(_ text: String, block blockName: String, key: String, value: String) -> Bool {
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

    private func yamlListContains(_ text: String, block blockName: String, key: String, value: String) -> Bool {
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
        let keyLine = lines[keyIndex].trimmingCharacters(in: .whitespaces).lowercased()
        let lowerValue = value.lowercased()
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

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func shellDoubleQuote(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "$", with: "\\$").replacingOccurrences(of: "`", with: "\\`"))\""
    }

    private func jsonEscaped(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [value], options: []),
              let json = String(data: data, encoding: .utf8),
              json.count >= 2 else {
            return value.replacingOccurrences(of: #"\"#, with: #"\\\"#).replacingOccurrences(of: #"""#, with: #"\""#)
        }
        return String(json.dropFirst().dropLast())
    }

    private func resolveWebUIHome() -> String {
        let env = ProcessInfo.processInfo.environment
        let candidates = [
            env["HERMES_WEB_UI_HOME"],
            env["HERMES_WEB_UI_DATA_DIR"],
            env["HERMES_WEB_UI_DIR"],
            webUIHome,
            "\(home)/Library/Application Support/Hermes Web UI",
            "\(home)/Library/Application Support/hermes-web-ui",
            "\(home)/.config/hermes-web-ui",
            "\(home)/.local/share/hermes-web-ui",
            "\(home)/.hermes/web-ui",
            "\(home)/.hermes/hermes-web-ui",
        ].compactMap { $0 }.filter { !$0.isEmpty }

        return candidates.first(where: { directory in
            fileManager.fileExists(atPath: directory + "/.token")
                || fileManager.fileExists(atPath: directory + "/hermes-web-ui.db")
                || fileManager.fileExists(atPath: directory + "/config.json")
        }) ?? webUIHome
    }

    private func resolveWebUIURL() -> String {
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

        let dataDirectory = resolveWebUIHome()
        let configPath = "\(dataDirectory)/config.json"
        var configURLWithoutPort: String?
        if let data = fileManager.contents(atPath: configPath),
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

        let logPath = "\(dataDirectory)/logs/server.log"
        if let content = try? String(contentsOfFile: logPath, encoding: .utf8),
           let url = firstHTTPURL(in: content),
           let normalized = normalizedLocalWebUIURL(from: url) {
            return normalized
        }

        if let configURLWithoutPort {
            return configURLWithoutPort
        }

        return "http://localhost:8648"
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

    private func restrictOwnerAccess(_ path: String) throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { return }
        let permissions: Int = isDirectory.boolValue ? 0o700 : 0o600
        try fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private func compactHome(_ path: String) -> String {
        path.replacingOccurrences(of: home, with: "~")
    }
}

private let openHumanPluginYAML = """
name: openhuman
description: Use OpenHuman Vault as Hermes external long-term memory.
version: 0.1.0
type: memory
hooks:
  - prefetch
  - sync_turn
  - on_memory_write
"""

private let webUIModelContextUpsertPython = #"""
import json
import sqlite3
import sys

payload = json.loads(sys.stdin.read() or "{}")
db_path = payload["db_path"]
provider = (payload.get("provider") or "").strip()
models = []
seen = set()
for model in payload.get("models") or []:
    model = str(model).strip()
    if model and model not in seen:
        seen.add(model)
        models.append(model)
context_length = int(payload.get("context_length") or 128000)

if not provider or not models:
    raise SystemExit("missing provider or models")

conn = sqlite3.connect(db_path)
try:
    conn.execute(
        "CREATE TABLE IF NOT EXISTS model_context (id INTEGER PRIMARY KEY AUTOINCREMENT, provider TEXT NOT NULL, model TEXT NOT NULL, context_limit INTEGER NOT NULL)"
    )
    conn.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_model_context_provider_model ON model_context(provider, model)"
    )
    for model in models:
        conn.execute(
            "INSERT OR REPLACE INTO model_context (provider, model, context_limit) VALUES (?, ?, ?)",
            (provider, model, context_length),
        )
    conn.commit()
finally:
    conn.close()
"""#

private let webUIModelContextCheckPython = #"""
import json
import sqlite3
import sys

payload = json.loads(sys.stdin.read() or "{}")
db_path = payload["db_path"]
provider = (payload.get("provider") or "").strip()
models = [str(model).strip() for model in payload.get("models") or [] if str(model).strip()]

if not provider or not models:
    raise SystemExit("missing provider or models")

conn = sqlite3.connect(db_path)
try:
    rows = conn.execute(
        "SELECT model FROM model_context WHERE provider = ?",
        (provider,),
    ).fetchall()
    existing = {row[0] for row in rows}
finally:
    conn.close()

missing = [model for model in models if model not in existing]
print("MISSING:" + ",".join(missing) if missing else "OK")
"""#

private let webUIModelContextPrunePython = #"""
import json
import sqlite3
import sys

payload = json.loads(sys.stdin.read() or "{}")
db_path = payload["db_path"]
provider = (payload.get("provider") or "").strip()
models = [str(model).strip() for model in payload.get("models") or [] if str(model).strip()]

if not provider:
    raise SystemExit("missing provider")

conn = sqlite3.connect(db_path)
try:
    if models:
        placeholders = ",".join("?" for _ in models)
        conn.execute(
            f"DELETE FROM model_context WHERE provider = ? AND model NOT IN ({placeholders})",
            [provider] + models,
        )
    else:
        conn.execute("DELETE FROM model_context WHERE provider = ?", (provider,))
    conn.commit()
finally:
    conn.close()
"""#

private let openHumanPluginReadme = """
# Hermes OpenHuman Memory Provider

This provider makes OpenHuman the only long-term memory backend for Hermes.

It uses OpenHuman's local memory schema first (`~/.openhuman/users/local/workspace/memory/memory.db`) and keeps Markdown sidecars under the OpenHuman workspace. Vault Markdown is used as a compatibility fallback for previously imported archives.

Set `OPENHUMAN_WORKSPACE` and `OPENHUMAN_VAULT`, then configure Hermes `memory.provider` to `openhuman`. Disable Hermes' built-in `memory` toolset so this provider can expose `openhuman_memory` and route durable reads/writes into OpenHuman.
"""

private let openHumanPluginInit = """
from __future__ import annotations

import json
import os
from pathlib import Path

try:
    from agent.memory_provider import MemoryProvider
except Exception:
    class MemoryProvider:
        pass

from .adapter import OpenHumanAdapter


class OpenHumanMemoryProvider(MemoryProvider):
    @property
    def name(self):
        return "openhuman"

    def is_available(self):
        return OpenHumanAdapter.default_workspace().exists()

    def initialize(self, session_id=None, **kwargs):
        self.session_id = session_id
        self.adapter = OpenHumanAdapter(
            vault=Path(os.environ.get("OPENHUMAN_VAULT", "")).expanduser() if os.environ.get("OPENHUMAN_VAULT") else None,
            workspace=Path(os.environ.get("OPENHUMAN_WORKSPACE", "")).expanduser() if os.environ.get("OPENHUMAN_WORKSPACE") else None,
        )
        self.adapter.ensure_openhuman_store()

    def system_prompt_block(self):
        return (
            "OpenHuman is the only long-term memory backend. "
            "Do not claim that durable memory is stored in ~/.hermes. "
            "Use the openhuman_memory tool to save durable facts; it writes to OpenHuman local memory. "
            "Never describe OpenHuman as read-only archive after this provider is active. "
            "Use recalled OpenHuman context for user history, preferences, projects, identity, and migrated memories."
        )

    def prefetch(self, query, **kwargs):
        if not getattr(self, "adapter", None):
            self.initialize(**kwargs)
        return self.adapter.format_for_context(self.adapter.search(query or "", limit=8), max_chars=5000)

    def recall(self, query, limit=8, **kwargs):
        if not getattr(self, "adapter", None):
            self.initialize(**kwargs)
        return self.adapter.format_for_context(self.adapter.search(query or "", limit=limit), max_chars=5000)

    def sync_turn(self, user_content, assistant_content, *, session_id=""):
        if not getattr(self, "adapter", None):
            self.initialize(session_id=session_id)
        key = self.adapter.write_turn(user=user_content or "", assistant=assistant_content or "", session_id=session_id)
        for fact in self.adapter.extract_long_term_facts(user_content or ""):
            self.adapter.write_fact(content=fact, target="user", action="add", metadata={"source": "sync_turn_extractor"}, session_id=session_id)
        return key

    def save_memory(self, content, metadata=None, **kwargs):
        if not getattr(self, "adapter", None):
            self.initialize(**kwargs)
        return self.adapter.write_fact(content=str(content or ""), target="memory", action="add", metadata=metadata or {}, session_id=kwargs.get("session_id", self.session_id or ""))

    def on_memory_write(self, action, target, content, metadata=None):
        if not getattr(self, "adapter", None):
            self.initialize(**(metadata or {}))
        return self.adapter.write_fact(
            content=str(content or ""),
            target=str(target or "memory"),
            action=str(action or "add"),
            metadata=metadata or {},
            session_id=(metadata or {}).get("session_id", self.session_id or ""),
        )

    def get_tool_schemas(self):
        return [
            {
                "name": "openhuman_memory",
                "description": (
                    "Save, update, remove, or read durable long-term memory in OpenHuman. "
                    "This is the only writable long-term memory tool after Hermes Manager configures OpenHuman. "
                    "Use proactively for stable user preferences, identity, project facts, environment facts, and lessons. "
                    "Do not save temporary task progress."
                ),
                "parameters": {
                    "type": "object",
                    "properties": {
                        "action": {"type": "string", "enum": ["add", "replace", "remove", "read"]},
                        "target": {"type": "string", "enum": ["memory", "user"], "description": "user for user profile/preferences; memory for agent/project notes."},
                        "content": {"type": "string", "description": "Entry content for add/replace/read."},
                        "old_text": {"type": "string", "description": "Substring to identify an entry for replace/remove/read."},
                    },
                    "required": ["action", "target"],
                },
            }
        ]

    def handle_tool_call(self, tool_name, arguments):
        if tool_name != "openhuman_memory":
            return json.dumps({"success": False, "error": f"OpenHuman provider has no tool named {tool_name}"}, ensure_ascii=False)
        if not getattr(self, "adapter", None):
            self.initialize()
        action = (arguments or {}).get("action", "")
        target = (arguments or {}).get("target", "memory")
        content = (arguments or {}).get("content") or ""
        old_text = (arguments or {}).get("old_text") or ""
        try:
            if action == "add":
                key = self.adapter.write_fact(content=content, target=target, action="add", metadata={"source": "memory_tool"}, session_id=self.session_id or "")
                return json.dumps({"success": True, "message": "Entry saved to OpenHuman long-term memory.", "key": key, "backend": "openhuman"}, ensure_ascii=False)
            if action == "replace":
                key = self.adapter.replace_fact(old_text=old_text, new_content=content, target=target, metadata={"source": "memory_tool"}, session_id=self.session_id or "")
                return json.dumps({"success": bool(key), "message": "Entry replaced in OpenHuman long-term memory." if key else "No matching OpenHuman memory entry found.", "key": key, "backend": "openhuman"}, ensure_ascii=False)
            if action == "remove":
                removed = self.adapter.remove_fact(old_text=old_text, target=target)
                return json.dumps({"success": removed > 0, "message": f"Removed {removed} OpenHuman memory entries.", "removed": removed, "backend": "openhuman"}, ensure_ascii=False)
            if action == "read":
                query = old_text or content or target
                results = self.adapter.search(query, limit=10)
                return json.dumps({"success": True, "entries": [r.to_dict() for r in results], "backend": "openhuman"}, ensure_ascii=False)
            return json.dumps({"success": False, "error": "Unknown action. Use add, replace, remove, or read."}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps({"success": False, "error": str(exc), "backend": "openhuman"}, ensure_ascii=False)

    def get_config_schema(self):
        return [
            {"key": "vault_path", "description": "OpenHuman Vault path. Defaults to OPENHUMAN_VAULT.", "required": False, "default": os.environ.get("OPENHUMAN_VAULT", "")},
            {"key": "workspace_path", "description": "OpenHuman workspace path. Defaults to ~/.openhuman/users/local/workspace.", "required": False, "default": str(OpenHumanAdapter.default_workspace())},
        ]

    def save_config(self, values, hermes_home=None):
        vault = (values or {}).get("vault_path")
        workspace = (values or {}).get("workspace_path")
        if vault:
            os.environ["OPENHUMAN_VAULT"] = str(vault)
        if workspace:
            os.environ["OPENHUMAN_WORKSPACE"] = str(workspace)
        return None


def register(ctx=None):
    provider = OpenHumanMemoryProvider()
    if ctx is not None and hasattr(ctx, "register_memory_provider"):
        ctx.register_memory_provider(provider)
        return None
    return provider
"""

private let openHumanStoreBootstrapPython = #"""
from __future__ import annotations

import os
import sqlite3
from pathlib import Path


workspace = Path(os.environ["OPENHUMAN_WORKSPACE"]).expanduser()
memory_dir = workspace / "memory"
db_path = memory_dir / "memory.db"
memory_dir.mkdir(parents=True, exist_ok=True)
(memory_dir / "namespaces").mkdir(parents=True, exist_ok=True)
(workspace / "memory_tree").mkdir(parents=True, exist_ok=True)
(workspace / "wiki").mkdir(parents=True, exist_ok=True)

conn = sqlite3.connect(str(db_path))
try:
    conn.executescript(
        """
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = NORMAL;

        CREATE TABLE IF NOT EXISTS memory_docs (
          document_id TEXT PRIMARY KEY,
          namespace TEXT NOT NULL,
          key TEXT NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          source_type TEXT NOT NULL,
          priority TEXT NOT NULL,
          tags_json TEXT NOT NULL,
          metadata_json TEXT NOT NULL,
          category TEXT NOT NULL,
          session_id TEXT,
          created_at REAL NOT NULL,
          updated_at REAL NOT NULL,
          markdown_rel_path TEXT NOT NULL,
          UNIQUE(namespace, key)
        );
        CREATE INDEX IF NOT EXISTS idx_memory_docs_ns_updated ON memory_docs(namespace, updated_at DESC);

        CREATE TABLE IF NOT EXISTS kv_global (
          key TEXT PRIMARY KEY,
          value_json TEXT NOT NULL,
          updated_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS kv_namespace (
          namespace TEXT NOT NULL,
          key TEXT NOT NULL,
          value_json TEXT NOT NULL,
          updated_at REAL NOT NULL,
          PRIMARY KEY(namespace, key)
        );
        CREATE INDEX IF NOT EXISTS idx_kv_namespace_ns ON kv_namespace(namespace);

        CREATE TABLE IF NOT EXISTS graph_global (
          subject TEXT NOT NULL,
          predicate TEXT NOT NULL,
          object TEXT NOT NULL,
          attrs_json TEXT NOT NULL,
          updated_at REAL NOT NULL,
          PRIMARY KEY(subject, predicate, object)
        );
        CREATE INDEX IF NOT EXISTS idx_graph_global_subject ON graph_global(subject, predicate);

        CREATE TABLE IF NOT EXISTS graph_namespace (
          namespace TEXT NOT NULL,
          subject TEXT NOT NULL,
          predicate TEXT NOT NULL,
          object TEXT NOT NULL,
          attrs_json TEXT NOT NULL,
          updated_at REAL NOT NULL,
          PRIMARY KEY(namespace, subject, predicate, object)
        );
        CREATE INDEX IF NOT EXISTS idx_graph_namespace_ns ON graph_namespace(namespace);
        CREATE INDEX IF NOT EXISTS idx_graph_namespace_subject ON graph_namespace(namespace, subject, predicate);

        CREATE TABLE IF NOT EXISTS vector_chunks (
          namespace TEXT NOT NULL,
          document_id TEXT NOT NULL,
          chunk_id TEXT NOT NULL,
          text TEXT NOT NULL,
          embedding BLOB,
          metadata_json TEXT NOT NULL,
          created_at REAL NOT NULL,
          updated_at REAL NOT NULL,
          PRIMARY KEY(namespace, chunk_id)
        );
        CREATE INDEX IF NOT EXISTS idx_vector_chunks_ns_doc ON vector_chunks(namespace, document_id);

        CREATE TABLE IF NOT EXISTS user_profile (
          facet_id TEXT PRIMARY KEY,
          facet_type TEXT NOT NULL,
          key TEXT NOT NULL,
          value TEXT NOT NULL,
          confidence REAL NOT NULL DEFAULT 0.5,
          evidence_count INTEGER NOT NULL DEFAULT 1,
          source_segment_ids TEXT,
          first_seen_at REAL NOT NULL,
          last_seen_at REAL NOT NULL,
          state TEXT NOT NULL DEFAULT 'active',
          stability REAL NOT NULL DEFAULT 0.0,
          user_state TEXT NOT NULL DEFAULT 'auto',
          evidence_refs_json TEXT,
          class TEXT,
          cue_families_json TEXT,
          UNIQUE(facet_type, key)
        );
        CREATE INDEX IF NOT EXISTS idx_profile_type ON user_profile(facet_type);
        CREATE INDEX IF NOT EXISTS idx_profile_state_stability ON user_profile(state, stability DESC);
        CREATE INDEX IF NOT EXISTS idx_profile_key ON user_profile(key);
        CREATE INDEX IF NOT EXISTS idx_profile_state_user_stability ON user_profile(state, user_state, stability);
        """
    )
    for column, definition in [
        ("state", "TEXT NOT NULL DEFAULT 'active'"),
        ("stability", "REAL NOT NULL DEFAULT 0.0"),
        ("user_state", "TEXT NOT NULL DEFAULT 'auto'"),
        ("evidence_refs_json", "TEXT"),
        ("class", "TEXT"),
        ("cue_families_json", "TEXT"),
    ]:
        try:
            conn.execute(f"ALTER TABLE user_profile ADD COLUMN {column} {definition}")
        except sqlite3.OperationalError:
            pass
    conn.commit()
finally:
    conn.close()

print(str(db_path))
"""#

private let openHumanDocumentUpsertPython = #"""
from __future__ import annotations

import hashlib
import json
import re
import sqlite3
import sys
import time
from pathlib import Path


payload = json.loads(sys.stdin.read() or "{}")
workspace = Path(payload["workspace"]).expanduser()
memory_dir = workspace / "memory"
db_path = memory_dir / "memory.db"
memory_dir.mkdir(parents=True, exist_ok=True)


def sanitize_namespace(value: str) -> str:
    ns = re.sub(r"[^A-Za-z0-9_.-]+", "_", (value or "default").strip()).strip("._-")
    return ns or "default"


def chunk_text(text: str, size: int = 1200):
    compact = "\n".join(line.rstrip() for line in (text or "").splitlines()).strip()
    if not compact:
        return []
    chunks = []
    for start in range(0, len(compact), size):
        chunks.append(compact[start:start + size])
    return chunks


def yaml_scalar(value: str) -> str:
    return json.dumps(str(value or ""), ensure_ascii=False)


def profile_candidates(text: str):
    compact_lines = [
        " ".join(line.strip().split())
        for line in (text or "").splitlines()
        if line.strip()
    ]
    patterns = [
        (r"(用户偏好[:：].{1,120})", "preference", "style"),
        (r"(我(?:很)?喜欢[^。！？\n]{1,80})", "preference", "style"),
        (r"(我(?:最)?爱[^。！？\n]{1,80})", "preference", "style"),
        (r"(我不喜欢[^。！？\n]{1,80})", "preference", "style"),
        (r"(我讨厌[^。！？\n]{1,80})", "preference", "style"),
        (r"(我(?:会|有|习惯)[^。！？\n]{1,80})", "habit", "style"),
        (r"(用户[^。！？\n]{0,20}(?:代号|名字|称呼|身份)[^。！？\n]{1,80})", "identity", "identity"),
        (r"(你(?:是|叫)[^。！？\n]{1,80})", "identity", "identity"),
        (r"(我的(?:代号|名字|称呼|身份)[^。！？\n]{1,80})", "identity", "identity"),
    ]
    seen = set()
    out = []
    for line in compact_lines[:240]:
        for pattern, facet_type, cls in patterns:
            for match in re.findall(pattern, line):
                value = match[0] if isinstance(match, tuple) else match
                value = value.strip()
                if not value or value in seen:
                    continue
                seen.add(value)
                out.append((facet_type, value, cls))
                if len(out) >= 24:
                    return out
    return out


def upsert_user_profile(conn, facet_type: str, value: str, cls: str, metadata: dict):
    value = " ".join((value or "").split())
    if not value:
        return
    key_seed = re.sub(r"[^A-Za-z0-9_\u4e00-\u9fff]+", "_", value[:56]).strip("_")
    key = (key_seed or hashlib.sha256(value.encode("utf-8")).hexdigest()[:16])[:72]
    facet_id = hashlib.sha256(f"{facet_type}:{key}".encode("utf-8")).hexdigest()[:32]
    now = time.time()
    row = conn.execute(
        "SELECT evidence_count, confidence, first_seen_at FROM user_profile WHERE facet_type = ? AND key = ?",
        (facet_type, key),
    ).fetchone()
    evidence_count = int(row[0]) + 1 if row else 1
    first_seen_at = float(row[2]) if row else now
    confidence = max(float(row[1]) if row else 0.72, 0.80)
    conn.execute(
        """
        INSERT INTO user_profile
          (facet_id, facet_type, key, value, confidence, evidence_count, source_segment_ids, first_seen_at, last_seen_at, state, stability, user_state, evidence_refs_json, class, cue_families_json)
        VALUES
          (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 0.9, 'auto', ?, ?, ?)
        ON CONFLICT(facet_type, key) DO UPDATE SET
          value = excluded.value,
          confidence = MAX(user_profile.confidence, excluded.confidence),
          evidence_count = ?,
          last_seen_at = excluded.last_seen_at,
          state = 'active',
          stability = MAX(user_profile.stability, excluded.stability),
          evidence_refs_json = excluded.evidence_refs_json,
          class = excluded.class,
          cue_families_json = excluded.cue_families_json
        """,
        (
            facet_id,
            facet_type,
            key,
            value,
            confidence,
            evidence_count,
            metadata.get("source_path", metadata.get("source", "")),
            first_seen_at,
            now,
            json.dumps([metadata], ensure_ascii=False),
            cls,
            json.dumps([cls, facet_type], ensure_ascii=False),
            evidence_count,
        ),
    )


namespace = sanitize_namespace(payload.get("namespace") or "hermes")
key = (payload.get("key") or "").strip() or hashlib.sha256((payload.get("content") or "").encode("utf-8")).hexdigest()[:24]
content = payload.get("content") or ""
title = payload.get("title") or key
source_type = payload.get("source_type") or "hermes"
priority = payload.get("priority") or "normal"
tags = payload.get("tags") or []
metadata = payload.get("metadata") or {}
category = payload.get("category") or "long_term"
session_id = payload.get("session_id") or ""
now = time.time()

conn = sqlite3.connect(str(db_path))
try:
    row = conn.execute(
        "SELECT document_id, created_at FROM memory_docs WHERE namespace = ? AND key = ? LIMIT 1",
        (namespace, key),
    ).fetchone()
    if row:
        document_id, created_at = row
    else:
        document_id = f"{int(now)}_{hashlib.sha256((namespace + key).encode('utf-8')).hexdigest()[:8]}"
        created_at = now

    doc_dir = memory_dir / "namespaces" / namespace / "docs"
    doc_dir.mkdir(parents=True, exist_ok=True)
    sidecar = doc_dir / f"{document_id}.md"
    markdown_rel = str(sidecar.relative_to(workspace))
    frontmatter = [
        "---",
        f"doc_id: {yaml_scalar(document_id)}",
        f"namespace: {yaml_scalar(namespace)}",
        f"title: {yaml_scalar(title)}",
        f"source_type: {yaml_scalar(source_type)}",
        f"priority: {yaml_scalar(priority)}",
        f"tags: {json.dumps(tags, ensure_ascii=False)}",
        f"created_at: {created_at}",
        f"updated_at: {now}",
        "---",
        "",
    ]
    sidecar.write_text("\n".join(frontmatter) + content.strip() + "\n", encoding="utf-8")

    conn.execute(
        """
        INSERT INTO memory_docs
          (document_id, namespace, key, title, content, source_type, priority, tags_json, metadata_json, category, session_id, created_at, updated_at, markdown_rel_path)
        VALUES
          (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(namespace, key) DO UPDATE SET
          title = excluded.title,
          content = excluded.content,
          source_type = excluded.source_type,
          priority = excluded.priority,
          tags_json = excluded.tags_json,
          metadata_json = excluded.metadata_json,
          category = excluded.category,
          session_id = excluded.session_id,
          updated_at = excluded.updated_at,
          markdown_rel_path = excluded.markdown_rel_path
        """,
        (
            document_id,
            namespace,
            key,
            title,
            content,
            source_type,
            priority,
            json.dumps(tags, ensure_ascii=False),
            json.dumps(metadata, ensure_ascii=False),
            category,
            session_id,
            created_at,
            now,
            markdown_rel,
        ),
    )
    conn.execute("DELETE FROM vector_chunks WHERE namespace = ? AND document_id = ?", (namespace, document_id))
    for index, chunk in enumerate(chunk_text(content)):
        chunk_id = f"{document_id}:{index}"
        conn.execute(
            """
            INSERT OR REPLACE INTO vector_chunks
              (namespace, document_id, chunk_id, text, embedding, metadata_json, created_at, updated_at)
            VALUES (?, ?, ?, ?, NULL, ?, ?, ?)
            """,
            (
                namespace,
                document_id,
                chunk_id,
                chunk,
                json.dumps({"chunk_index": index, "source": metadata.get("source", source_type)}, ensure_ascii=False),
                now,
                now,
            ),
        )
    if source_type in {"hermes_migration", "hermes_memory_tool"} or namespace in {"hermes_migrated", "user_profile"}:
        for facet_type, value, cls in profile_candidates(content):
            upsert_user_profile(conn, facet_type, value, cls, metadata)
    conn.commit()
finally:
    conn.close()

print(document_id)
"""#

private let openHumanDocumentCountPython = #"""
from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path


payload = json.loads(sys.stdin.read() or "{}")
workspace = Path(payload["workspace"]).expanduser()
namespace = payload.get("namespace") or ""
db_path = workspace / "memory" / "memory.db"
if not db_path.exists():
    print("0")
    raise SystemExit(0)
conn = sqlite3.connect(str(db_path))
try:
    if namespace:
        row = conn.execute("SELECT COUNT(*) FROM memory_docs WHERE namespace = ?", (namespace,)).fetchone()
    else:
        row = conn.execute("SELECT COUNT(*) FROM memory_docs").fetchone()
    print(int(row[0] if row else 0))
finally:
    conn.close()
"""#

private let openHumanAdapterPython = #"""
from __future__ import annotations

import hashlib
import json
import os
import re
import sqlite3
import time
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Union


@dataclass
class SearchResult:
    source: str
    score: int
    snippet: str
    namespace: str = ""
    key: str = ""

    @property
    def path(self) -> Path:
        return Path(self.source)

    def to_dict(self):
        return {
            "source": self.source,
            "path": self.source,
            "namespace": self.namespace,
            "key": self.key,
            "score": self.score,
            "snippet": self.snippet,
        }


class OpenHumanAdapter:
    def __init__(self, vault: Optional[Union[str, Path]] = None, workspace: Optional[Union[str, Path]] = None):
        self.vault = Path(vault or os.environ.get("OPENHUMAN_VAULT", "~/.openhuman/vault")).expanduser()
        self.workspace = Path(workspace or os.environ.get("OPENHUMAN_WORKSPACE", "") or self.default_workspace()).expanduser()
        self.memory_dir = self.workspace / "memory"
        self.db_path = self.memory_dir / "memory.db"

    @classmethod
    def default_workspace(cls) -> Path:
        return Path(os.environ.get("OPENHUMAN_WORKSPACE", "~/.openhuman/users/local/workspace")).expanduser()

    def is_available(self) -> bool:
        return self.default_workspace().exists() or self.vault.exists()

    def ensure_openhuman_store(self):
        self.memory_dir.mkdir(parents=True, exist_ok=True)
        (self.memory_dir / "namespaces").mkdir(parents=True, exist_ok=True)
        (self.workspace / "memory_tree").mkdir(parents=True, exist_ok=True)
        (self.workspace / "wiki").mkdir(parents=True, exist_ok=True)
        with self._connect() as conn:
            self._init_schema(conn)

    def _connect(self):
        self.memory_dir.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row
        self._init_schema(conn)
        return conn

    def _init_schema(self, conn):
        conn.executescript(
            """
            PRAGMA journal_mode = WAL;
            PRAGMA synchronous = NORMAL;

            CREATE TABLE IF NOT EXISTS memory_docs (
              document_id TEXT PRIMARY KEY,
              namespace TEXT NOT NULL,
              key TEXT NOT NULL,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              source_type TEXT NOT NULL,
              priority TEXT NOT NULL,
              tags_json TEXT NOT NULL,
              metadata_json TEXT NOT NULL,
              category TEXT NOT NULL,
              session_id TEXT,
              created_at REAL NOT NULL,
              updated_at REAL NOT NULL,
              markdown_rel_path TEXT NOT NULL,
              UNIQUE(namespace, key)
            );
            CREATE INDEX IF NOT EXISTS idx_memory_docs_ns_updated ON memory_docs(namespace, updated_at DESC);

            CREATE TABLE IF NOT EXISTS vector_chunks (
              namespace TEXT NOT NULL,
              document_id TEXT NOT NULL,
              chunk_id TEXT NOT NULL,
              text TEXT NOT NULL,
              embedding BLOB,
              metadata_json TEXT NOT NULL,
              created_at REAL NOT NULL,
              updated_at REAL NOT NULL,
              PRIMARY KEY(namespace, chunk_id)
            );
            CREATE INDEX IF NOT EXISTS idx_vector_chunks_ns_doc ON vector_chunks(namespace, document_id);

            CREATE TABLE IF NOT EXISTS user_profile (
              facet_id TEXT PRIMARY KEY,
              facet_type TEXT NOT NULL,
              key TEXT NOT NULL,
              value TEXT NOT NULL,
              confidence REAL NOT NULL DEFAULT 0.5,
              evidence_count INTEGER NOT NULL DEFAULT 1,
              source_segment_ids TEXT,
              first_seen_at REAL NOT NULL,
              last_seen_at REAL NOT NULL,
              state TEXT NOT NULL DEFAULT 'active',
              stability REAL NOT NULL DEFAULT 0.0,
              user_state TEXT NOT NULL DEFAULT 'auto',
              evidence_refs_json TEXT,
              class TEXT,
              cue_families_json TEXT,
              UNIQUE(facet_type, key)
            );
            CREATE INDEX IF NOT EXISTS idx_profile_type ON user_profile(facet_type);
            CREATE INDEX IF NOT EXISTS idx_profile_state_stability ON user_profile(state, stability DESC);
            CREATE INDEX IF NOT EXISTS idx_profile_key ON user_profile(key);
            CREATE INDEX IF NOT EXISTS idx_profile_state_user_stability ON user_profile(state, user_state, stability);
            """
        )
        for column, definition in [
            ("state", "TEXT NOT NULL DEFAULT 'active'"),
            ("stability", "REAL NOT NULL DEFAULT 0.0"),
            ("user_state", "TEXT NOT NULL DEFAULT 'auto'"),
            ("evidence_refs_json", "TEXT"),
            ("class", "TEXT"),
            ("cue_families_json", "TEXT"),
        ]:
            try:
                conn.execute(f"ALTER TABLE user_profile ADD COLUMN {column} {definition}")
            except sqlite3.OperationalError:
                pass
        conn.commit()

    def should_search(self, query: str) -> bool:
        return bool((query or "").strip())

    def extract_long_term_facts(self, text: str) -> List[str]:
        text = " ".join((text or "").strip().split())
        if not text:
            return []
        patterns = [
            (r"(我(?:很)?喜欢(?:吃|喝|用|玩|看|听)?[^。！？\n]{1,80})", "用户偏好"),
            (r"(我(?:最)?爱(?:吃|喝|用|玩|看|听)?[^。！？\n]{1,80})", "用户偏好"),
            (r"(我不喜欢[^。！？\n]{1,80})", "用户负向偏好"),
            (r"(我讨厌[^。！？\n]{1,80})", "用户负向偏好"),
            (r"(我(?:不能|不吃|不喝|过敏)[^。！？\n]{1,80})", "用户限制"),
            (r"(我(?:会|有|习惯)[^。！？\n]{1,80})", "用户习惯"),
            (r"(请记住[^。！？\n]{1,100})", "用户要求记忆"),
            (r"(记住[^。！？\n]{1,100})", "用户要求记忆"),
            (r"(?i)\b(i like [^.!?\n]{1,80})", "user preference"),
            (r"(?i)\b(i love [^.!?\n]{1,80})", "user preference"),
            (r"(?i)\b(my favorite [^.!?\n]{1,80})", "user preference"),
            (r"(?i)\b(remember that [^.!?\n]{1,100})", "user requested memory"),
        ]
        facts: List[str] = []
        for pattern, label in patterns:
            for match in re.findall(pattern, text):
                fact = match[0] if isinstance(match, tuple) else match
                fact = fact.strip()
                if fact and fact not in facts:
                    facts.append(f"{label}: {fact}")
        return facts[:5]

    def _sanitize_namespace(self, value: str) -> str:
        ns = re.sub(r"[^A-Za-z0-9_.-]+", "_", (value or "default").strip()).strip("._-")
        return ns or "default"

    def _safe_key(self, value: str, fallback: str) -> str:
        key = re.sub(r"[^A-Za-z0-9_.:/-]+", "-", (value or "").strip()).strip("-/")
        return key or fallback

    def _chunk_text(self, text: str, size: int = 1200) -> List[str]:
        compact = "\n".join(line.rstrip() for line in (text or "").splitlines()).strip()
        if not compact:
            return []
        return [compact[i:i + size] for i in range(0, len(compact), size)]

    def _yaml_scalar(self, value: str) -> str:
        return json.dumps(str(value or ""), ensure_ascii=False)

    def _write_sidecar(self, namespace: str, document_id: str, title: str, source_type: str, priority: str, tags: list, created_at: float, updated_at: float, content: str) -> str:
        doc_dir = self.memory_dir / "namespaces" / namespace / "docs"
        doc_dir.mkdir(parents=True, exist_ok=True)
        sidecar = doc_dir / f"{document_id}.md"
        frontmatter = [
            "---",
            f"doc_id: {self._yaml_scalar(document_id)}",
            f"namespace: {self._yaml_scalar(namespace)}",
            f"title: {self._yaml_scalar(title)}",
            f"source_type: {self._yaml_scalar(source_type)}",
            f"priority: {self._yaml_scalar(priority)}",
            f"tags: {json.dumps(tags, ensure_ascii=False)}",
            f"created_at: {created_at}",
            f"updated_at: {updated_at}",
            "---",
            "",
        ]
        sidecar.write_text("\n".join(frontmatter) + (content or "").strip() + "\n", encoding="utf-8")
        return str(sidecar.relative_to(self.workspace))

    def _upsert_openhuman_doc(self, *, namespace: str, key: str, title: str, content: str, source_type: str = "hermes", priority: str = "normal", tags: Optional[list] = None, metadata: Optional[dict] = None, category: str = "long_term", session_id: str = "") -> str:
        self.ensure_openhuman_store()
        namespace = self._sanitize_namespace(namespace)
        key = self._safe_key(key, hashlib.sha256((content or "").encode("utf-8")).hexdigest()[:24])
        tags = tags or []
        metadata = metadata or {}
        now = time.time()
        with self._connect() as conn:
            row = conn.execute(
                "SELECT document_id, created_at FROM memory_docs WHERE namespace = ? AND key = ? LIMIT 1",
                (namespace, key),
            ).fetchone()
            if row:
                document_id = row["document_id"]
                created_at = float(row["created_at"])
            else:
                document_id = f"{int(now)}_{hashlib.sha256((namespace + key).encode('utf-8')).hexdigest()[:8]}"
                created_at = now
            markdown_rel = self._write_sidecar(namespace, document_id, title, source_type, priority, tags, created_at, now, content)
            conn.execute(
                """
                INSERT INTO memory_docs
                  (document_id, namespace, key, title, content, source_type, priority, tags_json, metadata_json, category, session_id, created_at, updated_at, markdown_rel_path)
                VALUES
                  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(namespace, key) DO UPDATE SET
                  title = excluded.title,
                  content = excluded.content,
                  source_type = excluded.source_type,
                  priority = excluded.priority,
                  tags_json = excluded.tags_json,
                  metadata_json = excluded.metadata_json,
                  category = excluded.category,
                  session_id = excluded.session_id,
                  updated_at = excluded.updated_at,
                  markdown_rel_path = excluded.markdown_rel_path
                """,
                (
                    document_id,
                    namespace,
                    key,
                    title,
                    content,
                    source_type,
                    priority,
                    json.dumps(tags, ensure_ascii=False),
                    json.dumps(metadata, ensure_ascii=False),
                    category,
                    session_id,
                    created_at,
                    now,
                    markdown_rel,
                ),
            )
            conn.execute("DELETE FROM vector_chunks WHERE namespace = ? AND document_id = ?", (namespace, document_id))
            for index, chunk in enumerate(self._chunk_text(content)):
                conn.execute(
                    """
                    INSERT OR REPLACE INTO vector_chunks
                      (namespace, document_id, chunk_id, text, embedding, metadata_json, created_at, updated_at)
                    VALUES (?, ?, ?, ?, NULL, ?, ?, ?)
                    """,
                    (
                        namespace,
                        document_id,
                        f"{document_id}:{index}",
                        chunk,
                        json.dumps({"chunk_index": index, "source": metadata.get("source", source_type)}, ensure_ascii=False),
                        now,
                        now,
                    ),
                )
            conn.commit()
        return key

    def _classify_profile(self, content: str, target: str) -> tuple[str, str, str, str]:
        text = " ".join((content or "").split())
        lower = text.lower()
        if target == "user" or any(x in text for x in ["我喜欢", "我爱", "我不喜欢", "我讨厌", "偏好"]):
            facet_type = "preference"
            cls = "style"
        elif any(x in text for x in ["习惯", "我会", "我有"]):
            facet_type = "habit"
            cls = "style"
        elif any(x in text for x in ["我叫", "我的名字", "我的代号", "代号", "称呼", "身份", "你是", "你叫"]):
            facet_type = "identity"
            cls = "identity"
        elif any(x in lower for x in ["model", "api", "python", "node", "xcode", "环境", "配置"]):
            facet_type = "tooling"
            cls = "tooling"
        else:
            facet_type = "memory"
            cls = "goal"
        key_seed = re.sub(r"[^A-Za-z0-9_\u4e00-\u9fff]+", "_", text[:48]).strip("_") or hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]
        key = key_seed[:64]
        return facet_type, key, text, cls

    def _upsert_user_profile(self, content: str, target: str = "user", metadata: Optional[dict] = None) -> str:
        content = (content or "").strip()
        if not content:
            return ""
        facet_type, key, value, cls = self._classify_profile(content, target)
        facet_id = hashlib.sha256(f"{facet_type}:{key}".encode("utf-8")).hexdigest()[:32]
        now = time.time()
        metadata = metadata or {}
        with self._connect() as conn:
            row = conn.execute(
                "SELECT evidence_count, confidence, first_seen_at FROM user_profile WHERE facet_type = ? AND key = ?",
                (facet_type, key),
            ).fetchone()
            evidence_count = int(row["evidence_count"]) + 1 if row else 1
            first_seen_at = float(row["first_seen_at"]) if row else now
            confidence = max(float(row["confidence"]) if row else 0.75, 0.82)
            conn.execute(
                """
                INSERT INTO user_profile
                  (facet_id, facet_type, key, value, confidence, evidence_count, source_segment_ids, first_seen_at, last_seen_at, state, stability, user_state, evidence_refs_json, class, cue_families_json)
                VALUES
                  (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 1.0, 'pinned', ?, ?, ?)
                ON CONFLICT(facet_type, key) DO UPDATE SET
                  value = excluded.value,
                  confidence = MAX(user_profile.confidence, excluded.confidence),
                  evidence_count = ?,
                  last_seen_at = excluded.last_seen_at,
                  state = 'active',
                  stability = MAX(user_profile.stability, excluded.stability),
                  user_state = 'pinned',
                  evidence_refs_json = excluded.evidence_refs_json,
                  class = excluded.class,
                  cue_families_json = excluded.cue_families_json
                """,
                (
                    facet_id,
                    facet_type,
                    key,
                    value,
                    confidence,
                    evidence_count,
                    metadata.get("session_id", ""),
                    first_seen_at,
                    now,
                    json.dumps([metadata], ensure_ascii=False),
                    cls,
                    json.dumps([cls, facet_type], ensure_ascii=False),
                    evidence_count,
                ),
            )
            conn.commit()
        return key

    def write_turn(self, user: str, assistant: str, session_id: str = "") -> str:
        content = f"## User\n\n{(user or '').strip()}\n\n## Assistant\n\n{(assistant or '').strip()}".strip()
        if not content:
            return ""
        digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:16]
        key = f"turn/{session_id or 'session'}/{int(time.time())}-{digest}"
        return self._upsert_openhuman_doc(
            namespace="hermes_turns",
            key=key,
            title=f"Hermes turn {session_id or ''}".strip(),
            content=content,
            source_type="hermes_sync_turn",
            priority="low",
            tags=["hermes", "turn"],
            metadata={"source": "sync_turn", "session_id": session_id},
            category="conversation",
            session_id=session_id,
        )

    def write_fact(self, content: str, target: str = "memory", action: str = "add", metadata: Optional[dict] = None, session_id: str = "") -> str:
        content = (content or "").strip()
        if not content:
            return ""
        metadata = dict(metadata or {})
        metadata.setdefault("source", "hermes_memory_tool")
        metadata["action"] = action
        metadata["target"] = target
        metadata["session_id"] = session_id
        namespace = "user_profile" if target == "user" else "hermes_memory"
        digest = hashlib.sha256(content.encode("utf-8")).hexdigest()[:16]
        key = self._safe_key(f"{target}/{digest}", digest)
        if target == "user":
            profile_key = self._upsert_user_profile(content, target=target, metadata=metadata)
            key = self._safe_key(f"pinned/{profile_key or digest}", digest)
        return self._upsert_openhuman_doc(
            namespace=namespace,
            key=key,
            title=("User profile" if target == "user" else "Hermes memory"),
            content=content,
            source_type="hermes_memory_tool",
            priority="high" if target == "user" else "normal",
            tags=["hermes", "memory", target],
            metadata=metadata,
            category="user_profile" if target == "user" else "long_term",
            session_id=session_id,
        )

    def replace_fact(self, old_text: str, new_content: str, target: str = "memory", metadata: Optional[dict] = None, session_id: str = "") -> str:
        old_text = (old_text or "").strip()
        if not old_text:
            return self.write_fact(new_content, target=target, action="replace", metadata=metadata, session_id=session_id)
        namespace = "user_profile" if target == "user" else "hermes_memory"
        with self._connect() as conn:
            row = conn.execute(
                "SELECT key FROM memory_docs WHERE namespace = ? AND content LIKE ? ORDER BY updated_at DESC LIMIT 1",
                (namespace, f"%{old_text}%"),
            ).fetchone()
        if not row:
            return ""
        metadata = dict(metadata or {})
        metadata["replaces"] = old_text
        return self._upsert_openhuman_doc(
            namespace=namespace,
            key=row["key"],
            title=("User profile" if target == "user" else "Hermes memory"),
            content=(new_content or "").strip(),
            source_type="hermes_memory_tool",
            priority="high" if target == "user" else "normal",
            tags=["hermes", "memory", target],
            metadata=metadata,
            category="user_profile" if target == "user" else "long_term",
            session_id=session_id,
        )

    def remove_fact(self, old_text: str, target: str = "memory") -> int:
        old_text = (old_text or "").strip()
        if not old_text:
            return 0
        namespace = "user_profile" if target == "user" else "hermes_memory"
        removed = 0
        with self._connect() as conn:
            rows = conn.execute(
                "SELECT document_id FROM memory_docs WHERE namespace = ? AND content LIKE ?",
                (namespace, f"%{old_text}%"),
            ).fetchall()
            for row in rows:
                conn.execute("DELETE FROM vector_chunks WHERE namespace = ? AND document_id = ?", (namespace, row["document_id"]))
                conn.execute("DELETE FROM memory_docs WHERE namespace = ? AND document_id = ?", (namespace, row["document_id"]))
                removed += 1
            conn.execute("DELETE FROM user_profile WHERE value LIKE ?", (f"%{old_text}%",))
            conn.commit()
        return removed

    def _query_terms(self, query: str) -> List[str]:
        query = query or ""
        terms = re.findall(r"[a-z0-9_][a-z0-9_-]{1,}", query.lower())
        for segment in re.findall(r"[\u4e00-\u9fff]{2,}", query):
            terms.append(segment)
            for size in (2, 3, 4):
                if len(segment) >= size:
                    terms.extend(segment[index:index + size] for index in range(0, len(segment) - size + 1))
        lower = (query or "").lower()
        expansion_map = {
            "你是谁": ["identity", "persona", "身份", "人设"],
            "我是谁": ["user", "profile", "用户", "名字"],
            "我叫什么": ["user", "profile", "名字", "称呼"],
            "喜欢": ["preference", "preferences", "偏好", "喜欢"],
            "吃什么": ["food", "drink", "饮食", "口味", "吃", "喝"],
            "喝什么": ["food", "drink", "饮食", "口味", "咖啡", "茶"],
            "代号": ["identity", "codename", "代号", "称呼", "名字", "身份"],
            "习惯": ["habit", "preference", "习惯", "行为", "偏好"],
            "人设": ["identity", "persona", "人设", "身份"],
            "身份": ["identity", "persona", "身份", "名字", "称呼"],
            "饮食": ["food", "drink", "饮食", "口味", "吃", "喝"],
            "长期记忆": ["long_term", "memory", "长期", "记忆", "hermes_migrated"],
            "openhuman": ["openhuman", "memory", "记忆"],
        }
        for needle, extra in expansion_map.items():
            if needle in lower or needle in (query or ""):
                terms.extend(extra)
        deduped = []
        for term in terms:
            if term and term not in deduped:
                deduped.append(term)
        return deduped or [query.strip()] if query.strip() else []

    def _snippet(self, text: str, terms: List[str], max_chars: int = 900) -> str:
        compact = " ".join((text or "").strip().split())
        if not compact:
            return ""
        hay = compact.lower()
        positions = [hay.find(term.lower()) for term in terms if term and hay.find(term.lower()) >= 0]
        center = min(positions) if positions else 0
        start = max(0, center - max_chars // 3)
        return compact[start:start + max_chars]

    def _score_text(self, hay: str, terms: List[str]) -> int:
        lower = hay.lower()
        score = 0
        for term in terms:
            if not term:
                continue
            score += min(lower.count(term.lower()), 5) * 2
        if any(x in lower for x in ["preference", "user_profile", "identity", "persona", "偏好", "身份"]):
            score += 1
        return score

    def _profile_affinity_score(self, query: str, text: str) -> int:
        q = query or ""
        score = 0
        if re.search(r"(我|用户|user).{0,12}(喜欢|偏好|爱|讨厌|不喜欢|吃|喝|口味|饮食|是谁|叫什么|身份)", q, re.I):
            score += 4
        if any(token in q for token in ["我", "用户", "user", "偏好", "喜欢", "爱吃", "喝", "吃", "身份", "名字"]):
            score += 2
        if any(token in text for token in ["用户偏好", "preference", "identity", "用户", "喜欢", "不喜欢"]):
            score += 1
        return score

    def _namespace_affinity_score(self, query: str, namespace: str, hay: str) -> int:
        q = query or ""
        ns = namespace or ""
        score = 0
        if ns in {"hermes_migrated", "openhuman_existing", "hermes_memory"}:
            score += 1
        if ns == "hermes_migrated" and any(token in q for token in ["之前", "以前", "迁移", "原本", "长期记忆", "记忆", "代号", "身份", "人设"]):
            score += 4
        if ns not in {"user_profile", "vector"} and any(token in q for token in ["代号", "项目", "配置", "环境", "历史", "文档"]):
            score += 3
        if any(token in q for token in ["习惯", "喜欢", "偏好", "饮食", "吃", "喝"]) and any(token in hay for token in ["习惯", "喜欢", "偏好", "饮食", "吃", "喝"]):
            score += 3
        return score

    def _search_openhuman_db(self, query: str, limit: int = 5) -> List[SearchResult]:
        if not self.db_path.exists():
            return []
        terms = self._query_terms(query)
        results: List[SearchResult] = []
        with self._connect() as conn:
            for row in conn.execute(
                "SELECT namespace, key, title, content, markdown_rel_path, updated_at FROM memory_docs ORDER BY updated_at DESC LIMIT 600"
            ).fetchall():
                hay = "\n".join([row["namespace"], row["key"], row["title"], row["content"]])
                score = self._score_text(hay, terms) if terms else 1
                score += self._namespace_affinity_score(query, row["namespace"], hay)
                if score <= 0:
                    continue
                source = str(self.workspace / row["markdown_rel_path"]) if row["markdown_rel_path"] else f"memory_docs:{row['namespace']}:{row['key']}"
                results.append(SearchResult(source=source, namespace=row["namespace"], key=row["key"], score=score, snippet=self._snippet(row["content"], terms)))
            for row in conn.execute(
                "SELECT facet_type, key, value, confidence, evidence_count, last_seen_at FROM user_profile WHERE state != 'dropped' ORDER BY last_seen_at DESC LIMIT 300"
            ).fetchall():
                text = f"{row['facet_type']}/{row['key']}: {row['value']}"
                score = self._score_text(text, terms) + self._profile_affinity_score(query, text) + 3
                if score <= 0:
                    continue
                results.append(SearchResult(source=f"user_profile:{row['facet_type']}:{row['key']}", namespace="user_profile", key=row["key"], score=score, snippet=self._snippet(text, terms)))
            for row in conn.execute(
                "SELECT namespace, document_id, text, updated_at FROM vector_chunks ORDER BY updated_at DESC LIMIT 800"
            ).fetchall():
                score = self._score_text(row["text"], terms)
                score += self._namespace_affinity_score(query, row["namespace"], row["text"])
                if score <= 0:
                    continue
                results.append(SearchResult(source=f"vector_chunks:{row['namespace']}:{row['document_id']}", namespace=row["namespace"], key=row["document_id"], score=score, snippet=self._snippet(row["text"], terms)))
        results.sort(key=lambda item: item.score, reverse=True)
        seen = set()
        deduped: List[SearchResult] = []
        for item in results:
            marker = (item.namespace, item.key, item.snippet[:80])
            if marker in seen:
                continue
            seen.add(marker)
            deduped.append(item)
        diversified: List[SearchResult] = []
        used_namespaces = set()
        for item in deduped:
            if item.namespace in used_namespaces:
                continue
            diversified.append(item)
            used_namespaces.add(item.namespace)
            if len(diversified) >= limit:
                return diversified[:limit]
        for item in deduped:
            if item in diversified:
                continue
            diversified.append(item)
            if len(diversified) >= limit:
                break
        return diversified[:limit]

    def _search_vault_compat(self, query: str, limit: int = 5) -> List[SearchResult]:
        if not self.vault.exists():
            return []
        terms = self._query_terms(query)
        roots = [self.vault / "Hermes", self.vault / "Imported", self.vault]
        results: List[SearchResult] = []
        seen = set()
        for root in roots:
            if not root.exists():
                continue
            for path in root.rglob("*"):
                if path in seen:
                    continue
                if path.suffix.lower() not in {".md", ".txt", ".json", ".jsonl", ".yaml", ".yml", ".toml"}:
                    continue
                seen.add(path)
                try:
                    text = path.read_text(encoding="utf-8", errors="replace")
                except Exception:
                    continue
                hay = (str(path) + "\n" + text)
                score = self._score_text(hay, terms)
                if score <= 0 and terms:
                    continue
                results.append(SearchResult(source=str(path), namespace="vault", key=path.name, score=score, snippet=self._snippet(text, terms)))
        results.sort(key=lambda item: item.score, reverse=True)
        return results[:limit]

    def search(self, query: str, limit: int = 5) -> List[SearchResult]:
        # Always include the Vault compatibility layer. Existing OpenHuman and
        # imported OpenClaw archives may live only as Markdown, while active
        # Hermes writes live in SQLite. Returning early from SQLite can hide
        # those older long-term memories even when they are the best match.
        db_results = self._search_openhuman_db(query, limit=max(limit * 2, 8))
        fallback = self._search_vault_compat(query, limit=max(limit, 5))
        combined = db_results + fallback
        combined.sort(key=lambda item: item.score, reverse=True)
        seen = set()
        diversified: List[SearchResult] = []
        for item in combined:
            marker = (item.namespace, item.key, item.source, item.snippet[:80])
            if marker in seen:
                continue
            if item.namespace in {existing.namespace for existing in diversified} and len(diversified) < max(1, limit // 2):
                continue
            seen.add(marker)
            diversified.append(item)
            if len(diversified) >= limit:
                return diversified[:limit]
        for item in combined:
            marker = (item.namespace, item.key, item.source, item.snippet[:80])
            if marker in seen:
                continue
            seen.add(marker)
            diversified.append(item)
            if len(diversified) >= limit:
                break
        return diversified[:limit]

    def format_for_context(self, results: List[SearchResult], max_chars: int = 4000) -> Optional[str]:
        if not results:
            return None
        parts = [
            "OpenHuman recalled long-term memory:",
            "Durable memory source of truth is OpenHuman local memory, not ~/.hermes memory files.",
        ]
        for item in results:
            parts.append(f"- Source: {item.source}\n  Namespace: {item.namespace}\n  Excerpt: {item.snippet}")
        return "\n".join(parts)[:max_chars]
"""#

private let legacyOpenHumanAdapterPython = """
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Union


@dataclass
class SearchResult:
    path: Path
    score: int
    snippet: str


class OpenHumanAdapter:
    def __init__(self, vault: Optional[Union[str, Path]] = None):
        self.vault = Path(vault or os.environ.get("OPENHUMAN_VAULT", "")).expanduser()

    def should_search(self, query: str) -> bool:
        q = (query or "").lower()
        triggers = [
            "remember", "memory", "preference", "project", "history", "schedule",
            "identity", "persona", "previous", "before", "openhuman",
            "who am i", "who are you", "what do i like", "favorite", "food", "drink",
            "记忆", "偏好", "之前", "以前", "人设", "身份", "项目", "历史", "迁移",
            "你是谁", "我是谁", "我叫什么", "喜欢", "爱吃", "喝什么", "吃什么",
            "口味", "饮食", "咖啡", "茶", "模型", "供应商", "配置",
        ]
        if any(term in q for term in triggers):
            return True
        return bool(re.search(r"(我|用户|主人|user).{0,12}(喜欢|偏好|是谁|叫什么|吃|喝|项目|配置)", query or ""))

    def extract_long_term_facts(self, text: str) -> List[str]:
        text = " ".join((text or "").strip().split())
        if not text:
            return []
        patterns = [
            (r"(我(?:很)?喜欢(?:吃|喝|用|玩|看|听)?[^。！？\\n]{1,80})", "用户偏好"),
            (r"(我(?:最)?爱(?:吃|喝|用|玩|看|听)?[^。！？\\n]{1,80})", "用户偏好"),
            (r"(我不喜欢[^。！？\\n]{1,80})", "用户负向偏好"),
            (r"(我讨厌[^。！？\\n]{1,80})", "用户负向偏好"),
            (r"(我(?:不能|不吃|不喝|过敏)[^。！？\\n]{1,80})", "用户限制"),
            (r"(请记住[^。！？\\n]{1,100})", "用户要求记忆"),
            (r"(记住[^。！？\\n]{1,100})", "用户要求记忆"),
            (r"(?i)\\b(i like [^.!?\\n]{1,80})", "user preference"),
            (r"(?i)\\b(i love [^.!?\\n]{1,80})", "user preference"),
            (r"(?i)\\b(my favorite [^.!?\\n]{1,80})", "user preference"),
            (r"(?i)\\b(remember that [^.!?\\n]{1,100})", "user requested memory"),
        ]
        facts: List[str] = []
        for pattern, label in patterns:
            for match in re.findall(pattern, text):
                fact = match[0] if isinstance(match, tuple) else match
                fact = fact.strip()
                if fact and fact not in facts:
                    facts.append(f"{label}: {fact}")
        return facts[:5]

    def _query_terms(self, query: str) -> List[str]:
        terms = re.findall(r"[a-z0-9_][a-z0-9_-]{1,}", (query or "").lower())
        terms.extend(re.findall(r"[\\u4e00-\\u9fff]{2,}", query or ""))
        lower = (query or "").lower()
        expansion_map = {
            "你是谁": ["identity", "persona", "身份", "人设"],
            "我是谁": ["user", "profile", "用户", "名字"],
            "我叫什么": ["user", "profile", "名字", "称呼"],
            "喜欢": ["preference", "preferences", "偏好", "喜欢"],
            "吃什么": ["food", "drink", "饮食", "口味", "吃", "喝"],
            "喝什么": ["food", "drink", "饮食", "口味", "咖啡", "茶"],
        }
        for needle, extra in expansion_map.items():
            if needle in lower or needle in (query or ""):
                terms.extend(extra)
        deduped = []
        for term in terms:
            if term not in deduped:
                deduped.append(term)
        return deduped

    def _snippet(self, text: str, terms: List[str], max_chars: int = 900) -> str:
        compact = " ".join(text.strip().split())
        if not compact:
            return ""
        hay = compact.lower()
        positions = [hay.find(term.lower()) for term in terms if term and hay.find(term.lower()) >= 0]
        center = min(positions) if positions else 0
        start = max(0, center - max_chars // 3)
        return compact[start:start + max_chars]

    def search(self, query: str, limit: int = 5) -> List[SearchResult]:
        if not self.vault.exists():
            return []
        terms = self._query_terms(query)
        roots = [self.vault / "Hermes", self.vault / "Imported", self.vault]
        results: List[SearchResult] = []
        seen = set()
        for root in roots:
            if not root.exists():
                continue
            for path in root.rglob("*"):
                if path in seen:
                    continue
                if path.suffix.lower() not in {".md", ".txt", ".json", ".jsonl", ".yaml", ".yml", ".toml"}:
                    continue
                seen.add(path)
                text = path.read_text(encoding="utf-8", errors="replace")
                hay = (str(path) + "\\n" + text).lower()
                score = sum(min(hay.count(term.lower()), 5) for term in terms)
                if "identity" in hay or "persona" in hay:
                    score += 1
                if score <= 0 and terms:
                    continue
                results.append(SearchResult(path=path, score=score, snippet=self._snippet(text, terms)))
        results.sort(key=lambda item: item.score, reverse=True)
        return results[:limit]

    def format_for_context(self, results: List[SearchResult], max_chars: int = 4000) -> Optional[str]:
        if not results:
            return None
        parts = ["OpenHuman recalled long-term memory:"]
        for item in results:
            parts.append(f"- Source: {item.path}\\n  Excerpt: {item.snippet}")
        return "\\n".join(parts)[:max_chars]

    def write_memory_event(self, user: str, assistant: str, metadata: Optional[dict] = None, session_id: str = "") -> Optional[Path]:
        if not self.vault.exists():
            return None
        inbox = self.vault / "Hermes" / "Inbox"
        inbox.mkdir(parents=True, exist_ok=True)
        day = datetime.now().strftime("%Y-%m-%d")
        created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        target = inbox / f"{day}.md"
        with target.open("a", encoding="utf-8") as fh:
            fh.write(f"\\n---\\nsource: hermes\\ntype: memory_event\\ncreated_at: {created}\\nsession_id: {session_id}\\n---\\n\\n")
            fh.write("# Hermes Memory Event\\n\\n")
            fh.write("## User message\\n\\n" + (user or "").strip() + "\\n\\n")
            fh.write("## Assistant result\\n\\n" + (assistant or "").strip() + "\\n\\n")
            if metadata:
                fh.write("## Metadata\\n\\n")
                for key, value in metadata.items():
                    fh.write(f"- {key}: {value}\\n")
        return target

    def write_memory_fact(self, content: str, target: str = "memory", action: str = "add", metadata: Optional[dict] = None, session_id: str = "") -> Optional[Path]:
        content = (content or "").strip()
        if not content or not self.vault.exists():
            return None
        inbox = self.vault / "Hermes" / "LongTerm"
        inbox.mkdir(parents=True, exist_ok=True)
        day = datetime.now().strftime("%Y-%m-%d")
        created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        safe_target = re.sub(r"[^a-zA-Z0-9_-]+", "-", target or "memory").strip("-") or "memory"
        path = inbox / f"{safe_target}-{day}.md"
        with path.open("a", encoding="utf-8") as fh:
            fh.write(f"\\n---\\nsource: hermes\\ntype: long_term_fact\\naction: {action}\\ntarget: {target}\\ncreated_at: {created}\\nsession_id: {session_id}\\n---\\n\\n")
            fh.write(content + "\\n")
            if metadata:
                fh.write("\\n## Metadata\\n\\n")
                for key, value in metadata.items():
                    fh.write(f"- {key}: {value}\\n")
        return path
"""
