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

    // MARK: - Input & Animation Events

    func trackTrackpadGestureDetected(_ gestureType: String) {
        track(event: "trackpad_gesture_detected", properties: [
            "gesture_type": gestureType
        ])
    }

    // MARK: - Window & UI Events

    func trackWindowPositionChanged(_ position: String, method: String) {
        track(event: "window_position_changed", properties: [
            "position": position,
            "method": method // "manual_drag", "corner_menu", "keyboard_shortcut", "per_app_restore"
        ])
    }

    func trackContextMenuUsed(_ menuType: String, action: String) {
        track(event: "context_menu_used", properties: [
            "menu_type": menuType, // "right_click", "status_bar"
            "action": action
        ])
    }

    func trackVisibilityToggled(_ visible: Bool, method: String) {
        track(event: "visibility_toggled", properties: [
            "visible": visible,
            "method": method // "status_bar", "keyboard_shortcut", "context_menu"
        ])
    }

    // MARK: - Per-App Feature Events

    func trackPerAppPositioningToggled(_ enabled: Bool) {
        track(event: "per_app_positioning_toggled", properties: [
            "enabled": enabled
        ])
    }

    func trackPerAppHidingToggled(_ enabled: Bool) {
        track(event: "per_app_hiding_toggled", properties: [
            "enabled": enabled
        ])
    }

    func trackPerAppPositionSaved(_ appBundleID: String, totalAppsWithPositions: Int) {
        track(event: "per_app_position_saved", properties: [
            "app_bundle_id": appBundleID.replacingOccurrences(of: ".", with: "_"),
            "total_apps_with_positions": totalAppsWithPositions
        ])
    }

    func trackAppHiddenStatusChanged(_ appBundleID: String, hidden: Bool) {
        track(event: "app_hidden_status_changed", properties: [
            "app_bundle_id": appBundleID.replacingOccurrences(of: ".", with: "_"),
            "hidden": hidden
        ])
    }

    // MARK: - Session & Lifecycle Events

    func trackSessionDuration(_ duration: TimeInterval) {
        track(event: "session_ended", properties: [
            "duration_seconds": duration,
            "duration_minutes": duration / 60
        ])
    }

    func trackAppBecameActive() {
        track(event: "app_became_active")
    }

    func trackAppBecameInactive() {
        track(event: "app_became_inactive")
    }

    func trackSystemWakeDetected() {
        track(event: "system_wake_detected")
    }

    func trackSystemSleepDetected() {
        track(event: "system_sleep_detected")
    }

    // MARK: - Accessibility & Permissions Events

    func trackAccessibilityPermissionRequested() {
        track(event: "accessibility_permission_requested")
    }

    func trackAccessibilityPermissionGranted() {
        track(event: "accessibility_permission_granted")
    }

    func trackAccessibilityPermissionDenied() {
        track(event: "accessibility_permission_denied")
    }

    func trackNotificationPermissionRequested() {
        track(event: "notification_permission_requested")
    }

    func trackNotificationPermissionResult(_ granted: Bool) {
        track(event: "notification_permission_result", properties: [
            "granted": granted
        ])
    }

    // MARK: - Feature Discovery & Usage Events

    func trackFeatureDiscovered(_ featureName: String, discoveryMethod: String) {
        track(event: "feature_discovered", properties: [
            "feature_name": featureName,
            "discovery_method": discoveryMethod // "menu", "context_menu", "notification", "accidental"
        ])
    }

    func trackFirstTimeFeatureUsed(_ featureName: String) {
        track(event: "first_time_feature_used", properties: [
            "feature_name": featureName
        ])
    }

    func trackShortcutUsed(_ shortcut: String, action: String) {
        track(event: "shortcut_used", properties: [
            "shortcut": shortcut,
            "action": action
        ])
    }

    func trackImageLoadError(_ imageName: String, method: String) {
        track(event: "image_load_error", properties: [
            "image_name": imageName,
            "load_method": method
        ])
    }

    // MARK: - User Engagement Events

    func trackSocialShareInitiated(_ platform: String) {
        track(event: "social_share_initiated", properties: [
            "platform": platform // "twitter", "coffee_donation"
        ])
    }

    func trackSupportActionTaken(_ action: String) {
        track(event: "support_action_taken", properties: [
            "action": action // "bug_report", "website_visit", "changelog_view"
        ])
    }

    func trackSettingsExplored(_ settingsAccessed: [String], timeSpent: TimeInterval) {
        track(event: "settings_explored", properties: [
            "settings_accessed": settingsAccessed,
            "time_spent_seconds": timeSpent,
            "settings_count": settingsAccessed.count
        ])
    }

    func trackUserOnboardingCompleted(_ stepsCompleted: [String]) {
        track(event: "user_onboarding_completed", properties: [
            "steps_completed": stepsCompleted,
            "completion_rate": Double(stepsCompleted.count) / 5.0 // Assuming 5 onboarding steps
        ])
    }

    // MARK: - Update & Maintenance Events

    func trackUpdateCheckStarted(_ isManual: Bool) {
        track(event: "update_check_started", properties: [
            "is_manual": isManual
        ])
    }

    func trackUpdateCheckCompleted(_ updateAvailable: Bool, currentVersion: String, latestVersion: String?) {
        var properties: [String: Any] = [
            "update_available": updateAvailable,
            "current_version": currentVersion
        ]
        if let latestVersion = latestVersion {
            properties["latest_version"] = latestVersion
        }
        track(event: "update_check_completed", properties: properties)
    }

    func trackUpdateActionTaken(_ action: String, version: String) {
        track(event: "update_action_taken", properties: [
            "action": action, // "download", "skip", "later"
            "version": version
        ])
    }

    func trackFactoryResetPerformed() {
        track(event: "factory_reset_performed", properties: [
            "reset_timestamp": Date().timeIntervalSince1970
        ])
    }

    // MARK: - Notification Interaction Events

    func trackNotificationShown(_ notificationType: String, milestone: Int? = nil) {
        var properties: [String: Any] = [
            "notification_type": notificationType // "milestone", "update", "error"
        ]
        if let milestone = milestone {
            properties["milestone"] = milestone
        }
        track(event: "notification_shown", properties: properties)
    }

    func trackNotificationClicked(_ notificationType: String, action: String) {
        track(event: "notification_clicked", properties: [
            "notification_type": notificationType,
            "action": action
        ])
    }

    func trackNotificationDismissed(_ notificationType: String) {
        track(event: "notification_dismissed", properties: [
            "notification_type": notificationType
        ])
    }

    // MARK: - Performance & System Events

    func trackPerformanceMetrics(_ animationFrameRate: Double, memoryUsage: Double) {
        track(event: "performance_metrics", properties: [
            "animation_frame_rate": animationFrameRate,
            "memory_usage_mb": memoryUsage
        ])
    }

    func trackResourceLoadTime(_ resourceType: String, loadTime: TimeInterval) {
        track(event: "resource_load_time", properties: [
            "resource_type": resourceType, // "image", "setting", "position"
            "load_time_ms": loadTime * 1000
        ])
    }

    func trackConfigurationLoaded(_ configurationType: String, success: Bool) {
        track(event: "configuration_loaded", properties: [
            "configuration_type": configurationType, // "analytics", "settings", "positions"
            "success": success
        ])
    }

    // MARK: - Usage Pattern Events

    func trackUsagePattern(_ sessionDuration: TimeInterval, inputCount: Int, settingsChanged: Int, featuresUsed: [String]) {
        track(event: "usage_pattern", properties: [
            "session_duration_minutes": sessionDuration / 60,
            "input_count": inputCount,
            "settings_changed": settingsChanged,
            "features_used": featuresUsed,
            "features_used_count": featuresUsed.count
        ])
    }

    func trackSettingsCombination(_ settings: [String: Any]) {
        track(event: "settings_combination", properties: settings)
    }

    func trackAdvancedFeatureUsage(_ featureName: String, complexity: String, success: Bool) {
        track(event: "advanced_feature_usage", properties: [
            "feature_name": featureName,
            "complexity": complexity, // "basic", "intermediate", "advanced"
            "success": success
        ])
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
        // App Lifecycle
        static let appLaunched = "app_launched"
        static let appTerminated = "app_terminated"
        static let sessionEnded = "session_ended"
        static let appBecameActive = "app_became_active"
        static let appBecameInactive = "app_became_inactive"
        static let systemWakeDetected = "system_wake_detected"
        static let systemSleepDetected = "system_sleep_detected"

        // Settings & Customization
        static let scaleChanged = "scale_changed"
        static let settingToggled = "setting_toggled"
        static let pawBehaviorChanged = "paw_behavior_changed"
        static let positionChanged = "position_changed"
        static let strokeCounterReset = "stroke_counter_reset"
        static let factoryResetPerformed = "factory_reset_performed"
        static let settingsCombination = "settings_combination"

        // Input & Animation
        static let trackpadGestureDetected = "trackpad_gesture_detected"

        // Window & UI Management
        static let windowPositionChanged = "window_position_changed"
        static let contextMenuUsed = "context_menu_used"
        static let visibilityToggled = "visibility_toggled"

        // Per-App Features
        static let perAppPositioningToggled = "per_app_positioning_toggled"
        static let perAppHidingToggled = "per_app_hiding_toggled"
        static let perAppPositionSaved = "per_app_position_saved"
        static let appHiddenStatusChanged = "app_hidden_status_changed"

        // Milestones & Achievements
        static let milestoneReached = "milestone_reached"

        // Menu & Navigation
        static let menuAction = "menu_action"

        // Permissions & Accessibility
        static let accessibilityPermissionRequested = "accessibility_permission_requested"
        static let accessibilityPermissionGranted = "accessibility_permission_granted"
        static let accessibilityPermissionDenied = "accessibility_permission_denied"
        static let notificationPermissionRequested = "notification_permission_requested"
        static let notificationPermissionResult = "notification_permission_result"

        // Feature Discovery & Usage
        static let featureDiscovered = "feature_discovered"
        static let firstTimeFeatureUsed = "first_time_feature_used"
        static let shortcutUsed = "shortcut_used"
        static let advancedFeatureUsage = "advanced_feature_usage"

        // User Engagement
        static let socialShareInitiated = "social_share_initiated"
        static let supportActionTaken = "support_action_taken"
        static let settingsExplored = "settings_explored"
        static let userOnboardingCompleted = "user_onboarding_completed"

        // Updates & Maintenance
        static let updateCheckStarted = "update_check_started"
        static let updateCheckCompleted = "update_check_completed"
        static let updateActionTaken = "update_action_taken"

        // Notifications
        static let notificationShown = "notification_shown"
        static let notificationClicked = "notification_clicked"
        static let notificationDismissed = "notification_dismissed"

        // Performance & System
        static let performanceMetrics = "performance_metrics"
        static let resourceLoadTime = "resource_load_time"
        static let configurationLoaded = "configuration_loaded"
        static let usagePattern = "usage_pattern"

        // Errors & Issues
        static let errorOccurred = "error_occurred"
        static let imageLoadError = "image_load_error"
    }
}