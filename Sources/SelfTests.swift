import Foundation

enum HermesManagerSelfTests {
    static func runRequestedIfNeeded() -> Bool {
        let requested = ProcessInfo.processInfo.environment["HERMES_MANAGER_SELF_TEST"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard requested == "model-config" || requested == "version-compare" else { return false }

        do {
            if requested == "version-compare" {
                try runVersionComparisonTests()
                print("SELF_TEST_OK version-compare")
                return true
            }
            try runModelConfigurationTests()
            print("SELF_TEST_OK model-config")
            return true
        } catch {
            fputs("SELF_TEST_FAILED model-config: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func runVersionComparisonTests() throws {
        assertCompare("v0.1.0-beta.1", "v0.2.0", .orderedAscending, "preview lower than current app must not update")
        assertCompare("0.5.28", "v0.5.28", .orderedSame, "web UI same version with leading v must not update")
        assertCompare("v0.5.29", "0.5.28", .orderedDescending, "newer web UI should update")
        assertCompare("Hermes Agent v0.14.0 (2026.5.16)", "v0.14.0", .orderedSame, "Hermes version output should normalize")
        assertEqual(VersionFormatting.displayVersion("hermes-web-ui 0.5.28"), "v0.5.28", "display version should use v prefix")
    }

    private static func assertCompare(_ lhs: String, _ rhs: String, _ expected: ComparisonResult, _ message: String) {
        let actual = VersionFormatting.compare(lhs, rhs)
        guard actual == expected else {
            fatalError("\(message). Expected \(expected), got \(actual) for \(lhs) vs \(rhs)")
        }
    }

    private static func assertEqual(_ actual: String, _ expected: String, _ message: String) {
        guard actual == expected else {
            fatalError("\(message). Expected \(expected), got \(actual)")
        }
    }

    private static func runModelConfigurationTests() throws {
        let tempRoot = try makeTemporaryHome()
        defer { try? FileManager.default.removeItem(atPath: tempRoot) }

        try prepareActiveProfileHome(tempRoot)

        let service = SetupExecutionService(home: tempRoot)
        let builtin = ModelProviderConfiguration(
            providerKey: "opencode-go",
            providerLabel: "OpenCode Go",
            baseURL: "https://opencode.ai/zen/go/v1",
            apiKey: "test-opencode-key",
            defaultModel: "glm-5",
            models: ["glm-5", "kimi-k2.5"],
            contextLength: 128000
        )
        try unwrap(service.configureModelProvider(builtin) { _ in })

        let profileHome = tempRoot + "/.hermes/profiles/dev"
        let configPath = profileHome + "/config.yaml"
        let envPath = profileHome + "/.env"
        let webUIConfigPath = tempRoot + "/.hermes-web-ui/config.json"
        let webUIDBPath = tempRoot + "/.hermes-web-ui/hermes-web-ui.db"

        let builtinConfig = try read(configPath)
        let builtinEnv = try read(envPath)
        assertContains(builtinConfig, #"provider: "opencode-go""#, "active profile config should use opencode-go")
        assertContains(builtinConfig, #"default: "glm-5""#, "active profile config should use glm-5")
        assertContains(builtinEnv, "OPENCODE_API_KEY=", "active profile env should contain Web UI recognized key")
        assertContains(builtinEnv, "OPENCODE_GO_API_KEY=", "active profile env should contain Hermes Manager alias key")
        assertFileExists(webUIConfigPath)
        assertFileExists(webUIDBPath)
        assertSQLiteContains(dbPath: webUIDBPath, provider: "opencode-go", model: "glm-5")

        let custom = ModelProviderConfiguration(
            providerKey: "custom:team-gateway",
            providerLabel: "Team Gateway",
            baseURL: "https://gateway.example.com/v1",
            apiKey: "test-custom-key",
            defaultModel: "team-model-a",
            models: ["team-model-a", "team-model-b"],
            contextLength: 64000
        )
        try unwrap(service.configureModelProvider(custom) { _ in })

        let customConfig = try read(configPath)
        let customEnv = try read(envPath)
        assertContains(customConfig, #"provider: "custom:team-gateway""#, "custom provider should become current model provider")
        assertContains(customConfig, #"name: "Team Gateway""#, "custom provider should keep display name")
        assertContains(customConfig, #"key_env: "HERMES_MANAGER_CUSTOM_TEAM_GATEWAY_API_KEY""#, "custom provider should keep Hermes key_env")
        assertContains(customConfig, #"api_key: "test-custom-key""#, "custom provider should include inline api_key for Hermes Web UI")
        assertContains(customConfig, #"team-model-b"#, "custom provider should include selected model catalog")
        assertOccurrences(customConfig, #"name: "Team Gateway""#, 2, "custom provider should expose each selected model to Hermes Web UI fallback parsing")
        assertFirstCustomProviderModel(customConfig, #"team-model-a"#)
        assertContains(customEnv, "HERMES_MANAGER_CUSTOM_TEAM_GATEWAY_API_KEY=", "custom provider key should also be in active .env")
        assertSQLiteContains(dbPath: webUIDBPath, provider: "custom:team-gateway", model: "team-model-b")

        let trimmedCustom = ModelProviderConfiguration(
            providerKey: "custom:team-gateway",
            providerLabel: "Team Gateway",
            baseURL: "https://gateway.example.com/v1",
            apiKey: "test-custom-key",
            defaultModel: "team-model-a",
            models: ["team-model-a"],
            contextLength: 32000
        )
        try unwrap(service.configureModelProviderExact(trimmedCustom) { _ in })
        assertSQLiteContains(dbPath: webUIDBPath, provider: "custom:team-gateway", model: "team-model-a")
        assertSQLiteMissing(dbPath: webUIDBPath, provider: "custom:team-gateway", model: "team-model-b")

        assertPathMissing(tempRoot + "/.hermes/config.yaml", "default profile config should not be created when active profile is dev")
        assertPathMissing(NSHomeDirectory() + "/.hermes-manager-selftest-sentinel", "self-test must not touch real HOME")
    }

    private static func prepareActiveProfileHome(_ home: String) throws {
        let profileHome = home + "/.hermes/profiles/dev"
        try FileManager.default.createDirectory(atPath: profileHome, withIntermediateDirectories: true)
        try "dev\n".write(toFile: home + "/.hermes/active_profile", atomically: true, encoding: .utf8)
        try "model:\n  default: old-model\n  provider: old-provider\n".write(toFile: profileHome + "/config.yaml", atomically: true, encoding: .utf8)
        try "".write(toFile: profileHome + "/.env", atomically: true, encoding: .utf8)
    }

    private static func makeTemporaryHome() throws -> String {
        let root = NSTemporaryDirectory() + "HermesManagerSelfTest-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        return root
    }

    private static func unwrap(_ result: Result<Void, Error>) throws {
        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    private static func read(_ path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    private static func assertContains(_ text: String, _ needle: String, _ message: String) {
        guard text.contains(needle) else {
            fatalError("\(message). Missing: \(needle)")
        }
    }

    private static func assertOccurrences(_ text: String, _ needle: String, _ expected: Int, _ message: String) {
        let count = text.components(separatedBy: needle).count - 1
        guard count == expected else {
            fatalError("\(message). Expected \(expected), got \(count)")
        }
    }

    private static func assertFirstCustomProviderModel(_ text: String, _ expectedModel: String) {
        guard let customRange = text.range(of: "custom_providers:"),
              let firstModelRange = text[customRange.upperBound...].range(of: "    model: ") else {
            fatalError("custom provider model entry missing")
        }
        let afterModel = text[firstModelRange.upperBound...]
        let actual = afterModel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard actual.hasPrefix(expectedModel) || actual.hasPrefix("\"\(expectedModel)\"") else {
            fatalError("first custom provider should keep default model first")
        }
    }

    private static func assertFileExists(_ path: String) {
        guard FileManager.default.fileExists(atPath: path) else {
            fatalError("Expected file to exist: \(path)")
        }
    }

    private static func assertPathMissing(_ path: String, _ message: String) {
        guard !FileManager.default.fileExists(atPath: path) else {
            fatalError("\(message): \(path)")
        }
    }

    private static func assertSQLiteContains(dbPath: String, provider: String, model: String) {
        let count = sqliteModelCount(dbPath: dbPath, provider: provider, model: model)
        guard count > 0 else {
            fatalError("Expected Web UI model_context row for \(provider) / \(model)")
        }
    }

    private static func assertSQLiteMissing(dbPath: String, provider: String, model: String) {
        let count = sqliteModelCount(dbPath: dbPath, provider: provider, model: model)
        guard count == 0 else {
            fatalError("Expected Web UI model_context row to be removed for \(provider) / \(model)")
        }
    }

    private static func sqliteModelCount(dbPath: String, provider: String, model: String) -> Int {
        let task = Process()
        let output = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = [
            "sqlite3",
            dbPath,
            "SELECT COUNT(*) FROM model_context WHERE provider = '\(sqlEscape(provider))' AND model = '\(sqlEscape(model))';",
        ]
        task.standardOutput = output
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard task.terminationStatus == 0 else { fatalError("sqlite3 failed for \(provider) / \(model)") }
            return Int(text) ?? 0
        } catch {
            fatalError("sqlite3 failed: \(error.localizedDescription)")
        }
    }

    private static func sqlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "''")
    }
}
