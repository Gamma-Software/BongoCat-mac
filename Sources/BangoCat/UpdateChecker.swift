import Foundation
import UserNotifications
import AppKit

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let publishedAt: String
    let htmlUrl: String
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case draft
        case prerelease
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

    // Settings
    private var updateNotificationsEnabled: Bool = true
    private var skippedVersion: String?

    // Update checking
    private var dailyCheckTimer: Timer?
    private let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

    override init() {
        super.init()
        loadSettings()
    }

    // MARK: - Settings Management

    private func loadSettings() {
        updateNotificationsEnabled = UserDefaults.standard.object(forKey: updateNotificationsEnabledKey) == nil ? true : UserDefaults.standard.bool(forKey: updateNotificationsEnabledKey)
        skippedVersion = UserDefaults.standard.string(forKey: skipVersionKey)

        // Track configuration loading
        analytics.trackConfigurationLoaded("update_checker", success: true)

        print("🔄 Loaded update checker settings - notifications: \(updateNotificationsEnabled), skipped version: \(skippedVersion ?? "none")")
    }

    private func saveSettings() {
        UserDefaults.standard.set(updateNotificationsEnabled, forKey: updateNotificationsEnabledKey)
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

    func isUpdateNotificationsEnabled() -> Bool {
        return updateNotificationsEnabled
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
        let alert = NSAlert()
        alert.messageText = "🆕 BangoCat Update Available!"
        alert.informativeText = "Version \(release.tagName) is now available.\n\nCurrent version: \(getCurrentVersion())\nNew version: \(release.tagName.replacingOccurrences(of: "v", with: ""))\n\nWould you like to download it now?"
        alert.alertStyle = .informational

        alert.addButton(withTitle: "Download Now")
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Remind Me Later")

        let response = alert.runModal()

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
            break // Do nothing, will check again on next cycle
        default:
            analytics.trackNotificationDismissed("update")
            break
        }
    }

    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
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