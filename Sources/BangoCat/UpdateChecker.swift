import Foundation
import UserNotifications
import AppKit

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

class UpdateChecker: NSObject {
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
    private var updateNotificationsEnabled: Bool = true
    private var autoUpdateEnabled: Bool = true
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
            alert.addButton(withTitle: "Install Automatically")
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
            // Auto-update enabled: "Install Automatically", "Download Manually", "Skip This Version", "Remind Me Later"
            switch response {
            case .alertFirstButtonReturn: // Install Automatically
                analytics.trackUpdateActionTaken("auto_install", version: release.tagName)
                analytics.trackNotificationClicked("update", action: "auto_install")
                downloadAndInstallUpdate(release: release)
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

    private func downloadAndInstallUpdate(release: GitHubRelease) {
        guard !isUpdating else {
            print("🔄 Update already in progress")
            return
        }

        // Find DMG asset
        guard let dmgAsset = findDMGAsset(in: release.assets) else {
            showErrorAlert(message: "No DMG file found in the release assets. Please download manually from the GitHub releases page.")
            analytics.trackError("No DMG asset found", context: ["version": release.tagName])
            return
        }

        print("🔄 Starting automatic update download for version \(release.tagName)")
        print("📦 DMG Asset: \(dmgAsset.name) (\(ByteCountFormatter.string(fromByteCount: Int64(dmgAsset.size), countStyle: .file)))")

        isUpdating = true

        showDownloadProgressAlert { [weak self] cancelled in
            if cancelled {
                self?.cancelDownload()
            }
        }

        downloadDMG(from: dmgAsset) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUpdating = false
                self?.hideDownloadProgressAlert()

                switch result {
                case .success(let dmgPath):
                    print("✅ Download complete: \(dmgPath)")
                    self?.mountDMGAndInstall(dmgPath: dmgPath, version: release.tagName)
                case .failure(let error):
                    print("❌ Download failed: \(error.localizedDescription)")
                                         self?.analytics.trackError("Download failed", context: ["error": error.localizedDescription, "version": release.tagName])
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
            completion(.failure(NSError(domain: "UpdateChecker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])))
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let dmgPath = tempDir.appendingPathComponent(asset.name).path

        currentDownloadTask = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "UpdateChecker", code: 2, userInfo: [NSLocalizedDescriptionKey: "No temporary file URL"])))
                return
            }

            do {
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: dmgPath) {
                    try FileManager.default.removeItem(atPath: dmgPath)
                }

                try FileManager.default.moveItem(at: tempURL, to: URL(fileURLWithPath: dmgPath))
                completion(.success(dmgPath))
            } catch {
                completion(.failure(error))
            }
        }

        currentDownloadTask?.resume()
    }

    private func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
        isUpdating = false
        print("🛑 Download cancelled by user")
        analytics.trackUpdateActionTaken("cancel", version: "unknown")
    }

    private func mountDMGAndInstall(dmgPath: String, version: String) {
        print("🔄 Mounting DMG and installing update...")

        let mountScript = """
        set dmgPath to "\(dmgPath)"
        set appName to "BangoCat"

        try
            -- Mount the DMG
            set mountResult to do shell script "hdiutil attach '" & dmgPath & "' -nobrowse -quiet"

            -- Extract mount point from result
            set mountPoint to ""
            repeat with line in paragraphs of mountResult
                if line contains "/Volumes/" then
                    set mountPoint to word -1 of line
                    exit repeat
                end if
            end repeat

            if mountPoint is "" then
                error "Could not determine mount point"
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

            -- Unmount DMG
            do shell script "hdiutil detach '" & mountPoint & "' -quiet"

            -- Clean up downloaded DMG
            do shell script "rm '" & dmgPath & "'"

            return "success"

        on error errorMessage
            -- Try to unmount DMG in case of error
            try
                do shell script "hdiutil detach '" & mountPoint & "' -quiet"
            end try

            error errorMessage
        end try
        """

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let script = NSAppleScript(source: mountScript)
                var error: NSDictionary?
                let _ = script?.executeAndReturnError(&error)

                DispatchQueue.main.async {
                    if let error = error {
                        let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                        print("❌ Installation failed: \(errorMessage)")
                        self.analytics.trackError("Installation failed", context: ["error": errorMessage, "version": version])
                        self.showErrorAlert(message: "Failed to install update: \(errorMessage)")
                    } else {
                        print("✅ Update installed successfully!")
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

    private func showDownloadProgressAlert(onCancel: @escaping (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Downloading Update..."
        alert.informativeText = "BangoCat is downloading the latest version. This may take a few minutes."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Cancel")

        downloadProgressAlert = alert

        DispatchQueue.main.async {
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                onCancel(true)
            }
        }
    }

    private func hideDownloadProgressAlert() {
        // The alert will be dismissed automatically when the download completes
        downloadProgressAlert = nil
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
        alert.messageText = "Update Failed"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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