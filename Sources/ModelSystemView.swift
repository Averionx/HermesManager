import SwiftUI

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

struct ModelSystemView: View {
    @ObservedObject var manager: ServiceManager
    let onOpenAddProvider: () -> Void
    let onOpenEditProvider: (String) -> Void
    @State private var route: ModelSystemRoute = .overview
    @State private var snapshot: ModelSystemSnapshot
    @State private var selectedProviderID: String
    @State private var selectedModelID: String
    @State private var providerSearch = ""
    @State private var modelSearch = ""
    @State private var providerStatusFilter: ModelStatusFilter = .all
    @State private var modelStatusFilter: ModelStatusFilter = .all
    @State private var selectedProviderFilter = "all"
    @State private var isDetecting = false
    @State private var importSheetPresented = false
    @State private var visibleModelsProvider: ModelProviderItem?
    @State private var modelEditorContext: ModelEditorContext?
    @State private var bulkEditorPresented = false

    init(
        manager: ServiceManager,
        onOpenAddProvider: @escaping () -> Void = {},
        onOpenEditProvider: @escaping (String) -> Void = { _ in }
    ) {
        self.manager = manager
        self.onOpenAddProvider = onOpenAddProvider
        self.onOpenEditProvider = onOpenEditProvider
        let initial = manager.modelSystemSnapshot(preferMockWhenEmpty: true)
        _snapshot = State(initialValue: initial)
        _selectedProviderID = State(initialValue: initial.providers.first?.id ?? "")
        _selectedModelID = State(initialValue: initial.models.first(where: \.isCurrent)?.id ?? initial.models.first?.id ?? "")
    }

    private var currentModel: ModelInfoItem {
        snapshot.models.first(where: \.isCurrent) ?? snapshot.models.first ?? ModelInfoItem(
            id: "empty",
            name: "未检测",
            alias: "",
            providerID: "",
            providerName: "未检测",
            baseURL: "",
            visible: false,
            enabled: false,
            isCurrent: false,
            contextLength: "--",
            priceLevel: "--",
            status: .warning,
            latencyMS: nil,
            availabilityPercent: 0,
            lastCheckedAt: ""
        )
    }

    private var selectedProvider: ModelProviderItem? {
        snapshot.providers.first { $0.id == selectedProviderID } ?? snapshot.providers.first
    }

    private var selectedModel: ModelInfoItem? {
        snapshot.models.first { $0.id == selectedModelID } ?? snapshot.models.first(where: \.isCurrent) ?? snapshot.models.first
    }

    private func modelsForProvider(_ providerID: String) -> [ModelInfoItem] {
        snapshot.models.filter { $0.providerID == providerID }
    }

    private var availableRate: Int {
        guard !snapshot.models.isEmpty else { return 0 }
        let healthy = snapshot.models.filter { $0.status == .healthy }.count
        return Int((Double(healthy) / Double(snapshot.models.count) * 100).rounded())
    }

    private var averageLatency: Int {
        let values = snapshot.models.compactMap(\.latencyMS)
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / values.count
    }

    var body: some View {
        VStack(spacing: 0) {
            routeBar
                .padding(.bottom, 20)

            Group {
                switch route {
                case .overview:
                    ModelOverviewPage(
                        manager: manager,
                        snapshot: snapshot,
                        currentModel: currentModel,
                        availableRate: availableRate,
                        averageLatency: averageLatency,
                        isDetecting: isDetecting,
                        onNavigate: { route = $0 },
                        onDetectAll: { runDetectionAll() }
                    )
                case .providers:
                    ProviderConfigPage(
                        providers: filteredProviders,
                        models: snapshot.models,
                        selectedProvider: selectedProvider,
                        statusFilter: $providerStatusFilter,
                        searchText: $providerSearch,
                        onSelect: { selectedProviderID = $0.id },
                        onAdd: { openProviderCreation() },
                        onImport: {
                            handleImportConfiguration()
                        },
                        onDetectAll: { runProviderDetectionForAll() },
                        onTestProvider: { runProviderDetection($0) },
                        onEditProvider: { focusProviderForEditing($0) },
                        onDeleteProvider: { deleteProvider($0) },
                        onSyncProviderToCLI: { syncProviderToCLI($0) },
                        onSyncProviderToWebUI: { syncProviderToWebUI($0) },
                        onSetDefault: { setDefaultProvider($0) },
                        onCancelEdit: { cancelProviderEditing() },
                        onSaveProvider: { saveProviderDraft($0) }
                    )
                case .management:
                    ModelManagementPage(
                        providers: snapshot.providers,
                        models: filteredModels,
                        selectedModel: selectedModel,
                        selectedProviderFilter: $selectedProviderFilter,
                        statusFilter: $modelStatusFilter,
                        searchText: $modelSearch,
                        averageLatency: averageLatency,
                        onSelectModel: { selectedModelID = $0.id },
                        onDetectAll: { runDetectionAll() },
                        onAddModel: { openModelCreation() },
                        onBulkEdit: { bulkEditModels() },
                        onShowProviderModels: { focusProviderModels($0) },
                        onManageVisibleModels: { manageVisibleModels($0) },
                        onEditProvider: { focusProviderForEditing($0) },
                        onDeleteProvider: { deleteProvider($0) },
                        onSetCurrent: { setCurrentModel($0) },
                        onDetectModel: { runModelDetection($0) },
                        onEditModel: { editModel($0) },
                        onToggleModel: { toggleModel($0) }
                    )
                case .detection:
                    ModelDetectionCenterPage(
                        snapshot: snapshot,
                        isDetecting: isDetecting,
                        onDetectAll: { runDetectionAll() },
                        onDetectProvider: {
                            runSelectedProviderDetection()
                        },
                        onDetectModel: {
                            runSelectedModelDetection()
                        }
                    )
                }
            }
        }
        .onAppear {
            manager.refreshModelStatus()
            refreshSnapshotFromManager()
        }
        .onReceive(manager.$modelStatusUpdatedAt) { _ in
            refreshSnapshotFromManager()
        }
        .onReceive(manager.$modelDetectionHistory) { _ in
            refreshSnapshotFromManager()
        }
        .onReceive(manager.$modelHealthResults) { _ in
            refreshSnapshotFromManager()
        }
        .sheet(isPresented: $importSheetPresented) {
            ModelImportSheet(snapshot: snapshot) { draft in
                applyImportedProvider(draft)
            }
            .frame(minWidth: 640, minHeight: 560)
        }
        .sheet(item: $visibleModelsProvider) { provider in
            ModelVisibilitySheet(
                provider: provider,
                models: modelsForProvider(provider.id),
                currentModelID: selectedModelID
            ) { visible, preferred in
                applyVisibleModels(provider: provider, visibleModels: visible, preferredModel: preferred)
            }
            .frame(minWidth: 620, minHeight: 540)
        }
        .sheet(item: $modelEditorContext) { context in
            ModelEditorSheet(
                provider: context.provider,
                model: context.model,
                providerModels: modelsForProvider(context.provider.id)
            ) { name, alias, contextLength in
                applyModelEdit(context: context, name: name, alias: alias, contextLength: contextLength)
            }
            .frame(minWidth: 560, minHeight: 420)
        }
        .sheet(isPresented: $bulkEditorPresented) {
            BulkModelEditSheet(providers: snapshot.providers, models: snapshot.models) { providerID, visibleModels, preferredModel in
                guard let provider = snapshot.providers.first(where: { $0.id == providerID }) else { return }
                applyVisibleModels(provider: provider, visibleModels: visibleModels, preferredModel: preferredModel)
            }
            .frame(minWidth: 660, minHeight: 560)
        }
    }

    private var routeBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                routeButtons
                Spacer(minLength: 12)
                mockBadge
            }

            VStack(alignment: .leading, spacing: 10) {
                routeButtons
                mockBadge
            }
        }
    }

    private var routeButtons: some View {
        HStack(spacing: 10) {
            ForEach(ModelSystemRoute.allCases) { item in
                routeButton(item)
            }
        }
    }

    private var mockBadge: some View {
        Text(AppRuntimeMode.uiPrototype ? "UI Prototype" : "Live Config")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(AppRuntimeMode.uiPrototype ? SetupPalette.cyan : SetupPalette.emerald)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background((AppRuntimeMode.uiPrototype ? SetupPalette.cyan : SetupPalette.emerald).opacity(0.10))
            .cornerRadius(DesignTokens.radiusPill)
    }

    private func routeButton(_ item: ModelSystemRoute) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .bold))
            Text(item.title)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(route == item ? DesignTokens.textPrimary : DesignTokens.textTertiary)
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(route == item ? item.accent.opacity(0.16) : DesignTokens.surface2.opacity(0.34))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(route == item ? item.accent.opacity(0.34) : DesignTokens.borderSubtle, lineWidth: 1)
        )
        .cornerRadius(13)
        .contentShape(RoundedRectangle(cornerRadius: 13))
        .onTapGesture { route = item }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("打开")) { route = item }
    }

    private var filteredProviders: [ModelProviderItem] {
        let query = providerSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return snapshot.providers.filter { provider in
            providerStatusFilter.matches(provider.status)
                && (query.isEmpty
                    || provider.name.lowercased().contains(query)
                    || provider.id.lowercased().contains(query))
        }
    }

    private var filteredModels: [ModelInfoItem] {
        let query = modelSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return snapshot.models.filter { model in
            let providerMatches = selectedProviderFilter == "all" || model.providerID == selectedProviderFilter
            let statusMatches = modelStatusFilter.matches(model.status)
            let queryMatches = query.isEmpty
                || model.name.lowercased().contains(query)
                || model.providerName.lowercased().contains(query)
            return providerMatches && statusMatches && queryMatches
        }
    }

    private func refreshSnapshotFromManager() {
        let next = manager.modelSystemSnapshot(preferMockWhenEmpty: AppRuntimeMode.uiPrototype)
        snapshot = next
        selectedProviderID = next.providers.first(where: \.isDefault)?.id ?? next.providers.first?.id ?? ""
        selectedModelID = next.models.first(where: \.isCurrent)?.id ?? next.models.first?.id ?? ""
    }

    private func setCurrentModel(_ model: ModelInfoItem) {
        if AppRuntimeMode.uiPrototype {
            for index in snapshot.models.indices {
                snapshot.models[index].isCurrent = snapshot.models[index].id == model.id
            }
            selectedModelID = model.id
            manager.showToast(title: "已模拟切换模型", message: "UI 模式不会写入 Hermes/Web UI", icon: "paintbrush.fill", accent: SetupPalette.cyan)
            route = .overview
            return
        }
        isDetecting = true
        manager.applyCurrentModelSelection(providerKey: model.providerID, modelName: model.name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isDetecting = false
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
            self.selectedModelID = model.id
            self.route = .overview
        }
    }

    private func setDefaultProvider(_ provider: ModelProviderItem) {
        if AppRuntimeMode.uiPrototype {
            for index in snapshot.providers.indices {
                snapshot.providers[index].isDefault = snapshot.providers[index].id == provider.id
            }
            selectedProviderID = provider.id
            manager.showToast(title: "已模拟设为默认", message: "\(provider.name) 已在 UI 中标记为默认", icon: "star.fill", accent: SetupPalette.emerald)
            return
        }
        manager.applyDefaultProvider(providerKey: provider.id)
        selectedProviderID = provider.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
        }
    }

    private func focusProviderForEditing(_ provider: ModelProviderItem) {
        selectedProviderID = provider.id
        route = .providers
        manager.showToast(title: "已展开编辑表单", message: "\(provider.name) 已在当前页面展开", icon: "pencil", accent: SetupPalette.cyan)
    }

    private func deleteProvider(_ provider: ModelProviderItem) {
        if !AppRuntimeMode.uiPrototype {
            guard provider.kind == .custom else {
                manager.showToast(title: "内置 Provider 不可删除", message: "公开版不会直接删除 Hermes 内置 Provider，只允许移除自定义 Provider", icon: "lock.fill", accent: SetupPalette.amber)
                return
            }
            guard !provider.isDefault else {
                manager.showToast(title: "当前默认 Provider 受保护", message: "请先切换到别的默认 Provider，再删除这个自定义 Provider", icon: "lock.fill", accent: SetupPalette.amber)
                return
            }
            manager.removeCustomProvider(providerKey: provider.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                self.manager.refreshModelStatus()
                self.refreshSnapshotFromManager()
            }
            return
        }
        let originalCount = snapshot.providers.count
        snapshot.providers.removeAll { $0.id == provider.id && !$0.isDefault }
        if snapshot.providers.count == originalCount {
            showMockToast(title: "默认供应商未删除", message: "Phase 1 保护默认 Provider，避免 mock 状态无当前模型", icon: "lock.fill", accent: SetupPalette.amber)
            return
        }

        snapshot.models.removeAll { $0.providerID == provider.id }
        selectedProviderID = snapshot.providers.first(where: \.isDefault)?.id ?? snapshot.providers.first?.id ?? ""
        selectedModelID = snapshot.models.first(where: \.isCurrent)?.id ?? snapshot.models.first?.id ?? ""
        showMockToast(title: "已模拟删除供应商", message: "\(provider.name) 已从当前 UI 状态移除，不影响真实配置", icon: "trash", accent: DesignTokens.error)
    }

    private func openProviderCreation() {
        if AppRuntimeMode.uiPrototype {
            insertMockProvider()
            return
        }
        onOpenAddProvider()
    }

    private func openModelCreation() {
        guard let provider = selectedProvider ?? snapshot.providers.first else {
            manager.showToast(title: "没有可用 Provider", message: "请先添加供应商，再新增模型", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        modelEditorContext = ModelEditorContext(provider: provider, model: nil)
    }

    private func handleImportConfiguration() {
        if AppRuntimeMode.uiPrototype {
            importSheetPresented = true
        } else {
            importSheetPresented = true
        }
    }

    private func runDetectionAll() {
        guard !isDetecting else { return }
        isDetecting = true
        manager.checkAllModelHealth {
            self.isDetecting = false
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
        }
    }

    private func runProviderDetectionForAll() {
        runDetectionAll()
    }

    private func runProviderDetection(_ provider: ModelProviderItem) {
        guard !isDetecting else { return }
        if AppRuntimeMode.uiPrototype {
            isDetecting = true
            markProvider(provider.id, status: .healthy, latencyMS: 120 + provider.id.count)
            showMockToast(title: "已模拟测试连接", message: "\(provider.name) 连接正常，状态已更新", icon: "waveform.path.ecg", accent: SetupPalette.emerald)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.isDetecting = false
            }
            return
        }
        isDetecting = true
        manager.checkProviderHealth(providerKey: provider.id) {
            self.isDetecting = false
            self.refreshSnapshotFromManager()
        }
    }

    private func runSelectedProviderDetection() {
        guard let provider = selectedProvider else {
            manager.showToast(title: "没有选中供应商", message: "先在配置供应商页选择一个 Provider", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        runProviderDetection(provider)
    }

    private func runModelDetection(_ model: ModelInfoItem) {
        guard !isDetecting else { return }
        isDetecting = true
        manager.checkModelHealth(providerKey: model.providerID, modelName: model.name) {
            self.isDetecting = false
            self.refreshSnapshotFromManager()
        }
    }

    private func runSelectedModelDetection() {
        guard let model = selectedModel else {
            manager.showToast(title: "没有选中模型", message: "先在模型管理页选择一个模型", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        runModelDetection(model)
    }

    private func bulkEditModels() {
        bulkEditorPresented = true
    }

    private func focusProviderModels(_ provider: ModelProviderItem) {
        selectedProviderFilter = provider.id
        route = .management
        manager.showToast(title: "已聚焦供应商模型", message: "已筛选 \(provider.name) 下的模型", icon: "line.3.horizontal.decrease", accent: SetupPalette.cyan)
    }

    private func manageVisibleModels(_ provider: ModelProviderItem) {
        visibleModelsProvider = provider
    }

    private func editModel(_ model: ModelInfoItem) {
        guard let provider = snapshot.providers.first(where: { $0.id == model.providerID }) else {
            manager.showToast(title: "找不到 Provider", message: "当前模型没有匹配的供应商配置", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }
        modelEditorContext = ModelEditorContext(provider: provider, model: model)
    }

    private func toggleModel(_ model: ModelInfoItem) {
        if AppRuntimeMode.uiPrototype {
            toggleMockModel(model)
            return
        }
        let providerModels = modelsForProvider(model.providerID)
        let visibleModels: [String]
        if model.enabled {
            guard !model.isCurrent else {
                manager.showToast(title: "当前模型不能停用", message: "请先切换到同 Provider 下其他模型，再停用当前模型", icon: "lock.fill", accent: SetupPalette.amber)
                return
            }
            visibleModels = providerModels
                .filter { $0.id != model.id && $0.enabled }
                .map(\.name)
        } else {
            visibleModels = providerModels
                .filter(\.enabled)
                .map(\.name) + [model.name]
        }
        applyVisibleModels(providerID: model.providerID, visibleModels: visibleModels, preferredModel: selectedModel?.name)
    }

    private func syncProviderToCLI(_ provider: ModelProviderItem) {
        if AppRuntimeMode.uiPrototype {
            updateProvider(provider.id) { item in
                item.syncToCLI = true
                item.lastCheckedAt = currentTimeLabel()
            }
            manager.showToast(title: "已模拟同步 CLI", message: "\(provider.name) 的 CLI 同步状态已点亮", icon: "arrow.down.to.line", accent: SetupPalette.cyan)
        } else {
            manager.syncProviderConfiguration(providerKey: provider.id)
        }
    }

    private func syncProviderToWebUI(_ provider: ModelProviderItem) {
        if AppRuntimeMode.uiPrototype {
            updateProvider(provider.id) { item in
                item.syncToWebUI = true
                item.lastCheckedAt = currentTimeLabel()
            }
            manager.showToast(title: "已模拟同步 Web UI", message: "\(provider.name) 的 Web UI 同步状态已点亮", icon: "shippingbox", accent: SetupPalette.cyan)
        } else {
            manager.syncProviderConfiguration(providerKey: provider.id)
        }
    }

    private func cancelProviderEditing() {
        refreshSnapshotFromManager()
        manager.showToast(title: "已取消操作", message: AppRuntimeMode.uiPrototype ? "没有修改任何真实配置" : "没有写入新的 Provider 配置", icon: "xmark.circle", accent: DesignTokens.textSecondary)
    }

    private func updateProvider(_ providerID: String, mutation: (inout ModelProviderItem) -> Void) {
        guard let index = snapshot.providers.firstIndex(where: { $0.id == providerID }) else { return }
        mutation(&snapshot.providers[index])
    }

    private func markProvider(_ providerID: String, status: ModelHealthStatus, latencyMS: Int?) {
        updateProvider(providerID) { item in
            item.status = status
            item.latencyMS = latencyMS
            item.lastCheckedAt = currentTimeLabel()
        }
        for index in snapshot.models.indices where snapshot.models[index].providerID == providerID {
            snapshot.models[index].status = status
            snapshot.models[index].latencyMS = latencyMS
            snapshot.models[index].availabilityPercent = status == .healthy ? 100 : snapshot.models[index].availabilityPercent
            snapshot.models[index].lastCheckedAt = currentTimeLabel()
        }
    }

    private func currentTimeLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private func saveProviderDraft(_ draft: ModelProviderEditDraft) {
        if AppRuntimeMode.uiPrototype {
            let providerID = draft.providerKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if let index = snapshot.providers.firstIndex(where: { $0.id == providerID }) {
                snapshot.providers[index].name = draft.providerLabel.ifEmpty(snapshot.providers[index].name)
                snapshot.providers[index].baseURL = draft.baseURL.ifEmpty(snapshot.providers[index].baseURL)
                snapshot.providers[index].modelCount = max(draft.models.count, 1)
                snapshot.providers[index].enabled = draft.enabled
                snapshot.providers[index].syncToCLI = draft.syncToCLI
                snapshot.providers[index].syncToWebUI = draft.syncToWebUI
            }
            showMockToast(title: "已模拟保存供应商", message: "\(draft.providerLabel.ifEmpty(providerID)) 的改动只保存在当前 UI 状态", icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
            return
        }
        manager.saveModelProviderDraft(draft)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
        }
    }

    private func addMockModel() {
        let provider = selectedProvider ?? snapshot.providers.first
        let providerID = provider?.id ?? "custom-provider"
        let providerName = provider?.name ?? "Custom Provider"
        let modelIndex = snapshot.models.count + 1
        let model = ModelInfoItem(
            id: "\(providerID)|manual-model-\(modelIndex)",
            name: "manual-model-\(modelIndex)",
            alias: "Manual Model \(modelIndex)",
            providerID: providerID,
            providerName: providerName,
            baseURL: provider?.baseURL ?? "https://api.example.com/v1",
            visible: true,
            enabled: true,
            isCurrent: false,
            contextLength: "128K",
            priceLevel: "$$",
            status: .warning,
            latencyMS: nil,
            availabilityPercent: 0,
            lastCheckedAt: "未检测"
        )
        snapshot.models.insert(model, at: 0)
        if let index = snapshot.providers.firstIndex(where: { $0.id == providerID }) {
            snapshot.providers[index].modelCount += 1
        }
        selectedModelID = model.id
        showMockToast(title: "已模拟新增模型", message: "\(model.name) 已加入当前 UI 状态", icon: "plus.circle.fill", accent: SetupPalette.emerald)
    }

    private func toggleMockModel(_ model: ModelInfoItem) {
        guard let index = snapshot.models.firstIndex(where: { $0.id == model.id }) else { return }
        snapshot.models[index].enabled.toggle()
        snapshot.models[index].visible = snapshot.models[index].enabled
        if !snapshot.models[index].enabled {
            snapshot.models[index].status = .unavailable
            snapshot.models[index].availabilityPercent = 0
            snapshot.models[index].latencyMS = nil
        } else {
            snapshot.models[index].status = .healthy
            snapshot.models[index].availabilityPercent = 100
            snapshot.models[index].latencyMS = 188
        }
        selectedModelID = model.id
        showMockToast(
            title: snapshot.models[index].enabled ? "已模拟启用模型" : "已模拟停用模型",
            message: "\(model.name) 的状态只在当前 UI 中变化",
            icon: snapshot.models[index].enabled ? "play.circle.fill" : "pause.circle.fill",
            accent: snapshot.models[index].enabled ? SetupPalette.emerald : SetupPalette.amber
        )
    }

    private func insertMockProvider() {
        let nextIndex = snapshot.providers.count + 1
        let provider = ModelProviderItem(
            id: "custom-provider-\(nextIndex)",
            name: "Custom Provider \(nextIndex)",
            kind: .custom,
            baseURL: "https://api.example.com/v1",
            apiKeyConfigured: false,
            apiKeyMasked: "未配置",
            headersPreview: "{}",
            timeoutSeconds: 60,
            retryCount: 3,
            enabled: true,
            syncToCLI: true,
            syncToWebUI: true,
            isDefault: false,
            status: .warning,
            modelCount: 0,
            lastCheckedAt: "未检测",
            latencyMS: nil
        )
        snapshot.providers.insert(provider, at: 0)
        selectedProviderID = provider.id
        manager.showToast(title: "已创建空白供应商", message: "Phase 1 mock：右侧编辑面板可预览配置", icon: "plus.circle.fill", accent: SetupPalette.cyan)
    }

    private func showMockToast(title: String, message: String, icon: String, accent: Color) {
        manager.showToast(title: title, message: message, icon: icon, accent: accent)
    }

    private func applyImportedProvider(_ draft: ModelProviderEditDraft) {
        if AppRuntimeMode.uiPrototype {
            let provider = ModelProviderItem(
                id: draft.providerKey,
                name: draft.providerLabel,
                kind: draft.providerKey.hasPrefix("custom:") ? .custom : .builtin,
                baseURL: draft.baseURL,
                apiKeyConfigured: !draft.apiKey.isEmpty,
                apiKeyMasked: draft.apiKey.isEmpty ? "未配置" : "sk-••••••••••••",
                headersPreview: "{}",
                timeoutSeconds: 60,
                retryCount: 3,
                enabled: draft.enabled,
                syncToCLI: draft.syncToCLI,
                syncToWebUI: draft.syncToWebUI,
                isDefault: false,
                status: .warning,
                modelCount: draft.models.count,
                lastCheckedAt: "未检测",
                latencyMS: nil
            )
            snapshot.providers.removeAll { $0.id == provider.id }
            snapshot.providers.insert(provider, at: 0)
            for model in draft.models {
                snapshot.models.removeAll { $0.providerID == draft.providerKey && $0.name == model }
                snapshot.models.insert(
                    ModelInfoItem(
                        id: "\(draft.providerKey)|\(model)",
                        name: model,
                        alias: modelAliasDisplay(model),
                        providerID: draft.providerKey,
                        providerName: draft.providerLabel,
                        baseURL: draft.baseURL,
                        visible: true,
                        enabled: true,
                        isCurrent: false,
                        contextLength: "\(draft.contextLength / 1000)K",
                        priceLevel: "$$",
                        status: .warning,
                        latencyMS: nil,
                        availabilityPercent: 70,
                        lastCheckedAt: "未检测"
                    ),
                    at: 0
                )
            }
            selectedProviderID = draft.providerKey
            showMockToast(title: "已模拟导入配置", message: "\(draft.providerLabel) 已加入 UI 状态", icon: "square.and.arrow.down", accent: SetupPalette.cyan)
            return
        }
        manager.saveModelProviderDraft(draft)
    }

    private func applyVisibleModels(provider: ModelProviderItem, visibleModels: [String], preferredModel: String?) {
        applyVisibleModels(providerID: provider.id, visibleModels: visibleModels, preferredModel: preferredModel)
    }

    private func applyVisibleModels(providerID: String, visibleModels: [String], preferredModel: String?) {
        let models = normalizedModelNames(visibleModels)
        guard !models.isEmpty else {
            manager.showToast(title: "至少保留一个模型", message: "可见模型列表不能为空", icon: "lock.fill", accent: SetupPalette.amber)
            return
        }

        if AppRuntimeMode.uiPrototype {
            for index in snapshot.models.indices where snapshot.models[index].providerID == providerID {
                snapshot.models[index].enabled = models.contains(snapshot.models[index].name)
                snapshot.models[index].visible = snapshot.models[index].enabled
                if !snapshot.models[index].enabled {
                    snapshot.models[index].status = .unavailable
                    snapshot.models[index].availabilityPercent = 0
                    snapshot.models[index].latencyMS = nil
                } else if snapshot.models[index].status == .unavailable {
                    snapshot.models[index].status = .warning
                    snapshot.models[index].availabilityPercent = 70
                }
            }
            if let providerIndex = snapshot.providers.firstIndex(where: { $0.id == providerID }) {
                snapshot.providers[providerIndex].modelCount = models.count
            }
            selectedModelID = snapshot.models.first { $0.providerID == providerID && $0.name == (preferredModel ?? "") }?.id
                ?? snapshot.models.first { $0.providerID == providerID && models.contains($0.name) }?.id
                ?? selectedModelID
            showMockToast(title: "已模拟更新可见模型", message: "当前 Provider 保留 \(models.count) 个可见模型", icon: "rectangle.on.rectangle", accent: SetupPalette.cyan)
            return
        }

        manager.applyModelVisibility(providerKey: providerID, visibleModels: models, defaultModel: preferredModel)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
        }
    }

    private func applyModelEdit(context: ModelEditorContext, name: String, alias: String, contextLength: Int) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            manager.showToast(title: "模型名称不能为空", message: "请输入模型 ID", icon: "exclamationmark.triangle.fill", accent: SetupPalette.amber)
            return
        }

        var providerModels = modelsForProvider(context.provider.id)
            .filter(\.enabled)
            .map(\.name)
        if let oldModel = context.model {
            providerModels.removeAll { $0 == oldModel.name }
        }
        providerModels.append(cleanName)

        if AppRuntimeMode.uiPrototype {
            if let oldModel = context.model,
               let index = snapshot.models.firstIndex(where: { $0.id == oldModel.id }) {
                snapshot.models[index].name = cleanName
                snapshot.models[index].alias = alias.ifEmpty(modelAliasDisplay(cleanName))
                snapshot.models[index].contextLength = "\(max(contextLength, 8192) / 1000)K"
            } else {
                let model = ModelInfoItem(
                    id: "\(context.provider.id)|\(cleanName)",
                    name: cleanName,
                    alias: alias.ifEmpty(modelAliasDisplay(cleanName)),
                    providerID: context.provider.id,
                    providerName: context.provider.name,
                    baseURL: context.provider.baseURL,
                    visible: true,
                    enabled: true,
                    isCurrent: false,
                    contextLength: "\(max(contextLength, 8192) / 1000)K",
                    priceLevel: "$$",
                    status: .warning,
                    latencyMS: nil,
                    availabilityPercent: 70,
                    lastCheckedAt: "未检测"
                )
                snapshot.models.insert(model, at: 0)
            }
            if let providerIndex = snapshot.providers.firstIndex(where: { $0.id == context.provider.id }) {
                snapshot.providers[providerIndex].modelCount = modelsForProvider(context.provider.id).count
            }
            showMockToast(title: "已模拟保存模型", message: cleanName, icon: "checkmark.seal.fill", accent: SetupPalette.emerald)
            return
        }

        manager.saveModelCatalog(providerKey: context.provider.id, models: providerModels, defaultModel: cleanName, contextLength: contextLength)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.manager.refreshModelStatus()
            self.refreshSnapshotFromManager()
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

    private func modelAliasDisplay(_ model: String) -> String {
        model
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

struct ModelEditorContext: Identifiable {
    let id = UUID()
    let provider: ModelProviderItem
    let model: ModelInfoItem?
}

struct ModelOverviewPage: View {
    @ObservedObject var manager: ServiceManager
    let snapshot: ModelSystemSnapshot
    let currentModel: ModelInfoItem
    let availableRate: Int
    let averageLatency: Int
    let isDetecting: Bool
    let onNavigate: (ModelSystemRoute) -> Void
    let onDetectAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModelPageHeader(
                title: "模型",
                subtitle: "查看当前模型与供应商状态，快速掌握可用性与运行健康状况。",
                updatedAt: manager.modelStatusUpdatedAt,
                actionTitle: nil,
                action: nil
            )

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(minimum: 168), spacing: 14, alignment: .top),
                    count: 5
                ),
                spacing: 14
            ) {
                ModelSummaryCard(title: "当前模型", value: currentModel.name, detail: "已选择", icon: "cube.transparent", accent: SetupPalette.emerald)
                ModelSummaryCard(title: "当前供应商", value: currentModel.providerName, detail: "已选择", icon: "building.2", accent: SetupPalette.cyan)
                ModelSummaryCard(title: "已检测模型数量", value: "\(snapshot.models.count)", detail: "\(snapshot.providers.count) 个供应商", icon: "shippingbox", accent: Color(red: 0.43, green: 0.53, blue: 1.0))
                ModelSummaryCard(title: "可用率", value: "\(availableRate)%", detail: "\(snapshot.models.filter { $0.status == .healthy }.count) / \(snapshot.models.count) 可用", icon: "waveform.path.ecg", accent: SetupPalette.emerald)
                ModelSummaryCard(title: "最后校准时间", value: manager.modelStatusUpdatedAt.isEmpty ? "等待" : manager.modelStatusUpdatedAt, detail: "本地 UI 状态", icon: "calendar.badge.clock", accent: SetupPalette.amber)
            }

            CurrentModelCard(model: currentModel) {
                onNavigate(.management)
            }

            ModelSystemFlowLayout(minimum: 250, spacing: 14) {
                ModelActionTile(icon: "building.2", title: "配置供应商", subtitle: "添加、编辑或管理供应商", accent: SetupPalette.cyan) { onNavigate(.providers) }
                ModelActionTile(icon: "cube.transparent", title: "管理模型", subtitle: "浏览与管理所有可用模型", accent: Color(red: 0.43, green: 0.53, blue: 1.0)) { onNavigate(.management) }
                ModelActionTile(icon: isDetecting ? "arrow.triangle.2.circlepath" : "waveform.path.ecg", title: isDetecting ? "检测中..." : "一键检测全部模型", subtitle: "检测所有模型的可用性与性能", accent: SetupPalette.amber) { onDetectAll() }
            }

            ModelSystemSplitLayout(secondaryWidth: 230, spacing: 16) {
                ModelSystemFlowLayout(minimum: 360, spacing: 16) {
                    ModelHealthTable(models: Array(snapshot.models.prefix(5)))
                    RecentDetectionLogs(records: Array(snapshot.detections.prefix(5)))
                }
            } secondary: {
                OverviewHintPanel()
            }
        }
    }
}

struct CurrentModelCard: View {
    let model: ModelInfoItem
    let onSwitch: () -> Void

    var body: some View {
        ModelGlassCard(tint: SetupPalette.emerald, opacity: 0.13, cornerRadius: 22, borderColor: SetupPalette.emerald.opacity(0.36)) {
            ViewThatFits(in: .horizontal) {
                contentRow
                contentColumn
            }
        }
    }

    private var heroIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [SetupPalette.emerald.opacity(0.72), SetupPalette.cyan.opacity(0.20)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 118, height: 92)
            Image(systemName: "waveform.path.ecg.rectangle.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.black.opacity(0.52))
        }
    }

    private var modelInfo: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Text("当前选中模型")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SetupPalette.emerald)
                ModelStatusBadge(status: model.status)
            }
            Text(model.name)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12)], alignment: .leading, spacing: 10) {
                ModelInfoMetric(title: "供应商", value: model.providerName)
                ModelInfoMetric(title: "模型类型", value: "CLI 与 Web UI 共享模型")
                ModelInfoMetric(title: "上下文长度", value: model.contextLength)
                ModelInfoMetric(title: "价格等级", value: model.priceLevel)
                ModelInfoMetric(title: "延迟", value: model.latencyMS.map { "\($0)ms" } ?? "—")
            }
        }
    }

    private var switchButton: some View {
        Button(action: onSwitch) {
            HStack(spacing: 10) {
                Text("切换模型")
                    .font(.system(size: 13, weight: .bold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(DesignTokens.textPrimary)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(DesignTokens.surface2.opacity(0.68))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DesignTokens.borderSubtle, lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private var contentRow: some View {
        HStack(spacing: 22) {
            heroIcon
            modelInfo
                .layoutPriority(1)
            Spacer(minLength: 12)
            switchButton
        }
    }

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                heroIcon
                modelInfo
            }
            switchButton
        }
    }

}

struct ModelInfoMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ModelHealthTable: View {
    let models: [ModelInfoItem]

    var body: some View {
        ModelGlassCard(tint: SetupPalette.emerald, opacity: 0.075) {
            VStack(alignment: .leading, spacing: 14) {
                ConsoleSectionTitle(title: "模型健康状态", subtitle: "查看全部模型")
                HStack {
                    Text("模型名称").frame(maxWidth: .infinity, alignment: .leading)
                    Text("供应商").frame(width: 110, alignment: .leading)
                    Text("延迟").frame(width: 70, alignment: .leading)
                    Text("可用率").frame(width: 92, alignment: .leading)
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)

                ForEach(models) { model in
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Circle().fill(model.status.accent).frame(width: 7, height: 7)
                            Text(model.name)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(DesignTokens.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if model.isCurrent {
                                ModelKindBadge(text: "当前", accent: SetupPalette.cyan)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(model.providerName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DesignTokens.textTertiary)
                            .frame(width: 110, alignment: .leading)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        LatencyBadge(latencyMS: model.latencyMS, status: model.status)
                            .frame(width: 70, alignment: .leading)
                        HStack(spacing: 8) {
                            Text("\(model.availabilityPercent)%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(DesignTokens.textSecondary)
                                .frame(width: 34, alignment: .leading)
                            ModelProgressBar(value: model.availabilityPercent, accent: model.status.accent)
                        }
                        .frame(width: 92)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }
}

struct RecentDetectionLogs: View {
    let records: [ModelDetectionRecord]

    var body: some View {
        ModelGlassCard(tint: SetupPalette.cyan, opacity: 0.07) {
            VStack(alignment: .leading, spacing: 14) {
                ConsoleSectionTitle(title: "最近检测记录", subtitle: "查看全部")
                ForEach(records) { record in
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: record.status.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(record.status.accent)
                            .frame(width: 28, height: 28)
                            .background(record.status.accent.opacity(0.10))
                            .cornerRadius(14)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.title)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(DesignTokens.textPrimary)
                                .lineLimit(1)
                            Text(record.detail)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(DesignTokens.textTertiary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(record.checkedAt)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(DesignTokens.textMuted)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct OverviewHintPanel: View {
    var body: some View {
        ModelGlassCard(tint: SetupPalette.amber, opacity: 0.065) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 9) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(SetupPalette.amber)
                    Text("提示")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                }
                Text("此页面为模型概览，只提供状态总览与快速入口。添加或编辑供应商请前往「配置供应商」，管理模型请前往「模型管理」。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignTokens.textTertiary)
                    .lineSpacing(4)
            }
        }
    }
}

struct ProviderConfigPage: View {
    let providers: [ModelProviderItem]
    let models: [ModelInfoItem]
    let selectedProvider: ModelProviderItem?
    @Binding var statusFilter: ModelStatusFilter
    @Binding var searchText: String
    let onSelect: (ModelProviderItem) -> Void
    let onAdd: () -> Void
    let onImport: () -> Void
    let onDetectAll: () -> Void
    let onTestProvider: (ModelProviderItem) -> Void
    let onEditProvider: (ModelProviderItem) -> Void
    let onDeleteProvider: (ModelProviderItem) -> Void
    let onSyncProviderToCLI: (ModelProviderItem) -> Void
    let onSyncProviderToWebUI: (ModelProviderItem) -> Void
    let onSetDefault: (ModelProviderItem) -> Void
    let onCancelEdit: () -> Void
    let onSaveProvider: (ModelProviderEditDraft) -> Void
    @State private var editingProviderID: String?

    private var editingProvider: ModelProviderItem? {
        guard let editingProviderID else { return nil }
        return providers.first { $0.id == editingProviderID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ModelPageHeader(
                title: "配置供应商",
                subtitle: "添加、编辑和管理模型供应商，配置连接信息并同步到各端使用。",
                updatedAt: selectedProvider?.lastCheckedAt ?? "",
                actionTitle: nil,
                action: nil
            )

            ModelSystemToolbar(minimum: 150, spacing: 10) {
                ModelSystemPillButton(title: "添加供应商", icon: "plus.circle", accent: SetupPalette.emerald, filled: true, action: onAdd)
                ModelSystemPillButton(title: "导入配置", icon: "square.and.arrow.down", accent: SetupPalette.cyan, filled: false, action: onImport)
                ModelSystemPillButton(title: "检测全部供应商", icon: "gearshape.2", accent: SetupPalette.cyan, filled: false, action: onDetectAll)
            }

            ModelSystemToolbar(minimum: 180, spacing: 12) {
                ModelSearchField(placeholder: "搜索供应商名称或 Provider ID...", text: $searchText)
                Picker("", selection: $statusFilter) {
                    ForEach(ModelStatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 150)
            }

            VStack(spacing: 14) {
                ForEach(providers) { provider in
                    VStack(spacing: 12) {
                        ProviderCard(
                            provider: provider,
                            isSelected: selectedProvider?.id == provider.id || editingProviderID == provider.id,
                            onSelect: { onSelect(provider) },
                            onEdit: {
                                onSelect(provider)
                                onEditProvider(provider)
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                                    editingProviderID = provider.id
                                }
                            },
                            onDelete: { onDeleteProvider(provider) },
                            onTest: { onTestProvider(provider) },
                            onSyncToCLI: { onSyncProviderToCLI(provider) },
                            onSyncToWebUI: { onSyncProviderToWebUI(provider) },
                            onSetDefault: { onSetDefault(provider) }
                        )
                        .frame(maxWidth: .infinity)

                        if editingProviderID == provider.id {
                            ProviderInlineEditPanel(
                                provider: provider,
                                models: models.filter { $0.providerID == provider.id },
                                onCancel: {
                                    onCancelEdit()
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                                        editingProviderID = nil
                                    }
                                },
                                onSave: { draft in
                                    onSaveProvider(draft)
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.90)) {
                                        editingProviderID = nil
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }

                if editingProvider == nil {
                    ProviderSelectionHintPanel(provider: selectedProvider)
                }

                Text("共 \(providers.count) 个供应商")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(DesignTokens.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .onChange(of: providers.map(\.id)) { _, ids in
            if let editingProviderID, !ids.contains(editingProviderID) {
                self.editingProviderID = nil
            }
        }
    }
}

struct ProviderCard: View {
    let provider: ModelProviderItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTest: () -> Void
    let onSyncToCLI: () -> Void
    let onSyncToWebUI: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        ModelGlassCard(tint: isSelected ? SetupPalette.emerald : provider.status.accent, opacity: isSelected ? 0.12 : 0.06, borderColor: isSelected ? SetupPalette.emerald.opacity(0.45) : DesignTokens.borderSubtle) {
            VStack(alignment: .leading, spacing: 14) {
                Button(action: onSelect) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            providerIdentity
                                .layoutPriority(1)
                            Spacer(minLength: 8)
                            ModelStatusBadge(status: provider.status)
                        }

                        ModelProviderMetricGrid(provider: provider)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().background(DesignTokens.borderSubtle)

                ProviderActionGrid(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onTest: onTest,
                    onSyncToCLI: onSyncToCLI,
                    onSyncToWebUI: onSyncToWebUI,
                    onSetDefault: onSetDefault
                )
            }
        }
    }

    private var providerIdentity: some View {
        HStack(spacing: 14) {
            Image(systemName: provider.kind == .builtin ? "building.2.crop.circle" : "link.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(provider.kind == .builtin ? SetupPalette.cyan : SetupPalette.emerald)
                .frame(width: 48, height: 48)
                .background((provider.kind == .builtin ? SetupPalette.cyan : SetupPalette.emerald).opacity(0.12))
                .cornerRadius(18)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(provider.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    ModelKindBadge(text: provider.kind.rawValue, accent: provider.kind == .builtin ? SetupPalette.emerald : SetupPalette.cyan)
                }
                Text(provider.id)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(DesignTokens.textTertiary)
            }
        }
    }
}

private struct ProviderSelectionHintPanel: View {
    let provider: ModelProviderItem?

    var body: some View {
        ModelGlassCard(tint: SetupPalette.cyan, opacity: 0.055, cornerRadius: 18) {
            HStack(spacing: 14) {
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(SetupPalette.cyan)
                    .frame(width: 40, height: 40)
                    .background(SetupPalette.cyan.opacity(0.12))
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 5) {
                    Text(provider == nil ? "选择一个供应商" : "当前供应商：\(provider?.name ?? "")")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Text("点击卡片可选中；点击「编辑」会在当前页面展开编辑表单，不会跳到别的窗口。")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)
            }
        }
    }
}

private struct ModelProviderMetricGrid: View {
    let provider: ModelProviderItem

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 10)], alignment: .leading, spacing: 10) {
            ProviderMiniMetric(title: "Base URL", value: provider.baseURL)
            ProviderMiniMetric(title: "API Key", value: provider.apiKeyConfigured ? provider.apiKeyMasked : "未配置")
            ProviderMiniMetric(title: "模型数量", value: "\(provider.modelCount)")
            ProviderMiniMetric(title: "默认", value: provider.isDefault ? "默认" : "—")
        }
    }
}

private struct ProviderActionGrid: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onTest: () -> Void
    let onSyncToCLI: () -> Void
    let onSyncToWebUI: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 132), spacing: 10, alignment: .leading)],
            alignment: .leading,
            spacing: 10
        ) {
            ProviderActionButton(title: "编辑", icon: "pencil", action: onEdit)
            ProviderActionButton(title: "删除", icon: "trash", destructive: true, action: onDelete)
            ProviderActionButton(title: "测试连接", icon: "speedometer", action: onTest)
            ProviderActionButton(title: "同步到 CLI", icon: "arrow.down.to.line", action: onSyncToCLI)
            ProviderActionButton(title: "同步到 Web UI", icon: "shippingbox", action: onSyncToWebUI)
            ProviderActionButton(title: "设为默认", icon: "star", action: onSetDefault)
        }
    }
}

struct ProviderMiniMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(DesignTokens.textMuted)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProviderActionButton: View {
    let title: String
    let icon: String
    var destructive = false
    var action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundColor(destructive ? DesignTokens.error : DesignTokens.textSecondary)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(DesignTokens.surface2.opacity(0.42))
            .cornerRadius(10)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

struct ProviderInlineEditPanel: View {
    let provider: ModelProviderItem
    let models: [ModelInfoItem]
    let onCancel: () -> Void
    let onSave: (ModelProviderEditDraft) -> Void

    var body: some View {
        ProviderEditPanel(
            provider: provider,
            models: models,
            onCancel: onCancel,
            onSave: onSave,
            title: "编辑 \(provider.name)",
            compact: false
        )
    }
}

struct ProviderEditPanel: View {
    let provider: ModelProviderItem?
    let models: [ModelInfoItem]
    let onCancel: () -> Void
    let onSave: (ModelProviderEditDraft) -> Void
    var title = "编辑供应商"
    var compact = true
    @State private var providerID = ""
    @State private var providerName = ""
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var modelList = ""
    @State private var defaultModel = ""
    @State private var contextLength = "128000"
    @State private var enabled = true
    @State private var syncToCLI = true
    @State private var syncToWebUI = true

    var body: some View {
        ModelGlassCard(tint: SetupPalette.emerald, opacity: 0.075, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Spacer()
                    if let provider {
                        ModelKindBadge(text: provider.kind.rawValue, accent: provider.kind == .builtin ? SetupPalette.emerald : SetupPalette.cyan)
                    }
                }

                if let provider {
                    LazyVGrid(columns: editColumns, alignment: .leading, spacing: 12) {
                        ProviderEditableField(title: "名称", placeholder: "Provider 名称", text: $providerName)
                        ProviderEditableField(title: "Provider ID", placeholder: "provider 或 custom:provider", text: $providerID, isDisabled: provider.kind == .builtin)
                        ProviderEditableField(title: "Base URL", placeholder: "https://api.example.com/v1", text: $baseURL)
                        ProviderEditableField(title: "API Key", placeholder: provider.apiKeyConfigured ? "留空沿用已配置 Key" : "sk-...", text: $apiKey, secure: true)
                        ProviderEditableField(title: "当前模型", placeholder: "默认使用的模型 ID", text: $defaultModel)
                        ProviderEditableField(title: "上下文", placeholder: "128000", text: $contextLength)
                    }

                    ProviderEditableField(title: "模型列表", placeholder: "每行一个模型 ID", text: $modelList, multiline: true)

                    ProviderFormRow(title: "重试次数", value: "\(provider.retryCount)")

                    VStack(spacing: 10) {
                        ProviderSwitchPreview(title: "是否启用", isOn: $enabled)
                        ProviderSwitchPreview(title: "同步到 Hermes (CLI)", isOn: $syncToCLI)
                        ProviderSwitchPreview(title: "同步到 Web UI", isOn: $syncToWebUI)
                    }

                    ModelGlassCard(tint: provider.status.accent, opacity: 0.055, cornerRadius: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                ModelStatusBadge(status: provider.status, title: provider.status == .healthy ? "连接成功" : provider.status.rawValue)
                                Spacer()
                                Text(provider.lastCheckedAt)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(DesignTokens.textMuted)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 10)], alignment: .leading, spacing: 8) {
                                ModelInfoMetric(title: "延迟", value: provider.latencyMS.map { "\($0)ms" } ?? "—")
                                ModelInfoMetric(title: "发现模型", value: "\(provider.modelCount) 个")
                                ModelInfoMetric(title: "状态", value: provider.status.rawValue)
                            }
                        }
                    }

                    HStack {
                        Spacer()
                        ModelSystemPillButton(title: "取消", icon: "xmark", accent: DesignTokens.textMuted, filled: false, action: onCancel)
                        ModelSystemPillButton(title: "保存", icon: "checkmark", accent: SetupPalette.emerald, filled: true) {
                            onSave(draft(from: provider))
                        }
                    }
                } else {
                    Text("选择左侧供应商后，这里会显示编辑表单。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                }
            }
        }
        .onAppear { syncDraft(with: provider) }
        .onChange(of: provider?.id ?? "") { _, _ in
            syncDraft(with: provider)
        }
    }

    private var editColumns: [GridItem] {
        [GridItem(.adaptive(minimum: compact ? 180 : 240), spacing: 12, alignment: .top)]
    }

    private func syncDraft(with provider: ModelProviderItem?) {
        guard let provider else { return }
        providerID = provider.id
        providerName = provider.name
        baseURL = provider.baseURL
        apiKey = ""
        modelList = models.map(\.name).joined(separator: "\n")
        defaultModel = models.first(where: \.isCurrent)?.name ?? models.first?.name ?? ""
        contextLength = contextLengthValue(from: models.first(where: \.isCurrent)?.contextLength ?? models.first?.contextLength ?? "128K")
        enabled = provider.enabled
        syncToCLI = provider.syncToCLI
        syncToWebUI = provider.syncToWebUI
    }

    private func draft(from provider: ModelProviderItem) -> ModelProviderEditDraft {
        let models = modelList
            .replacingOccurrences(of: ",", with: "\n")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let chosenDefault = defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        return ModelProviderEditDraft(
            providerKey: providerID.ifEmpty(provider.id),
            providerLabel: providerName.ifEmpty(provider.name),
            baseURL: baseURL.ifEmpty(provider.baseURL),
            apiKey: apiKey,
            models: models.isEmpty ? [chosenDefault].filter { !$0.isEmpty } : models,
            defaultModel: chosenDefault.ifEmpty(models.first ?? ""),
            contextLength: Int(contextLength.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 128000,
            enabled: enabled,
            syncToCLI: syncToCLI,
            syncToWebUI: syncToWebUI
        )
    }

    private func contextLengthValue(from display: String) -> String {
        let clean = display.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.hasSuffix("K"), let value = Int(clean.dropLast()) {
            return "\(value * 1000)"
        }
        return Int(clean).map(String.init) ?? "128000"
    }
}

struct ProviderFormRow: View {
    let title: String
    let value: String
    var multiline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: value.contains("http") || value.contains("{") ? .monospaced : .default))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(multiline ? 4 : 1)
                .truncationMode(.middle)
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, minHeight: multiline ? 74 : 34, alignment: .leading)
                .background(DesignTokens.surface2.opacity(0.50))
                .cornerRadius(10)
        }
    }
}

struct ProviderEditableField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var multiline = false
    var secure = false
    var isDisabled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
            Group {
                if multiline {
                    TextEditor(text: $text)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 78)
                } else if secure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textPrimary)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .medium, design: text.contains("http") ? .monospaced : .default))
                        .foregroundColor(DesignTokens.textPrimary)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, multiline ? 8 : 0)
            .frame(maxWidth: .infinity, minHeight: multiline ? 86 : 34, alignment: .leading)
            .background(DesignTokens.surface2.opacity(isDisabled ? 0.28 : 0.50))
            .cornerRadius(10)
            .disabled(isDisabled)
        }
    }
}

struct ProviderSwitchPreview: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.textSecondary)
        }
        .toggleStyle(.switch)
    }
}

struct ModelManagementPage: View {
    let providers: [ModelProviderItem]
    let models: [ModelInfoItem]
    let selectedModel: ModelInfoItem?
    @Binding var selectedProviderFilter: String
    @Binding var statusFilter: ModelStatusFilter
    @Binding var searchText: String
    let averageLatency: Int
    let onSelectModel: (ModelInfoItem) -> Void
    let onDetectAll: () -> Void
    let onAddModel: () -> Void
    let onBulkEdit: () -> Void
    let onShowProviderModels: (ModelProviderItem) -> Void
    let onManageVisibleModels: (ModelProviderItem) -> Void
    let onEditProvider: (ModelProviderItem) -> Void
    let onDeleteProvider: (ModelProviderItem) -> Void
    let onSetCurrent: (ModelInfoItem) -> Void
    let onDetectModel: (ModelInfoItem) -> Void
    let onEditModel: (ModelInfoItem) -> Void
    let onToggleModel: (ModelInfoItem) -> Void

    private var grouped: [(provider: ModelProviderItem, models: [ModelInfoItem])] {
        providers.map { provider in
            (provider, models.filter { $0.providerID == provider.id })
        }.filter { !$0.models.isEmpty || selectedProviderFilter == "all" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ModelPageHeader(
                title: "模型管理",
                subtitle: "管理所有提供商及其模型，统一查看模型状态、性能和可用性。",
                updatedAt: selectedModel?.lastCheckedAt ?? "",
                actionTitle: nil,
                action: nil
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 188), spacing: 14)], spacing: 14) {
                ModelSummaryCard(title: "模型总数", value: "\(models.count)", detail: "所有提供商", icon: "square.grid.3x3", accent: SetupPalette.emerald)
                ModelSummaryCard(title: "可用模型", value: "\(models.filter { $0.status == .healthy }.count)", detail: "可正常使用", icon: "checkmark.seal", accent: SetupPalette.emerald)
                ModelSummaryCard(title: "不可用模型", value: "\(models.filter { $0.status == .unavailable }.count)", detail: "连接失败或停用", icon: "xmark.octagon", accent: DesignTokens.error)
                ModelSummaryCard(title: "平均延迟", value: "\(averageLatency)ms", detail: "所有可用模型", icon: "timer", accent: SetupPalette.amber)
            }

            ModelSystemToolbar(minimum: 150, spacing: 10) {
                ModelSearchField(placeholder: "搜索提供商或模型名称...", text: $searchText)
                Picker("", selection: $selectedProviderFilter) {
                    Text("所有供应商").tag("all")
                    ForEach(providers) { provider in
                        Text(provider.name).tag(provider.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(minWidth: 145)
                Picker("", selection: $statusFilter) {
                    ForEach(ModelStatusFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(minWidth: 130)
                ModelSystemPillButton(title: "批量检测", icon: "waveform.path.ecg", accent: SetupPalette.cyan, filled: false, action: onDetectAll)
                ModelSystemPillButton(title: "新增模型", icon: "plus", accent: SetupPalette.emerald, filled: true, action: onAddModel)
                ModelSystemPillButton(title: "批量编辑", icon: "square.and.pencil", accent: DesignTokens.textSecondary, filled: false, action: onBulkEdit)
            }

            ModelSystemSplitLayout(secondaryWidth: 330, spacing: 18) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 330), spacing: 14)], spacing: 14) {
                    ForEach(grouped, id: \.provider.id) { group in
                        ModelProviderCard(
                            provider: group.provider,
                            models: group.models,
                            selectedModelID: selectedModel?.id ?? "",
                        onSelectModel: onSelectModel,
                        onShowAll: { onShowProviderModels(group.provider) },
                        onManageVisible: { onManageVisibleModels(group.provider) },
                        onEditProvider: { onEditProvider(group.provider) },
                            onDeleteProvider: { onDeleteProvider(group.provider) },
                            onAddModel: { onAddModel() }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } secondary: {
                ModelDetailPanel(model: selectedModel, onSetCurrent: onSetCurrent, onDetect: onDetectModel, onEdit: onEditModel, onToggle: onToggleModel)
            }
        }
    }
}
struct ModelProviderCard: View {
    let provider: ModelProviderItem
    let models: [ModelInfoItem]
    let selectedModelID: String
    let onSelectModel: (ModelInfoItem) -> Void
    let onShowAll: () -> Void
    let onManageVisible: () -> Void
    let onEditProvider: () -> Void
    let onDeleteProvider: () -> Void
    let onAddModel: () -> Void

    var body: some View {
        ModelGlassCard(tint: provider.status.accent, opacity: 0.07, borderColor: provider.isDefault ? SetupPalette.emerald.opacity(0.36) : DesignTokens.borderSubtle) {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(provider.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(DesignTokens.textPrimary)
                            ModelKindBadge(text: provider.kind.rawValue, accent: provider.kind == .builtin ? SetupPalette.cyan : SetupPalette.emerald)
                        }
                        Text("Base URL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DesignTokens.textMuted)
                        Text(provider.baseURL)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignTokens.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("模型数量")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(DesignTokens.textMuted)
                        Text("\(provider.modelCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(DesignTokens.textPrimary)
                    }
                }

                FlexibleModelChips(models: Array(models.prefix(5)), selectedModelID: selectedModelID, onSelectModel: onSelectModel)

                Divider().background(DesignTokens.borderSubtle)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 8) {
                    ProviderActionButton(title: "显示全部", icon: "line.3.horizontal.decrease", action: onShowAll)
                    ProviderActionButton(title: "管理可见模型", icon: "rectangle.on.rectangle", action: onManageVisible)
                    ProviderActionButton(title: "新增模型", icon: "plus", action: onAddModel)
                    ProviderActionButton(title: "编辑", icon: "pencil", action: onEditProvider)
                    ProviderActionButton(title: "删除", icon: "trash", destructive: true, action: onDeleteProvider)
                }
            }
        }
    }
}

struct FlexibleModelChips: View {
    let models: [ModelInfoItem]
    let selectedModelID: String
    let onSelectModel: (ModelInfoItem) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(models) { model in
                ModelChip(model: model, isSelected: selectedModelID == model.id) {
                    onSelectModel(model)
                }
            }
        }
    }
}

struct ModelDetailPanel: View {
    let model: ModelInfoItem?
    let onSetCurrent: (ModelInfoItem) -> Void
    let onDetect: (ModelInfoItem) -> Void
    let onEdit: (ModelInfoItem) -> Void
    let onToggle: (ModelInfoItem) -> Void

    var body: some View {
        ModelGlassCard(tint: SetupPalette.cyan, opacity: 0.075, cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("模型详情")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DesignTokens.textPrimary)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DesignTokens.textMuted)
                }

                if let model {
                    HStack(spacing: 14) {
                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(SetupPalette.emerald)
                            .frame(width: 72, height: 72)
                            .background(SetupPalette.emerald.opacity(0.12))
                            .cornerRadius(22)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(model.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(DesignTokens.textPrimary)
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .layoutPriority(1)
                                if model.isCurrent {
                                    ModelKindBadge(text: "当前使用", accent: SetupPalette.emerald)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(model.providerName) · \(model.status.rawValue)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(DesignTokens.textTertiary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(spacing: 12) {
                        ModelDetailRow(icon: "heart", title: "模型名称", value: model.name)
                        ModelDetailRow(icon: "person.2", title: "别名", value: model.alias)
                        ModelDetailRow(icon: "cube", title: "Provider", value: model.providerName)
                        ModelDetailRow(icon: "building.2", title: "Base URL", value: model.baseURL)
                        ModelDetailRow(icon: "calendar", title: "上下文长度", value: model.contextLength)
                        ModelDetailRow(icon: "tag", title: "价格级别", value: model.priceLevel)
                        ModelDetailRow(icon: "gearshape", title: "状态", value: model.status.rawValue, accent: model.status.accent)
                        ModelDetailRow(icon: "timer", title: "延迟", value: model.latencyMS.map { "\($0)ms" } ?? "—", accent: model.status.accent)
                        ModelDetailRow(icon: "clock", title: "最近检测时间", value: model.lastCheckedAt)
                    }

                    VStack(spacing: 10) {
                        ModelSystemPillButton(title: "设为当前模型", icon: "star", accent: SetupPalette.emerald, filled: true) { onSetCurrent(model) }
                        HStack(spacing: 10) {
                            ModelSystemPillButton(title: "编辑模型", icon: "pencil", accent: SetupPalette.cyan, filled: false) { onEdit(model) }
                            ModelSystemPillButton(title: "立即检测", icon: "arrow.clockwise", accent: SetupPalette.cyan, filled: false) { onDetect(model) }
                        }
                        ModelSystemPillButton(title: model.enabled ? "停用模型" : "启用模型", icon: model.enabled ? "pause.circle" : "play.circle", accent: DesignTokens.textSecondary, filled: false) { onToggle(model) }
                    }
                } else {
                    Text("点击左侧模型 Chip 后，这里会显示模型详情。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.textTertiary)
                }
            }
        }
    }
}

struct ModelDetailRow: View {
    let icon: String
    let title: String
    let value: String
    var accent: Color = DesignTokens.textSecondary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 18)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignTokens.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 150, alignment: .trailing)
        }
    }
}

struct ModelDetectionCenterPage: View {
    let snapshot: ModelSystemSnapshot
    let isDetecting: Bool
    let onDetectAll: () -> Void
    let onDetectProvider: () -> Void
    let onDetectModel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ModelPageHeader(
                title: "检测中心",
                subtitle: "一键检测全部模型、指定供应商或指定模型，采集延迟与可用性。",
                updatedAt: snapshot.detections.first?.checkedAt ?? "",
                actionTitle: nil,
                action: nil
            )

            ModelSystemFlowLayout(minimum: 250, spacing: 14) {
                ModelActionTile(icon: isDetecting ? "arrow.triangle.2.circlepath" : "slider.horizontal.3", title: isDetecting ? "检测中..." : "一键检测全部模型", subtitle: "并发检测所有可见模型", accent: Color(red: 0.55, green: 0.42, blue: 1.0), action: onDetectAll)
                ModelActionTile(icon: "cube.transparent", title: "检测指定供应商", subtitle: "检测当前选中供应商下全部模型", accent: SetupPalette.cyan, action: onDetectProvider)
                ModelActionTile(icon: "person.crop.square", title: "检测指定模型", subtitle: "针对单个模型执行检测", accent: SetupPalette.emerald, action: onDetectModel)
            }

            ModelSystemSplitLayout(secondaryWidth: 320, spacing: 16) {
                ModelGlassCard(tint: SetupPalette.emerald, opacity: 0.075) {
                    VStack(alignment: .leading, spacing: 14) {
                        ConsoleSectionTitle(title: "检测结果采集", subtitle: "结果回流")
                        DetectionFact(icon: "checkmark.seal.fill", title: "响应延迟（Latency）")
                        DetectionFact(icon: "checkmark.seal.fill", title: "可用性（Availability）")
                        DetectionFact(icon: "checkmark.seal.fill", title: "错误率（Error Rate）")
                        DetectionFact(icon: "checkmark.seal.fill", title: "最后检测时间")
                    }
                }
            } secondary: {
                RecentDetectionLogs(records: snapshot.detections)
            }
        }
    }
}

struct DetectionFact: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(SetupPalette.emerald)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignTokens.textSecondary)
        }
    }
}

struct ModelSystemFlowLayout<Content: View>: View {
    var minimum: CGFloat = 240
    var spacing: CGFloat = 14
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}

struct ModelSystemSplitLayout<Primary: View, Secondary: View>: View {
    var secondaryWidth: CGFloat = 340
    var spacing: CGFloat = 18
    @ViewBuilder let primary: Primary
    @ViewBuilder let secondary: Secondary

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: spacing) {
                primary
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                secondary
                    .frame(width: secondaryWidth)
            }

            VStack(alignment: .leading, spacing: spacing) {
                primary
                secondary
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

struct ModelSystemToolbar<Content: View>: View {
    var minimum: CGFloat = 148
    var spacing: CGFloat = 10
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: spacing)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}

struct ModelImportSheet: View {
    let snapshot: ModelSystemSnapshot
    let onImport: (ModelProviderEditDraft) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var providerLabel = ""
    @State private var providerKey = "custom:imported-provider"
    @State private var baseURL = ""
    @State private var apiKey = ""
    @State private var modelsText = ""
    @State private var defaultModel = ""
    @State private var contextLength = "128000"

    var body: some View {
        ModelSheetScaffold(
            title: "导入配置",
            subtitle: "粘贴 OpenAI 兼容 Provider 信息，保存后同步 Hermes CLI 与 Hermes Web UI。",
            icon: "square.and.arrow.down"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ModelSheetField(title: "Provider 名称", placeholder: "例如 Team Gateway", text: $providerLabel)
                ModelSheetField(title: "Provider ID", placeholder: "custom:team-gateway", text: $providerKey)
                ModelSheetField(title: "Base URL", placeholder: "https://api.example.com/v1", text: $baseURL)
                ModelSheetField(title: "API Key", placeholder: "sk-...", text: $apiKey, secure: true)
                ModelSheetField(title: "模型列表", placeholder: "每行一个模型 ID", text: $modelsText, multiline: true)
                HStack(spacing: 12) {
                    ModelSheetField(title: "当前模型", placeholder: "默认使用模型", text: $defaultModel)
                    ModelSheetField(title: "上下文", placeholder: "128000", text: $contextLength)
                        .frame(width: 130)
                }

                if !snapshot.providers.isEmpty {
                    SettingsStatusNote(icon: "info.circle", text: "当前已有 \(snapshot.providers.count) 个供应商。导入同 ID 会按 Hermes/Web UI 的现有写回规则更新。", accent: SetupPalette.cyan)
                }
            }
        } footer: {
            ModelSystemPillButton(title: "取消", icon: "xmark", accent: DesignTokens.textMuted, filled: false) { dismiss() }
            ModelSystemPillButton(title: "导入", icon: "checkmark", accent: SetupPalette.emerald, filled: true) {
                onImport(draft)
                dismiss()
            }
        }
    }

    private var draft: ModelProviderEditDraft {
        let models = normalizedModels(from: modelsText)
        let cleanDefault = defaultModel.trimmingCharacters(in: .whitespacesAndNewlines)
        return ModelProviderEditDraft(
            providerKey: normalizedProviderKey(providerKey.ifEmpty(providerLabel)),
            providerLabel: providerLabel.ifEmpty(providerKey),
            baseURL: baseURL,
            apiKey: apiKey,
            models: models.isEmpty ? [cleanDefault].filter { !$0.isEmpty } : models,
            defaultModel: cleanDefault.ifEmpty(models.first ?? ""),
            contextLength: Int(contextLength.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 128000,
            enabled: true,
            syncToCLI: true,
            syncToWebUI: true
        )
    }
}

struct ModelVisibilitySheet: View {
    let provider: ModelProviderItem
    let models: [ModelInfoItem]
    let currentModelID: String
    let onSave: ([String], String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var visibleModels: Set<String>
    @State private var preferredModel: String

    init(
        provider: ModelProviderItem,
        models: [ModelInfoItem],
        currentModelID: String,
        onSave: @escaping ([String], String?) -> Void
    ) {
        self.provider = provider
        self.models = models
        self.currentModelID = currentModelID
        self.onSave = onSave
        let initialVisible = Set(models.filter(\.enabled).map(\.name))
        _visibleModels = State(initialValue: initialVisible.isEmpty ? Set(models.map(\.name)) : initialVisible)
        _preferredModel = State(initialValue: models.first(where: { $0.id == currentModelID })?.name ?? models.first(where: \.isCurrent)?.name ?? models.first?.name ?? "")
    }

    var body: some View {
        ModelSheetScaffold(
            title: "管理可见模型",
            subtitle: provider.name,
            icon: "rectangle.on.rectangle"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if models.isEmpty {
                    SettingsStatusNote(icon: "exclamationmark.triangle.fill", text: "当前 Provider 还没有模型。请先新增模型或导入配置。", accent: SetupPalette.amber)
                } else {
                    Picker("当前模型", selection: $preferredModel) {
                        ForEach(models.map(\.name), id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], alignment: .leading, spacing: 10) {
                        ForEach(models) { model in
                            ModelSelectionChip(title: model.name, isSelected: visibleModels.contains(model.name)) {
                                if visibleModels.contains(model.name) {
                                    visibleModels.remove(model.name)
                                } else {
                                    visibleModels.insert(model.name)
                                }
                            }
                        }
                    }
                }
            }
        } footer: {
            ModelSystemPillButton(title: "取消", icon: "xmark", accent: DesignTokens.textMuted, filled: false) { dismiss() }
            ModelSystemPillButton(title: "保存", icon: "checkmark", accent: SetupPalette.emerald, filled: true) {
                onSave(Array(visibleModels).sorted(), preferredModel)
                dismiss()
            }
        }
    }
}

struct ModelEditorSheet: View {
    let provider: ModelProviderItem
    let model: ModelInfoItem?
    let providerModels: [ModelInfoItem]
    let onSave: (String, String, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var modelName: String
    @State private var alias: String
    @State private var contextLength: String

    init(
        provider: ModelProviderItem,
        model: ModelInfoItem?,
        providerModels: [ModelInfoItem],
        onSave: @escaping (String, String, Int) -> Void
    ) {
        self.provider = provider
        self.model = model
        self.providerModels = providerModels
        self.onSave = onSave
        _modelName = State(initialValue: model?.name ?? "")
        _alias = State(initialValue: model?.alias ?? "")
        _contextLength = State(initialValue: contextLengthValue(from: model?.contextLength ?? "128K"))
    }

    var body: some View {
        ModelSheetScaffold(
            title: model == nil ? "新增模型" : "编辑模型",
            subtitle: provider.name,
            icon: model == nil ? "plus" : "pencil"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ModelSheetField(title: "模型 ID", placeholder: "deepseek-v4-flash", text: $modelName)
                ModelSheetField(title: "别名", placeholder: "可选，仅用于展示", text: $alias)
                ModelSheetField(title: "上下文", placeholder: "128000", text: $contextLength)
                SettingsStatusNote(icon: "shippingbox", text: "保存后会把该模型加入 \(provider.name) 的可见模型，并同步到 Hermes CLI 与 Hermes Web UI。", accent: SetupPalette.cyan)
                if !providerModels.isEmpty {
                    Text("当前 Provider 已有 \(providerModels.count) 个模型")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(DesignTokens.textMuted)
                }
            }
        } footer: {
            ModelSystemPillButton(title: "取消", icon: "xmark", accent: DesignTokens.textMuted, filled: false) { dismiss() }
            ModelSystemPillButton(title: "保存", icon: "checkmark", accent: SetupPalette.emerald, filled: true) {
                onSave(modelName, alias, Int(contextLength.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 128000)
                dismiss()
            }
        }
    }
}

struct BulkModelEditSheet: View {
    let providers: [ModelProviderItem]
    let models: [ModelInfoItem]
    let onSave: (String, [String], String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProviderID: String
    @State private var visibleModels: Set<String>
    @State private var preferredModel: String

    init(
        providers: [ModelProviderItem],
        models: [ModelInfoItem],
        onSave: @escaping (String, [String], String?) -> Void
    ) {
        self.providers = providers
        self.models = models
        self.onSave = onSave
        let firstProvider = providers.first?.id ?? ""
        let providerModels = models.filter { $0.providerID == firstProvider }
        _selectedProviderID = State(initialValue: firstProvider)
        _visibleModels = State(initialValue: Set(providerModels.filter(\.enabled).map(\.name)))
        _preferredModel = State(initialValue: providerModels.first(where: \.isCurrent)?.name ?? providerModels.first?.name ?? "")
    }

    private var providerModels: [ModelInfoItem] {
        models.filter { $0.providerID == selectedProviderID }
    }

    var body: some View {
        ModelSheetScaffold(
            title: "批量编辑",
            subtitle: "按供应商批量调整可见模型",
            icon: "square.and.pencil"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("供应商", selection: $selectedProviderID) {
                    ForEach(providers) { provider in
                        Text(provider.name).tag(provider.id)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedProviderID) { _, newValue in
                    let nextModels = models.filter { $0.providerID == newValue }
                    let nextVisible = Set(nextModels.filter(\.enabled).map(\.name))
                    visibleModels = nextVisible.isEmpty ? Set(nextModels.map(\.name)) : nextVisible
                    preferredModel = nextModels.first(where: \.isCurrent)?.name ?? nextModels.first?.name ?? ""
                }

                if providerModels.isEmpty {
                    SettingsStatusNote(icon: "exclamationmark.triangle.fill", text: "当前供应商没有可批量编辑的模型。", accent: SetupPalette.amber)
                } else {
                    Picker("当前模型", selection: $preferredModel) {
                        ForEach(providerModels.map(\.name), id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], alignment: .leading, spacing: 10) {
                        ForEach(providerModels) { model in
                            ModelSelectionChip(title: model.name, isSelected: visibleModels.contains(model.name)) {
                                if visibleModels.contains(model.name) {
                                    visibleModels.remove(model.name)
                                } else {
                                    visibleModels.insert(model.name)
                                }
                            }
                        }
                    }
                }
            }
        } footer: {
            ModelSystemPillButton(title: "取消", icon: "xmark", accent: DesignTokens.textMuted, filled: false) { dismiss() }
            ModelSystemPillButton(title: "应用", icon: "checkmark", accent: SetupPalette.emerald, filled: true) {
                onSave(selectedProviderID, Array(visibleModels).sorted(), preferredModel)
                dismiss()
            }
        }
    }
}

struct ModelSheetScaffold<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    var body: some View {
        ZStack {
            SetupBackground()
            VStack(spacing: 0) {
                HStack(spacing: 13) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(SetupPalette.emerald)
                        .frame(width: 42, height: 42)
                        .background(SetupPalette.emerald.opacity(0.12))
                        .cornerRadius(14)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(DesignTokens.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignTokens.textTertiary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(22)

                Divider().background(DesignTokens.borderSubtle)

                ScrollView {
                    content
                        .padding(22)
                }

                Divider().background(DesignTokens.borderSubtle)

                HStack(spacing: 12) {
                    Spacer()
                    footer
                }
                .padding(18)
                .background(DesignTokens.surface1.opacity(0.72))
            }
            .background(DiffusePanelBackground(cornerRadius: 24, tint: SetupPalette.emerald, opacity: 0.10))
        }
    }
}

struct ModelSheetField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var multiline = false
    var secure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignTokens.textTertiary)
            Group {
                if multiline {
                    TextEditor(text: $text)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 110)
                } else if secure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(DesignTokens.textPrimary)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: text.contains("http") ? .monospaced : .default))
                        .foregroundColor(DesignTokens.textPrimary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: multiline ? 126 : 42, alignment: .leading)
            .background(DesignTokens.surface2.opacity(0.58))
            .cornerRadius(12)
        }
    }
}

private func normalizedModels(from text: String) -> [String] {
    var seen = Set<String>()
    var values: [String] = []
    for item in text.replacingOccurrences(of: ",", with: "\n").components(separatedBy: .newlines) {
        let clean = item.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, seen.insert(clean).inserted else { continue }
        values.append(clean)
    }
    return values
}

private func normalizedProviderKey(_ value: String) -> String {
    let clean = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if clean.hasPrefix("custom:") { return clean }
    return clean.contains(":") ? clean : "custom:\(clean.replacingOccurrences(of: " ", with: "-"))"
}

private func contextLengthValue(from display: String) -> String {
    let clean = display.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if clean.hasSuffix("K"), let value = Int(clean.dropLast()) {
        return "\(value * 1000)"
    }
    return Int(clean).map(String.init) ?? "128000"
}
