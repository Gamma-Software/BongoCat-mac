import Foundation
import PostHog

/**
 * PostHog Analytics Manager for BangoCat
 *
 * Setup Instructions:
 * 1. Create a PostHog account at https://posthog.com
 * 2. Create a new project and get your API key
 * 3. Configure your credentials (choose one method):
 *
 *    Option A - Environment Variables (Recommended):
 *    export POSTHOG_API_KEY="ph_your_key_here"
 *    export POSTHOG_HOST="https://us.i.posthog.com"
 *
 *    Option B - Local Config File:
 *    cp analytics-config.plist.template analytics-config.plist
 *    # Edit analytics-config.plist with your keys
 *
 *    Option C - Info.plist (Not recommended for public repos):
 *    Update POSTHOG_API_KEY and POSTHOG_HOST in Info.plist
 *
 * Privacy:
 * - All tracking is anonymous by default
 * - Users can opt-out via the menu
 * - No personal information is collected
 * - Only feature usage and app behavior is tracked
 */
class PostHogAnalyticsManager: ObservableObject {
    static let shared = PostHogAnalyticsManager()

    // Privacy settings
    @Published private(set) var isAnalyticsEnabled: Bool = true
    private let analyticsEnabledKey = "BangoCatAnalyticsEnabled"

    // Configuration
    private let apiKey: String
    private let host: String
    private var isConfigured: Bool = false

    private init() {
        // Try multiple configuration sources in order of preference
        if let config = Self.loadConfiguration() {
            self.apiKey = config.apiKey
            self.host = config.host
            self.isConfigured = true
            print("✅ PostHog configured from \(config.source)")
        } else {
            // Fallback to placeholder values
            self.apiKey = "ph_development_key_not_configured"
            self.host = "https://eu.i.posthog.com"
            self.isConfigured = false
            print("⚠️ PostHog not configured. See README for setup instructions.")
        }

        loadAnalyticsPreference()
        if isConfigured {
            setupPostHog()
        }
    }

    private static func loadConfiguration() -> (apiKey: String, host: String, source: String)? {
        // 1. Try environment variables (preferred for CI/CD and local development)
        if let envApiKey = ProcessInfo.processInfo.environment["POSTHOG_API_KEY"],
           !envApiKey.isEmpty && envApiKey != "YOUR_POSTHOG_API_KEY" {
            let envHost = ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "https://us.i.posthog.com"
            return (apiKey: envApiKey, host: envHost, source: "environment variables")
        }

        // 2. Try local analytics-config.plist file (gitignored)
        if let configPath = Bundle.main.path(forResource: "analytics-config", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath),
           let configApiKey = configDict["POSTHOG_API_KEY"] as? String,
           !configApiKey.isEmpty && configApiKey != "YOUR_POSTHOG_API_KEY" {
            let configHost = configDict["POSTHOG_HOST"] as? String ?? "https://us.i.posthog.com"
            return (apiKey: configApiKey, host: configHost, source: "analytics-config.plist")
        }

        // 3. Try Info.plist (last resort, not recommended for public repos)
        if let plistApiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String,
           !plistApiKey.isEmpty && plistApiKey != "YOUR_POSTHOG_API_KEY" {
            let plistHost = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_HOST") as? String ?? "https://us.i.posthog.com"
            return (apiKey: plistApiKey, host: plistHost, source: "Info.plist")
        }

        return nil
    }

    private func setupPostHog() {
        // Check if we're running in a proper bundle context
        guard Bundle.main.bundleIdentifier != nil else {
            print("⚠️ PostHog not initialized - no bundle identifier (running via swift run?)")
            print("   Analytics will be disabled for this session")
            print("   Use 'swift build && open .build/debug/BangoCat.app' for proper testing")

            // Disable PostHog for this session since we can't initialize it safely
            isConfigured = false
            return
        }

        let config = PostHogConfig(apiKey: apiKey, host: host)

        // Configure privacy settings
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false // We'll manually track relevant screens
        config.debug = false // Set to true for development
        config.optOut = !isAnalyticsEnabled

        PostHogSDK.shared.setup(config)

        print("PostHog initialized with analytics enabled: \(isAnalyticsEnabled)")
    }

    // MARK: - Privacy Controls

    private func loadAnalyticsPreference() {
        if UserDefaults.standard.object(forKey: analyticsEnabledKey) != nil {
            isAnalyticsEnabled = UserDefaults.standard.bool(forKey: analyticsEnabledKey)
        } else {
            isAnalyticsEnabled = true // Default enabled, but user can opt out
        }
    }

    private func saveAnalyticsPreference() {
        UserDefaults.standard.set(isAnalyticsEnabled, forKey: analyticsEnabledKey)
    }

    func setAnalyticsEnabled(_ enabled: Bool) {
        isAnalyticsEnabled = enabled
        saveAnalyticsPreference()

        if enabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }

        print("Analytics \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Event Tracking

    func track(event: String, properties: [String: Any] = [:]) {
        guard isAnalyticsEnabled && isConfigured else {
            if !isConfigured {
                print("📊 Analytics not configured, would track: \(event)")
            }
            return
        }

        var eventProperties = properties
        eventProperties["app_version"] = getAppVersion()
        eventProperties["platform"] = "macOS"

        PostHogSDK.shared.capture(event, properties: eventProperties)
        print("📊 Tracked event: \(event) with properties: \(eventProperties)")
    }

    func identify(userId: String? = nil, userProperties: [String: Any] = [:]) {
        guard isAnalyticsEnabled && isConfigured else { return }

        if let userId = userId {
            PostHogSDK.shared.identify(userId, userProperties: userProperties)
        } else {
            // Use a consistent anonymous ID based on device
            let deviceId = getDeviceId()
            PostHogSDK.shared.identify(deviceId, userProperties: userProperties)
        }
    }

    func reset() {
        PostHogSDK.shared.reset()
        print("PostHog analytics reset")
    }

    // MARK: - App Lifecycle Events

    func trackAppLaunch() {
        track(event: "app_launched", properties: [
            "launch_count": incrementLaunchCount()
        ])
    }

    func trackAppTerminate() {
        track(event: "app_terminated")
        PostHogSDK.shared.flush() // Ensure events are sent before app closes
    }

    // MARK: - Feature Usage Events

    func trackScaleChanged(_ scale: Double) {
        track(event: "scale_changed", properties: [
            "scale": scale
        ])
    }

    func trackSettingToggled(_ settingName: String, enabled: Bool) {
        track(event: "setting_toggled", properties: [
            "setting_name": settingName,
            "enabled": enabled
        ])
    }

    func trackPawBehaviorChanged(_ behavior: String) {
        track(event: "paw_behavior_changed", properties: [
            "behavior": behavior
        ])
    }

    func trackPositionChanged(_ position: String) {
        track(event: "position_changed", properties: [
            "position": position
        ])
    }

    func trackStrokeCounterReset() {
        track(event: "stroke_counter_reset")
    }

    func trackMilestoneReached(_ milestone: Int, type: String) {
        track(event: "milestone_reached", properties: [
            "milestone": milestone,
            "type": type
        ])
    }

    func trackMenuAction(_ action: String) {
        track(event: "menu_action", properties: [
            "action": action
        ])
    }

    func trackError(_ error: String, context: [String: Any] = [:]) {
        var errorProperties = context
        errorProperties["error"] = error
        errorProperties["timestamp"] = Date().timeIntervalSince1970

        track(event: "error_occurred", properties: errorProperties)
    }

    // MARK: - Helper Functions

    private func getAppVersion() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(version).\(build)"
        }
        return "unknown"
    }

    private func getDeviceId() -> String {
        // Create a consistent device identifier
        if let identifier = UserDefaults.standard.string(forKey: "BangoCatDeviceId") {
            return identifier
        }

        let newIdentifier = UUID().uuidString
        UserDefaults.standard.set(newIdentifier, forKey: "BangoCatDeviceId")
        return newIdentifier
    }

    private func incrementLaunchCount() -> Int {
        let currentCount = UserDefaults.standard.integer(forKey: "BangoCatLaunchCount")
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: "BangoCatLaunchCount")
        return newCount
    }

    // MARK: - Testing and Debug

    func isConfiguredForAnalytics() -> Bool {
        return isConfigured
    }

    func getConfigurationStatus() -> String {
        if isConfigured {
            return "✅ PostHog configured with API key: \(String(apiKey.prefix(8)))..."
        } else {
            return """
            ⚠️ PostHog not configured. Choose a setup method:

            1. Environment variables:
               export POSTHOG_API_KEY="ph_your_key"
               export POSTHOG_HOST="https://us.i.posthog.com"

            2. Create analytics-config.plist from template

            3. Update Info.plist (not recommended for public repos)
            """
        }
    }

    func testAnalytics() {
        track(event: "test_analytics", properties: [
            "test": true,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}

// MARK: - Event Names Constants
extension PostHogAnalyticsManager {
    struct Events {
        static let appLaunched = "app_launched"
        static let appTerminated = "app_terminated"
        static let scaleChanged = "scale_changed"
        static let settingToggled = "setting_toggled"
        static let pawBehaviorChanged = "paw_behavior_changed"
        static let positionChanged = "position_changed"
        static let strokeCounterReset = "stroke_counter_reset"
        static let milestoneReached = "milestone_reached"
        static let menuAction = "menu_action"
        static let errorOccurred = "error_occurred"
    }
}