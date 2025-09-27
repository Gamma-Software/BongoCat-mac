import Cocoa
import SwiftUI
import UserNotifications
import ServiceManagement

enum CornerPosition: String, CaseIterable {
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case custom = "Custom"

    var displayName: String {
        return self.rawValue
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, ObservableObject {
    var overlayWindow: OverlayWindow?
    var inputMonitor: InputMonitor?
    var statusBarItem: NSStatusItem?
    var preferencesWindowController: PreferencesWindowController?
    var welcomeScreenController: WelcomeScreenController?

    // App information
    private let appVersion = "1.8.3"
    private let appBuild = "1.8.3.202508071405"
    private let appAuthor = "Valentin Rudloff"
    private let appWebsite = "https://valentin.pival.fr"

    // Scale management
    @Published var currentScale: Double = 0.75  // Default to Medium (75%)
    private let scaleKey = "BongoCatScale"

    // Scale pulse on input management
    @Published var scaleOnInputEnabled: Bool = true
    private let scaleOnInputKey = "BongoCatScaleOnInput"

    // Rotation management
    @Published var currentRotation: Double = 0.0
    private let rotationKey = "BongoCatRotation"

    // Horizontal flip management
    @Published var isFlippedHorizontally: Bool = false
    private let flipKey = "BongoCatFlipHorizontally"

    // Ignore clicks management
    @Published var ignoreClicksEnabled: Bool = false
    private let ignoreClicksKey = "BongoCatIgnoreClicks"

    // Click through management
    @Published var clickThroughEnabled: Bool = true  // Default enabled
    private let clickThroughKey = "BongoCatClickThrough"

    // Paw behavior management
    @Published var pawBehaviorMode: PawBehaviorMode = .random  // Default to random
    private let pawBehaviorKey = "BongoCatPawBehavior"

    // Auto-start at launch management
    @Published var autoStartAtLaunchEnabled: Bool = true  // Default enabled
    private let autoStartAtLaunchKey = "BongoCatAutoStartAtLaunch"

    // Position management - Enhanced for per-app positioning
    private var snapToCornerEnabled: Bool = false
    private let snapToCornerKey = "BongoCatSnapToCorner"
    private var savedPosition: NSPoint = NSPoint(x: 100, y: 100)
    private let savedPositionXKey = "BongoCatPositionX"
    private let savedPositionYKey = "BongoCatPositionY"
    @Published var currentCornerPosition: CornerPosition = .custom
    private let cornerPositionKey = "BongoCatCornerPosition"

    // Per-app position management
    @Published internal var perAppPositions: [String: NSPoint] = [:]
    private let perAppPositionsKey = "BongoCatPerAppPositions"
    internal var currentActiveApp: String = ""
    private var appSwitchTimer: Timer?
    private var appSwitchTimerInterval: TimeInterval = 0.1
    @Published internal var isPerAppPositioningEnabled: Bool = true  // Default enabled
    private let perAppPositioningKey = "BongoCatPerAppPositioning"

    // Per-app hiding management
    @Published internal var perAppHiddenApps: Set<String> = []
    private let perAppHiddenAppsKey = "BongoCatPerAppHiddenApps"
    @Published internal var isPerAppHidingEnabled: Bool = true  // Default enabled
    private let perAppHidingKey = "BongoCatPerAppHiding"

    // Milestone notifications management
    @Published internal var milestoneManager = MilestoneNotificationManager.shared

    // Update checking management
    @Published internal var updateChecker = UpdateChecker.shared

    // Analytics management
    internal let analytics = PostHogAnalyticsManager.shared

    // Force SwiftUI updates when settings change
    @Published private var settingsUpdateTrigger: Bool = false

    // Session tracking
    private var appLaunchTime = Date()
    private var settingsChangedThisSession: [String] = []
    private var featuresUsedThisSession: [String] = []

    // MARK: - SwiftUI Update Trigger

    internal func triggerSettingsUpdate() {
        settingsUpdateTrigger.toggle()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("BongoCat starting...")
        appLaunchTime = Date()

        // Track app lifecycle
        analytics.trackConfigurationLoaded("settings", success: true)

        loadSavedScale()
        loadScaleOnInputPreference()
        loadSavedRotation()
        loadSavedFlip()
        loadIgnoreClicksPreference()
        loadClickThroughPreference()
        loadPawBehaviorPreference()
        loadAutoStartAtLaunchPreference()
        loadPositionPreferences()
        loadPerAppPositioning()
        loadPerAppHiding()
        setupStatusBarItem()
        setupOverlayWindow()
        setupInputMonitoring()
        setupAppSwitchMonitoring()
        requestAccessibilityPermissions()

        // Initialize analytics and track app launch
        analytics.trackAppLaunch()

        // Request notification permissions for milestone notifications after a delay
        // This ensures the app is fully initialized before accessing UserNotifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.milestoneManager.requestNotificationPermission()
        }

        // Start daily update checks after a delay to ensure app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.updateChecker.startDailyUpdateChecks()
        }

        // Sync auto-start state with system
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.syncAutoStartState()
        }

        // Track initial settings combination
        trackCurrentSettingsCombination()

        // Set up app lifecycle notifications
        setupAppLifecycleNotifications()

        // Show welcome screen if needed (first launch)
        showWelcomeScreenIfNeeded()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        inputMonitor?.stop()
        appSwitchTimer?.invalidate()
        savePerAppPositioning()
        savePerAppHiding()

        // Track session duration and usage patterns
        let sessionDuration = Date().timeIntervalSince(appLaunchTime)
        analytics.trackSessionDuration(sessionDuration)

        // Track usage pattern for this session
        if let inputController = overlayWindow?.catAnimationController {
            let totalInputs = inputController.strokeCounter.totalStrokes
            analytics.trackUsagePattern(sessionDuration,
                                      inputCount: totalInputs,
                                      settingsChanged: settingsChangedThisSession.count,
                                      featuresUsed: featuresUsedThisSession)
        }

        // Track app termination
        analytics.trackAppTerminate()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            overlayWindow?.showWindow()
            analytics.trackVisibilityToggled(true, method: "dock_click")
        }
        return true
    }

    private func setupStatusBarItem() {
        print("🔧 Setting up status bar item...")
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("🔧 Status bar item created: \(statusBarItem != nil)")

        if let button = statusBarItem?.button {
            // Try to load the menu-logo.png file
            if let iconImage = loadStatusBarIcon() {
                button.image = iconImage
                button.imagePosition = .imageOnly
                print("🔧 Status bar icon loaded from menu-logo.png")
            } else {
                // Fallback to emoji if icon loading fails
                button.title = "🐱"
                print("🔧 Fallback to emoji icon")
            }

            button.toolTip = "BongoCat - Click for menu"
            print("🔧 Status bar button configured")
        } else {
            print("❌ Failed to get status bar button")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Welcome Guide 🎯", action: #selector(showWelcomeGuide), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Stroke counter section
        let strokeCounterItem = NSMenuItem(title: "Loading stroke count...", action: nil, keyEquivalent: "")
        strokeCounterItem.tag = 999 // Special tag to identify this item for updates
        menu.addItem(strokeCounterItem)
        menu.addItem(NSMenuItem(title: "Reset Stroke Counter", action: #selector(resetStrokeCounter), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Buy me a coffee ☕", action: #selector(buyMeACoffee), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Tweet about BongoCat 🐦", action: #selector(tweetAboutBongoCat), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for Updates 🔄", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Auto-Start at Launch 🚀", action: #selector(toggleAutoStartAtLaunch), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About BongoCat", action: #selector(showCredits), keyEquivalent: ""))

        // Developer options (only show if analytics debug is needed)
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "🔧 Analytics Status", action: #selector(showAnalyticsStatus), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🧪 Test Analytics", action: #selector(testAnalytics), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🔍 Debug Update System", action: #selector(debugUpdateSystem), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "📥 Test Download", action: #selector(testDownloadFunctionality), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🔄 Reset Welcome Screen", action: #selector(resetWelcomeScreen), keyEquivalent: ""))
        #endif

        // Version info
        let versionItem = NSMenuItem(title: "Version \(getVersionString())", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false // Make it non-clickable
        menu.addItem(versionItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BongoCat", action: #selector(quitApp), keyEquivalent: "q"))

        // Set targets for menu items
        menu.items.forEach { item in
            item.target = self
            item.submenu?.items.forEach { subItem in
                subItem.target = self
            }
        }

        statusBarItem?.menu = menu
        menu.delegate = self  // Set delegate to update stroke counter when menu opens
        print("🔧 Menu attached to status bar item")

        // Update stroke counter after a short delay to ensure overlay window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStrokeCounterMenuItem()
        }

        // Update auto-start menu item state
        updateAutoStartAtLaunchMenuItem()

        print("🔧 Status bar setup complete")
    }

    /// Loads the status bar icon, searching in the app bundle's Resources directory first,
    /// then falling back to other locations for development and CLI scenarios.
    private func loadStatusBarIcon() -> NSImage? {
        print("🔍 Attempting to load status bar icon: menu-logo.png")

        // 1. Try Bundle.main.resourceURL (the correct way for packaged macOS apps)
        if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("menu-logo.png") {
            print("🔎 Checking Bundle.main.resourceURL: \(resourceURL.path)")
            if let image = NSImage(contentsOf: resourceURL) {
                print("✅ Loaded status bar icon from Bundle.main.resourceURL: \(resourceURL.path)")
                return resizeIconForStatusBar(image, fromPath: "Bundle.main.resourceURL: \(resourceURL.path)")
            }
        } else {
            print("⚠️  Bundle.main.resourceURL is nil")
        }

        // 2. Try Bundle.main.path(forResource:) (legacy, but sometimes works)
        if let bundlePath = Bundle.main.path(forResource: "menu-logo", ofType: "png") {
            print("🔎 Checking Bundle.main.path: \(bundlePath)")
            if let bundleImage = NSImage(contentsOfFile: bundlePath) {
                print("✅ Loaded status bar icon from Bundle.main.path: \(bundlePath)")
                return resizeIconForStatusBar(bundleImage, fromPath: "Bundle.main.path: \(bundlePath)")
            }
        } else {
            print("⚠️  Bundle.main.path(forResource:) returned nil")
        }

        // 3. Try NSImage(named:) (works if image is in asset catalog or registered in bundle)
        print("🔎 Checking NSImage(named: menu-logo)")
        if let bundleImage = NSImage(named: "menu-logo") {
            print("✅ Loaded status bar icon from NSImage(named: menu-logo)")
            return resizeIconForStatusBar(bundleImage, fromPath: "NSImage(named: menu-logo)")
        }

        // 4. Try in-place next to executable (for CLI/dev scenarios)
        if let executablePath = Bundle.main.executablePath {
            let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
            let possiblePaths = [
                executableDir.appendingPathComponent("menu-logo.png"),
                executableDir.appendingPathComponent("Resources/menu-logo.png"),
                executableDir.appendingPathComponent("Sources/BongoCat/Resources/menu-logo.png")
            ]
            for path in possiblePaths {
                print("🔎 Checking executable directory: \(path.path)")
                if let image = NSImage(contentsOf: path) {
                    print("✅ Loaded status bar icon from executable directory: \(path.path)")
                    return resizeIconForStatusBar(image, fromPath: "executable directory: \(path.path)")
                }
            }
        } else {
            print("⚠️  Bundle.main.executablePath is nil")
        }

        // 5. Try current working directory (for CLI/dev scenarios)
        let currentDir = FileManager.default.currentDirectoryPath
        let cwdPaths = [
            "\(currentDir)/menu-logo.png",
            "\(currentDir)/Resources/menu-logo.png",
            "\(currentDir)/Sources/BongoCat/Resources/menu-logo.png"
        ]
        for path in cwdPaths {
            print("🔎 Checking current directory: \(path)")
            if let image = NSImage(contentsOfFile: path) {
                print("✅ Loaded status bar icon from current directory: \(path)")
                return resizeIconForStatusBar(image, fromPath: "current directory: \(path)")
            }
        }

        // 6. Try relative paths (last resort)
        let relativePaths = [
            "menu-logo.png",
            "./menu-logo.png",
            "Resources/menu-logo.png",
            "Sources/BongoCat/Resources/menu-logo.png"
        ]
        for path in relativePaths {
            print("🔎 Checking relative path: \(path)")
            if let image = NSImage(contentsOfFile: path) {
                print("✅ Loaded status bar icon from relative path: \(path)")
                return resizeIconForStatusBar(image, fromPath: "relative path: \(path)")
            }
        }

        // 7. (Optional) Try loading from a resource bundle if present (for SPM plugin/dev)
        let allBundles = Bundle.allBundles
        if !allBundles.isEmpty {
            for bundle in allBundles {
                print("🔎 Checking bundle: \(bundle.bundlePath)")
                if let url = bundle.url(forResource: "menu-logo", withExtension: "png") {
                    print("🔎 Checking bundle resource: \(url.path)")
                    if let image = NSImage(contentsOf: url) {
                        print("✅ Loaded status bar icon from bundle: \(bundle.bundlePath)")
                        return resizeIconForStatusBar(image, fromPath: "Bundle: \(bundle.bundlePath)")
                    }
                }
            }
        } else {
            print("⚠️  No additional bundles found in Bundle.allBundles")
        }

        print("❌ Failed to load menu-logo.png from all attempted methods")
        print("🔍 Debug info:")
        print("  - Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
        print("  - Bundle.main.resourceURL: \(Bundle.main.resourceURL?.path ?? "nil")")
        print("  - Bundle.main.executablePath: \(Bundle.main.executablePath ?? "nil")")
        print("  - Current working directory: \(FileManager.default.currentDirectoryPath)")
        return nil
    }

    private func resizeIconForStatusBar(_ originalImage: NSImage, fromPath: String) -> NSImage {
        let statusBarSize = NSSize(width: 18, height: 18)
        let resizedImage = NSImage(size: statusBarSize)

        resizedImage.lockFocus()

        // Use high quality scaling
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high

        // Draw the image preserving alpha channel
        originalImage.draw(in: NSRect(origin: .zero, size: statusBarSize),
                          from: NSRect(origin: .zero, size: originalImage.size),
                          operation: .sourceOver,
                          fraction: 1.0)

        resizedImage.unlockFocus()

        // Don't set as template - let it keep its colors and transparency
        // resizedImage.isTemplate = false  // This is the default

        print("✅ Loaded and resized status bar icon from: \(fromPath)")
        return resizedImage
    }

    private func setupOverlayWindow() {
        overlayWindow = OverlayWindow()
        overlayWindow?.appDelegate = self // Set reference for position saving
        overlayWindow?.updateAppDelegate() // Ensure the CatAnimationController has the appDelegate reference
        overlayWindow?.showWindow()
        overlayWindow?.updateScale(currentScale)  // Apply the loaded scale
        overlayWindow?.updateRotation(currentRotation)  // Apply the loaded rotation
        overlayWindow?.updateFlip(isFlippedHorizontally)  // Apply the loaded flip
        overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)  // Apply pulse preference
        overlayWindow?.catAnimationController?.setIgnoreClicksEnabled(ignoreClicksEnabled)  // Apply ignore clicks preference
        overlayWindow?.catAnimationController?.setPawBehaviorMode(pawBehaviorMode)  // Apply paw behavior preference
        overlayWindow?.updateIgnoreMouseEvents(clickThroughEnabled)  // Apply click through preference

        // Apply saved position
        overlayWindow?.setPositionProgrammatically(savedPosition)

        print("Overlay window created")
    }

    private func setupInputMonitoring() {
        inputMonitor = InputMonitor { [weak self] inputType in
            DispatchQueue.main.async {
                self?.overlayWindow?.catAnimationController?.triggerAnimation(for: inputType)
            }
        }
        inputMonitor?.start()
        print("Input monitoring started")
    }

    private func requestAccessibilityPermissions() {
        // Track permission request
        analytics.trackAccessibilityPermissionRequested()

        // First check without prompting
        let accessEnabled = AXIsProcessTrusted()

        if accessEnabled {
            print("✅ Accessibility access already granted")
            analytics.trackAccessibilityPermissionGranted()
            return
        }

        print("⚠️ Accessibility access required")

        // Check if we should show the system prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        let accessEnabledWithPrompt = AXIsProcessTrustedWithOptions(options)

        if !accessEnabledWithPrompt {
            // Give the system a moment to show the system dialog first
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Only show our custom dialog if system dialog didn't handle it
                if !AXIsProcessTrusted() {
                    self.analytics.trackAccessibilityPermissionDenied()
                    self.showAccessibilityAlert()
                } else {
                    self.analytics.trackAccessibilityPermissionGranted()
                }
            }
        } else {
            analytics.trackAccessibilityPermissionGranted()
        }
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = """
        BongoCat needs accessibility access to detect your keyboard input.

        If you already granted access but still see this message, try:
        1. Remove BongoCat from Accessibility list in System Preferences
        2. Re-add it by running the app again

        This happens when the app is reinstalled or built from a different location.
        The app will now be code signed to maintain consistent identity.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Continue Anyway")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    @objc private func toggleOverlay() {
        overlayWindow?.toggleVisibility()
        let isVisible = overlayWindow?.window?.isVisible ?? false
        analytics.trackVisibilityToggled(isVisible, method: "status_bar")
        trackFeatureUsed("toggle_overlay")
    }

    @objc internal func resetToFactoryDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset to Factory Defaults"
        alert.informativeText = "This will reset all BongoCat settings to their default values:\n\n• Scale: 75% (Medium)\n• Scale Pulse: Enabled\n• Rotation: Disabled\n• Flip: Disabled\n• Ignore Clicks: Disabled\n• Click Through: Enabled\n• Auto-Start at Launch: Enabled\n• Position: Default location\n• Per-App Positioning: Enabled\n• Per-App Hiding: Enabled (all hidden apps cleared)\n• Paw Behavior: Random\n• Stroke Counter: Will be reset\n\nThis action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Track factory reset
            analytics.trackFactoryResetPerformed()
            trackFeatureUsed("factory_reset")

            // Reset all settings to factory defaults
            currentScale = 0.75  // Medium size
            scaleOnInputEnabled = true
            currentRotation = 0.0
            isFlippedHorizontally = false
            ignoreClicksEnabled = false
            clickThroughEnabled = true
            pawBehaviorMode = .random  // Random paw behavior
            autoStartAtLaunchEnabled = true
            savedPosition = NSPoint(x: 100, y: 100)
            currentCornerPosition = .custom
            snapToCornerEnabled = false
            isPerAppPositioningEnabled = true  // Per-app positioning enabled
            perAppPositions.removeAll()
            isPerAppHidingEnabled = true  // Per-app hiding enabled
            perAppHiddenApps.removeAll()

            // Save all the reset values
            saveScale()
            saveScaleOnInputPreference()
            saveRotation()
            saveFlip()
            saveIgnoreClicksPreference()
            saveClickThroughPreference()
            savePawBehaviorPreference()
            saveAutoStartAtLaunchPreference()
            savePositionPreferences()
            savePerAppPositioning()
            savePerAppHiding()

            // Apply changes to the overlay window
            overlayWindow?.updateScale(currentScale)
            overlayWindow?.updateRotation(currentRotation)
            overlayWindow?.updateFlip(isFlippedHorizontally)
            overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)
            overlayWindow?.catAnimationController?.setIgnoreClicksEnabled(ignoreClicksEnabled)
            overlayWindow?.catAnimationController?.setPawBehaviorMode(pawBehaviorMode)
            overlayWindow?.updateIgnoreMouseEvents(clickThroughEnabled)
            overlayWindow?.setPositionProgrammatically(savedPosition)

            // Reset stroke counter
            overlayWindow?.catAnimationController?.strokeCounter.reset()

            // Update all menu items to reflect the changes
            updateScaleMenuItems()
            updateScalePulseMenuItem()
            updateRotationMenuItem()
            updateFlipMenuItem()
            updateIgnoreClicksMenuItem()
            updateClickThroughMenuItem()
            updatePawBehaviorMenuItems()
            updatePositionMenuItems()
            updatePerAppPositioningMenuItem()
            updatePerAppHidingMenuItem()
            updateHiddenAppsMenuItems()
            updateAutoStartAtLaunchMenuItem()
            updateStrokeCounterMenuItem()

            print("All settings reset to factory defaults")

            // Show confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Settings Reset"
            confirmAlert.informativeText = "All BongoCat settings have been reset to factory defaults."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()
        }
    }

    @objc private func showCredits() {
        // Track menu action
        analytics.trackMenuAction("show_credits")

        let alert = NSAlert()
        alert.messageText = "About BongoCat \(getVersionString())"
        alert.informativeText = """
        🐱 BongoCat for macOS 🐱

        Version: \(getVersionString())
        Bundle ID: \(getBundleIdentifier())

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        Created with ❤️ by \(appAuthor)
        Website: \(appWebsite)
        🐛 Report Bug: github.com/Gamma-Software/BongoCat-mac/issues/new

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        🎵 Original Concept:
        Inspired by DitzyFlama's Bongo Cat meme and StrayRogue's adorable cat artwork. The Windows Steam version by Irox Games Studio sparked the idea for this native macOS implementation.

        🚀 Features:
        • Native Swift/SwiftUI implementation
        • Global input monitoring with accessibility permissions
        • Per-application position memory
        • Customizable animations and scaling
        • Low resource usage & streaming-ready

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        Enjoy your typing companion! 🎹🐱
        Made for streamers, coders, and cat lovers everywhere.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Visit Website")
        alert.addButton(withTitle: "Report Bug")
        alert.addButton(withTitle: "OK")

        // Try to set the app icon if available
        if let iconImage = loadStatusBarIcon() {
            // Create a larger version for the dialog
            let dialogIconSize = NSSize(width: 64, height: 64)
            let dialogIcon = NSImage(size: dialogIconSize)

            dialogIcon.lockFocus()
            let context = NSGraphicsContext.current
            context?.imageInterpolation = .high

            iconImage.draw(in: NSRect(origin: .zero, size: dialogIconSize),
                          from: NSRect(origin: .zero, size: iconImage.size),
                          operation: .sourceOver,
                          fraction: 1.0)
            dialogIcon.unlockFocus()

            alert.icon = dialogIcon
        }

        let response = alert.runModal()

        // Handle button responses
        if response == .alertFirstButtonReturn {
            // "Visit Website" button clicked
            visitWebsite()
        } else if response == .alertSecondButtonReturn {
            // "Report Bug" button clicked
            reportBug()
        }
        // .alertThirdButtonReturn would be "OK" button - no action needed
    }

    @objc internal func visitWebsite() {
        // Track menu action and support action
        analytics.trackMenuAction("visit_website")
        analytics.trackSupportActionTaken("website_visit")
        trackFeatureUsed("visit_website")

        if let url = URL(string: "https://valentin.pival.fr") {
            NSWorkspace.shared.open(url)
            print("Opening website: https://valentin.pival.fr")
        } else {
            print("Failed to create URL for website")
        }
    }

    @objc internal func buyMeACoffee() {
        // Track menu action and social share
        analytics.trackMenuAction("buy_me_coffee")
        analytics.trackSocialShareInitiated("coffee_donation")
        trackFeatureUsed("buy_coffee")

        if let url = URL(string: "https://coff.ee/valentinrudloff") {
            NSWorkspace.shared.open(url)
            print("Opening Buy me a coffee: https://coff.ee/valentinrudloff")
        } else {
            print("Failed to create URL for Buy me a coffee")
        }
    }

    @objc internal func tweetAboutBongoCat() {
        // Track social share
        analytics.trackMenuAction("tweet_about_bongocat")
        analytics.trackSocialShareInitiated("twitter")
        trackFeatureUsed("social_share")

        let tweetText = "Just discovered BongoCat for macOS! A Bongo Cat overlay for your Mac - reacts to typing and clicks in real-time! Perfect for streamers and developers ✨ #BongoCat #macOS #Swift #OpenSource\n\nDownload: https://github.com/Gamma-Software/BongoCat-mac/releases/tag/v1.8.0\nSee it in action: https://youtu.be/ZFw8m6V3qRQ"
        if let encodedText = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let tweetURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            NSWorkspace.shared.open(tweetURL)
            print("Opening Tweet about BongoCat: \(tweetURL)")
        } else {
            print("Failed to create Tweet URL")
        }
    }

    @objc internal func reportBug() {
        // Track support action
        analytics.trackMenuAction("report_bug")
        analytics.trackSupportActionTaken("bug_report")
        trackFeatureUsed("bug_report")

        if let url = URL(string: "https://github.com/Gamma-Software/BongoCat-mac/issues/new") {
            NSWorkspace.shared.open(url)
            print("Opening bug report: https://github.com/Gamma-Software/BongoCat-mac/issues/new")
        } else {
            print("Failed to create URL for bug report")
        }
    }

    @objc internal func viewChangelog() {
        // Track support action
        analytics.trackMenuAction("view_changelog")
        analytics.trackSupportActionTaken("changelog_view")
        trackFeatureUsed("view_changelog")

        // Try to find and read the CHANGELOG.md file
        let possiblePaths = [
            "CHANGELOG.md",
            "./CHANGELOG.md",
            Bundle.main.path(forResource: "CHANGELOG", ofType: "md")
        ]

        var changelogContent: String?
        var foundPath: String?

        // Check each possible path and try to read content
        for path in possiblePaths.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: path) {
                do {
                    changelogContent = try String(contentsOfFile: path, encoding: .utf8)
                    foundPath = path
                    break
                } catch {
                    print("Failed to read changelog from \(path): \(error)")
                }
            }
        }

        // Try current working directory as fallback
        if changelogContent == nil {
            let currentDir = FileManager.default.currentDirectoryPath
            let currentDirPath = "\(currentDir)/CHANGELOG.md"
            if FileManager.default.fileExists(atPath: currentDirPath) {
                do {
                    changelogContent = try String(contentsOfFile: currentDirPath, encoding: .utf8)
                    foundPath = currentDirPath
                } catch {
                    print("Failed to read changelog from \(currentDirPath): \(error)")
                }
            }
        }

        // Create and show the changelog window
        let alert = NSAlert()
        alert.messageText = "BongoCat Changelog"

        if let content = changelogContent, let path = foundPath {
            // Successfully read the changelog file
            print("Displaying changelog from: \(path)")

            // Create a scrollable text view for the changelog content
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = false

            let textView = NSTextView(frame: scrollView.bounds)
            textView.isEditable = false
            textView.isSelectable = true
            textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.string = content
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: scrollView.bounds.width, height: CGFloat.greatestFiniteMagnitude)

            scrollView.documentView = textView
            alert.accessoryView = scrollView

            alert.informativeText = "Full changelog loaded from \(path)"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Visit Repository")
        } else {
            // Fallback to summary if file not found
            alert.informativeText = """
            📋 BongoCat v\(getVersionString()) - Recent Changes:

            🎯 Latest Features:
            • Keyboard layout-based paw mapping for realistic typing
            • Enhanced bug reporting and debugging features
            • Per-app positioning - cat remembers positions for each app
            • Comprehensive stroke counter with persistent statistics
            • Advanced visual customization (scale, rotation, flip)
            • Professional menu system with all settings accessible

            🏗️ Technical Improvements:
            • Native Swift/SwiftUI implementation
            • Optimized performance and resource usage
            • Enhanced accessibility permissions handling
            • Professional DMG packaging and distribution

            For complete changelog, visit the project repository.
            """
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Visit Repository")
        }

        alert.alertStyle = .informational

        // Try to set the app icon if available
        if let iconImage = loadStatusBarIcon() {
            let dialogIconSize = NSSize(width: 64, height: 64)
            let dialogIcon = NSImage(size: dialogIconSize)

            dialogIcon.lockFocus()
            let context = NSGraphicsContext.current
            context?.imageInterpolation = .high

            iconImage.draw(in: NSRect(origin: .zero, size: dialogIconSize),
                          from: NSRect(origin: .zero, size: iconImage.size),
                          operation: .sourceOver,
                          fraction: 1.0)
            dialogIcon.unlockFocus()

            alert.icon = dialogIcon
        }

        let response = alert.runModal()

        // Handle button responses
        if (changelogContent != nil && response == .alertSecondButtonReturn) ||
           (changelogContent == nil && response == .alertSecondButtonReturn) {
            // "Visit Repository" button clicked
            if let url = URL(string: "https://github.com/Gamma-Software/BongoCat-mac/blob/develop/CHANGELOG.md") {
                NSWorkspace.shared.open(url)
                print("Opening online changelog")
            }
        }
    }

    @objc internal func checkForUpdates() {
        // Track menu action
        analytics.trackMenuAction("check_for_updates")
        trackFeatureUsed("manual_update_check")

        updateChecker.checkForUpdatesManually()
    }

    @objc internal func openInstallerDMG() {
        // Track menu action
        analytics.trackMenuAction("open_installer_dmg")
        trackFeatureUsed("open_installer_dmg")

        // Get the path to the DMG file in the Build directory
        let buildPath = "Build/BongoCat-\(appVersion).dmg"
        let currentDirectory = FileManager.default.currentDirectoryPath
        let dmgPath = "\(currentDirectory)/\(buildPath)"

        // Check if the DMG file exists
        if FileManager.default.fileExists(atPath: dmgPath) {
            // Open the DMG file using NSWorkspace
            if let url = URL(string: "file://\(dmgPath)") {
                NSWorkspace.shared.open(url)
                print("✅ Opened DMG file: \(dmgPath)")

                // Show confirmation to user
                let alert = NSAlert()
                alert.messageText = "Installer DMG Opened"
                alert.informativeText = "The BongoCat installer DMG has been opened in Finder.\n\nTo install:\n1. Drag the BongoCat app to your Applications folder\n2. Eject the DMG when finished"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            } else {
                print("❌ Failed to create URL for DMG file")
                showDMGErrorAlert("Failed to create URL for DMG file")
            }
        } else {
            print("❌ DMG file not found at: \(dmgPath)")
            showDMGErrorAlert("DMG file not found. Please build the app first using the build script.")
        }
    }

    private func showDMGErrorAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Cannot Open Installer DMG"
        alert.informativeText = "\(message)\n\nTo create the installer DMG:\n1. Run the build script: ./Scripts/build.sh\n2. The DMG will be created in the Build directory"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open Build Directory")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // Open the Build directory in Finder
            let buildURL = URL(fileURLWithPath: "\(FileManager.default.currentDirectoryPath)/Build")
            NSWorkspace.shared.open(buildURL)
        }
    }

    @objc internal func debugUpdateSystem() {
        print("🔍 Debugging update system from menu...")
        updateChecker.debugUpdateSystem()
        updateChecker.testVersionComparison()

        // Show a simple alert to confirm the debug was triggered
        let alert = NSAlert()
        alert.messageText = "Debug Complete"
        alert.informativeText = "Check the console for debug information about the update system."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc internal func testDownloadFunctionality() {
        print("🧪 Testing download functionality from menu...")
        updateChecker.testDownloadFunctionality()

        // Show a simple alert to confirm the test was triggered
        let alert = NSAlert()
        alert.messageText = "Download Test Started"
        alert.informativeText = "Check the console for download test results."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc internal func resetWelcomeScreen() {
        resetFirstLaunchFlag()

        let alert = NSAlert()
        alert.messageText = "Welcome Screen Reset"
        alert.informativeText = "The welcome screen will show on the next app launch."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    internal func checkForUpdatesPublic() {
        checkForUpdates()
    }

    internal func openInstallerDMGPublic() {
        openInstallerDMG()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }

    // MARK: - Version Information

    internal func getVersionString() -> String {
        // Try to get version from bundle first, fallback to hardcoded
        if let bundleVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let bundleBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return "\(bundleVersion) (\(bundleBuild))"
        } else {
            return "\(appVersion) (\(appBuild))"
        }
    }

    internal func getBundleIdentifier() -> String {
        return Bundle.main.bundleIdentifier ?? "com.leaptech.bongocat"
    }

        // MARK: - Public methods for context menu

    func setScalePublic(_ scale: Double) {
        setScale(scale)
    }

    func setCornerPositionPublic(_ corner: CornerPosition) {
        let position = getCornerPosition(for: corner)
        overlayWindow?.setPositionProgrammatically(position)
        currentCornerPosition = corner
        saveManualPosition(position)
        updatePositionMenuItems()
        print("Moved cat to \(corner.displayName) at position: \(position)")
    }

    func toggleScalePulsePublic() {
        toggleScalePulse()
    }

    func toggleBongoCatRotatePublic() {
        toggleBongoCatRotate()
    }

    func toggleHorizontalFlipPublic() {
        toggleHorizontalFlip()
    }

    func toggleIgnoreClicksPublic() {
        toggleIgnoreClicks()
    }

    func toggleClickThroughPublic() {
        toggleClickThrough()
    }

    func setPawBehaviorKeyboardLayoutPublic() {
        setPawBehaviorKeyboardLayout()
    }

    func setPawBehaviorRandomPublic() {
        setPawBehaviorRandom()
    }

    func setPawBehaviorAlternatingPublic() {
        setPawBehaviorAlternating()
    }

    func toggleOverlayPublic() {
        toggleOverlay()
    }

    func resetStrokeCounterPublic() {
        resetStrokeCounter()
    }

    func toggleMilestoneNotificationsPublic() {
        toggleMilestoneNotifications()
    }

    func saveCurrentPositionActionPublic() {
        saveCurrentPositionAction()
    }

    func restoreSavedPositionPublic() {
        restoreSavedPosition()
    }

    func visitWebsitePublic() {
        visitWebsite()
    }

    func buyMeACoffeePublic() {
        buyMeACoffee()
    }

    func tweetAboutBongoCatPublic() {
        tweetAboutBongoCat()
    }

    func reportBugPublic() {
        reportBug()
    }

    func viewChangelogPublic() {
        viewChangelog()
    }

    func showCreditsPublic() {
        showCredits()
    }

    func quitAppPublic() {
        NSApplication.shared.terminate(self)
    }

    func toggleAutoStartAtLaunchPublic() {
        toggleAutoStartAtLaunch()
    }

    // MARK: - Developer/Debug Methods

    #if DEBUG
    @objc private func showAnalyticsStatus() {
        let alert = NSAlert()
        alert.messageText = "Analytics Configuration Status"
        alert.informativeText = """
        \(analytics.getConfigurationStatus())

        Analytics Enabled: \(analytics.isAnalyticsEnabled ? "Yes" : "No")

                 To configure PostHog analytics:
         1. Sign up at https://posthog.com
         2. Create a new project
         3. Configure securely (see ANALYTICS_SETUP.md):
            • Environment variables (recommended)
            • Local analytics-config.plist file
            • Info.plist (not for public repos)
         4. Rebuild the app

        Once configured, BongoCat will track anonymous usage data to help improve the app.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open PostHog")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://posthog.com") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc private func testAnalytics() {
        let alert = NSAlert()
        alert.messageText = "Test Analytics Event"
        alert.informativeText = "This will send a test event to PostHog (if configured).\n\n\(analytics.getConfigurationStatus())"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Send Test Event")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            analytics.testAnalytics()

            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Test Event Sent"
            confirmAlert.informativeText = analytics.isConfiguredForAnalytics() ?
                "Test event has been sent to PostHog. Check your PostHog dashboard to see if it appears." :
                "Analytics not configured, but test event would have been sent."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()
        }
    }
    #endif

    func togglePerAppHidingPublic() {
        togglePerAppHiding()
    }

    func hideForCurrentAppPublic() {
        hideForCurrentApp()
    }

    func showForCurrentAppPublic() {
        showForCurrentApp()
    }

    func manageHiddenAppsPublic() {
        manageHiddenApps()
    }

    // MARK: - Scale Management

    private func loadSavedScale() {
        if UserDefaults.standard.object(forKey: scaleKey) != nil {
            currentScale = UserDefaults.standard.double(forKey: scaleKey)
        } else {
            currentScale = 0.75 // Default to Medium (75%)
        }
        print("Loaded scale: \(currentScale)")
    }

    private func loadScaleOnInputPreference() {
        if UserDefaults.standard.object(forKey: scaleOnInputKey) != nil {
            scaleOnInputEnabled = UserDefaults.standard.bool(forKey: scaleOnInputKey)
        } else {
            scaleOnInputEnabled = true // Default enabled
        }
        print("Loaded scale on input preference: \(scaleOnInputEnabled)")
    }

    private func loadSavedRotation() {
        if UserDefaults.standard.object(forKey: rotationKey) != nil {
            currentRotation = UserDefaults.standard.double(forKey: rotationKey)
        } else {
            currentRotation = 0.0 // Default rotation
        }
        print("Loaded rotation: \(currentRotation)")
    }

    private func loadSavedFlip() {
        if UserDefaults.standard.object(forKey: flipKey) != nil {
            isFlippedHorizontally = UserDefaults.standard.bool(forKey: flipKey)
        } else {
            isFlippedHorizontally = false // Default not flipped
        }
        print("Loaded horizontal flip: \(isFlippedHorizontally)")
    }

    private func loadIgnoreClicksPreference() {
        if UserDefaults.standard.object(forKey: ignoreClicksKey) != nil {
            ignoreClicksEnabled = UserDefaults.standard.bool(forKey: ignoreClicksKey)
        } else {
            ignoreClicksEnabled = false // Default disabled
        }
        print("Loaded ignore clicks preference: \(ignoreClicksEnabled)")
    }

    private func loadClickThroughPreference() {
        if UserDefaults.standard.object(forKey: clickThroughKey) != nil {
            clickThroughEnabled = UserDefaults.standard.bool(forKey: clickThroughKey)
        } else {
            clickThroughEnabled = true // Default enabled
        }
        print("Loaded click through preference: \(clickThroughEnabled)")
    }

    private func loadPawBehaviorPreference() {
        if let behaviorString = UserDefaults.standard.string(forKey: pawBehaviorKey),
           let behavior = PawBehaviorMode(rawValue: behaviorString) {
            pawBehaviorMode = behavior
        } else {
            pawBehaviorMode = .random // Default to random
        }
        print("Loaded paw behavior preference: \(pawBehaviorMode.displayName)")
    }

    private func loadAutoStartAtLaunchPreference() {
        if UserDefaults.standard.object(forKey: autoStartAtLaunchKey) != nil {
            autoStartAtLaunchEnabled = UserDefaults.standard.bool(forKey: autoStartAtLaunchKey)
        } else {
            autoStartAtLaunchEnabled = true // Default enabled
        }
        print("Loaded auto-start at launch preference: \(autoStartAtLaunchEnabled)")
    }

    internal func saveScale() {
        UserDefaults.standard.set(currentScale, forKey: scaleKey)
        print("Saved scale: \(currentScale)")
    }

    internal func saveScaleOnInputPreference() {
        UserDefaults.standard.set(scaleOnInputEnabled, forKey: scaleOnInputKey)
        print("Saved scale on input preference: \(scaleOnInputEnabled)")
    }

    internal func saveRotation() {
        UserDefaults.standard.set(currentRotation, forKey: rotationKey)
        print("Saved rotation: \(currentRotation)")
    }

    internal func saveFlip() {
        UserDefaults.standard.set(isFlippedHorizontally, forKey: flipKey)
        print("Saved horizontal flip: \(isFlippedHorizontally)")
    }

    internal func saveIgnoreClicksPreference() {
        UserDefaults.standard.set(ignoreClicksEnabled, forKey: ignoreClicksKey)
        print("Saved ignore clicks preference: \(ignoreClicksEnabled)")
    }

    internal func saveClickThroughPreference() {
        UserDefaults.standard.set(clickThroughEnabled, forKey: clickThroughKey)
        print("Saved click through preference: \(clickThroughEnabled)")
    }

    internal func savePawBehaviorPreference() {
        UserDefaults.standard.set(pawBehaviorMode.rawValue, forKey: pawBehaviorKey)
        print("Saved paw behavior preference: \(pawBehaviorMode.displayName)")
    }

    internal func saveAutoStartAtLaunchPreference() {
        UserDefaults.standard.set(autoStartAtLaunchEnabled, forKey: autoStartAtLaunchKey)
        print("Saved auto-start at launch preference: \(autoStartAtLaunchEnabled)")
    }

    @objc private func setScale065() {
        setScale(0.65)
    }

    @objc private func setScale075() {
        setScale(0.75)
    }

    @objc private func setScale100() {
        setScale(1.0)
    }

    @objc private func setScale125() {
        setScale(1.25)
    }

    @objc private func setScale150() {
        setScale(1.5)
    }

    @objc private func setScale200() {
        setScale(2.0)
    }

    private func setScale(_ scale: Double) {
        currentScale = scale
        saveScale()
        overlayWindow?.updateScale(scale)
        updateScaleMenuItems()

        // Track scale change and setting change
        analytics.trackScaleChanged(scale)
        trackSettingChanged("scale")
        trackFeatureUsed("scale_adjustment")

        print("Scale changed to: \(scale)")
    }

    private func updateScaleMenuItems() {
        // Update checkmarks on scale menu items
        guard let menu = statusBarItem?.menu else { return }

        // Find the scale submenu
        for item in menu.items {
            if item.title == "Scale", let submenu = item.submenu {
                for subItem in submenu.items {
                    let title = subItem.title
                    if title.hasSuffix("%") {
                        let scaleString = String(title.dropLast())
                        if let itemScale = Double(scaleString) {
                            subItem.state = (itemScale / 100 == currentScale) ? .on : .off
                        }
                    }
                }
            }
        }
    }

    // MARK: - Scale Pulse Management

    @objc internal func toggleScalePulse() {
        scaleOnInputEnabled.toggle()
        saveScaleOnInputPreference()
        overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)  // Apply immediately
        updateScalePulseMenuItem()

        // Track setting toggle
        analytics.trackSettingToggled("scale_pulse", enabled: scaleOnInputEnabled)
        trackSettingChanged("scale_pulse")
        trackFeatureUsed("scale_pulse")

        print("Scale pulse on input toggled to: \(scaleOnInputEnabled)")
    }

    private func updateScalePulseMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Scale Pulse on Input" {
                item.state = scaleOnInputEnabled ? .on : .off
                break
            }
        }
    }

    // MARK: - Bongo Cat Rotate Management

    @objc private func toggleBongoCatRotate() {
        // Toggle between 0 degrees and 13/-13 degrees rotation based on flip state
        if currentRotation == 0.0 {
            // When enabling rotation, use 13° if not flipped, -13° if flipped
            currentRotation = isFlippedHorizontally ? -13.0 : 13.0
        } else {
            // When disabling rotation, always go back to 0°
            currentRotation = 0.0
        }
        saveRotation()
        overlayWindow?.updateRotation(currentRotation)
        updateRotationMenuItem()

        // Track setting toggle and setting change
        analytics.trackSettingToggled("rotation", enabled: currentRotation != 0.0)
        trackSettingChanged("rotation")
        trackFeatureUsed("rotation")

        print("Bongo Cat rotated to: \(currentRotation) degrees")
    }

    @objc private func toggleHorizontalFlip() {
        isFlippedHorizontally.toggle()

        // If the cat is currently rotated, adjust the rotation for the new flip state
        if currentRotation != 0.0 {
            currentRotation = isFlippedHorizontally ? -13.0 : 13.0
            saveRotation()
            overlayWindow?.updateRotation(currentRotation)
        }

        saveFlip()
        overlayWindow?.updateFlip(isFlippedHorizontally)
        updateFlipMenuItem()

        // Track setting toggle
        analytics.trackSettingToggled("horizontal_flip", enabled: isFlippedHorizontally)
        trackSettingChanged("horizontal_flip")
        trackFeatureUsed("horizontal_flip")

        print("Cat horizontal flip toggled to: \(isFlippedHorizontally)")
    }

    @objc internal func toggleIgnoreClicks() {
        ignoreClicksEnabled.toggle()
        saveIgnoreClicksPreference()
        overlayWindow?.catAnimationController?.setIgnoreClicksEnabled(ignoreClicksEnabled)
        updateIgnoreClicksMenuItem()

        // Track setting toggle
        analytics.trackSettingToggled("ignore_clicks", enabled: ignoreClicksEnabled)
        trackSettingChanged("ignore_clicks")
        trackFeatureUsed("ignore_clicks")

        print("Ignore clicks toggled to: \(ignoreClicksEnabled)")
    }

    @objc internal func toggleClickThrough() {
        clickThroughEnabled.toggle()
        saveClickThroughPreference()
        overlayWindow?.updateIgnoreMouseEvents(clickThroughEnabled)
        updateClickThroughMenuItem()

        // Track setting toggle
        analytics.trackSettingToggled("click_through", enabled: clickThroughEnabled)
        trackSettingChanged("click_through")
        trackFeatureUsed("click_through")

        print("Click through toggled to: \(clickThroughEnabled)")
    }

    @objc private func setPawBehaviorKeyboardLayout() {
        setPawBehavior(.keyboardLayout)
    }

    @objc private func setPawBehaviorRandom() {
        setPawBehavior(.random)
    }

    @objc private func setPawBehaviorAlternating() {
        setPawBehavior(.alternating)
    }

    private func setPawBehavior(_ behavior: PawBehaviorMode) {
        pawBehaviorMode = behavior
        savePawBehaviorPreference()
        overlayWindow?.catAnimationController?.setPawBehaviorMode(pawBehaviorMode)
        updatePawBehaviorMenuItems()

        // Track paw behavior change
        analytics.trackPawBehaviorChanged(behavior.displayName)
        trackSettingChanged("paw_behavior")
        trackFeatureUsed("paw_behavior_\(behavior.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))")

        print("Paw behavior changed to: \(behavior.displayName)")
    }

    // MARK: - Stroke Counter Management

    @objc internal func resetStrokeCounter() {
        let alert = NSAlert()
        alert.messageText = "Reset Stroke Counter"
        alert.informativeText = "Are you sure you want to reset the stroke counter? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            overlayWindow?.catAnimationController?.strokeCounter.reset()
            updateStrokeCounterMenuItem()

            // Track stroke counter reset
            analytics.trackStrokeCounterReset()
            trackFeatureUsed("stroke_counter_reset")

            print("Stroke counter reset by user")
        }
    }

    private func updateStrokeCounterMenuItem() {
        guard let menu = statusBarItem?.menu else { return }

        // Find the stroke counter menu item by its tag
        for item in menu.items {
            if item.tag == 999 {
                if let strokeCounter = overlayWindow?.catAnimationController?.strokeCounter {
                    let total = strokeCounter.totalStrokes
                    let keys = strokeCounter.keystrokes
                    let clicks = strokeCounter.mouseClicks
                    item.title = "Strokes: \(total) (Keys: \(keys), Clicks: \(clicks))"
                } else {
                    item.title = "Strokes: Loading..."
                }
                break
            }
        }
    }

    // MARK: - Milestone Notifications Management

    @objc private func toggleMilestoneNotifications() {
        let currentlyEnabled = milestoneManager.isNotificationsEnabled()
        milestoneManager.setNotificationsEnabled(!currentlyEnabled)
        updateMilestoneNotificationsMenuItem()
        print("Milestone notifications toggled to: \(!currentlyEnabled)")
    }

    @objc private func toggleUpdateNotifications() {
        let currentlyEnabled = updateChecker.isUpdateNotificationsEnabled()
        updateChecker.setUpdateNotificationsEnabled(!currentlyEnabled)
        updateUpdateNotificationsMenuItem()

        // Track setting toggle
        analytics.trackSettingToggled("update_notifications", enabled: !currentlyEnabled)

        print("Update notifications toggled to: \(!currentlyEnabled)")
    }

    @objc private func toggleAnalytics() {
        showAnalyticsPrivacyDialog()
    }

    private func showAnalyticsPrivacyDialog() {
        let alert = NSAlert()
        alert.messageText = "Analytics & Privacy Settings"
        alert.informativeText = """
        BongoCat uses analytics to improve the app experience by tracking:

        📊 What We Track:
        • App launches and usage patterns
        • Feature usage (scale changes, settings toggles)
        • Milestone achievements
        • Error occurrences (for debugging)

        🔒 What We DON'T Track:
        • Personal information or keystrokes content
        • Screen contents or passwords
        • Files or documents you're working on

        🛡️ Privacy:
        • All data is anonymous
        • No personal identification
        • Data helps improve BongoCat for everyone

        Current Status: \(analytics.isAnalyticsEnabled ? "Analytics Enabled" : "Analytics Disabled")
        """

        alert.alertStyle = .informational
        alert.addButton(withTitle: analytics.isAnalyticsEnabled ? "Disable Analytics" : "Enable Analytics")
        alert.addButton(withTitle: "Keep Current Setting")
        alert.addButton(withTitle: "Learn More")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            // Toggle analytics
            let newState = !analytics.isAnalyticsEnabled
            analytics.setAnalyticsEnabled(newState)
            updateAnalyticsMenuItem()

            // Show confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Analytics \(newState ? "Enabled" : "Disabled")"
            confirmAlert.informativeText = newState ?
                "Thank you! Analytics will help us improve BongoCat." :
                "Analytics has been disabled. You can re-enable it anytime from the menu."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()

            print("Analytics toggled to: \(newState)")
        } else if response == .alertThirdButtonReturn {
            // Learn more - open privacy policy or GitHub
            if let url = URL(string: "https://github.com/Gamma-Software/BongoCat-mac#privacy") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    internal func updateMilestoneNotificationsMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Milestone Notifications 🔔" {
                item.state = milestoneManager.isNotificationsEnabled() ? .on : .off
                break
            }
        }
    }

    internal func updateUpdateNotificationsMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Update Notifications 🔄" {
                item.state = updateChecker.isUpdateNotificationsEnabled() ? .on : .off
                break
            }
        }
    }

    internal func updateAutoUpdateMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Auto-Update ⚡" {
                item.state = UpdateChecker.shared.isAutoUpdateEnabled() ? .on : .off
                break
            }
        }
    }

    internal func updateAnalyticsMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Analytics & Privacy 📊" {
                item.state = analytics.isAnalyticsEnabled ? .on : .off
                break
            }
        }
    }

    private func updateAutoStartAtLaunchMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Auto-Start at Launch 🚀" {
                item.state = autoStartAtLaunchEnabled ? .on : .off
                break
            }
        }
    }

    private func updateRotationMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Bongo Cat Rotate" {
                item.state = (currentRotation != 0.0) ? .on : .off
                break
            }
        }
    }

    private func updateFlipMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Flip Horizontally" {
                item.state = isFlippedHorizontally ? .on : .off
                break
            }
        }
    }

    private func updateIgnoreClicksMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Ignore Clicks" {
                item.state = ignoreClicksEnabled ? .on : .off
                break
            }
        }
    }

    private func updateClickThroughMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Click Through (Hold ⌘ to Drag)" {
                item.state = clickThroughEnabled ? .on : .off
                break
            }
        }
    }

    private func updatePawBehaviorMenuItems() {
        guard let menu = statusBarItem?.menu else { return }

        // Find the paw behavior submenu
        for item in menu.items {
            if item.title == "Paw Behavior", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Keyboard Layout" {
                        subItem.state = (pawBehaviorMode == .keyboardLayout) ? .on : .off
                    } else if subItem.title == "Random" {
                        subItem.state = (pawBehaviorMode == .random) ? .on : .off
                    } else if subItem.title == "Alternating" {
                        subItem.state = (pawBehaviorMode == .alternating) ? .on : .off
                    }
                }
            }
        }
    }

    private func updatePositionMenuItems() {
        guard let menu = statusBarItem?.menu else { return }

        // Find the position submenu and update checkmarks
        for item in menu.items {
            if item.title == "Position", let submenu = item.submenu {
                for subItem in submenu.items {
                    if let corner = subItem.representedObject as? CornerPosition {
                        subItem.state = (corner == currentCornerPosition) ? .on : .off
                    }
                }
            }
        }
    }

    func saveManualPosition(_ position: NSPoint) {
        if isPerAppPositioningEnabled && currentActiveApp != "unknown" {
            // Save position for the current active app
            perAppPositions[currentActiveApp] = position
            savePerAppPositioning()
            triggerSettingsUpdate()
            print("Manual position saved for \(currentActiveApp): \(position)")
        } else {
            // Save position globally (original behavior)
            savedPosition = position
            currentCornerPosition = .custom
            savePositionPreferences()
            updatePositionMenuItems()

            // Track global position save
            print("Manual position saved: \(position)")
        }
    }

    private func loadPositionPreferences() {
        // Load snap to corner preference
        if UserDefaults.standard.object(forKey: snapToCornerKey) != nil {
            snapToCornerEnabled = UserDefaults.standard.bool(forKey: snapToCornerKey)
        } else {
            snapToCornerEnabled = false // Default disabled
        }

        // Load saved position
        if UserDefaults.standard.object(forKey: savedPositionXKey) != nil {
            let x = UserDefaults.standard.double(forKey: savedPositionXKey)
            let y = UserDefaults.standard.double(forKey: savedPositionYKey)
            savedPosition = NSPoint(x: x, y: y)
        } else {
            savedPosition = NSPoint(x: 100, y: 100) // Default position
        }

        // Load corner position preference
        if let cornerString = UserDefaults.standard.string(forKey: cornerPositionKey),
           let corner = CornerPosition(rawValue: cornerString) {
            currentCornerPosition = corner
        } else {
            currentCornerPosition = .custom // Default to custom
        }

        print("Loaded position preferences - snap: \(snapToCornerEnabled), position: \(savedPosition), corner: \(currentCornerPosition)")
    }

    internal func savePositionPreferences() {
        UserDefaults.standard.set(snapToCornerEnabled, forKey: snapToCornerKey)
        UserDefaults.standard.set(savedPosition.x, forKey: savedPositionXKey)
        UserDefaults.standard.set(savedPosition.y, forKey: savedPositionYKey)
        UserDefaults.standard.set(currentCornerPosition.rawValue, forKey: cornerPositionKey)
        print("Saved position preferences - snap: \(snapToCornerEnabled), position: \(savedPosition), corner: \(currentCornerPosition)")
    }

    @objc internal func saveCurrentPositionAction() {
        let currentPosition = overlayWindow?.window?.frame.origin ?? NSPoint.zero
        saveManualPosition(currentPosition)

        // Track position save
        trackFeatureUsed("save_position")

        print("Current position saved: \(currentPosition)")
    }

    @objc internal func restoreSavedPosition() {
        overlayWindow?.setPositionProgrammatically(savedPosition)
        currentCornerPosition = .custom // Assuming saved position is custom
        updatePositionMenuItems()

        // Track position restore
        trackFeatureUsed("restore_position")

        print("Restored saved position: \(savedPosition)")
    }

    @objc private func setCornerPosition(_ sender: NSMenuItem) {
        guard let corner = sender.representedObject as? CornerPosition else { return }
        let position = getCornerPosition(for: corner)
        overlayWindow?.setPositionProgrammatically(position)
        currentCornerPosition = corner
        saveManualPosition(position)
        updatePositionMenuItems()

        // Track position change
        analytics.trackPositionChanged(corner.displayName)
        trackFeatureUsed("corner_positioning")

        print("Moved cat to \(corner.displayName) at position: \(position)")
    }

    private func getCornerPosition(for corner: CornerPosition, on screen: NSScreen? = nil) -> NSPoint {
        let targetScreen = screen ?? getCurrentScreen() ?? NSScreen.main ?? NSScreen.screens.first

        guard let screen = targetScreen else {
            return NSPoint(x: 100, y: 100)
        }

        let screenFrame = screen.visibleFrame
        let windowSize = overlayWindow?.window?.frame.size ?? NSSize(width: 150, height: 125) // Updated default size
        let margin: CGFloat = 20 // Distance from screen edges

        switch corner {
        case .topLeft:
            return NSPoint(
                x: screenFrame.minX + margin,
                y: screenFrame.maxY - windowSize.height - margin
            )
        case .topRight:
            return NSPoint(
                x: screenFrame.maxX - windowSize.width - margin,
                y: screenFrame.maxY - windowSize.height - margin
            )
        case .bottomLeft:
            return NSPoint(
                x: screenFrame.minX + margin,
                y: screenFrame.minY + margin
            )
        case .bottomRight:
            return NSPoint(
                x: screenFrame.maxX - windowSize.width - margin,
                y: screenFrame.minY + margin
            )
        case .custom:
            return savedPosition
        }
    }

    // MARK: - Per-App Position Management

    internal func getCurrentActiveApp() -> String {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            let bundleID = frontmostApp.bundleIdentifier ?? "unknown"
            let appName = frontmostApp.localizedName ?? "Unknown App"
            print("🎯 Current active app: \(appName) (Bundle ID: \(bundleID))")
            return bundleID
        }
        return "unknown"
    }

        internal func getSavedPositionsWithAppNames() -> [(appName: String, bundleID: String, position: NSPoint, screenName: String)] {
        var positionsWithNames: [(appName: String, bundleID: String, position: NSPoint, screenName: String)] = []

        for (bundleID, position) in perAppPositions {
            var appName = bundleID

            // Try to get the app name from the bundle ID
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
               let bundle = Bundle(url: url) {
                if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                    appName = displayName
                } else if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                    appName = bundleName
                }
            }

            // Determine which screen this position is on
            let screenName = getScreenNameForPosition(position)

            positionsWithNames.append((appName: appName, bundleID: bundleID, position: position, screenName: screenName))
        }

        // Sort by app name for better organization
        return positionsWithNames.sorted { $0.appName.lowercased() < $1.appName.lowercased() }
    }

    private func getScreenNameForPosition(_ position: NSPoint) -> String {
        let screens = getAllScreens()

        for screen in screens {
            let frame = screen.frame
            if position.x >= frame.minX && position.x <= frame.maxX &&
               position.y >= frame.minY && position.y <= frame.maxY {
                return getScreenName(screen)
            }
        }

        return "Unknown Screen"
    }

    internal func deleteSavedPosition(for bundleID: String) {
        perAppPositions.removeValue(forKey: bundleID)
        savePerAppPositioning()
        triggerSettingsUpdate()
        print("🗑️ Deleted saved position for \(bundleID)")
    }

    internal func clearAllSavedPositions() {
        perAppPositions.removeAll()
        savePerAppPositioning()
        triggerSettingsUpdate()
        print("🗑️ Cleared all saved positions")
    }

    // MARK: - Screen Detection and Management

    internal func getCurrentScreen() -> NSScreen? {
        guard let window = overlayWindow?.window else { return nil }
        return window.screen
    }

    internal func getAllScreens() -> [NSScreen] {
        return NSScreen.screens
    }

    internal func getScreenInfo() -> [(index: Int, screen: NSScreen, isCurrent: Bool)] {
        let screens = getAllScreens()
        let currentScreen = getCurrentScreen()

        return screens.enumerated().map { index, screen in
            let isCurrent = screen == currentScreen
            return (index: index, screen: screen, isCurrent: isCurrent)
        }
    }

    internal func getScreenName(_ screen: NSScreen) -> String {
        let localizedName = screen.localizedName
        if !localizedName.isEmpty {
            return localizedName
        }

        // Fallback to screen dimensions if no name is available
        let frame = screen.frame
        return "Screen \(Int(frame.width))x\(Int(frame.height))"
    }

    internal func isOverlayOnScreen(_ screen: NSScreen) -> Bool {
        guard let currentScreen = getCurrentScreen() else { return false }
        return currentScreen == screen
    }

    internal func moveOverlayToScreen(_ screen: NSScreen) {
        guard let window = overlayWindow?.window else { return }

        // Get the current position relative to the current screen
        let currentPosition = window.frame.origin
        let currentScreen = getCurrentScreen()

        // Calculate the relative position within the screen (0.0 to 1.0)
        var relativeX: CGFloat = 0.5
        var relativeY: CGFloat = 0.5

        if let currentScreen = currentScreen {
            let currentFrame = currentScreen.frame
            relativeX = (currentPosition.x - currentFrame.minX) / currentFrame.width
            relativeY = (currentPosition.y - currentFrame.minY) / currentFrame.height
        }

        // Apply the same relative position to the target screen
        let targetFrame = screen.frame
        let newX = targetFrame.minX + (relativeX * targetFrame.width)
        let newY = targetFrame.minY + (relativeY * targetFrame.height)

        // Ensure the window stays within the target screen bounds
        let windowSize = window.frame.size
        let constrainedX = max(targetFrame.minX, min(newX, targetFrame.maxX - windowSize.width))
        let constrainedY = max(targetFrame.minY, min(newY, targetFrame.maxY - windowSize.height))

        let newPosition = NSPoint(x: constrainedX, y: constrainedY)
        overlayWindow?.setPositionProgrammatically(newPosition)

        print("🖥️ Moved overlay to screen: \(getScreenName(screen))")
    }

    internal func getCurrentScreenInfo() -> String {
        guard let currentScreen = getCurrentScreen() else {
            return "Unknown Screen"
        }

        let screenName = getScreenName(currentScreen)
        let frame = currentScreen.frame
        return "\(screenName) (\(Int(frame.width))x\(Int(frame.height)))"
    }

    internal func setPositionOnScreen(_ corner: CornerPosition, screen: NSScreen) {
        let position = getCornerPosition(for: corner, on: screen)
        overlayWindow?.setPositionProgrammatically(position)
        currentCornerPosition = corner
        saveManualPosition(position)
        updatePositionMenuItems()

        print("🖥️ Moved cat to \(corner.displayName) on screen: \(getScreenName(screen))")
    }

    internal func loadPerAppPositioning() {
        // Load per-app positioning preference
        if UserDefaults.standard.object(forKey: perAppPositioningKey) != nil {
            isPerAppPositioningEnabled = UserDefaults.standard.bool(forKey: perAppPositioningKey)
        } else {
            isPerAppPositioningEnabled = true // Default enabled
        }

        // Load per-app positions dictionary
        if let savedPositions = UserDefaults.standard.dictionary(forKey: perAppPositionsKey) as? [String: [String: Double]] {
            for (bundleID, position) in savedPositions {
                if let x = position["x"], let y = position["y"] {
                    perAppPositions[bundleID] = NSPoint(x: x, y: y)
                }
            }
        }

        // Initialize current active app
        currentActiveApp = getCurrentActiveApp()

        print("Loaded per-app positioning - enabled: \(isPerAppPositioningEnabled), positions: \(perAppPositions)")
    }

    internal func savePerAppPositioning() {
        UserDefaults.standard.set(isPerAppPositioningEnabled, forKey: perAppPositioningKey)

        // Convert NSPoint dictionary to saveable format
        var saveablePositions: [String: [String: Double]] = [:]
        for (bundleID, position) in perAppPositions {
            saveablePositions[bundleID] = ["x": position.x, "y": position.y]
        }
        UserDefaults.standard.set(saveablePositions, forKey: perAppPositionsKey)

        print("Saved per-app positioning - enabled: \(isPerAppPositioningEnabled), positions: \(perAppPositions)")
    }

    internal func loadPerAppHiding() {
        // Load per-app hiding preference
        if UserDefaults.standard.object(forKey: perAppHidingKey) != nil {
            isPerAppHidingEnabled = UserDefaults.standard.bool(forKey: perAppHidingKey)
        } else {
            isPerAppHidingEnabled = true // Default enabled
        }

        // Load per-app hidden apps set
        if let savedHiddenApps = UserDefaults.standard.array(forKey: perAppHiddenAppsKey) as? [String] {
            perAppHiddenApps = Set(savedHiddenApps)
        }

        print("Loaded per-app hiding - enabled: \(isPerAppHidingEnabled), hidden apps: \(perAppHiddenApps)")
    }

    internal func savePerAppHiding() {
        UserDefaults.standard.set(isPerAppHidingEnabled, forKey: perAppHidingKey)
        UserDefaults.standard.set(Array(perAppHiddenApps), forKey: perAppHiddenAppsKey)

        print("Saved per-app hiding - enabled: \(isPerAppHidingEnabled), hidden apps: \(perAppHiddenApps)")
    }

    private func setupAppSwitchMonitoring() {
        // Set up a timer to periodically check for app switches
        // Using a timer approach to avoid potential permission issues with workspace notifications
        appSwitchTimer = Timer.scheduledTimer(withTimeInterval: appSwitchTimerInterval, repeats: true) { [weak self] _ in
            self?.checkForAppSwitch()
        }

        print("App switch monitoring started")
    }

    private func checkForAppSwitch() {
        guard isPerAppPositioningEnabled || isPerAppHidingEnabled else { return }

        let newActiveApp = getCurrentActiveApp()
        if newActiveApp != currentActiveApp && newActiveApp != "unknown" {
            print("🔄 App switch detected: \(currentActiveApp) -> \(newActiveApp)")
            handleAppSwitch(from: currentActiveApp, to: newActiveApp)
            currentActiveApp = newActiveApp
        }
    }

        internal func handleAppSwitch(from oldApp: String, to newApp: String) {
        // Handle per-app positioning
        if isPerAppPositioningEnabled {
            // Save current position for the old app (if it's not "unknown")
            if oldApp != "unknown", let currentPosition = overlayWindow?.window?.frame.origin {
                perAppPositions[oldApp] = currentPosition
                print("💾 Saved position for \(oldApp): \(currentPosition)")
            }

            // Load and apply position for the new app
            if let savedPosition = perAppPositions[newApp] {
                print("📍 Restoring position for \(newApp): \(savedPosition)")
                overlayWindow?.setPositionProgrammatically(savedPosition)
            } else {
                // Set default position to top-right corner for unknown bundle IDs or new apps
                let defaultPosition = getCornerPosition(for: .topRight)
                print("🆕 No saved position for \(newApp), setting to top-right corner: \(defaultPosition)")
                overlayWindow?.setPositionProgrammatically(defaultPosition)
            }

            // Save the updated positions
            savePerAppPositioning()
        }

        // Handle per-app hiding
        if isPerAppHidingEnabled {
            let shouldHideForNewApp = perAppHiddenApps.contains(newApp)
            if shouldHideForNewApp {
                print("🙈 Hiding cat for \(newApp)")
                overlayWindow?.hideWindow()
                analytics.trackVisibilityToggled(false, method: "per_app_hiding")
            } else {
                print("👁️ Showing cat for \(newApp)")
                overlayWindow?.showWindow()
                analytics.trackVisibilityToggled(true, method: "per_app_showing")
            }
        }
    }

    @objc internal func togglePerAppPositioning() {
        isPerAppPositioningEnabled.toggle()
        savePerAppPositioning()

        if isPerAppPositioningEnabled {
            // When enabling, save current position for the current app
            currentActiveApp = getCurrentActiveApp()
            if let currentPosition = overlayWindow?.window?.frame.origin {
                perAppPositions[currentActiveApp] = currentPosition
                savePerAppPositioning()
            }
        }

        updatePerAppPositioningMenuItem()

        // Track per-app positioning toggle
        analytics.trackPerAppPositioningToggled(isPerAppPositioningEnabled)
        trackSettingChanged("per_app_positioning")
        trackFeatureUsed("per_app_positioning")

        print("Per-app positioning toggled to: \(isPerAppPositioningEnabled)")
    }

    @objc internal func togglePerAppHiding() {
        isPerAppHidingEnabled.toggle()
        savePerAppHiding()

        if isPerAppHidingEnabled {
            // When enabling, check if current app should be hidden
            currentActiveApp = getCurrentActiveApp()
            let shouldHide = perAppHiddenApps.contains(currentActiveApp)
            if shouldHide {
                overlayWindow?.hideWindow()
                analytics.trackVisibilityToggled(false, method: "per_app_hiding_enabled")
            } else {
                overlayWindow?.showWindow()
                analytics.trackVisibilityToggled(true, method: "per_app_hiding_enabled")
            }
        } else {
            // When disabling, always show the cat
            overlayWindow?.showWindow()
            analytics.trackVisibilityToggled(true, method: "per_app_hiding_disabled")
        }

        updatePerAppHidingMenuItem()

        // Track per-app hiding toggle
        analytics.trackPerAppHidingToggled(isPerAppHidingEnabled)
        trackSettingChanged("per_app_hiding")
        trackFeatureUsed("per_app_hiding")

        print("Per-app hiding toggled to: \(isPerAppHidingEnabled)")
    }

    @objc internal func hideForCurrentApp() {
        let currentApp = getCurrentActiveApp()
        if currentApp != "unknown" {
            perAppHiddenApps.insert(currentApp)
            savePerAppHiding()

            if isPerAppHidingEnabled {
                overlayWindow?.hideWindow()
                analytics.trackVisibilityToggled(false, method: "hide_for_current_app")
            }

            updateHiddenAppsMenuItems()

            // Track app hidden status change
            analytics.trackAppHiddenStatusChanged(currentApp, hidden: true)
            trackFeatureUsed("hide_for_current_app")

            print("Added \(currentApp) to hidden apps list")

            // Show confirmation with app name
            if let appName = NSWorkspace.shared.frontmostApplication?.localizedName {
                showNotification(title: "BongoCat Hidden", message: "Cat will now hide when \(appName) is active")
            }
        }
    }

    @objc internal func showForCurrentApp() {
        let currentApp = getCurrentActiveApp()
        if currentApp != "unknown" {
            perAppHiddenApps.remove(currentApp)
            savePerAppHiding()

            if isPerAppHidingEnabled {
                overlayWindow?.showWindow()
                analytics.trackVisibilityToggled(true, method: "show_for_current_app")
            }

            updateHiddenAppsMenuItems()

            // Track app hidden status change
            analytics.trackAppHiddenStatusChanged(currentApp, hidden: false)
            trackFeatureUsed("show_for_current_app")

            print("Removed \(currentApp) from hidden apps list")

            // Show confirmation with app name
            if let appName = NSWorkspace.shared.frontmostApplication?.localizedName {
                showNotification(title: "BongoCat Visible", message: "Cat will now show when \(appName) is active")
            }
        }
    }

    @objc internal func manageHiddenApps() {
        // Track feature usage
        trackFeatureUsed("manage_hidden_apps")
        analytics.trackMenuAction("manage_hidden_apps")

        let alert = NSAlert()
        alert.messageText = "Manage Hidden Apps"

        if perAppHiddenApps.isEmpty {
            alert.informativeText = "No apps are currently set to hide the cat.\n\nTo hide the cat for specific apps:\n1. Switch to the app you want to hide the cat for\n2. Use 'Hide Cat for Current App' from the menu\n\nOr enable 'Per-App Hiding' and the hide/show options will become available."
            alert.addButton(withTitle: "OK")
        } else {
            var appNames: [String] = []
            for bundleID in perAppHiddenApps {
                // Try to find the app name for this bundle ID
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
                   let bundle = Bundle(url: url),
                   let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                    appNames.append("\(appName) (\(bundleID))")
                } else {
                    appNames.append(bundleID)
                }
            }

            alert.informativeText = "The following apps are set to hide the cat:\n\n• \(appNames.joined(separator: "\n• "))\n\nTo remove apps from this list, switch to the app and use 'Show Cat for Current App' from the menu."
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Clear All")
        }

        alert.alertStyle = .informational

        let response = alert.runModal()
                if response == .alertSecondButtonReturn && !perAppHiddenApps.isEmpty {
            // Clear all hidden apps
            perAppHiddenApps.removeAll()
            savePerAppHiding()
            updateHiddenAppsMenuItems()

            // Show the cat since no apps are hidden now
            if isPerAppHidingEnabled {
                overlayWindow?.showWindow()
                analytics.trackVisibilityToggled(true, method: "clear_all_hidden_apps")
            }

            // Track clearing all hidden apps
            analytics.trackAdvancedFeatureUsage("clear_all_hidden_apps", complexity: "basic", success: true)
            trackFeatureUsed("clear_all_hidden_apps")

            print("Cleared all hidden apps")
            showNotification(title: "Hidden Apps Cleared", message: "Cat will now show for all applications")
        }
    }

    private func updatePerAppPositioningMenuItem() {
        guard let menu = statusBarItem?.menu else { return }

        // Find the position submenu and update the per-app positioning item
        for item in menu.items {
            if item.title == "Position", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Per-App Positioning" {
                        subItem.state = isPerAppPositioningEnabled ? .on : .off
                        break
                    }
                }
                break
            }
        }
    }

    private func updatePerAppHidingMenuItem() {
        guard let menu = statusBarItem?.menu else { return }

        // Find the app visibility submenu and update the per-app hiding item
        for item in menu.items {
            if item.title == "App Visibility", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Per-App Hiding" {
                        subItem.state = isPerAppHidingEnabled ? .on : .off
                        break
                    }
                }
                break
            }
        }
    }

    private func updateHiddenAppsMenuItems() {
        guard let menu = statusBarItem?.menu else { return }
        let currentApp = getCurrentActiveApp()
        let isCurrentAppHidden = perAppHiddenApps.contains(currentApp)

        // Find the app visibility submenu and update the hide/show items
        for item in menu.items {
            if item.title == "App Visibility", let submenu = item.submenu {
                for subItem in submenu.items {
                    if subItem.title == "Hide Cat for Current App" {
                        subItem.isEnabled = !isCurrentAppHidden && currentApp != "unknown"
                    } else if subItem.title == "Show Cat for Current App" {
                        subItem.isEnabled = isCurrentAppHidden && currentApp != "unknown"
                    }
                }
                break
            }
        }
    }

    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver notification: \(error)")
            }
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Update stroke counter display when menu is about to open
        updateStrokeCounterMenuItem()

        // Update per-app hiding menu items based on current app
        updateHiddenAppsMenuItems()
    }

    // MARK: - App Lifecycle Tracking

    private func setupAppLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Track system sleep/wake if available
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func applicationDidBecomeActive() {
        analytics.trackAppBecameActive()
    }

    @objc private func applicationDidResignActive() {
        analytics.trackAppBecameInactive()
    }

    @objc private func systemWillSleep() {
        analytics.trackSystemSleepDetected()
    }

    @objc private func systemDidWake() {
        analytics.trackSystemWakeDetected()
    }

    // MARK: - Settings Tracking

    private func trackCurrentSettingsCombination() {
        let settings: [String: Any] = [
            "scale": currentScale,
            "scale_on_input": scaleOnInputEnabled,
            "rotation": currentRotation,
            "horizontal_flip": isFlippedHorizontally,
            "ignore_clicks": ignoreClicksEnabled,
            "click_through": clickThroughEnabled,
            "paw_behavior": pawBehaviorMode.rawValue,
            "auto_start_at_launch": autoStartAtLaunchEnabled,
            "per_app_positioning": isPerAppPositioningEnabled,
            "per_app_hiding": isPerAppHidingEnabled,
            "corner_position": currentCornerPosition.rawValue
        ]
        analytics.trackSettingsCombination(settings)
    }

    private func trackFeatureUsed(_ featureName: String) {
        if !featuresUsedThisSession.contains(featureName) {
            featuresUsedThisSession.append(featureName)
            analytics.trackFirstTimeFeatureUsed(featureName)
        }
    }

    private func trackSettingChanged(_ settingName: String) {
        if !settingsChangedThisSession.contains(settingName) {
            settingsChangedThisSession.append(settingName)
        }
    }

        // MARK: - Auto-Update Menu Action

    @objc private func toggleAutoUpdate(_ sender: NSMenuItem) {
        let newState = !UpdateChecker.shared.isAutoUpdateEnabled()
        UpdateChecker.shared.setAutoUpdateEnabled(newState)
        sender.state = newState ? .on : .off

        // Show user feedback
        let alert = NSAlert()
        alert.messageText = "Auto-Update \(newState ? "Enabled" : "Disabled")"
        alert.informativeText = newState ?
            "BongoCat will automatically download and install updates when available." :
            "Updates will require manual download from the GitHub releases page."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc internal func toggleAutoStartAtLaunch() {
        autoStartAtLaunchEnabled.toggle()
        saveAutoStartAtLaunchPreference()
        updateAutoStartAtLaunchMenuItem()

        // Apply the auto-start setting
        if autoStartAtLaunchEnabled {
            enableAutoStartAtLaunch()
        } else {
            disableAutoStartAtLaunch()
        }

        // Track setting toggle
        analytics.trackSettingToggled("auto_start_at_launch", enabled: autoStartAtLaunchEnabled)
        trackSettingChanged("auto_start_at_launch")
        trackFeatureUsed("auto_start_at_launch")

        print("Auto-start at launch toggled to: \(autoStartAtLaunchEnabled)")
    }

    // MARK: - Preferences Window

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(appDelegate: self)
        }

        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    internal func openPreferencesPublic() {
        openPreferences()
    }

    // MARK: - Welcome Screen

    @objc private func showWelcomeGuide() {
        if welcomeScreenController == nil {
            welcomeScreenController = WelcomeScreenController(appDelegate: self)
        }

        welcomeScreenController?.showWelcomeScreen()

        // Track welcome guide access
        analytics.trackMenuAction("show_welcome_guide")
        trackFeatureUsed("welcome_guide")
    }

    internal func showWelcomeGuidePublic() {
        showWelcomeGuide()
    }

        private func shouldShowWelcomeScreen() -> Bool {
        // Check if this is the first launch
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "BongoCatHasLaunchedBefore")

        if !hasLaunchedBefore {
            // Mark as launched
            UserDefaults.standard.set(true, forKey: "BongoCatHasLaunchedBefore")
            return true
        }

        // Also show if accessibility is not enabled (for existing users)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !isAccessibilityEnabled {
            return true
        }

        return false
    }

    private func showWelcomeScreenIfNeeded() {
        if shouldShowWelcomeScreen() {
            // Show welcome screen after a short delay to ensure app is fully initialized
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showWelcomeGuide()
            }
        }
    }

    // For testing purposes - reset first launch flag
    internal func resetFirstLaunchFlag() {
        UserDefaults.standard.removeObject(forKey: "BongoCatHasLaunchedBefore")
        print("First launch flag reset - welcome screen will show on next launch")
    }

        // MARK: - Additional Helper Methods

    func updateOverlay() {
        overlayWindow?.updateScale(currentScale)
        overlayWindow?.updateRotation(currentRotation)
        overlayWindow?.updateFlip(isFlippedHorizontally)
    }

    func updateOverlayClickThrough() {
        overlayWindow?.updateIgnoreMouseEvents(clickThroughEnabled)
    }

    func setPosition(to corner: CornerPosition) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        var newPosition: NSPoint

        switch corner {
        case .topLeft:
            newPosition = NSPoint(x: screenFrame.minX + 20, y: screenFrame.maxY - 120)
        case .topRight:
            newPosition = NSPoint(x: screenFrame.maxX - 120, y: screenFrame.maxY - 120)
        case .bottomLeft:
            newPosition = NSPoint(x: screenFrame.minX + 20, y: screenFrame.minY + 20)
        case .bottomRight:
            newPosition = NSPoint(x: screenFrame.maxX - 120, y: screenFrame.minY + 20)
        case .custom:
            return // Don't change position for custom
        }

        overlayWindow?.setPositionProgrammatically(newPosition)
        savedPosition = newPosition
        savePositionPreferences()
    }

    // MARK: - Auto-Start at Launch Management

    private func enableAutoStartAtLaunch() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("❌ Failed to get bundle identifier for auto-start")
            return
        }

        // Try using the modern SMAppService API first (macOS 13.0+)
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                try service.register()
                print("✅ Auto-start enabled using SMAppService")
            } catch {
                print("❌ Failed to enable auto-start with SMAppService: \(error)")
                // Fallback to legacy method
                enableAutoStartAtLaunchLegacy()
            }
        } else {
            // Fallback to legacy method for older macOS versions
            enableAutoStartAtLaunchLegacy()
        }
    }

    private func disableAutoStartAtLaunch() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("❌ Failed to get bundle identifier for auto-start")
            return
        }

        // Try using the modern SMAppService API first (macOS 13.0+)
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                try service.unregister()
                print("✅ Auto-start disabled using SMAppService")
            } catch {
                print("❌ Failed to disable auto-start with SMAppService: \(error)")
                // Fallback to legacy method
                disableAutoStartAtLaunchLegacy()
            }
        } else {
            // Fallback to legacy method for older macOS versions
            disableAutoStartAtLaunchLegacy()
        }
    }

    private func enableAutoStartAtLaunchLegacy() {
        // Legacy method using launchd
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            make login item at end with properties {path:"\(appPath)", hidden:false}
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                print("✅ Auto-start enabled using legacy method")
            } else {
                print("❌ Failed to enable auto-start using legacy method")
            }
        } catch {
            print("❌ Error enabling auto-start using legacy method: \(error)")
        }
    }

    private func disableAutoStartAtLaunchLegacy() {
        // Legacy method using launchd
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            delete login item "\(appPath)"
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                print("✅ Auto-start disabled using legacy method")
            } else {
                print("❌ Failed to disable auto-start using legacy method")
            }
        } catch {
            print("❌ Error disabling auto-start using legacy method: \(error)")
        }
    }

    private func isAutoStartAtLaunchEnabled() -> Bool {
        // Check if the app is in login items
        let appPath = Bundle.main.bundlePath
        let script = """
        tell application "System Events"
            return exists login item "\(appPath)"
        end tell
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]

        do {
            let pipe = Pipe()
            task.standardOutput = pipe
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return output == "true"
        } catch {
            print("❌ Error checking auto-start status: \(error)")
            return false
        }
    }

    private func syncAutoStartState() {
        // Check if the system state matches our saved preference
        let systemEnabled = isAutoStartAtLaunchEnabled()

        if systemEnabled != autoStartAtLaunchEnabled {
            print("🔄 Auto-start state mismatch detected - system: \(systemEnabled), saved: \(autoStartAtLaunchEnabled)")

            // Update our saved preference to match the system state
            autoStartAtLaunchEnabled = systemEnabled
            saveAutoStartAtLaunchPreference()
            updateAutoStartAtLaunchMenuItem()

            print("✅ Auto-start state synced with system")
        }
    }
}
