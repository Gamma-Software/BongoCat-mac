import Foundation
import UserNotifications
import AppKit

class MilestoneNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MilestoneNotificationManager()

    // Milestone settings
    private var notificationsEnabled: Bool = true
    private let notificationsEnabledKey = "BangoCatMilestoneNotificationsEnabled"

    // Default milestone intervals
    private var milestoneIntervals: [Int] = [100, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000, 1000000, 10000000]
    private let milestoneIntervalsKey = "BangoCatMilestoneIntervals"

    // Track last notified milestones to avoid duplicates
    private var lastNotifiedKeystrokeMilestone: Int = 0
    private var lastNotifiedClickMilestone: Int = 0
    private var lastNotifiedTotalMilestone: Int = 0

    private let lastKeystrokeMilestoneKey = "BangoCatLastKeystrokeMilestone"
    private let lastClickMilestoneKey = "BangoCatLastClickMilestone"
    private let lastTotalMilestoneKey = "BangoCatLastTotalMilestone"

    // Track if notifications have been set up
    private var notificationsSetup: Bool = false

    // Analytics tracking
    private var analytics: PostHogAnalyticsManager {
        return PostHogAnalyticsManager.shared
    }

    override init() {
        super.init()
        loadSettings()
        // Don't setup notifications immediately - defer until needed
    }

    // MARK: - Setup and Permissions

            private func setupNotifications() {
        guard !notificationsSetup else { return }

        // Check if we can safely access UserNotifications
        guard canAccessNotifications() else {
            print("⚠️ UserNotifications not available - running in development mode, notifications disabled")
            notificationsEnabled = false
            return
        }

        // Try to safely access the notification center
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        notificationsSetup = true
        print("✅ Notifications setup completed")
    }

    private func canAccessNotifications() -> Bool {
        // Check if we have a proper bundle identifier
        guard let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty else {
            return false
        }

        // Check if we're running in an app context (not just a command line tool)
        guard NSRunningApplication.current.activationPolicy != .prohibited else {
            return false
        }

        return true
    }

    func requestNotificationPermission() {
        // Ensure notifications are setup first
        setupNotifications()

        guard notificationsSetup else {
            print("⚠️ Cannot request notification permission - setup failed")
            return
        }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                } else if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("⚠️ Notification permission denied")
                    self?.notificationsEnabled = false
                    self?.saveSettings()
                }
            }
        }
    }

    // MARK: - Settings Management

    private func loadSettings() {
        // Load notifications enabled preference
        if UserDefaults.standard.object(forKey: notificationsEnabledKey) != nil {
            notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
        }

        // Load custom milestone intervals if any
        if let savedIntervals = UserDefaults.standard.array(forKey: milestoneIntervalsKey) as? [Int] {
            milestoneIntervals = savedIntervals
        }

        // Load last notified milestones
        lastNotifiedKeystrokeMilestone = UserDefaults.standard.integer(forKey: lastKeystrokeMilestoneKey)
        lastNotifiedClickMilestone = UserDefaults.standard.integer(forKey: lastClickMilestoneKey)
        lastNotifiedTotalMilestone = UserDefaults.standard.integer(forKey: lastTotalMilestoneKey)

        print("🔔 Loaded milestone settings - enabled: \(notificationsEnabled), intervals: \(milestoneIntervals)")
    }

    private func saveSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: notificationsEnabledKey)
        UserDefaults.standard.set(milestoneIntervals, forKey: milestoneIntervalsKey)
        UserDefaults.standard.set(lastNotifiedKeystrokeMilestone, forKey: lastKeystrokeMilestoneKey)
        UserDefaults.standard.set(lastNotifiedClickMilestone, forKey: lastClickMilestoneKey)
        UserDefaults.standard.set(lastNotifiedTotalMilestone, forKey: lastTotalMilestoneKey)
    }

    // MARK: - Public Interface

    func setNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        saveSettings()
        print("🔔 Milestone notifications \(enabled ? "enabled" : "disabled")")
    }

    func isNotificationsEnabled() -> Bool {
        return notificationsEnabled
    }

    func setMilestoneIntervals(_ intervals: [Int]) {
        milestoneIntervals = intervals.sorted()
        saveSettings()
        print("🔔 Milestone intervals updated: \(milestoneIntervals)")
    }

    func getMilestoneIntervals() -> [Int] {
        return milestoneIntervals
    }

    // MARK: - Milestone Checking

    func checkKeystrokeMilestone(_ keystrokeCount: Int) {
        guard notificationsEnabled else { return }

        if let milestone = getNextMilestone(for: keystrokeCount, lastNotified: lastNotifiedKeystrokeMilestone) {
            lastNotifiedKeystrokeMilestone = milestone
            saveSettings()

            // Track milestone reached in analytics
            analytics.trackMilestoneReached(milestone, type: "keystrokes")

            sendMilestoneNotification(
                type: "Keystroke",
                count: milestone,
                icon: "⌨️",
                message: "You've typed \(formatCount(milestone)) keystrokes!"
            )
        }
    }

    func checkMouseClickMilestone(_ clickCount: Int) {
        guard notificationsEnabled else { return }

        if let milestone = getNextMilestone(for: clickCount, lastNotified: lastNotifiedClickMilestone) {
            lastNotifiedClickMilestone = milestone
            saveSettings()

            // Track milestone reached in analytics
            analytics.trackMilestoneReached(milestone, type: "mouse_clicks")

            sendMilestoneNotification(
                type: "Mouse Click",
                count: milestone,
                icon: "🖱️",
                message: "You've made \(formatCount(milestone)) mouse clicks!"
            )
        }
    }

    func checkTotalStrokeMilestone(_ totalCount: Int) {
        guard notificationsEnabled else { return }

        if let milestone = getNextMilestone(for: totalCount, lastNotified: lastNotifiedTotalMilestone) {
            lastNotifiedTotalMilestone = milestone
            saveSettings()

            // Track milestone reached in analytics
            analytics.trackMilestoneReached(milestone, type: "total_activity")

            sendMilestoneNotification(
                type: "Total Activity",
                count: milestone,
                icon: "🎯",
                message: "Amazing! You've reached \(formatCount(milestone)) total actions!"
            )
        }
    }

    // MARK: - Helper Methods

    private func getNextMilestone(for count: Int, lastNotified: Int) -> Int? {
        // Find the next milestone that should be notified
        for milestone in milestoneIntervals {
            if count >= milestone && milestone > lastNotified {
                return milestone
            }
        }
        return nil
    }

    private func formatCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    private func sendMilestoneNotification(type: String, count: Int, icon: String, message: String) {
        // Ensure notifications are setup first
        setupNotifications()

        guard notificationsSetup else {
            print("⚠️ Cannot send notification - setup failed")
            return
        }

        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "\(icon) BangoCat Milestone!"
        content.body = message
        content.sound = .default

        // Add custom data for potential future use
        content.userInfo = [
            "type": type,
            "count": count,
            "milestone": true
        ]

        // Create request with unique identifier
        let identifier = "milestone-\(type.lowercased().replacingOccurrences(of: " ", with: "-"))-\(count)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        center.add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to send milestone notification: \(error.localizedDescription)")
                } else {
                    print("🔔 Milestone notification sent: \(type) - \(count)")
                }
            }
        }
    }

    // MARK: - Reset Methods

    func resetMilestoneTracking() {
        lastNotifiedKeystrokeMilestone = 0
        lastNotifiedClickMilestone = 0
        lastNotifiedTotalMilestone = 0
        saveSettings()
        print("🔔 Milestone tracking reset")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap if needed
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notifications even when app is active
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}