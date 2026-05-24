import AppKit
import CryptoKit
import Foundation

struct RemoteVersionManifest: Codable, Equatable {
    static let manifestURLDefaultsKey = "remoteUpdateManifestURL"
    static let defaultGitHubManifestURL = "https://raw.githubusercontent.com/Averionx/HermesManager/main/version-manifest.json"

    static let bundled = RemoteVersionManifest(
        schemaVersion: 1,
        channel: "stable",
        releasedAt: "2026-05-23T00:00:00Z",
        app: AppUpdateChannelManifest(
            stable: AppReleaseManifest(
                enabled: true,
                version: "v0.1.0",
                downloadURL: "",
                sha256: "",
                notes: "Bundled fallback manifest. Configure a GitHub raw manifest URL after publishing."
            ),
            preview: nil
        ),
        components: ComponentVersionManifest(
            hermes: GitComponentManifest(
                name: "Hermes",
                version: "v0.14.0",
                repo: "https://github.com/NousResearch/hermes-agent.git",
                ref: "43e566f77eaf01293086eb7cb99a21e240d60634"
            ),
            openHuman: GitComponentManifest(
                name: "OpenHuman",
                version: "v0.54.0",
                repo: "https://github.com/tinyhumansai/openhuman.git",
                ref: "48548a223bbf71fded61d43ff1b4de15bc34979b"
            ),
            hermesWebUI: NPMComponentManifest(
                package: "hermes-web-ui",
                version: "0.5.28"
            )
        ),
        compatibilityBundle: CompatibilityBundleManifest(
            version: "core-2026.05.23",
            label: "Hermes v0.14.0 + OpenHuman v0.54.0"
        )
    )

    let schemaVersion: Int
    let channel: String
    let releasedAt: String
    let app: AppUpdateChannelManifest
    let components: ComponentVersionManifest
    let compatibilityBundle: CompatibilityBundleManifest

    func appRelease(includePreview: Bool) -> AppReleaseManifest? {
        if includePreview, let preview = app.preview, preview.isEnabled {
            return preview
        }
        if app.stable.isEnabled {
            return app.stable
        }
        if let preview = app.preview, preview.isEnabled {
            return preview
        }
        return nil
    }

    func appTargetVersion(includePreview: Bool) -> String {
        appRelease(includePreview: includePreview)?.version ?? "未配置"
    }
}

struct AppUpdateChannelManifest: Codable, Equatable {
    let stable: AppReleaseManifest
    let preview: AppReleaseManifest?
}

struct AppReleaseManifest: Codable, Equatable {
    let enabled: Bool?
    let version: String
    let downloadURL: String
    let sha256: String
    let notes: String?

    var isEnabled: Bool {
        enabled ?? true
    }

    var hasDownload: Bool {
        guard let url = URL(string: downloadURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return false
        }
        return ["https", "http"].contains(url.scheme?.lowercased() ?? "")
    }
}

struct ComponentVersionManifest: Codable, Equatable {
    let hermes: GitComponentManifest
    let openHuman: GitComponentManifest
    let hermesWebUI: NPMComponentManifest
}

struct GitComponentManifest: Codable, Equatable {
    let name: String
    let version: String?
    let repo: String
    let ref: String

    var shortRef: String {
        String(ref.prefix(7))
    }

    var displayVersion: String {
        let explicit = VersionFormatting.displayVersion(version ?? "", fallback: "")
        if !explicit.isEmpty { return explicit }

        // Older public manifests only had Git refs. Keep the public UI version-only
        // by falling back to the currently developer-verified component versions.
        let component = name.lowercased()
        if component.contains("openhuman") { return "v0.54.0" }
        if component.contains("hermes") { return "v0.14.0" }
        return VersionFormatting.displayVersion(ref)
    }
}

enum VersionFormatting {
    static func displayVersion(_ value: String, fallback: String = "未检测") -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        let pattern = #"v?\d+(?:\.\d+){1,3}(?:[-_][A-Za-z0-9.\-_]+)?"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
           let range = Range(match.range, in: trimmed) {
            let version = String(trimmed[range]).replacingOccurrences(of: "_", with: "-")
            return version.hasPrefix("v") ? version : "v\(version)"
        }
        return fallback
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = comparableParts(lhs)
        let right = comparableParts(rhs)
        guard left.hasVersion || right.hasVersion else {
            return left.suffix.localizedStandardCompare(right.suffix)
        }
        guard left.hasVersion else { return .orderedAscending }
        guard right.hasVersion else { return .orderedDescending }

        let count = max(left.numbers.count, right.numbers.count)
        for index in 0..<count {
            let a = index < left.numbers.count ? left.numbers[index] : 0
            let b = index < right.numbers.count ? right.numbers[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        if left.suffix == right.suffix { return .orderedSame }
        if left.suffix.isEmpty && !right.suffix.isEmpty { return .orderedDescending }
        if !left.suffix.isEmpty && right.suffix.isEmpty { return .orderedAscending }
        return left.suffix.localizedStandardCompare(right.suffix)
    }

    private static func comparableParts(_ value: String) -> (numbers: [Int], suffix: String, hasVersion: Bool) {
        let lower = value.lowercased()
        let pattern = #"v?(\d+(?:\.\d+){0,3})(?:[-_]?([a-z][a-z0-9.\-_]*\d*|[a-z0-9]*[a-z][a-z0-9.\-_]*))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: lower, range: NSRange(lower.startIndex..., in: lower)),
              let versionRange = Range(match.range(at: 1), in: lower) else {
            return ([], lower.trimmingCharacters(in: .whitespacesAndNewlines), false)
        }
        let numbers = lower[versionRange]
            .split(separator: ".")
            .map { Int($0) ?? 0 }
        let suffix: String
        if match.numberOfRanges > 2,
           let suffixRange = Range(match.range(at: 2), in: lower) {
            suffix = String(lower[suffixRange])
        } else {
            suffix = ""
        }
        return (numbers, suffix, true)
    }
}

struct NPMComponentManifest: Codable, Equatable {
    let package: String
    let version: String
}

struct CompatibilityBundleManifest: Codable, Equatable {
    let version: String
    let label: String

    func displayVersion(hermes: String, openHuman: String) -> String {
        let fromVersion = VersionFormatting.displayVersion(version, fallback: "")
        if !fromVersion.isEmpty { return fromVersion }
        return "Hermes \(hermes) / OpenHuman \(openHuman)"
    }

    func displayLabel(hermes: String, openHuman: String) -> String {
        "Hermes \(hermes) + OpenHuman \(openHuman)"
    }
}

enum RemoteVersionManifestService {
    static func activeManifestURL() -> URL? {
        let configured = UserDefaults.standard.string(forKey: RemoteVersionManifest.manifestURLDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = configured?.isEmpty == false ? configured! : RemoteVersionManifest.defaultGitHubManifestURL
        guard !raw.contains("YOUR_GITHUB_ACCOUNT") else {
            return nil
        }
        return URL(string: raw)
    }

    static func fetch(completion: @escaping (Result<(RemoteVersionManifest, String), Error>) -> Void) {
        guard let url = activeManifestURL() else {
            completion(.success((RemoteVersionManifest.bundled, "内置离线清单")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                completion(.failure(UpdateManifestError.remoteStatus(http.statusCode)))
                return
            }
            guard let data else {
                completion(.failure(UpdateManifestError.emptyResponse))
                return
            }

            do {
                let manifest = try JSONDecoder().decode(RemoteVersionManifest.self, from: data)
                completion(.success((manifest, url.absoluteString)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum UpdateManifestError: LocalizedError {
    case remoteStatus(Int)
    case emptyResponse
    case missingDownloadURL
    case checksumMismatch

    var errorDescription: String? {
        switch self {
        case .remoteStatus(let code):
            return "远程版本清单请求失败：HTTP \(code)"
        case .emptyResponse:
            return "远程版本清单为空。"
        case .missingDownloadURL:
            return "当前版本清单没有配置 App 下载地址。"
        case .checksumMismatch:
            return "下载文件的 sha256 与版本清单不一致，已取消安装。"
        }
    }
}

enum AppUpdateDownloadService {
    static func download(release: AppReleaseManifest, completion: @escaping (Result<URL, Error>) -> Void) {
        guard release.hasDownload, let url = URL(string: release.downloadURL) else {
            completion(.failure(UpdateManifestError.missingDownloadURL))
            return
        }

        URLSession.shared.downloadTask(with: url) { temporaryURL, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let temporaryURL else {
                completion(.failure(UpdateManifestError.emptyResponse))
                return
            }

            do {
                let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                    ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads", isDirectory: true)
                try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
                let filename = "HermesManager-\(safeFilename(release.version)).dmg"
                let destination = downloads.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: temporaryURL, to: destination)
                try verifyChecksumIfNeeded(fileURL: destination, expectedSHA256: release.sha256)
                completion(.success(destination))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private static func verifyChecksumIfNeeded(fileURL: URL, expectedSHA256: String) throws {
        let expected = expectedSHA256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !expected.isEmpty else { return }
        let data = try Data(contentsOf: fileURL)
        let actual = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
        guard actual == expected else {
            try? FileManager.default.removeItem(at: fileURL)
            throw UpdateManifestError.checksumMismatch
        }
    }

    private static func safeFilename(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
        return value.unicodeScalars.map { allowed.contains($0) ? String($0) : "-" }.joined()
    }
}
