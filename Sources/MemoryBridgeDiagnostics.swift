import Foundation

struct MemoryBridgeDiagnosticSnapshot {
    let linked: Bool
    let migrated: Bool
    let issues: [String]
    let warnings: [String]
    let openHumanDocumentCount: Int
    let migratedDocumentCount: Int
    let legacyHermesMemoryCount: Int

    var summary: String {
        if linked && migrated && issues.isEmpty {
            return warnings.first ?? "OpenHuman 已作为 Hermes 长期记忆库"
        }
        return (issues.first ?? warnings.first) ?? "等待记忆连接检测"
    }
}

enum MemoryBridgeDiagnosticService {
    static func diagnose(home: String = NSHomeDirectory()) -> MemoryBridgeDiagnosticSnapshot {
        let fileManager = FileManager.default
        let hermesHome = home + "/.hermes"
        let activeHermesHome = activeHermesProfileHome(baseHermesHome: hermesHome, fileManager: fileManager)
        let openHumanVault = home + "/.openhuman/vault"
        let openHumanWorkspace = home + "/.openhuman/users/local/workspace"
        let configPath = activeHermesHome + "/config.yaml"
        let envPath = activeHermesHome + "/.env"
        let dbPath = openHumanWorkspace + "/memory/memory.db"

        let config = (try? String(contentsOfFile: configPath, encoding: .utf8)) ?? ""
        let env = (try? String(contentsOfFile: envPath, encoding: .utf8)) ?? ""

        let configExists = fileManager.fileExists(atPath: configPath)
        let vaultExists = fileManager.fileExists(atPath: openHumanVault)
        let dbExists = fileManager.fileExists(atPath: dbPath)
        let providerConfigured = yamlNestedScalarEquals(config, block: "memory", key: "provider", value: "openhuman")
        let memoryEnabledDisabled = yamlScalarIsFalse(config, key: "memory_enabled")
        let userProfileDisabled = yamlScalarIsFalse(config, key: "user_profile_enabled")
        let builtinToolsetDisabled = yamlListContains(config, block: "agent", key: "disabled_toolsets", value: "memory")
        let envVaultConfigured = env.localizedCaseInsensitiveContains("OPENHUMAN_VAULT=")
        let envWorkspaceConfigured = env.localizedCaseInsensitiveContains("OPENHUMAN_WORKSPACE=")
        let pluginConfigured = fileManager.fileExists(atPath: activeHermesHome + "/plugins/openhuman/plugin.yaml")
            || fileManager.fileExists(atPath: activeHermesHome + "/plugins/memory/openhuman/plugin.yaml")
            || fileManager.fileExists(atPath: hermesHome + "/plugins/openhuman/plugin.yaml")
            || fileManager.fileExists(atPath: hermesHome + "/plugins/memory/openhuman/plugin.yaml")

        let legacyHermesMemory = countLongTermHermesMemory(hermesHome: activeHermesHome)
        let importedHermesFiles = countMemoryFiles(openHumanVault + "/Imported/Hermes")
        let openHumanDocuments = countOpenHumanDocuments(dbPath: dbPath, namespace: nil)
        let migratedDocuments = countOpenHumanDocuments(dbPath: dbPath, namespace: "hermes_migrated")
        let migrated = legacyHermesMemory == 0 || importedHermesFiles > 0 || migratedDocuments > 0

        var issues: [String] = []
        var warnings: [String] = []

        if !configExists { issues.append("Hermes config.yaml 不存在") }
        if !vaultExists { issues.append("OpenHuman Vault 不存在") }
        if !dbExists { issues.append("OpenHuman SQLite 记忆库不存在") }
        if !providerConfigured { issues.append("memory.provider 不是 openhuman") }
        if !memoryEnabledDisabled || !userProfileDisabled { issues.append("Hermes 内置长期记忆未关闭") }
        if !builtinToolsetDisabled { issues.append("Hermes 内置 memory toolset 未禁用") }
        if !envVaultConfigured { issues.append("缺少 OPENHUMAN_VAULT") }
        if !envWorkspaceConfigured { issues.append("缺少 OPENHUMAN_WORKSPACE") }
        if !pluginConfigured { issues.append("OpenHuman memory provider 插件不存在") }
        if legacyHermesMemory > 0 && !migrated { issues.append("Hermes 长期记忆未迁移到 OpenHuman") }
        if dbExists && openHumanDocuments == 0 { warnings.append("OpenHuman DB 为空，尚未写入长期记忆") }

        let linked = configExists
            && vaultExists
            && dbExists
            && providerConfigured
            && memoryEnabledDisabled
            && userProfileDisabled
            && builtinToolsetDisabled
            && envVaultConfigured
            && envWorkspaceConfigured
            && pluginConfigured

        return MemoryBridgeDiagnosticSnapshot(
            linked: linked,
            migrated: migrated,
            issues: issues,
            warnings: warnings,
            openHumanDocumentCount: openHumanDocuments,
            migratedDocumentCount: migratedDocuments,
            legacyHermesMemoryCount: legacyHermesMemory
        )
    }

    private static func activeHermesProfileHome(baseHermesHome: String, fileManager: FileManager) -> String {
        let activeFile = baseHermesHome + "/active_profile"
        guard let raw = try? String(contentsOfFile: activeFile, encoding: .utf8) else {
            return baseHermesHome
        }
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != "default" else {
            return baseHermesHome
        }
        let profileHome = baseHermesHome + "/profiles/" + name
        return fileManager.fileExists(atPath: profileHome) ? profileHome : baseHermesHome
    }

    private static func yamlScalarIsFalse(_ text: String, key: String) -> Bool {
        text.components(separatedBy: .newlines).contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            return trimmed == "\(key): false" || trimmed == "\(key): no" || trimmed == "\(key): 0"
        }
    }

    private static func yamlNestedScalarEquals(_ text: String, block blockName: String, key: String, value: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard let blockStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).lowercased() == "\(blockName):" }) else {
            return false
        }
        let blockIndent = indentation(of: lines[blockStart])
        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty,
               !trimmed.hasPrefix("#"),
               indentation(of: line) <= blockIndent,
               trimmed.contains(":") {
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

    private static func yamlListContains(_ text: String, block blockName: String, key: String, value: String) -> Bool {
        let lines = text.components(separatedBy: .newlines)
        guard let blockStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).lowercased() == "\(blockName):" }) else {
            return false
        }
        let blockIndent = indentation(of: lines[blockStart])
        var blockEnd = blockStart + 1
        while blockEnd < lines.count {
            let line = lines[blockEnd]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty,
               !trimmed.hasPrefix("#"),
               indentation(of: line) <= blockIndent,
               trimmed.contains(":") {
                break
            }
            blockEnd += 1
        }
        guard let keyIndex = lines[blockStart..<blockEnd].firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("\(key):")
        }) else {
            return false
        }
        let lowerValue = value.lowercased()
        let keyLine = lines[keyIndex].trimmingCharacters(in: .whitespaces).lowercased()
        if keyLine.contains("[") {
            let values = keyLine
                .replacingOccurrences(of: "\(key):", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"'")).lowercased() }
            if values.contains(lowerValue) { return true }
        }
        var index = keyIndex + 1
        while index < blockEnd {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            if !trimmed.isEmpty && indentation(of: line) <= indentation(of: lines[keyIndex]) && trimmed.contains(":") {
                break
            }
            let item = trimmed
                .replacingOccurrences(of: "- ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if item == lowerValue { return true }
            index += 1
        }
        return false
    }

    private static func indentation(of line: String) -> Int {
        line.prefix { $0 == " " || $0 == "\t" }.count
    }

    private static func countOpenHumanDocuments(dbPath: String, namespace: String?) -> Int {
        guard FileManager.default.fileExists(atPath: dbPath) else { return 0 }
        let sql: String
        if let namespace {
            sql = "SELECT COUNT(*) FROM memory_docs WHERE namespace = '\(namespace.replacingOccurrences(of: "'", with: "''"))';"
        } else {
            sql = "SELECT COUNT(*) FROM memory_docs;"
        }
        let output = runReadOnlyShell("sqlite3 \(shellQuote(dbPath)) \(shellQuote(sql))")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(output) ?? 0
    }

    private static func countLongTermHermesMemory(hermesHome: String) -> Int {
        countMemoryFiles(hermesHome + "/memories")
            + countLongTermTopLevelHermesNotes(hermesHome: hermesHome)
            + countLongTermHermesMemoryDirectoryFiles(hermesHome: hermesHome)
    }

    private static func countLongTermTopLevelHermesNotes(hermesHome: String) -> Int {
        let root = hermesHome
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

    private static func countLongTermHermesMemoryDirectoryFiles(hermesHome: String) -> Int {
        let root = hermesHome + "/memory"
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

    private static func runReadOnlyShell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-lc", command]
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
