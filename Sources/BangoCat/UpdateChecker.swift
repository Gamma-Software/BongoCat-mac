import Foundation
import UserNotifications
import AppKit
import SwiftUI

struct GitHubReleaseAsset: Codable {
    let id: Int
    let name: String
    let browserDownloadUrl: String
    let size: Int
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case contentType = "content_type"
    }
}

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let publishedAt: String
    let htmlUrl: String
    let draft: Bool
    let prerelease: Bool
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case draft
        case prerelease
        case assets
    }
}

class UpdateChecker: NSObject, ObservableObject {
    static let shared = UpdateChecker()

    // GitHub repository information
    private let repoOwner = "Gamma-Software"
    private let repoName = "BangoCat-mac"
    private let releasesURL = "https://api.github.com/repos/Gamma-Software/BangoCat-mac/releases"

    // Settings keys
    private let lastCheckDateKey = "BangoCatLastUpdateCheck"
    private let updateNotificationsEnabledKey = "BangoCatUpdateNotificationsEnabled"
    private let skipVersionKey = "BangoCatSkipVersion"
    private let autoUpdateEnabledKey = "BangoCatAutoUpdateEnabled"

    // Settings
    @Published private var updateNotificationsEnabled: Bool = true
    @Published private var autoUpdateEnabled: Bool = true
    private var skippedVersion: String?

    // Update checking
    private var dailyCheckTimer: Timer?
    private let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    // Download tracking
    private var currentDownloadTask: URLSessionDownloadTask?
    private var isUpdating: Bool = false

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

    override init() {
        super.init()
        loadSettings()
    }

    // MARK: - Settings Management

    private func loadSettings() {
        updateNotificationsEnabled = UserDefaults.standard.object(forKey: updateNotificationsEnabledKey) == nil ? true : UserDefaults.standard.bool(forKey: updateNotificationsEnabledKey)
        autoUpdateEnabled = UserDefaults.standard.object(forKey: autoUpdateEnabledKey) == nil ? true : UserDefaults.standard.bool(forKey: autoUpdateEnabledKey)
        skippedVersion = UserDefaults.standard.string(forKey: skipVersionKey)

        // Track configuration loading
        analytics.trackConfigurationLoaded("update_checker", success: true)

        print("🔄 Loaded update checker settings - notifications: \(updateNotificationsEnabled), auto-update: \(autoUpdateEnabled), skipped version: \(skippedVersion ?? "none")")
    }

    private func saveSettings() {
        UserDefaults.standard.set(updateNotificationsEnabled, forKey: updateNotificationsEnabledKey)
        UserDefaults.standard.set(autoUpdateEnabled, forKey: autoUpdateEnabledKey)
        if let skippedVersion = skippedVersion {
            UserDefaults.standard.set(skippedVersion, forKey: skipVersionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: skipVersionKey)
        }
    }

    // MARK: - Public Interface

    func startDailyUpdateChecks() {
        // Check immediately if it's been more than 24 hours since last check
        checkForUpdatesIfNeeded()

        // Set up daily timer
        dailyCheckTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkForUpdatesIfNeeded()
        }

        print("🔄 Daily update checks started")
    }

    func stopDailyUpdateChecks() {
        dailyCheckTimer?.invalidate()
        dailyCheckTimer = nil
        print("🔄 Daily update checks stopped")
    }

    func checkForUpdatesManually() {
        print("🔄 Manual update check requested")
        analytics.trackUpdateCheckStarted(true)
        checkForUpdates(isManual: true)
    }

    // MARK: - Debug Methods

    func debugUpdateSystem() {
        print("🔍 Debugging update system...")

        let currentVersion = getCurrentVersion()
        print("📱 Current version: \(currentVersion)")
        print("🔧 Auto-update enabled: \(autoUpdateEnabled)")
        print("🔔 Update notifications enabled: \(updateNotificationsEnabled)")
        print("⏭️ Skipped version: \(skippedVersion ?? "none")")

        // Test network connectivity
        guard let url = URL(string: releasesURL) else {
            print("❌ Invalid GitHub API URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Network response: HTTP \(httpResponse.statusCode)")
                    if let data = data {
                        print("📦 Response size: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")

                        // Try to parse the response
                        do {
                            let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
                            if let latestRelease = releases.first {
                                let latestVersion = latestRelease.tagName.replacingOccurrences(of: "v", with: "")
                                print("🔄 Latest GitHub version: \(latestVersion)")
                                print("🔄 Version comparison result: \(self.isNewerVersion(latest: latestVersion, current: currentVersion))")
                            }
                        } catch {
                            print("❌ Failed to parse GitHub response: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        task.resume()
    }

    func testVersionComparison() {
        let currentVersion = getCurrentVersion()
        let testVersions = ["1.5.2", "1.5.3", "1.5.4", "1.6.0", "2.0.0"]

        print("🧪 Testing version comparison with current version: \(currentVersion)")
        for testVersion in testVersions {
            let result = isNewerVersion(latest: testVersion, current: currentVersion)
            print("  \(testVersion) > \(currentVersion): \(result)")
        }
    }

    func testDownloadFunctionality() {
        print("🧪 Testing download functionality...")

        // Create a mock release for testing
        let mockAsset = GitHubReleaseAsset(
            id: 1,
            name: "BangoCat-1.5.4.dmg",
            browserDownloadUrl: "https://github.com/Gamma-Software/BangoCat-mac/releases/download/v1.5.3/BangoCat-1.5.3.dmg",
            size: 1024 * 1024 * 10, // 10MB
            contentType: "application/octet-stream"
        )

        let mockRelease = GitHubRelease(
            tagName: "v1.5.4",
            name: "Test Release",
            publishedAt: "2024-01-01T00:00:00Z",
            htmlUrl: "https://github.com/Gamma-Software/BangoCat-mac/releases/tag/v1.5.4",
            draft: false,
            prerelease: false,
            assets: [mockAsset]
        )

        print("🔄 Testing download with mock release: \(mockRelease.tagName)")
        downloadAndOpenUpdate(release: mockRelease)
    }

    func testDownloadOnly() {
        print("🧪 Testing download only (no installation)...")

        // Create a mock release for testing
        let mockAsset = GitHubReleaseAsset(
            id: 1,
            name: "BangoCat-1.5.4.dmg",
            browserDownloadUrl: "https://github.com/Gamma-Software/BangoCat-mac/releases/download/v1.5.3/BangoCat-1.5.3.dmg",
            size: 1024 * 1024 * 10, // 10MB
            contentType: "application/octet-stream"
        )

        let mockRelease = GitHubRelease(
            tagName: "v1.5.4",
            name: "Test Release",
            publishedAt: "2024-01-01T00:00:00Z",
            htmlUrl: "https://github.com/Gamma-Software/BangoCat-mac/releases/tag/v1.5.4",
            draft: false,
            prerelease: false,
            assets: [mockAsset]
        )

        print("🔄 Testing download only with mock release: \(mockRelease.tagName)")

        // Find DMG asset
        guard let dmgAsset = findDMGAsset(in: mockRelease.assets) else {
            print("❌ No DMG asset found")
            return
        }

        print("🔄 Starting download test for version \(mockRelease.tagName)")
        print("📦 DMG Asset: \(dmgAsset.name) (\(ByteCountFormatter.string(fromByteCount: Int64(dmgAsset.size), countStyle: .file)))")

        downloadDMG(from: dmgAsset) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dmgPath):
                    print("✅ Download test successful: \(dmgPath)")
                    // Don't try to install, just clean up
                    try? FileManager.default.removeItem(atPath: dmgPath)
                    print("🧹 Cleaned up test file")
                case .failure(let error):
                    print("❌ Download test failed: \(error.localizedDescription)")
                }
            }
        }
    }

    func setUpdateNotificationsEnabled(_ enabled: Bool) {
        updateNotificationsEnabled = enabled
        saveSettings()

        // Track setting change
        analytics.trackSettingToggled("update_notifications", enabled: enabled)

        print("🔄 Update notifications \(enabled ? "enabled" : "disabled")")
    }

    func setAutoUpdateEnabled(_ enabled: Bool) {
        autoUpdateEnabled = enabled
        saveSettings()

        // Track setting change
        analytics.trackSettingToggled("auto_update", enabled: enabled)

        print("🔄 Auto-update \(enabled ? "enabled" : "disabled")")
    }

    func isUpdateNotificationsEnabled() -> Bool {
        return updateNotificationsEnabled
    }

    func isAutoUpdateEnabled() -> Bool {
        return autoUpdateEnabled
    }

    func skipVersion(_ version: String) {
        skippedVersion = version
        saveSettings()

        // Track update action
        analytics.trackUpdateActionTaken("skip", version: version)

        print("🔄 Skipping version: \(version)")
    }

    func clearSkippedVersion() {
        skippedVersion = nil
        saveSettings()
        print("🔄 Cleared skipped version")
    }

    // MARK: - Private Methods

    private func checkForUpdatesIfNeeded() {
        guard updateNotificationsEnabled else { return }

        let lastCheckDate = UserDefaults.standard.object(forKey: lastCheckDateKey) as? Date
        let now = Date()

        // Check if we need to update (first time or more than 24 hours ago)
        if lastCheckDate == nil || now.timeIntervalSince(lastCheckDate!) >= checkInterval {
            analytics.trackUpdateCheckStarted(false)
            checkForUpdates(isManual: false)
        }
    }

    private func checkForUpdates(isManual: Bool) {
        guard let url = URL(string: releasesURL) else {
            print("❌ Invalid GitHub API URL")
            analytics.trackError("Invalid GitHub API URL", context: ["is_manual": isManual])
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handleUpdateCheckResponse(data: data, response: response, error: error, isManual: isManual)
            }
        }

        task.resume()
        print("🔄 Checking for updates from GitHub...")
    }

    private func handleUpdateCheckResponse(data: Data?, response: URLResponse?, error: Error?, isManual: Bool) {
        // Update last check date
        UserDefaults.standard.set(Date(), forKey: lastCheckDateKey)

        if let error = error {
            print("❌ Update check failed: \(error.localizedDescription)")
            analytics.trackError("Update check failed", context: ["error": error.localizedDescription, "is_manual": isManual])
            analytics.trackUpdateCheckCompleted(false, currentVersion: getCurrentVersion(), latestVersion: nil)

            if isManual {
                showErrorAlert(message: "Failed to check for updates: \(error.localizedDescription)")
            }
            return
        }

        guard let data = data else {
            print("❌ No data received from GitHub API")
            analytics.trackError("No data from GitHub API", context: ["is_manual": isManual])
            analytics.trackUpdateCheckCompleted(false, currentVersion: getCurrentVersion(), latestVersion: nil)

            if isManual {
                showErrorAlert(message: "No data received from GitHub")
            }
            return
        }

        do {
            let releases = try JSONDecoder().decode([GitHubRelease].self, from: data)
            processReleases(releases, isManual: isManual)
        } catch {
            print("❌ Failed to parse GitHub API response: \(error.localizedDescription)")
            analytics.trackError("Failed to parse update response", context: ["error": error.localizedDescription, "is_manual": isManual])
            analytics.trackUpdateCheckCompleted(false, currentVersion: getCurrentVersion(), latestVersion: nil)

            if isManual {
                showErrorAlert(message: "Failed to parse update information")
            }
        }
    }

    private func processReleases(_ releases: [GitHubRelease], isManual: Bool) {
        // Filter out drafts and prereleases
        let validReleases = releases.filter { !$0.draft && !$0.prerelease }

        guard let latestRelease = validReleases.first else {
            print("🔄 No valid releases found")
            analytics.trackUpdateCheckCompleted(false, currentVersion: getCurrentVersion(), latestVersion: nil)

            if isManual {
                showInfoAlert(title: "No Updates", message: "No releases available.")
            }
            return
        }

        let currentVersion = getCurrentVersion()
        let latestVersion = latestRelease.tagName.replacingOccurrences(of: "v", with: "")

        print("🔄 Current version: \(currentVersion), Latest version: \(latestVersion)")
        print("🔄 Version comparison: isNewerVersion(\(latestVersion), \(currentVersion)) = \(isNewerVersion(latest: latestVersion, current: currentVersion))")

        if isNewerVersion(latest: latestVersion, current: currentVersion) {
            analytics.trackUpdateCheckCompleted(true, currentVersion: currentVersion, latestVersion: latestVersion)

            // Check if this version was skipped
            if let skippedVersion = skippedVersion, skippedVersion == latestVersion {
                print("🔄 Update available but version \(latestVersion) was skipped")
                if isManual {
                    showUpdateAvailable(release: latestRelease, isSkipped: true)
                }
                return
            }

            print("🔄 New version available: \(latestVersion)")
            showUpdateAvailable(release: latestRelease, isSkipped: false)
        } else {
            analytics.trackUpdateCheckCompleted(false, currentVersion: currentVersion, latestVersion: latestVersion)

            print("🔄 App is up to date")
            if isManual {
                showInfoAlert(title: "Up to Date", message: "You have the latest version of BangoCat (\(currentVersion)).")
            }
        }
    }

    private func getCurrentVersion() -> String {
        // Try to get version from bundle first, fallback to hardcoded version
        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return bundleVersion
        }
        return "1.1.0" // Fallback to current version
    }

    private func isNewerVersion(latest: String, current: String) -> Bool {
        let latestComponents = latest.components(separatedBy: ".").compactMap { Int($0) }
        let currentComponents = current.components(separatedBy: ".").compactMap { Int($0) }

        // Ensure we have at least 3 components for comparison
        let maxComponents = max(latestComponents.count, currentComponents.count, 3)

        for i in 0..<maxComponents {
            let latestValue = i < latestComponents.count ? latestComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0

            if latestValue > currentValue {
                return true
            } else if latestValue < currentValue {
                return false
            }
        }

        return false // Versions are equal
    }

    private func showUpdateAvailable(release: GitHubRelease, isSkipped: Bool) {
        // Show notification if supported
        if MilestoneNotificationManager.shared.isNotificationsEnabled() {
            sendUpdateNotification(release: release)
        }

        // Always show alert for user interaction
        showUpdateAlert(release: release, isSkipped: isSkipped)
    }

    private func sendUpdateNotification(release: GitHubRelease) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "🆕 BangoCat Update Available!"
        content.body = "Version \(release.tagName) is now available. Click to learn more."
        content.sound = .default

        content.userInfo = [
            "type": "update",
            "version": release.tagName,
            "url": release.htmlUrl
        ]

        let identifier = "update-\(release.tagName)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        // Track notification shown
        analytics.trackNotificationShown("update")

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send update notification: \(error.localizedDescription)")
                self.analytics.trackError("Failed to send update notification", context: ["error": error.localizedDescription])
            } else {
                print("🔔 Update notification sent for version \(release.tagName)")
            }
        }
    }

    private func showUpdateAlert(release: GitHubRelease, isSkipped: Bool) {
        guard !isUpdating else {
            print("🔄 Update already in progress, ignoring new update alert")
            return
        }

        let alert = NSAlert()
        alert.messageText = "🆕 BangoCat Update Available!"

        let currentVersion = getCurrentVersion()
        let newVersion = release.tagName.replacingOccurrences(of: "v", with: "")

        var infoText = "Version \(release.tagName) is now available.\n\nCurrent version: \(currentVersion)\nNew version: \(newVersion)"

        if autoUpdateEnabled {
            infoText += "\n\nWould you like to automatically download and install it now?"
            alert.addButton(withTitle: "Open DMG Automatically")
            alert.addButton(withTitle: "Download Manually")
        } else {
            infoText += "\n\nWould you like to download it now?"
            alert.addButton(withTitle: "Download Now")
        }

        alert.informativeText = infoText
        alert.alertStyle = .informational

        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Remind Me Later")

        let response = alert.runModal()

        if autoUpdateEnabled {
            // Auto-update enabled: "Open DMG Automatically", "Download Manually", "Skip This Version", "Remind Me Later"
            switch response {
            case .alertFirstButtonReturn: // Open DMG Automatically
                analytics.trackUpdateActionTaken("auto_open_dmg", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "auto_open_dmg")
                downloadAndOpenUpdate(release: release)
            case .alertSecondButtonReturn: // Download Manually
                analytics.trackUpdateActionTaken("download", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "download")
                openUpdateURL(release.htmlUrl)
            case .alertThirdButtonReturn: // Skip This Version
                analytics.trackUpdateActionTaken("skip", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "skip")
                skipVersion(release.tagName.replacingOccurrences(of: "v", with: ""))
            case NSApplication.ModalResponse(rawValue: NSApplication.ModalResponse.alertThirdButtonReturn.rawValue + 1): // Remind Me Later
                analytics.trackUpdateActionTaken("later", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "later")
            default:
                analytics.trackNotificationDismissed("update")
            }
        } else {
            // Auto-update disabled: "Download Now", "Skip This Version", "Remind Me Later"
            switch response {
            case .alertFirstButtonReturn: // Download Now
                analytics.trackUpdateActionTaken("download", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "download")
                openUpdateURL(release.htmlUrl)
            case .alertSecondButtonReturn: // Skip This Version
                analytics.trackUpdateActionTaken("skip", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "skip")
                skipVersion(release.tagName.replacingOccurrences(of: "v", with: ""))
            case .alertThirdButtonReturn: // Remind Me Later
                analytics.trackUpdateActionTaken("later", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "later")
            default:
                analytics.trackNotificationDismissed("update")
            }
        }
    }

    // MARK: - Automatic Update Methods

    private func downloadAndOpenUpdate(release: GitHubRelease) {
        guard !isUpdating else {
            print("🔄 Update already in progress")
            return
        }

        // Verify that this is actually a newer version before proceeding
        let currentVersion = getCurrentVersion()
        let latestVersion = release.tagName.replacingOccurrences(of: "v", with: "")

        if !isNewerVersion(latest: latestVersion, current: currentVersion) {
            print("❌ Attempted to download update for same or older version: current=\(currentVersion), latest=\(latestVersion)")
            showErrorAlert(message: "No update available. You already have the latest version (\(currentVersion)).")
            return
        }

        // Find DMG asset
        guard let dmgAsset: GitHubReleaseAsset = findDMGAsset(in: release.assets) else {
            showErrorAlert(message: "No DMG file found in the release assets. Please download manually from the GitHub releases page.")
            analytics.trackError("No DMG asset found", context: ["version": release.tagName])
            return
        }

        print("🔄 Starting automatic update download for version \(release.tagName)")
        print("📦 DMG Asset: \(dmgAsset.name) (\(ByteCountFormatter.string(fromByteCount: Int64(dmgAsset.size), countStyle: .file)))")

        isUpdating = true

        showDownloadProgressAlert(
            onCancel: { [weak self] cancelled in
                if cancelled {
                    self?.cancelDownload()
                }
            },
            onInstall: { [weak self] dmgPath in
                self?.openDownloadedDMG(dmgPath: dmgPath, version: release.tagName)
            }
        )

        downloadDMG(from: dmgAsset) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUpdating = false

                switch result {
                case .success(let dmgPath):
                    print("✅ Download complete: \(dmgPath)")
                    self?.updateDownloadAlertToInstall(dmgPath: dmgPath, version: release.tagName)
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                    self?.analytics.trackError("Download failed", context: ["error": error.localizedDescription, "version": release.tagName])
                    self?.hideDownloadProgressAlert()
                    self?.showErrorAlert(message: "Failed to download update: \(error.localizedDescription)")
                }
            }
        }
    }

    private func findDMGAsset(in assets: [GitHubReleaseAsset]) -> GitHubReleaseAsset? {
        // Look for DMG files, prioritizing non-debug versions
        let dmgAssets = assets.filter { $0.name.lowercased().hasSuffix(".dmg") }

        // First try to find a non-debug DMG
        if let nonDebugDMG = dmgAssets.first(where: { !$0.name.lowercased().contains("debug") }) {
            return nonDebugDMG
        }

        // Fall back to any DMG
        return dmgAssets.first
    }

    private func downloadDMG(from asset: GitHubReleaseAsset, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: asset.browserDownloadUrl) else {
            print("❌ Invalid download URL: \(asset.browserDownloadUrl)")
            completion(.failure(NSError(domain: "UpdateChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])))
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let dmgPath = tempDir.appendingPathComponent(asset.name).path

        // Create a custom URLSession configuration for better reliability
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 300.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true

        let session = URLSession(configuration: config)

        print("🔄 Starting download from: \(url)")
        print("📁 Target path: \(dmgPath)")
        print("📦 Expected file size: \(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))")

        currentDownloadTask = session.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                print("❌ Download error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                completion(.failure(NSError(domain: "UpdateChecker", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }

            print("📡 HTTP Response: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP error: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "UpdateChecker", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode) error"])))
                return
            }

            guard let tempURL = tempURL else {
                print("❌ No temporary file URL")
                completion(.failure(NSError(domain: "UpdateChecker", code: 2, userInfo: [NSLocalizedDescriptionKey: "No temporary file URL"])))
                return
            }

            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: dmgPath) {
                    try FileManager.default.removeItem(atPath: dmgPath)
                }

                try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: dmgPath))

                // Verify the file was downloaded correctly
                let fileSize = try FileManager.default.attributesOfItem(atPath: dmgPath)[.size] as? Int64 ?? 0
                print("✅ Download complete: \(dmgPath) (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))")

                // Verify file size is reasonable
                if fileSize < 1024 * 1024 { // Less than 1MB
                    print("⚠️ Warning: Downloaded file seems too small (\(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)))")
                }

                completion(.success(dmgPath))
            } catch {
                print("❌ File operation error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        currentDownloadTask?.resume()
    }

    private func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        isUpdating = false
        downloadedDMGPath = nil
        downloadedVersion = nil
        print("🛑 Download cancelled by user")
        analytics.trackUpdateActionTaken("cancel", version: "unknown")
    }

    private func openDownloadedDMG(dmgPath: String, version: String) {
        print("🔄 Opening downloaded DMG for manual installation...")

        // Open the DMG file using NSWorkspace
        if let url = URL(string: "file://\(dmgPath)") {
            NSWorkspace.shared.open(url)
            print("✅ Opened DMG file: \(dmgPath)")

            // Show success alert with installation instructions
            let alert = NSAlert()
            alert.messageText = "📦 Update Downloaded Successfully!"
            alert.informativeText = "BangoCat v\(version) has been downloaded and opened in Finder.\n\nTo install the update:\n1. Drag the BangoCat app to your Applications folder\n2. Replace the existing app when prompted\n3. Eject the DMG when finished\n4. Restart BangoCat to complete the update"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Open Applications Folder")

            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                // Open Applications folder
                let applicationsURL = URL(fileURLWithPath: "/Applications")
                NSWorkspace.shared.open(applicationsURL)
            }

            // Track the action
            analytics.trackUpdateActionTaken("opened_dmg", version: version)
        } else {
            print("❌ Failed to create URL for DMG file")
            showErrorAlert(message: "Failed to open downloaded DMG file.")
        }
    }

    private func mountDMGAndInstall(dmgPath: String, version: String) {
        print("🔄 Mounting DMG and installing update...")

        let mountScript = """
        set dmgPath to "\(dmgPath)"
        set appName to "BangoCat"
        set mountPoint to ""

        try
            -- Verify DMG file exists and is readable
            do shell script "test -f '" & dmgPath & "'"
            do shell script "test -r '" & dmgPath & "'"

            -- Mount the DMG
            set mountResult to do shell script "hdiutil attach '" & dmgPath & "' -nobrowse -quiet"

            -- Extract mount point from result
            repeat with line in paragraphs of mountResult
                if line contains "/Volumes/" then
                    set mountPoint to word -1 of line
                    exit repeat
                end if
            end repeat

            if mountPoint is "" then
                error "Could not determine mount point from: " & mountResult
            end if

            -- Find the app in the mounted volume
            set appPath to mountPoint & "/" & appName & ".app"
            set destinationPath to "/Applications/" & appName & ".app"

            -- Check if app exists in DMG
            do shell script "test -d '" & appPath & "'"

            -- Kill the running app if it exists
            try
                do shell script "pkill -f " & quoted form of appName
                delay 2
            end try

            -- Remove existing app if it exists
            try
                do shell script "rm -rf " & quoted form of destinationPath
            end try

            -- Copy new app to Applications
            do shell script "cp -R " & quoted form of appPath & " " & quoted form of destinationPath

            -- Set proper permissions
            do shell script "chmod -R 755 " & quoted form of destinationPath

            -- Verify the installation
            do shell script "test -d '" & destinationPath & "'"

            -- Unmount DMG
            do shell script "hdiutil detach '" & mountPoint & "' -quiet"

            -- Clean up downloaded DMG
            do shell script "rm '" & dmgPath & "'"

            return "success"

        on error errorMessage
            -- Try to unmount DMG in case of error
            if mountPoint is not "" then
                try
                    do shell script "hdiutil detach '" & mountPoint & "' -quiet"
                end try
            end if

            error errorMessage
        end try
        """

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                print("🔄 Executing AppleScript installation...")
                let script = NSAppleScript(source: mountScript)
                var error: NSDictionary?
                let result = script?.executeAndReturnError(&error)

                DispatchQueue.main.async {
                    if let error = error {
                        let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                        let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                        print("❌ Installation failed: \(errorMessage) (Error #\(errorNumber))")
                        self.analytics.trackError("Installation failed", context: ["error": errorMessage, "version": version])
                        self.showErrorAlert(message: "Failed to install update: \(errorMessage)")
                    } else {
                        print("✅ Update installed successfully!")
                        print("📦 Installation result: \(result?.stringValue ?? "unknown")")
                        self.analytics.trackUpdateActionTaken("installed", version: version)
                        self.showInstallationSuccessAlert(version: version)
                    }
                }
            }
        }
    }

    // MARK: - UI Methods

    private var downloadProgressAlert: NSAlert?
    private var progressWindow: NSWindow?
    private var downloadCompletionCallback: ((String) -> Void)?
    private var downloadedDMGPath: String?
    private var downloadedVersion: String?

    private func showDownloadProgressAlert(onCancel: @escaping (Bool) -> Void, onInstall: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = "🔄 Downloading Update..."
        alert.informativeText = "BangoCat is downloading the latest version.\n\nThis may take a few minutes depending on your internet connection."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        downloadProgressAlert = alert
        downloadCompletionCallback = onInstall

        // Show the alert in a non-blocking way
        DispatchQueue.main.async {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // User clicked Install
                if let dmgPath = self.downloadedDMGPath {
                    onInstall(dmgPath)
                }
            }
        }
    }

    private func hideDownloadProgressAlert() {
        DispatchQueue.main.async {
            // Dismiss the alert if it's still showing
            if self.downloadProgressAlert != nil {
                // The alert will be dismissed when the download completes
                self.downloadProgressAlert = nil
            }
        }
    }

        private func updateDownloadAlertToInstall(dmgPath: String, version: String) {
        DispatchQueue.main.async {
            // Dismiss the current alert
            if let alert = self.downloadProgressAlert {
                alert.window.close()
            }
            self.downloadProgressAlert = nil

            // Create a new alert for installation
            let installAlert = NSAlert()
            installAlert.messageText = "✅ Download Complete!"
            installAlert.informativeText = "The update has been downloaded successfully.\n\nClick 'Install' to open the DMG and install the update manually."
            installAlert.alertStyle = .informational
            installAlert.addButton(withTitle: "Install")
            installAlert.addButton(withTitle: "Cancel")

            // Store the DMG path and version for the install action
            self.downloadedDMGPath = dmgPath
            self.downloadedVersion = version

            // Show the new alert
            let response = installAlert.runModal()
            if response == .alertFirstButtonReturn {
                // User clicked Install
                self.openDownloadedDMG(dmgPath: dmgPath, version: version)
            }
        }
    }

    private func showInstallationSuccessAlert(version: String) {
        let alert = NSAlert()
        alert.messageText = "🎉 Update Installed Successfully!"
        alert.informativeText = "BangoCat has been updated to version \(version). The app will restart automatically."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart BangoCat")
        alert.addButton(withTitle: "Restart Later")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            restartApplication()
        }
    }

    private func restartApplication() {
        print("🔄 Restarting BangoCat...")

        let path = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            task.launch()
            NSApplication.shared.terminate(nil)
        }
    }

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "❌ Update Failed"
        alert.informativeText = message + "\n\nIf the problem persists, please try downloading the update manually from the GitHub releases page."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open GitHub Releases")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            openUpdateURL("https://github.com/Gamma-Software/BangoCat-mac/releases")
        }
    }

    private func showInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func openUpdateURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid update URL: \(urlString)")
            analytics.trackError("Invalid update URL", context: ["url": urlString])
            return
        }

        NSWorkspace.shared.open(url)
        print("🔄 Opened update URL: \(urlString)")
    }
}