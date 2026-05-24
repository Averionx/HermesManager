import SwiftUI
import Foundation

// MARK: - Setup Models

enum SetupScenario: String, CaseIterable, Identifiable {
    case freshInstall
    case addOpenHuman
    case repairLink
    case ready

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freshInstall:
            return L10n.t("全新安装", "Fresh Install")
        case .addOpenHuman:
            return L10n.t("补装 OpenHuman", "Add OpenHuman")
        case .repairLink:
            return L10n.t("修复记忆连接", "Repair Memory Bridge")
        case .ready:
            return L10n.t("已完成配置", "Configured")
        }
    }

    var subtitle: String {
        switch self {
        case .freshInstall:
            return L10n.t("一键安装 Hermes、OpenHuman、Hermes Web UI，并自动配置 OpenHuman 作为 Hermes 记忆库。", "Install Hermes, OpenHuman, and Hermes Web UI in one click, then configure OpenHuman as Hermes memory.")
        case .addOpenHuman:
            return L10n.t("检测到 Hermes，补装 OpenHuman，并把 Hermes 现有记忆迁移到 OpenHuman。", "Hermes is detected. Install OpenHuman and migrate existing Hermes memory into it.")
        case .repairLink:
            return L10n.t("Hermes 和 OpenHuman 已存在，但需要重新连接并关闭 Hermes 自带记忆。", "Hermes and OpenHuman exist, but the bridge must be repaired and Hermes native memory disabled.")
        case .ready:
            return L10n.t("当前机器已满足 Hermes 主控、OpenHuman 记忆库、Web UI 控制台的组合要求。", "This machine already matches the Hermes brain, OpenHuman memory, and Web UI console requirements.")
        }
    }

    var icon: String {
        switch self {
        case .freshInstall:
            return "sparkles"
        case .addOpenHuman:
            return "externaldrive.connected.to.line.below"
        case .repairLink:
            return "point.3.connected.trianglepath.dotted"
        case .ready:
            return "checkmark.seal.fill"
        }
    }

    var accent: Color {
        switch self {
        case .freshInstall:
            return SetupPalette.cyan
        case .addOpenHuman:
            return SetupPalette.emerald
        case .repairLink:
            return SetupPalette.amber
        case .ready:
            return DesignTokens.success
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .freshInstall:
            return L10n.t("开始一键安装", "Start One-click Install")
        case .addOpenHuman:
            return L10n.t("安装并迁移记忆", "Install and Migrate Memory")
        case .repairLink:
            return L10n.t("自动修复连接", "Auto-repair Bridge")
        case .ready:
            return L10n.t("执行完成检查", "Run Final Check")
        }
    }

    var completionTitle: String {
        switch self {
        case .freshInstall:
            return L10n.t("全新安装完成", "Fresh Install Complete")
        case .addOpenHuman:
            return L10n.t("OpenHuman 补装完成", "OpenHuman Installed")
        case .repairLink:
            return L10n.t("记忆连接修复完成", "Memory Bridge Repaired")
        case .ready:
            return L10n.t("配置检查完成", "Configuration Check Complete")
        }
    }

    var completionSubtitle: String {
        switch self {
        case .freshInstall:
            return L10n.t("Hermes 主控、OpenHuman 记忆库、Hermes Web UI 已完成安装与配置。", "Hermes brain, OpenHuman memory, and Hermes Web UI are installed and configured.")
        case .addOpenHuman:
            return L10n.t("OpenHuman 已补装完成，Hermes 记忆迁移和连接检查已进入完成状态。", "OpenHuman is installed; Hermes memory migration and bridge checks are complete.")
        case .repairLink:
            return L10n.t("Hermes 与 OpenHuman 的记忆连接已修复，后续可进入控制面板验证。", "The Hermes and OpenHuman memory bridge is repaired. You can verify it in the dashboard.")
        case .ready:
            return L10n.t("当前机器已满足主控、外置记忆库和 Web UI 控制台的目标组合。", "This machine matches the target brain, external memory, and Web UI console setup.")
        }
    }

    var requiresAPISetup: Bool {
        self == .freshInstall
    }

    var defaultsToMemoryMigration: Bool {
        switch self {
        case .addOpenHuman, .repairLink:
            return true
        case .freshInstall, .ready:
            return false
        }
    }

    func plannedSteps(
        reinstall: Bool,
        clearExisting: Bool,
        migrateMemory: Bool,
        reinstallHermes: Bool = false,
        reinstallOpenHuman: Bool = false,
        clearHermes: Bool = false,
        clearOpenHuman: Bool = false
    ) -> [String] {
        var steps: [String] = [
            L10n.t("检测 macOS 环境和 Homebrew/PATH 可用性", "Check macOS environment and Homebrew/PATH availability"),
            L10n.t("锁定当前本机验证版本；如果要最新版，请安装完成后在控制面板选择更新", "Use the locally verified version first; update from the dashboard after setup if needed"),
        ]

        switch self {
        case .freshInstall:
            steps.append(contentsOf: [
                L10n.t("安装 Hermes 主控", "Install Hermes brain"),
                L10n.t("安装 OpenHuman 并初始化 Vault", "Install OpenHuman and initialize the Vault"),
                L10n.t("安装 Hermes Web UI", "Install Hermes Web UI"),
                L10n.t("写入 Hermes -> OpenHuman 记忆连接配置", "Write Hermes -> OpenHuman memory bridge config"),
                L10n.t("关闭 Hermes 自带长期记忆写入", "Disable Hermes native long-term memory writes"),
                L10n.t("启动 Hermes Web UI 并抓取登录 token", "Start Hermes Web UI and read the login token"),
            ])
        case .addOpenHuman:
            steps.append(contentsOf: [
                L10n.t("保留现有 Hermes 安装", "Keep the existing Hermes installation"),
                L10n.t("安装 OpenHuman 并初始化 Vault", "Install OpenHuman and initialize the Vault"),
                L10n.t("扫描 Hermes 现有记忆文件", "Scan existing Hermes memory files"),
                L10n.t("迁移 Hermes 记忆到 OpenHuman Vault", "Migrate Hermes memory to OpenHuman Vault"),
                L10n.t("关闭 Hermes 自带长期记忆写入", "Disable Hermes native long-term memory writes"),
                L10n.t("检查 Hermes Web UI，缺失时提示安装", "Check Hermes Web UI and install it if missing"),
            ])
        case .repairLink:
            steps.append(contentsOf: [
                L10n.t("检查 Hermes 配置文件", "Check Hermes config files"),
                L10n.t("检查 OpenHuman Vault", "Check OpenHuman Vault"),
                L10n.t("重写 Hermes -> OpenHuman 记忆连接配置", "Rewrite Hermes -> OpenHuman memory bridge config"),
                L10n.t("关闭 Hermes 本地 MEMORY/USER 写入，改由 OpenHuman provider 负责召回和新增长期记忆", "Disable local Hermes MEMORY/USER writes; OpenHuman provider handles recall and new long-term memory"),
                L10n.t("执行连接健康检查", "Run bridge health checks"),
            ])
        case .ready:
            steps.append(contentsOf: [
                L10n.t("刷新服务状态", "Refresh service status"),
                L10n.t("确认 Hermes 自带长期记忆已关闭", "Confirm Hermes native long-term memory is disabled"),
                L10n.t("确认 Hermes 正在使用 OpenHuman 作为记忆库", "Confirm Hermes uses OpenHuman as memory"),
                L10n.t("确认 Hermes 长期记忆已经迁移到 OpenHuman，短期日志保留本地", "Confirm Hermes long-term memory is migrated to OpenHuman while short-term logs remain local"),
                L10n.t("读取 Hermes Web UI token", "Read Hermes Web UI token"),
                L10n.t("生成完成页并显示可复制地址/Token", "Show completion page with copyable URL/token"),
            ])
        }

        if reinstall {
            let separator = L10n.current == .en ? ", " : "、"
            let targets = [
                reinstallHermes ? "Hermes" : nil,
                reinstallOpenHuman ? "OpenHuman" : nil,
            ].compactMap { $0 }.joined(separator: separator)
            steps.insert(L10n.t("用户选择重新安装：\(targets.isEmpty ? "待选择组件" : targets)", "User selected reinstall: \(targets.isEmpty ? "select components" : targets)"), at: min(2, steps.count))
        }
        if clearExisting {
            let separator = L10n.current == .en ? ", " : "、"
            let targets = [
                clearHermes ? "Hermes" : nil,
                clearOpenHuman ? "OpenHuman" : nil,
            ].compactMap { $0 }.joined(separator: separator)
            steps.insert(L10n.t("用户选择清除：\(targets.isEmpty ? "待选择组件" : targets)，执行前会要求二次确认", "User selected clear: \(targets.isEmpty ? "select components" : targets). A second confirmation is required before running."), at: min(3, steps.count))
        }
        if migrateMemory && self != .freshInstall {
            steps.append(L10n.t("迁移并校验 Hermes 长期记忆，短期日志保留在本地", "Migrate and verify Hermes long-term memory; short-term logs stay local"))
        }

        return steps
    }
}

struct SetupDetectionSnapshot {
    let hermesInstalled: Bool
    let openHumanInstalled: Bool
    let webUIInstalled: Bool
    let memoryLinked: Bool
    let memoryMigrated: Bool
    let memoryIssues: [String]
    let memoryWarnings: [String]
    let openHumanDocumentCount: Int
    let legacyHermesMemoryCount: Int
    let tokenPath: String
    let vaultPath: String

    static let placeholder = SetupDetectionSnapshot(
        hermesInstalled: false,
        openHumanInstalled: false,
        webUIInstalled: false,
        memoryLinked: false,
        memoryMigrated: false,
        memoryIssues: [],
        memoryWarnings: [],
        openHumanDocumentCount: 0,
        legacyHermesMemoryCount: 0,
        tokenPath: NSHomeDirectory() + "/.hermes-web-ui/.token",
        vaultPath: NSHomeDirectory() + "/.openhuman/vault"
    )

    var matchedScenario: SetupScenario {
        if !hermesInstalled {
            return .freshInstall
        }
        if hermesInstalled && !openHumanInstalled {
            return .addOpenHuman
        }
        if hermesInstalled && openHumanInstalled && (!memoryLinked || !memoryMigrated) {
            return .repairLink
        }
        return .ready
    }
}

enum SetupWizardStage {
    case detecting
    case overview
    case running
    case api
    case summary
}

enum SetupPalette {
    static let ink = Color(red: 0.020, green: 0.024, blue: 0.026)
    static let abyss = Color(red: 0.008, green: 0.014, blue: 0.016)
    static let emerald = Color(red: 0.08, green: 0.78, blue: 0.48)
    static let cyan = Color(red: 0.18, green: 0.70, blue: 0.92)
    static let amber = Color(red: 0.96, green: 0.66, blue: 0.22)
    static let ruby = Color(red: 0.95, green: 0.23, blue: 0.30)
    static let panel = Color(red: 0.045, green: 0.052, blue: 0.055)
    static let panelRaised = Color(red: 0.070, green: 0.078, blue: 0.082)
}

// MARK: - Setup Wizard

struct SetupWizardView: View {
    @ObservedObject var manager: ServiceManager
    let onComplete: () -> Void

    @AppStorage("configuredModelName") private var configuredModelName = ""
    @AppStorage("configuredAPIBaseURL") private var configuredAPIBaseURL = ""

    @State private var stage: SetupWizardStage = .detecting
    @State private var snapshot = SetupDetectionSnapshot.placeholder
    @State private var selectedScenario: SetupScenario = .freshInstall
    @State private var installLogs: [String] = []
    @State private var progress: Double = 0
    @State private var currentStep = L10n.t("准备检测", "Preparing detection")
    @State private var reinstallSelected = false
    @State private var clearSelected = false
    @State private var migrateMemorySelected = true
    @State private var reinstallHermesSelected = true
    @State private var reinstallOpenHumanSelected = true
    @State private var clearHermesSelected = false
    @State private var clearOpenHumanSelected = false
    @State private var apiBaseURL = ""
    @State private var apiKey = ""
    @State private var modelName = ""
    @State private var runFinished = false
    @State private var runSucceeded = false
    @State private var apiSaveInProgress = false
    @State private var showClearConfirmation = false

    private var unlockAllCardsForTesting: Bool {
        AppRuntimeMode.uiPrototype
    }

    var body: some View {
        ZStack {
            SetupBackground()

            GeometryReader { proxy in
                Group {
                    switch stage {
                    case .detecting:
                        SetupLoadingView()
                    case .overview:
                        overview
                    case .running:
                        SetupRunView(
                            scenario: selectedScenario,
                            progress: progress,
                            currentStep: currentStep,
                            logs: installLogs,
                            isFinished: runFinished,
                            succeeded: runSucceeded,
                            onBack: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                    stage = .overview
                                }
                            },
                            onContinue: {
                                if selectedScenario.requiresAPISetup {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                        stage = .api
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                        stage = .summary
                                    }
                                }
                            }
                        )
                    case .api:
                        APIConfigurationView(
                            baseURL: $apiBaseURL,
                            apiKey: $apiKey,
                            modelName: $modelName,
                            onSkip: {
                                configuredModelName = ""
                                configuredAPIBaseURL = ""
                                if selectedScenario == .freshInstall {
                                    manager.startAll(openBrowserIfWebUIRunning: true)
                                }
                                refreshCompletionData()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                    stage = .summary
                                }
                            },
                            isSaving: apiSaveInProgress,
                            onSave: {
                                saveModelConfiguration()
                            }
                        )
                    case .summary:
                        completionSummary
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
                .padding(.top, topContentPadding(for: proxy))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startDetection()
            refreshCompletionData()
        }
        .alert(L10n.t("确认清除选中组件？", "Clear selected components?"), isPresented: $showClearConfirmation) {
            Button(L10n.t("取消", "Cancel"), role: .cancel) {}
            Button(L10n.t("确认备份并清除", "Back up and clear"), role: .destructive) {
                beginSetupRun()
            }
        } message: {
            Text(L10n.t("这会先把选中的 Hermes/OpenHuman 数据移动到 ~/.hermes-manager/backups，再继续安装或修复。源路径会暂时不可用，请确认你确实要重置这些组件。", "This first moves selected Hermes/OpenHuman data into ~/.hermes-manager/backups, then continues install or repair. Source paths will be temporarily unavailable, so confirm you really want to reset these components."))
        }
    }

    private var completionSummary: some View {
        ScrollView(.vertical, showsIndicators: true) {
            SetupCompletionView(
                manager: manager,
                scenario: selectedScenario,
                onEnterDashboard: onComplete
            )
            .padding(.bottom, 28)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func topContentPadding(for proxy: GeometryProxy) -> CGFloat {
        let safeTop = proxy.safeAreaInsets.top
        let titlebarAllowance: CGFloat = safeTop < 16 ? 42 : 12
        return max(18, safeTop + titlebarAllowance)
    }

    private var overview: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    SetupHero(snapshot: snapshot)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L10n.t("选择安装状态", "Choose Setup State"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(DesignTokens.textPrimary)
                            Spacer()
                        }

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(SetupScenario.allCases) { scenario in
                                let matched = scenario == snapshot.matchedScenario
                                SetupScenarioCard(
                                    scenario: scenario,
                                    isMatched: matched,
                                    isSelected: selectedScenario == scenario,
                                    isEnabled: unlockAllCardsForTesting || matched
                                ) {
                                    selectedScenario = scenario
                                    migrateMemorySelected = scenario.defaultsToMemoryMigration
                                }
                            }
                        }
                    }

                    if selectedScenario != .freshInstall && selectedScenario != .ready {
                        SetupRecoveryOptions(
                            scenario: selectedScenario,
                            reinstallSelected: $reinstallSelected,
                            clearSelected: $clearSelected,
                            migrateMemorySelected: $migrateMemorySelected,
                            reinstallHermesSelected: $reinstallHermesSelected,
                            reinstallOpenHumanSelected: $reinstallOpenHumanSelected,
                            clearHermesSelected: $clearHermesSelected,
                            clearOpenHumanSelected: $clearOpenHumanSelected
                        )
                    }

                    if selectedScenario == .freshInstall || selectedScenario == .ready {
                        SetupScenarioInfoPanel(scenario: selectedScenario)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)

                SetupPlanPanel(
                    scenario: selectedScenario,
                    snapshot: snapshot,
                    reinstallSelected: reinstallSelected,
                    clearSelected: clearSelected,
                    migrateMemorySelected: migrateMemorySelected,
                    reinstallHermesSelected: reinstallHermesSelected,
                    reinstallOpenHumanSelected: reinstallOpenHumanSelected,
                    clearHermesSelected: clearHermesSelected,
                    clearOpenHumanSelected: clearOpenHumanSelected,
                    onRefresh: startDetection,
                    onPrimary: handlePrimaryAction
                )
                .frame(width: 330)
            }
            .padding(.bottom, AppRuntimeMode.uiPrototype ? 96 : 56)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private func startDetection() {
        stage = .detecting
        currentStep = L10n.t("扫描本机 Hermes/OpenHuman/Web UI 状态", "Scanning local Hermes/OpenHuman/Web UI status")
        SetupEnvironmentDetector.detect { detected in
            snapshot = detected
            selectedScenario = detected.matchedScenario
            migrateMemorySelected = detected.matchedScenario.defaultsToMemoryMigration
            manager.readToken()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                stage = .overview
            }
        }
    }

    private func handlePrimaryAction() {
        if AppRuntimeMode.uiPrototype {
            beginSetupRun()
            return
        }
        if clearSelected && (clearHermesSelected || clearOpenHumanSelected) {
            showClearConfirmation = true
            return
        }
        beginSetupRun()
    }

    private func beginSetupRun() {
        installLogs = []
        progress = 0
        runFinished = false
        runSucceeded = false
        currentStep = L10n.t("准备执行", "Preparing")

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            stage = .running
        }

        let options = SetupExecutionOptions(
            scenario: selectedScenario,
            reinstall: reinstallSelected,
            clearExisting: clearSelected,
            migrateMemory: migrateMemorySelected,
            reinstallHermes: reinstallSelected && reinstallHermesSelected,
            reinstallOpenHuman: reinstallSelected && reinstallOpenHumanSelected,
            clearHermes: clearSelected && clearHermesSelected,
            clearOpenHuman: clearSelected && clearOpenHumanSelected,
            startWebUIAfterRun: selectedScenario != .freshInstall
        )

        if AppRuntimeMode.uiPrototype {
            simulateSetupRun(options: options)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let semaphore = DispatchSemaphore(value: 0)
            var resolvedManifest = RemoteVersionManifest.bundled
            var manifestSource = L10n.t("内置离线清单", "bundled offline manifest")

            RemoteVersionManifestService.fetch { result in
                switch result {
                case .success(let value):
                    resolvedManifest = value.0
                    manifestSource = value.1
                case .failure(let error):
                    manifestSource = L10n.t("远程清单读取失败，已回退内置离线清单：\(error.localizedDescription)", "Remote manifest failed; using bundled offline manifest: \(error.localizedDescription)")
                }
                semaphore.signal()
            }
            semaphore.wait()

            DispatchQueue.main.async {
                installLogs.append(L10n.t("[INFO] 版本清单来源：\(manifestSource)", "[INFO] Version manifest source: \(manifestSource)"))
                installLogs.append(L10n.t("[INFO] 目标版本：Hermes \(resolvedManifest.components.hermes.displayVersion)，OpenHuman \(resolvedManifest.components.openHuman.displayVersion)，Hermes Web UI \(VersionFormatting.displayVersion(resolvedManifest.components.hermesWebUI.version))", "[INFO] Target versions: Hermes \(resolvedManifest.components.hermes.displayVersion), OpenHuman \(resolvedManifest.components.openHuman.displayVersion), Hermes Web UI \(VersionFormatting.displayVersion(resolvedManifest.components.hermesWebUI.version))"))
            }

            let result = SetupExecutionService(versionManifest: resolvedManifest).run(options: options) { update in
                DispatchQueue.main.async {
                    currentStep = update.step
                    progress = update.progress
                    installLogs.append(update.logLine)
                }
            }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    runSucceeded = true
                    progress = 1
                    currentStep = L10n.t("执行完成", "Run complete")
                case .failure(let error):
                    runSucceeded = false
                    currentStep = L10n.t("执行失败", "Run failed")
                    installLogs.append("[ERROR] \(error.localizedDescription)")
                }
                runFinished = true
                refreshCompletionData()
            }
        }
    }

    private func simulateSetupRun(options: SetupExecutionOptions) {
        let steps = selectedScenario.plannedSteps(
            reinstall: reinstallSelected,
            clearExisting: clearSelected,
            migrateMemory: migrateMemorySelected,
            reinstallHermes: reinstallHermesSelected,
            reinstallOpenHuman: reinstallOpenHumanSelected,
            clearHermes: clearHermesSelected,
            clearOpenHuman: clearOpenHumanSelected
        )
        installLogs = [
            L10n.t("[UI] 当前为 UI Prototype 模式，本次执行只模拟界面流程。", "[UI] UI Prototype mode: this run only simulates the interface flow."),
            L10n.t("[UI] 不会安装、重装、清除、迁移、启动 Hermes/Web UI，也不会写入 Hermes/OpenHuman 文件或数据库。", "[UI] No install, reinstall, clear, migration, service start, or Hermes/OpenHuman file/database writes will occur."),
        ]

        let total = max(steps.count, 1)
        for (index, step) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.20) {
                currentStep = step
                progress = Double(index + 1) / Double(total)
                installLogs.append("[UI STEP] \(step)")
                installLogs.append(L10n.t("[UI OK] 已模拟完成：\(step)", "[UI OK] Simulated complete: \(step)"))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(total) * 0.20 + 0.15) {
            runSucceeded = true
            runFinished = true
            progress = 1
            currentStep = L10n.t("UI 模拟执行完成", "UI simulation complete")
            installLogs.append(L10n.t("[UI DONE] 四个安装状态选项均可安全测试，未执行真实系统命令。", "[UI DONE] All four setup state options are safe to test; no real system command was executed."))
        }
    }

    private func saveModelConfiguration() {
        let trimmedModelName = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let configuration = ModelAPIConfiguration(
            baseURL: trimmedBaseURL,
            apiKey: apiKey,
            modelName: trimmedModelName
        )

        if AppRuntimeMode.uiPrototype {
            configuredModelName = trimmedModelName
            configuredAPIBaseURL = trimmedBaseURL
            installLogs.append(L10n.t("[UI] 已模拟保存 API 配置；未写入 ~/.hermes 或 Hermes Web UI 配置。", "[UI] Simulated saving API config; did not write ~/.hermes or Hermes Web UI config."))
            manager.showToast(title: L10n.t("UI 模式", "UI Mode"), message: L10n.t("已模拟保存模型配置，没有写入真实配置文件", "Simulated saving model config; no real config file was written"), icon: "paintbrush.fill", accent: SetupPalette.cyan)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                stage = .summary
            }
            return
        }

        apiSaveInProgress = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = SetupExecutionService().configureModelAPI(configuration) { line in
                DispatchQueue.main.async {
                    installLogs.append(line)
                }
            }

            DispatchQueue.main.async {
                apiSaveInProgress = false
                switch result {
                case .success:
                    configuredModelName = trimmedModelName
                    configuredAPIBaseURL = trimmedBaseURL
                    if selectedScenario == .freshInstall {
                        manager.startAll(openBrowserIfWebUIRunning: true)
                    }
                    refreshCompletionData()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        stage = .summary
                    }
                case .failure(let error):
                    installLogs.append("[ERROR] \(error.localizedDescription)")
                    manager.showToast(
                        title: L10n.t("API 配置失败", "API Config Failed"),
                        message: error.localizedDescription,
                        icon: "exclamationmark.triangle.fill",
                        accent: DesignTokens.error
                    )
                }
            }
        }
    }

    private func refreshCompletionData() {
        manager.readToken()
        manager.refreshModelStatus()
        manager.checkStatus(force: true)
    }
}

// MARK: - Detector

enum SetupEnvironmentDetector {
    static func detect(completion: @escaping (SetupDetectionSnapshot) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let home = NSHomeDirectory()
            let hermesInstalled = commandExists("hermes") || FileManager.default.fileExists(atPath: home + "/.hermes")
            let openHumanInstalled = FileManager.default.fileExists(atPath: home + "/.openhuman")
                || FileManager.default.fileExists(atPath: home + "/.openhuman/vault")
                || commandExists("openhuman")
            let webUIInstalled = commandExists("hermes-web-ui")
                || FileManager.default.fileExists(atPath: home + "/.hermes-web-ui")
                || FileManager.default.fileExists(atPath: home + "/.hermes-manager/runtime/hermes-web-ui/node_modules/.bin/hermes-web-ui")
            let vaultPath = home + "/.openhuman/vault"
            let memoryDiagnostic = MemoryBridgeDiagnosticService.diagnose(home: home)
            let memoryMigrated = memoryDiagnostic.migrated
            let memoryLinked = hermesInstalled
                && openHumanInstalled
                && memoryDiagnostic.linked

            let snapshot = SetupDetectionSnapshot(
                hermesInstalled: hermesInstalled,
                openHumanInstalled: openHumanInstalled,
                webUIInstalled: webUIInstalled,
                memoryLinked: memoryLinked,
                memoryMigrated: memoryMigrated,
                memoryIssues: memoryDiagnostic.issues,
                memoryWarnings: memoryDiagnostic.warnings,
                openHumanDocumentCount: memoryDiagnostic.openHumanDocumentCount,
                legacyHermesMemoryCount: memoryDiagnostic.legacyHermesMemoryCount,
                tokenPath: locateWebUITokenPath(home: home),
                vaultPath: vaultPath
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                completion(snapshot)
            }
        }
    }

    private static func commandExists(_ command: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", "command -v \(command) >/dev/null 2>&1"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    private static func fileContains(path: String, needle: String) -> Bool {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        return content.localizedCaseInsensitiveContains(needle)
    }

    private static func yamlScalarIsFalse(path: String, key: String) -> Bool {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        return content.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            return trimmed == "\(key): false" || trimmed == "\(key): no" || trimmed == "\(key): 0"
        }
    }

    private static func yamlNestedScalarEquals(path: String, block blockName: String, key: String, value: String) -> Bool {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        let lines = content.components(separatedBy: .newlines)
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

    private static func yamlListContains(path: String, block blockName: String, key: String, value: String) -> Bool {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return false
        }
        let lines = content.components(separatedBy: .newlines)
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

    private static func countMemoryFiles(_ root: String) -> Int {
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
                if shouldSkipMigrationPath(path) { enumerator.skipDescendants() }
                continue
            }
            if shouldCountMemoryPath(path), !shouldSkipMigrationPath(path) {
                count += 1
            }
        }
        return count
    }

    private static func countLongTermHermesMemory(home: String) -> Int {
        countMemoryFiles(home + "/.hermes/memories")
            + countLongTermTopLevelHermesNotes(home: home)
            + countLongTermHermesMemoryDirectoryFiles(home: home)
    }

    private static func countLongTermTopLevelHermesNotes(home: String) -> Int {
        let root = home + "/.hermes"
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermTopLevelHermesNote(entry), !shouldSkipMigrationPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private static func countLongTermHermesMemoryDirectoryFiles(home: String) -> Int {
        let root = home + "/.hermes/memory"
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, isLongTermMemoryDirectoryFile(entry), !shouldSkipMigrationPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private static func isLongTermTopLevelHermesNote(_ name: String) -> Bool {
        let upper = name.uppercased()
        let allowlist = [
            "MEMORY.MD", "USER.MD", "SOUL.MD", "IDENTITY.MD",
            "MEMORY-HUB.MD", "SESSION-STATE.MD", "HEARTBEAT.MD",
            "BOOTSTRAP.MD", "AGENTS.MD", "TOOLS.MD",
        ]
        return allowlist.contains(upper) || upper.hasPrefix("PERSONAL-MODEL-")
    }

    private static func isLongTermMemoryDirectoryFile(_ name: String) -> Bool {
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

    private static func countTopLevelMarkdownFiles(_ root: String) -> Int {
        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: root) else { return 0 }
        return entries.reduce(0) { partial, entry in
            let path = root + "/" + entry
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            guard !isDirectory.boolValue, entry.lowercased().hasSuffix(".md"), !shouldSkipMigrationPath(path) else {
                return partial
            }
            return partial + 1
        }
    }

    private static func shouldCountMemoryPath(_ path: String) -> Bool {
        let lower = path.lowercased()
        return lower.hasSuffix(".md")
            || lower.hasSuffix(".json")
            || lower.hasSuffix(".jsonl")
            || lower.hasSuffix(".txt")
            || lower.hasSuffix(".yaml")
            || lower.hasSuffix(".yml")
            || lower.hasSuffix(".toml")
    }

    private static func shouldSkipMigrationPath(_ path: String) -> Bool {
        let lower = path.lowercased()
        let blocked = [
            ".git/", "node_modules/", ".venv/", "venv/", "__pycache__/",
            ".dreams/", "auth", "token", "secret", "apikey", "api_key",
            "credential", "password", "cookie", "cost-", "dream-", ".db", ".sqlite",
        ]
        return blocked.contains { lower.contains($0) }
    }

    private static func locateWebUITokenPath(home: String) -> String {
        let candidates = [
            home + "/.hermes-web-ui/.token",
            home + "/Library/Application Support/Hermes Web UI/.token",
            home + "/Library/Application Support/hermes-web-ui/.token",
            home + "/.config/hermes-web-ui/.token",
            home + "/.local/share/hermes-web-ui/.token",
            home + "/.hermes/web-ui/.token",
            home + "/.hermes/hermes-web-ui/.token",
        ]
        return candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) ?? candidates[0]
    }
}

// MARK: - Setup Components

struct SetupBackground: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        SetupPalette.abyss,
                        SetupPalette.ink,
                        Color(red: 0.018, green: 0.038, blue: 0.036),
                        Color(red: 0.018, green: 0.025, blue: 0.030),
                        DesignTokens.canvas,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                DiffuseOrb(
                    color: SetupPalette.emerald,
                    size: max(360, min(width, height) * 0.46),
                    opacity: 0.24,
                    blur: 92
                )
                .offset(x: -width * 0.36, y: -height * 0.30)

                DiffuseOrb(
                    color: SetupPalette.cyan,
                    size: max(420, min(width, height) * 0.58),
                    opacity: 0.18,
                    blur: 118
                )
                .offset(x: width * 0.35, y: height * 0.28)

                DiffuseOrb(
                    color: SetupPalette.amber,
                    size: max(260, min(width, height) * 0.34),
                    opacity: 0.07,
                    blur: 110
                )
                .offset(x: width * 0.08, y: -height * 0.45)

                DiffuseOrb(
                    color: Color.white,
                    size: max(180, min(width, height) * 0.24),
                    opacity: 0.035,
                    blur: 80
                )
                .offset(x: -width * 0.04, y: -height * 0.04)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.045),
                        Color.clear,
                        SetupPalette.emerald.opacity(0.025),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 38) {
                    ForEach(0..<12, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.026))
                            .frame(height: 1)
                    }
                }
                .rotationEffect(.degrees(-8))
                .offset(y: 22)

                HStack(spacing: 48) {
                    ForEach(0..<18, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.010))
                            .frame(width: 1)
                    }
                }
                .rotationEffect(.degrees(-8))
                .offset(x: 18, y: 22)

                RadialGradient(
                    colors: [
                        Color.clear,
                        SetupPalette.abyss.opacity(0.12),
                        SetupPalette.abyss.opacity(0.48),
                    ],
                    center: .center,
                    startRadius: min(width, height) * 0.32,
                    endRadius: max(width, height) * 0.72
                )

                Rectangle()
                    .fill(Color.black.opacity(0.10))
            }
        }
        .ignoresSafeArea()
    }
}

struct DiffuseOrb: View {
    let color: Color
    let size: CGFloat
    let opacity: Double
    let blur: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(opacity))
                .frame(width: size, height: size)
                .blur(radius: blur)
            Circle()
                .fill(Color.white.opacity(opacity * 0.16))
                .frame(width: size * 0.34, height: size * 0.34)
                .blur(radius: blur * 0.52)
                .offset(x: -size * 0.12, y: -size * 0.10)
        }
        .allowsHitTesting(false)
    }
}

struct DiffusePanelBackground: View {
    var cornerRadius: CGFloat
    var tint: Color = SetupPalette.emerald
    var opacity: Double = 0.12

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SetupPalette.panel.opacity(0.96),
                    SetupPalette.panelRaised.opacity(0.70),
                    SetupPalette.panel.opacity(0.88),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [tint.opacity(opacity), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 280
            )

            RadialGradient(
                colors: [SetupPalette.cyan.opacity(opacity * 0.70), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 320
            )

            LinearGradient(
                colors: [Color.white.opacity(0.040), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SetupLoadingView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(SetupPalette.emerald.opacity(0.18), lineWidth: 12)
                    .frame(width: 92, height: 92)
                Circle()
                    .trim(from: 0, to: 0.68)
                    .stroke(
                        LinearGradient(colors: [SetupPalette.emerald, SetupPalette.cyan], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 92, height: 92)
                    .rotationEffect(.degrees(pulse ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                Image(systemName: "bolt.horizontal.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(SetupPalette.emerald)
            }

            Text(L10n.t("正在检测本机环境", "Checking Local Environment"))
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)
            Text(L10n.t("扫描 Hermes、OpenHuman、Hermes Web UI、记忆连接状态", "Scanning Hermes, OpenHuman, Hermes Web UI, and memory bridge status"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            pulse = true
        }
    }
}

struct SetupHero: View {
    let snapshot: SetupDetectionSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hermes + OpenHuman")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(L10n.t("一键安装、连接并准备好你的 Hermes 工作台", "Install, connect, and prepare your Hermes workspace in one click"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignTokens.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("macOS Preview")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(SetupPalette.emerald)
                    Text(L10n.t("当前先安装本机验证版本", "Install the locally verified version first"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                }
            }

            Text(L10n.t("安装完成后，你可以直接和 Hermes 对话，重要信息会交给 OpenHuman 保存。当前先使用已验证版本，后续可在控制面板里检查更新。", "After setup, you can chat with Hermes right away, while OpenHuman keeps important long-term information. This installer uses a verified version first; updates can be checked later from the dashboard."))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignTokens.textTertiary)
                .lineSpacing(3)

            HStack(spacing: 8) {
                SetupHealthChip(title: "Hermes", isOn: snapshot.hermesInstalled)
                SetupHealthChip(title: "OpenHuman", isOn: snapshot.openHumanInstalled)
                SetupHealthChip(title: "Web UI", isOn: snapshot.webUIInstalled)
                SetupHealthChip(title: L10n.t("记忆连接", "Memory Bridge"), isOn: snapshot.memoryLinked)
                SetupHealthChip(title: L10n.t("长期记忆迁移", "Memory Migration"), isOn: snapshot.memoryMigrated)
            }

            if !snapshot.memoryIssues.isEmpty || !snapshot.memoryWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.t("记忆诊断", "Memory Diagnostics"))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(SetupPalette.amber)
                        .textCase(.uppercase)
                    ForEach(Array((snapshot.memoryIssues + snapshot.memoryWarnings).prefix(3)), id: \.self) { issue in
                        Text("• \(L10n.dynamic(issue))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignTokens.textTertiary)
                            .lineLimit(1)
                    }
                    Text(L10n.t("OpenHuman 文档 \(snapshot.openHumanDocumentCount) 条；Hermes 待迁移长期记忆 \(snapshot.legacyHermesMemoryCount) 个。", "OpenHuman docs: \(snapshot.openHumanDocumentCount); Hermes long-term items pending: \(snapshot.legacyHermesMemoryCount)."))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textMuted)
                        .lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
                .cornerRadius(14)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(SetupPalette.panel.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(SetupPalette.emerald.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

struct SetupHealthChip: View {
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((isOn ? SetupPalette.emerald : DesignTokens.textMuted).opacity(0.10))
        .cornerRadius(DesignTokens.radiusPill)
    }
}

struct SetupScenarioCard: View {
    let scenario: SetupScenario
    let isMatched: Bool
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(scenario.accent.opacity(0.13))
                            .frame(width: 36, height: 36)
                        Image(systemName: scenario.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(scenario.accent)
                    }

                    Spacer()

                    if isMatched {
                        Text(L10n.t("当前匹配", "Matched"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SetupPalette.emerald)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(SetupPalette.emerald.opacity(0.10))
                            .cornerRadius(DesignTokens.radiusPill)
            } else if isEnabled {
                        Text(L10n.t("可选择", "Available"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DesignTokens.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(DesignTokens.surface3)
                            .cornerRadius(DesignTokens.radiusPill)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(scenario.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(scenario.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 138, alignment: .topLeading)
            .background(hovering || isSelected ? SetupPalette.panelRaised : SetupPalette.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? scenario.accent.opacity(0.75) : DesignTokens.borderSubtle, lineWidth: isSelected ? 1.4 : 1)
            )
            .cornerRadius(18)
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { value in
            withAnimation(.easeOut(duration: 0.14)) {
                hovering = value
            }
        }
    }
}

struct SetupRecoveryOptions: View {
    let scenario: SetupScenario
    @Binding var reinstallSelected: Bool
    @Binding var clearSelected: Bool
    @Binding var migrateMemorySelected: Bool
    @Binding var reinstallHermesSelected: Bool
    @Binding var reinstallOpenHumanSelected: Bool
    @Binding var clearHermesSelected: Bool
    @Binding var clearOpenHumanSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("高级选项", "Advanced Options"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.textSecondary)

            HStack(spacing: 10) {
                SetupOptionToggle(title: L10n.t("重新安装", "Reinstall"), subtitle: L10n.t("重装选中组件", "Reinstall selected components"), isOn: $reinstallSelected)
                SetupOptionToggle(title: L10n.t("全部清除", "Clear All"), subtitle: L10n.t("危险操作，默认不启用", "Dangerous; disabled by default"), isOn: $clearSelected)
                SetupOptionToggle(title: L10n.t("迁移记忆", "Migrate Memory"), subtitle: L10n.t("只迁移长期记忆", "Only migrate long-term memory"), isOn: $migrateMemorySelected)
            }

            if reinstallSelected {
                SetupComponentSelector(
                    title: L10n.t("重新安装范围", "Reinstall Scope"),
                    hermesSelected: $reinstallHermesSelected,
                    openHumanSelected: $reinstallOpenHumanSelected
                )
            }

            if clearSelected {
                SetupComponentSelector(
                    title: L10n.t("全部清除范围", "Clear Scope"),
                    hermesSelected: $clearHermesSelected,
                    openHumanSelected: $clearOpenHumanSelected
                )
            }

            SetupMigrationNote(scenario: scenario, migrateMemorySelected: migrateMemorySelected)
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.09))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
        .onChange(of: clearSelected) {
            if clearSelected {
                clearHermesSelected = true
                clearOpenHumanSelected = true
            } else {
                clearHermesSelected = false
                clearOpenHumanSelected = false
            }
        }
        .onChange(of: reinstallSelected) {
            if reinstallSelected && !reinstallHermesSelected && !reinstallOpenHumanSelected {
                reinstallHermesSelected = true
                reinstallOpenHumanSelected = true
            }
        }
    }
}

struct SetupOptionToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Spacer()
                    Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                }
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .topLeading)
            .background(isOn ? SetupPalette.emerald.opacity(0.08) : DesignTokens.surface2.opacity(0.55))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

struct SetupScenarioInfoPanel: View {
    let scenario: SetupScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(scenario == .freshInstall ? L10n.t("安装完成后会得到", "After install you get") : L10n.t("已完成配置的确认标准", "Configured-state criteria"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignTokens.textSecondary)
                Spacer()
                Text(scenario == .freshInstall ? L10n.t("交付物预览", "Deliverables") : L10n.t("无需迁移", "No migration needed"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(scenario.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(scenario.accent.opacity(0.10))
                    .cornerRadius(DesignTokens.radiusPill)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(items, id: \.title) { item in
                    SetupInfoTile(icon: item.icon, title: item.title, detail: item.detail, accent: scenario.accent)
                }
            }
        }
        .padding(14)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.09))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }

    private var items: [(icon: String, title: String, detail: String)] {
        switch scenario {
        case .freshInstall:
            return [
                ("globe", L10n.t("Web UI 地址", "Web UI URL"), L10n.t("完成页展示本机访问地址", "Completion page shows the local access URL")),
                ("key.fill", L10n.t("登录 Token", "Login Token"), L10n.t("自动读取并展示登录口令", "Automatically reads and shows the login token")),
                ("cpu", L10n.t("模型配置", "Model Config"), L10n.t("显示已配置模型或未配置状态", "Shows configured model or unconfigured state")),
                ("brain.head.profile", L10n.t("记忆架构", "Memory Architecture"), L10n.t("Hermes 主控，OpenHuman 记忆", "Hermes brain, OpenHuman memory")),
            ]
        case .ready:
            return [
                ("checkmark.shield", L10n.t("记忆关闭", "Memory Disabled"), L10n.t("Hermes 自带长期记忆已关闭", "Hermes native long-term memory is disabled")),
                ("externaldrive.connected.to.line.below", "OpenHuman", L10n.t("Hermes 已连接 OpenHuman Vault", "Hermes is connected to OpenHuman Vault")),
                ("tray.and.arrow.down", L10n.t("迁移确认", "Migration Verified"), L10n.t("Hermes 长期记忆已迁移完成", "Hermes long-term memory migration is complete")),
                ("rectangle.connected.to.line.below", L10n.t("控制面板", "Dashboard"), L10n.t("Web UI 和 CLI 可直接进入", "Web UI and CLI are ready to enter")),
            ]
        case .addOpenHuman, .repairLink:
            return []
        }
    }
}

struct SetupInfoTile: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(10)
        .background(DesignTokens.surface2.opacity(0.46))
        .cornerRadius(14)
    }
}

struct SetupComponentSelector: View {
    let title: String
    @Binding var hermesSelected: Bool
    @Binding var openHumanSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
                .frame(width: 92, alignment: .leading)

            SetupMiniToggle(title: "Hermes", isOn: $hermesSelected)
            SetupMiniToggle(title: "OpenHuman", isOn: $openHumanSelected)

            Spacer()
        }
        .padding(10)
        .background(DesignTokens.surface2.opacity(0.48))
        .cornerRadius(14)
    }
}

struct SetupMiniToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isOn ? SetupPalette.emerald : DesignTokens.textMuted)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isOn ? DesignTokens.textPrimary : DesignTokens.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isOn ? SetupPalette.emerald.opacity(0.08) : DesignTokens.surface3.opacity(0.65))
            .cornerRadius(DesignTokens.radiusPill)
        }
        .buttonStyle(.plain)
    }
}

struct SetupMigrationNote: View {
    let scenario: SetupScenario
    let migrateMemorySelected: Bool

    private var title: String {
        if migrateMemorySelected {
            return scenario == .addOpenHuman ? L10n.t("为什么默认迁移记忆", "Why memory migration is on by default") : L10n.t("修复时为什么迁移可选", "Why migration is optional during repair")
        }
        return L10n.t("已关闭迁移旧数据", "Legacy migration disabled")
    }

    private var message: String {
        if migrateMemorySelected {
            switch scenario {
            case .addOpenHuman:
                return L10n.t("补装 OpenHuman 时，Hermes 里通常已有长期记忆，所以默认导入到 OpenHuman；按日期保存的短期日志会保留在本地。", "When adding OpenHuman, Hermes usually already has long-term memory, so it is imported into OpenHuman by default; date-based short-term logs stay local.")
            case .repairLink:
                return L10n.t("修复连接时会先检查 Hermes 是否还有未迁移记忆；如果有，就导入 OpenHuman，避免主控切换后丢失历史。", "During bridge repair, Hermes is checked for unmigrated memory; if found, it is imported into OpenHuman to avoid losing history.")
            case .freshInstall, .ready:
                return L10n.t("当前状态不需要迁移 Hermes 长期记忆。", "This state does not need Hermes long-term memory migration.")
            }
        }

        return L10n.t("不会导入 Hermes 长期记忆，但仍会关闭 Hermes 自带长期记忆写入，并把 OpenHuman 设为记忆库；短期日志始终保留在本地。", "Hermes long-term memory will not be imported, but Hermes native long-term writes will still be disabled and OpenHuman will become the memory store; short-term logs always stay local.")
    }

    private var accent: Color {
        migrateMemorySelected ? SetupPalette.emerald : SetupPalette.amber
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: migrateMemorySelected ? "arrow.right.doc.on.clipboard" : "exclamationmark.triangle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                Text(message)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(10)
        .background(accent.opacity(0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct SetupPlanPanel: View {
    let scenario: SetupScenario
    let snapshot: SetupDetectionSnapshot
    let reinstallSelected: Bool
    let clearSelected: Bool
    let migrateMemorySelected: Bool
    let reinstallHermesSelected: Bool
    let reinstallOpenHumanSelected: Bool
    let clearHermesSelected: Bool
    let clearOpenHumanSelected: Bool
    let onRefresh: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(L10n.t("执行计划", "Execution Plan"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(DesignTokens.surface3)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            if !snapshot.webUIInstalled && scenario != .freshInstall {
                SetupNoticeCard(
                    icon: "globe.badge.chevron.backward",
                    title: L10n.t("Hermes Web UI 未检测到", "Hermes Web UI Not Detected"),
                    message: L10n.t("执行时会安装到 Hermes Manager 私有运行目录；已安装则自动跳过。", "It will be installed into Hermes Manager's private runtime directory; existing installs are skipped automatically.")
                )
            }

            Divider().background(DesignTokens.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(scenario.plannedSteps(
                        reinstall: reinstallSelected,
                        clearExisting: clearSelected,
                        migrateMemory: migrateMemorySelected,
                        reinstallHermes: reinstallHermesSelected,
                        reinstallOpenHuman: reinstallOpenHumanSelected,
                        clearHermes: clearHermesSelected,
                        clearOpenHuman: clearOpenHumanSelected
                    ).enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(scenario.accent)
                                .frame(width: 22, height: 22)
                                .background(scenario.accent.opacity(0.10))
                                .cornerRadius(7)
                            Text(step)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignTokens.textSecondary)
                                .lineSpacing(3)
                            Spacer()
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                Button(action: onPrimary) {
                    HStack {
                        Text(scenario.primaryActionTitle)
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black.opacity(0.86))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(colors: [scenario.accent, SetupPalette.emerald], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)

                Text(L10n.t("执行完成后先显示完成页", "Show the completion page after execution"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(DesignTokens.surface2.opacity(0.45))
                    .cornerRadius(12)
            }
        }
        .frame(maxHeight: AppRuntimeMode.uiPrototype ? 620 : .infinity, alignment: .top)
        .padding(18)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.11))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(22)
    }
}

struct SetupPathRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(DesignTokens.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct SetupNoticeCard: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(SetupPalette.amber)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(message)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .background(SetupPalette.amber.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SetupPalette.amber.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(14)
    }
}

struct SetupRunView: View {
    let scenario: SetupScenario
    let progress: Double
    let currentStep: String
    let logs: [String]
    let isFinished: Bool
    let succeeded: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    private var logTitle: String {
        scenario == .ready ? L10n.t("健康检查日志", "Health Check Logs") : L10n.t("安装日志", "Install Logs")
    }

    private var continueTitle: String {
        if scenario.requiresAPISetup {
            return L10n.t("进入 API 配置", "Open API Config")
        }
        return scenario == .ready ? L10n.t("查看检查结果", "View Check Result") : L10n.t("查看完成页", "View Completion Page")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(scenario.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(currentStep)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(scenario.accent)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(DesignTokens.surface2)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(LinearGradient(colors: [scenario.accent, SetupPalette.emerald], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geometry.size.width * progress))
                }
            }
            .frame(height: 10)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(logTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.textSecondary)
                    Spacer()
                    Text(isFinished ? (succeeded ? "COMPLETED" : "FAILED") : "LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isFinished ? (succeeded ? SetupPalette.emerald : DesignTokens.error) : SetupPalette.cyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(DesignTokens.surface2)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(logs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .id(index)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(logColor(for: line))
                                    .textSelection(.enabled)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                    }
                    .onChange(of: logs.count) {
                        if let last = logs.indices.last {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            .background(SetupPalette.ink.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(18)

            HStack {
                Button(action: onBack) {
                    Text(isFinished ? L10n.t("返回检测页", "Back to Detection") : L10n.t("执行中不可返回", "Cannot go back while running"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DesignTokens.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DesignTokens.surface2)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!isFinished)

                Spacer()

                Button(action: onContinue) {
                    Text(continueTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black.opacity(0.86))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(isFinished && succeeded ? SetupPalette.emerald : DesignTokens.textMuted)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(!isFinished || !succeeded)
            }
        }
        .padding(24)
        .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(24)
    }

    private func logColor(for line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("[error]") || lower.contains("失败") || lower.contains("failed") {
            return DesignTokens.error
        }
        if lower.contains("[warn]") || lower.contains("警告") || lower.contains("warn") {
            return SetupPalette.amber
        }
        if lower.contains("[ok]") || lower.contains("完成") || lower.contains("success") {
            return SetupPalette.emerald
        }
        if lower.contains("[step]") {
            return SetupPalette.cyan
        }
        return DesignTokens.textSecondary
    }
}

struct APIConfigurationView: View {
    @Binding var baseURL: String
    @Binding var apiKey: String
    @Binding var modelName: String
    let onSkip: () -> Void
    let isSaving: Bool
    let onSave: () -> Void
    @State private var discoveredModels: [String] = []
    @State private var modelFetchInProgress = false
    @State private var modelFetchMessage = ""

    private var canSave: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.t("配置模型 API", "Configure Model API"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(L10n.t("支持 OpenAI 兼容接口。保存后会写入 Hermes CLI 配置，并更新 Hermes Web UI 的模型可见性。API Key 只写入当前用户本机配置，不会上传。", "Supports OpenAI-compatible APIs. Saving writes Hermes CLI config and updates Hermes Web UI model visibility. API keys stay on this local user account and are never uploaded."))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(4)

                VStack(spacing: 12) {
                    SetupTextField(title: "API Base URL", placeholder: "https://api.openai.com/v1", text: $baseURL)
                    SetupSecureField(title: "API Key", placeholder: "sk-...", text: $apiKey)
                    SetupTextField(title: L10n.t("模型名称", "Model Name"), placeholder: "gpt-4.1 / kimi-k2 / deepseek-chat", text: $modelName)
                }

                if !discoveredModels.isEmpty || !modelFetchMessage.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if !modelFetchMessage.isEmpty {
                            Text(modelFetchMessage)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(discoveredModels.isEmpty ? SetupPalette.amber : SetupPalette.emerald)
                        }
                        if !discoveredModels.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(discoveredModels.prefix(24), id: \.self) { model in
                                        Button {
                                            modelName = model
                                        } label: {
                                            Text(model)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(modelName == model ? .black.opacity(0.86) : DesignTokens.textSecondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 7)
                                                .background(modelName == model ? SetupPalette.emerald : DesignTokens.surface2.opacity(0.72))
                                                .cornerRadius(DesignTokens.radiusPill)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button(action: fetchModels) {
                        Label(modelFetchInProgress ? L10n.t("拉取中...", "Fetching...") : L10n.t("自动拉取模型", "Fetch Models"), systemImage: "arrow.down.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(modelFetchInProgress ? DesignTokens.textMuted : DesignTokens.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(DesignTokens.surface2.opacity(0.7))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(modelFetchInProgress || baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help(L10n.t("根据 API Base URL 和 API Key 请求 /models", "Request /models using API Base URL and API Key"))

                    Spacer()

                    Button(action: onSkip) {
                        Text(L10n.t("跳过", "Skip"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignTokens.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(DesignTokens.surface2)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)

                    Button(action: onSave) {
                        Text(isSaving ? L10n.t("正在保存...", "Saving...") : L10n.t("保存并查看完成页", "Save and View Completion"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(canSave ? .black.opacity(0.86) : DesignTokens.textMuted)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(canSave ? SetupPalette.emerald : DesignTokens.surface3)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || !canSave)
                    .help(canSave ? L10n.t("写入 Hermes CLI 和 Web UI 模型配置", "Write Hermes CLI and Web UI model config") : L10n.t("API Base URL、API Key、模型名称需要同时填写；也可以点击跳过", "API Base URL, API Key, and model name are required; you can also skip"))
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t("将自动写入", "Will Write To"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DesignTokens.textSecondary)
                APIWriteTarget(title: "Hermes CLI", path: L10n.t("当前 active profile 的 config.yaml / .env", "Current active profile config.yaml / .env"))
                APIWriteTarget(title: "Hermes Web UI", path: L10n.t("自动检测 .hermes-web-ui 数据目录", "Auto-detected .hermes-web-ui data directory"))
                APIWriteTarget(title: L10n.t("模型列表", "Model List"), path: L10n.t("通过兼容 API 拉取", "Fetched through the compatible API"))
                Spacer()
                Text(L10n.t("OpenHuman 不需要模型 API，它只作为 Hermes 的长期记忆库。", "OpenHuman does not need a model API; it only acts as Hermes long-term memory."))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(4)
            }
            .padding(18)
            .frame(width: 280)
            .background(DiffusePanelBackground(cornerRadius: 20, tint: SetupPalette.emerald, opacity: 0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .padding(24)
        .background(DiffusePanelBackground(cornerRadius: 24, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(24)
    }

    private func fetchModels() {
        modelFetchInProgress = true
        modelFetchMessage = AppRuntimeMode.uiPrototype ? L10n.t("UI 模式：正在模拟模型列表...", "UI mode: simulating model list...") : L10n.t("正在请求 /models...", "Requesting /models...")
        discoveredModels = []

        ModelCatalogService.fetchOpenAICompatibleModels(baseURL: baseURL, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                modelFetchInProgress = false
                switch result {
                case .success(let models):
                    discoveredModels = models
                    modelFetchMessage = models.isEmpty ? L10n.t("没有从接口返回模型，请手动填写模型名称。", "No models were returned; enter a model name manually.") : L10n.t("已拉取 \(models.count) 个模型，点击可填入。", "Fetched \(models.count) models. Click one to fill it in.")
                    if modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let first = models.first {
                        modelName = first
                    }
                case .failure(let error):
                    modelFetchMessage = L10n.t("模型拉取失败：\(error.localizedDescription)", "Model fetch failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct SetupCompletionView: View {
    @ObservedObject var manager: ServiceManager
    let scenario: SetupScenario
    let onEnterDashboard: () -> Void
    @State private var tokenHidden = true
    @State private var copiedToken = false
    @State private var copiedWebURL = false
    @AppStorage("configuredModelName") private var configuredModelName = ""

    private var displayToken: String {
        manager.webUIToken.isEmpty ? L10n.t("未检测到登录 Token", "Login token not detected") : manager.webUIToken
    }

    private var tokenPresentation: String {
        tokenHidden ? String(repeating: "•", count: max(24, displayToken.count)) : displayToken
    }

    private var displayModel: String {
        let liveModel = manager.currentModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !liveModel.isEmpty { return liveModel }
        return configuredModelName.isEmpty ? L10n.t("未检测到当前模型", "Current model not detected") : configuredModelName
    }

    private var displayProvider: String {
        let provider = manager.currentModelProvider.trimmingCharacters(in: .whitespacesAndNewlines)
        return provider.isEmpty ? L10n.t("未检测", "Not detected") : provider
    }

    private var modelInventoryValue: String {
        if manager.detectedProviderCount > 0 || manager.detectedModelCount > 0 {
            return L10n.t("\(manager.detectedProviderCount) 个供应商 / \(manager.detectedModelCount) 个模型", "\(manager.detectedProviderCount) providers / \(manager.detectedModelCount) models")
        }
        return L10n.t("清单未读取", "Inventory not read")
    }

    private var modelInventoryDetail: String {
        manager.modelCalibrationHealthy ? L10n.t("Web UI 与 CLI 已校准", "Web UI and CLI are calibrated") : L10n.dynamic(manager.modelCalibrationSummary)
    }

    private var memoryValue: String {
        if manager.openHumanMemoryLinked && manager.migratedMemoryAvailable {
            return L10n.t("OpenHuman 已接管", "OpenHuman Active")
        }
        if manager.openHumanMemoryLinked {
            return L10n.t("已连接，待校验迁移", "Connected; migration pending")
        }
        return L10n.t("未完成连接", "Bridge incomplete")
    }

    private var memoryDetail: String {
        let documents = manager.openHumanDocumentCount
        let migrated = manager.migratedMemoryDocumentCount
        if documents > 0 || migrated > 0 {
            return L10n.t("OpenHuman \(documents) 条 / Hermes 迁移 \(migrated) 条", "OpenHuman \(documents) docs / Hermes migrated \(migrated)")
        }
        return L10n.dynamic(manager.memoryBridgeSummary)
    }

    private let columnGap: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            completionHeader

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: columnGap) {
                    VStack(spacing: 14) {
                        completionAccessColumn
                        SetupCompletionChecklistPanel(manager: manager, scenario: scenario)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)

                    VStack(spacing: 14) {
                        completionMetaColumn
                        SetupCompletionNextPanel(onEnterDashboard: onEnterDashboard)
                    }
                    .frame(width: 520, alignment: .top)
                }

                VStack(spacing: 14) {
                    completionAccessColumn
                    completionMetaColumn
                    SetupCompletionChecklistPanel(manager: manager, scenario: scenario)
                    SetupCompletionNextPanel(onEnterDashboard: onEnterDashboard)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(DiffusePanelBackground(cornerRadius: 24, tint: SetupPalette.emerald, opacity: 0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(24)
        .onAppear(perform: refreshCompletionSnapshot)
    }

    private var completionAccessColumn: some View {
        VStack(spacing: 10) {
            SetupCompletionCopyCard(
                icon: "globe",
                title: L10n.t("网页地址", "Web URL"),
                value: manager.webUIURL,
                accent: SetupPalette.cyan,
                copied: copiedWebURL,
                onCopy: copyWebURL
            )
            .frame(maxWidth: .infinity, minHeight: 104)

            SetupCompletionTokenCard(
                token: tokenPresentation,
                tokenPath: manager.webUITokenPath,
                isHidden: tokenHidden,
                copied: copiedToken,
                onToggleHidden: { tokenHidden.toggle() },
                onCopy: copyToken
            )
            .frame(maxWidth: .infinity, minHeight: 122)
        }
    }

    private var completionMetaColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.t("运行状态", "Runtime Status"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text(manager.modelStatusUpdatedAt.isEmpty ? L10n.t("正在读取 Hermes / Web UI 配置", "Reading Hermes / Web UI config") : L10n.t("最后校准 \(manager.modelStatusUpdatedAt)", "Last calibrated \(manager.modelStatusUpdatedAt)"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(DesignTokens.textMuted)
                }
                Spacer()
                Button(action: refreshCompletionSnapshot) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                        Text(L10n.t("刷新", "Refresh"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(DesignTokens.textSecondary)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(DesignTokens.surface2.opacity(0.56))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                SetupResultTile(icon: "cpu", title: L10n.t("当前模型", "Current Model"), value: displayModel, detail: manager.modelCalibrationHealthy ? L10n.t("当前配置已校准", "Current config is calibrated") : L10n.t("以实时检测结果为准", "Based on live detection"), accent: manager.modelCalibrationHealthy ? SetupPalette.emerald : SetupPalette.amber)
                SetupResultTile(icon: "network", title: L10n.t("模型供应商", "Model Provider"), value: displayProvider, detail: displayProvider == L10n.t("未检测", "Not detected") ? L10n.t("等待 Web UI/CLI 返回", "Waiting for Web UI/CLI") : L10n.t("来自 Hermes 配置", "From Hermes config"), accent: SetupPalette.cyan)
                SetupResultTile(icon: "square.stack.3d.up", title: L10n.t("模型清单", "Model Inventory"), value: modelInventoryValue, detail: modelInventoryDetail, accent: manager.modelCalibrationHealthy ? SetupPalette.emerald : SetupPalette.amber)
                SetupResultTile(icon: "externaldrive.connected.to.line.below", title: L10n.t("记忆链路", "Memory Bridge"), value: memoryValue, detail: memoryDetail, accent: manager.openHumanMemoryLinked ? SetupPalette.emerald : SetupPalette.amber)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }

    private var completionHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(SetupPalette.emerald.opacity(0.14))
                    .frame(width: 56, height: 56)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(SetupPalette.emerald)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(scenario.completionTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(scenario.completionSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer()

            if AppRuntimeMode.uiPrototype {
                Text(L10n.t("UI 原型模式", "UI Prototype"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(SetupPalette.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(SetupPalette.emerald.opacity(0.10))
                    .cornerRadius(DesignTokens.radiusPill)
            }
        }
    }

    private func refreshCompletionSnapshot() {
        manager.readToken()
        manager.refreshModelStatus()
        manager.checkStatus(force: true)
    }

    private func copyToken() {
        guard !manager.webUIToken.isEmpty else {
            manager.showToast(title: L10n.t("Token 为空", "Token Empty"), message: L10n.t("当前没有检测到可复制的 Hermes Web UI Token", "No copyable Hermes Web UI token was detected"), icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        manager.copyToClipboard(displayToken, label: L10n.t("登录 Token", "Login Token"), message: L10n.t("可粘贴到 Hermes Web UI 登录页", "Paste it into the Hermes Web UI login page"))
        copiedToken = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedToken = false
        }
    }

    private func copyWebURL() {
        manager.copyToClipboard(manager.webUIURL, label: L10n.t("Web 地址", "Web URL"), message: L10n.t("可粘贴到浏览器打开 Hermes Web UI", "Paste it into a browser to open Hermes Web UI"))
        copiedWebURL = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedWebURL = false
        }
    }
}

struct SetupResultTile: View {
    let icon: String
    let title: String
    let value: String
    var detail: String = ""
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .truncationMode(.middle)
                .textSelection(.enabled)

            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(DesignTokens.surface2.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct SetupCompletionCopyCard: View {
    let icon: String
    let title: String
    let value: String
    let accent: Color
    let copied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accent)
                Spacer()
                Button(action: onCopy) {
                    HStack(spacing: 5) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .bold))
                        Text(copied ? L10n.t("已复制", "Copied") : L10n.t("复制", "Copy"))
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(copied ? SetupPalette.emerald : DesignTokens.textSecondary)
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(DesignTokens.surface2.opacity(0.72))
                    .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.surface2.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.20), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct SetupCompletionStatusItem: View {
    let icon: String
    let title: String
    let detail: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
        .background(accent.opacity(0.07))
        .cornerRadius(13)
    }
}

struct SetupCompletionChecklistPanel: View {
    @ObservedObject var manager: ServiceManager
    let scenario: SetupScenario

    private var gatewayDetail: String {
        manager.gatewayRunning ? L10n.t("Gateway 运行中", "Gateway running") : L10n.t("Gateway 未运行或暂未检测到", "Gateway is not running or not detected yet")
    }

    private var webUIDetail: String {
        manager.webUIRunning ? L10n.t("Web UI 运行中，地址和 Token 已就绪", "Web UI is running; URL and token are ready") : L10n.t("Web UI 未运行或等待启动", "Web UI is not running or waiting to start")
    }

    private var memoryDetail: String {
        if manager.openHumanMemoryLinked && manager.migratedMemoryAvailable {
            return L10n.t("OpenHuman 已接管，迁移数据可用", "OpenHuman is active and migrated data is available")
        }
        if manager.openHumanMemoryLinked {
            return L10n.t("已接入 OpenHuman，迁移状态待校验", "Connected to OpenHuman; migration still needs verification")
        }
        return L10n.dynamic(manager.memoryBridgeSummary)
    }

    private var hermesMemoryDetail: String {
        manager.openHumanMemoryLinked ? L10n.t("长期记忆写入目标为 OpenHuman", "Long-term memory writes target OpenHuman") : L10n.t("需要修复 provider 配置", "Provider configuration needs repair")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(L10n.t("完成清单", "Completion Checklist"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Spacer()
                Text(scenario.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(SetupPalette.emerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(SetupPalette.emerald.opacity(0.10))
                    .cornerRadius(DesignTokens.radiusPill)
            }

            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    SetupCompletionCheckRow(
                        title: L10n.t("Hermes 主控", "Hermes Brain"),
                        detail: gatewayDetail,
                        icon: "bolt.horizontal.fill",
                        accent: manager.gatewayRunning ? SetupPalette.cyan : SetupPalette.amber
                    )
                    SetupCompletionCheckRow(
                        title: L10n.t("Web UI 控制台", "Web UI Console"),
                        detail: webUIDetail,
                        icon: "globe",
                        accent: manager.webUIRunning ? SetupPalette.cyan : SetupPalette.amber
                    )
                }
                VStack(spacing: 8) {
                    SetupCompletionCheckRow(
                        title: L10n.t("OpenHuman 记忆", "OpenHuman Memory"),
                        detail: memoryDetail,
                        icon: "brain.head.profile",
                        accent: manager.openHumanMemoryLinked ? SetupPalette.emerald : SetupPalette.amber
                    )
                    SetupCompletionCheckRow(
                        title: L10n.t("Hermes 自带记忆", "Hermes Native Memory"),
                        detail: hermesMemoryDetail,
                        icon: "checkmark.shield.fill",
                        accent: manager.openHumanMemoryLinked ? SetupPalette.emerald : SetupPalette.amber
                    )
                }
            }

            HStack(spacing: 8) {
                SetupCompletionStatusPill(title: L10n.t("OpenHuman 文档", "OpenHuman Docs"), value: "\(manager.openHumanDocumentCount)")
                SetupCompletionStatusPill(title: L10n.t("迁移记忆", "Migrated"), value: "\(manager.migratedMemoryDocumentCount)")
                SetupCompletionStatusPill(title: L10n.t("本地长期项", "Local Long-term"), value: "\(manager.legacyHermesMemoryCount)")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct SetupCompletionStatusPill: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(DesignTokens.textPrimary)
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(SetupPalette.panel.opacity(0.70))
        .cornerRadius(11)
    }
}

struct SetupCompletionCheckRow: View {
    let title: String
    let detail: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.11))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
        .background(SetupPalette.panel.opacity(0.72))
        .cornerRadius(13)
    }
}

struct SetupCompletionNextPanel: View {
    let onEnterDashboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("下一步", "Next Steps"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(DesignTokens.textPrimary)

            HStack(alignment: .top, spacing: 10) {
                SetupCompletionStep(index: 1, title: L10n.t("复制 Web 地址", "Copy Web URL"), detail: L10n.t("从上方地址卡片复制。", "Copy it from the URL card above."))
                SetupCompletionStep(index: 2, title: L10n.t("复制 Token 登录", "Copy Token to Login"), detail: L10n.t("复制 Token 到 Web UI。", "Paste the token into Web UI."))
                SetupCompletionStep(index: 3, title: L10n.t("进入控制台", "Enter Dashboard"), detail: L10n.t("检查模型和记忆链路。", "Check model and memory bridge status."))
            }

            Button(action: onEnterDashboard) {
                HStack {
                    Text(L10n.t("进入控制面板", "Enter Dashboard"))
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
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DiffusePanelBackground(cornerRadius: 18, tint: SetupPalette.cyan, opacity: 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(18)
    }
}

struct SetupCompletionTokenCard: View {
    let token: String
    let tokenPath: String
    let isHidden: Bool
    let copied: Bool
    let onToggleHidden: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SetupPalette.emerald)
                Text(L10n.t("登录 Token", "Login Token"))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignTokens.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button(action: onToggleHidden) {
                    Image(systemName: isHidden ? "eye.slash" : "eye")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(DesignTokens.surface2.opacity(0.70))
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
                Button(action: onCopy) {
                    Text(copied ? L10n.t("已复制", "Copied") : L10n.t("复制", "Copy"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(copied ? SetupPalette.emerald : DesignTokens.textSecondary)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(DesignTokens.surface2.opacity(0.70))
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }

            Text(token)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(token == L10n.t("未检测到登录 Token", "Login token not detected") ? DesignTokens.textMuted : DesignTokens.textPrimary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)

            if !tokenPath.isEmpty {
                Text(compactPath(tokenPath))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.surface2.opacity(0.52))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SetupPalette.emerald.opacity(0.20), lineWidth: 1)
        )
        .cornerRadius(16)
    }
}

struct SetupCompletionStep: View {
    let index: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(SetupPalette.emerald)
                .frame(width: 22, height: 22)
                .background(SetupPalette.emerald.opacity(0.10))
                .cornerRadius(7)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(3)
            }
        }
    }
}

struct SetupTextField: View {
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

struct SetupSecureField: View {
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

struct APIWriteTarget: View {
    let title: String
    let path: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(SetupPalette.emerald)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(path)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(12)
        .background(DesignTokens.surface2.opacity(0.62))
        .cornerRadius(13)
    }
}
