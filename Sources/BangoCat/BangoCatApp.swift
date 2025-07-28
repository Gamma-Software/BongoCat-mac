import Cocoa
import SwiftUI
import UserNotifications

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

    // App information
    private let appVersion = "1.4.2"
    private let appBuild = "1.4.2.202507281145"
    private let appAuthor = "Valentin Rudloff"
    private let appWebsite = "https://valentin.pival.fr"

    // Scale management
    @Published var currentScale: Double = 1.0
    private let scaleKey = "BangoCatScale"

    // Scale pulse on input management
    @Published var scaleOnInputEnabled: Bool = true
    private let scaleOnInputKey = "BangoCatScaleOnInput"

    // Rotation management
    @Published var currentRotation: Double = 0.0
    private let rotationKey = "BangoCatRotation"

    // Horizontal flip management
    @Published var isFlippedHorizontally: Bool = false
    private let flipKey = "BangoCatFlipHorizontally"

    // Ignore clicks management
    @Published var ignoreClicksEnabled: Bool = false
    private let ignoreClicksKey = "BangoCatIgnoreClicks"

    // Click through management
    @Published var clickThroughEnabled: Bool = true  // Default enabled
    private let clickThroughKey = "BangoCatClickThrough"

    // Paw behavior management
    @Published var pawBehaviorMode: PawBehaviorMode = .keyboardLayout  // Default to keyboard layout
    private let pawBehaviorKey = "BangoCatPawBehavior"

    // Position management - Enhanced for per-app positioning
    private var snapToCornerEnabled: Bool = false
    private let snapToCornerKey = "BangoCatSnapToCorner"
    private var savedPosition: NSPoint = NSPoint(x: 100, y: 100)
    private let savedPositionXKey = "BangoCatPositionX"
    private let savedPositionYKey = "BangoCatPositionY"
    @Published var currentCornerPosition: CornerPosition = .custom
    private let cornerPositionKey = "BangoCatCornerPosition"

    // Per-app position management
    @Published internal var perAppPositions: [String: NSPoint] = [:]
    private let perAppPositionsKey = "BangoCatPerAppPositions"
    internal var currentActiveApp: String = ""
    private var appSwitchTimer: Timer?
    @Published internal var isPerAppPositioningEnabled: Bool = true
    private let perAppPositioningKey = "BangoCatPerAppPositioning"

    // Per-app hiding management
    @Published internal var perAppHiddenApps: Set<String> = []
    private let perAppHiddenAppsKey = "BangoCatPerAppHiddenApps"
    @Published internal var isPerAppHidingEnabled: Bool = false
    private let perAppHidingKey = "BangoCatPerAppHiding"

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
        print("BangoCat starting...")
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

        // Track initial settings combination
        trackCurrentSettingsCombination()

        // Set up app lifecycle notifications
        setupAppLifecycleNotifications()
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
            // Try to load the bongo-simple.png file
            if let iconImage = loadStatusBarIcon() {
                button.image = iconImage
                button.imagePosition = .imageOnly
                print("🔧 Status bar icon loaded from bongo-simple.png")
            } else {
                // Fallback to emoji if icon loading fails
                button.title = "🐱"
                print("🔧 Fallback to emoji icon")
            }

            button.toolTip = "BangoCat - Click for menu"
            print("🔧 Status bar button configured")
        } else {
            print("❌ Failed to get status bar button")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())

        // Scale submenu
        let scaleSubmenu = NSMenu()
        scaleSubmenu.addItem(NSMenuItem(title: "Small", action: #selector(setScale065), keyEquivalent: ""))
        scaleSubmenu.addItem(NSMenuItem(title: "Medium", action: #selector(setScale075), keyEquivalent: ""))
        scaleSubmenu.addItem(NSMenuItem(title: "Big", action: #selector(setScale100), keyEquivalent: ""))

        let scaleMenuItem = NSMenuItem(title: "Scale", action: nil, keyEquivalent: "")
        scaleMenuItem.submenu = scaleSubmenu
        menu.addItem(scaleMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Scale pulse option
        menu.addItem(NSMenuItem(title: "Scale Pulse on Input", action: #selector(toggleScalePulse), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Bango cat rotate option
        menu.addItem(NSMenuItem(title: "Bango Cat Rotate", action: #selector(toggleBangoCatRotate), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Horizontal flip option
        menu.addItem(NSMenuItem(title: "Flip Horizontally", action: #selector(toggleHorizontalFlip), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Paw behavior submenu
        let pawBehaviorSubmenu = NSMenu()
        pawBehaviorSubmenu.addItem(NSMenuItem(title: "Keyboard Layout", action: #selector(setPawBehaviorKeyboardLayout), keyEquivalent: ""))
        pawBehaviorSubmenu.addItem(NSMenuItem(title: "Random", action: #selector(setPawBehaviorRandom), keyEquivalent: ""))
        pawBehaviorSubmenu.addItem(NSMenuItem(title: "Alternating", action: #selector(setPawBehaviorAlternating), keyEquivalent: ""))

        let pawBehaviorMenuItem = NSMenuItem(title: "Paw Behavior", action: nil, keyEquivalent: "")
        pawBehaviorMenuItem.submenu = pawBehaviorSubmenu
        menu.addItem(pawBehaviorMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Ignore clicks option
        menu.addItem(NSMenuItem(title: "Ignore Clicks", action: #selector(toggleIgnoreClicks), keyEquivalent: ""))

        // Click through option
        menu.addItem(NSMenuItem(title: "Click Through (Hold ⌘ to Drag)", action: #selector(toggleClickThrough), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Stroke counter section
        let strokeCounterItem = NSMenuItem(title: "Loading stroke count...", action: nil, keyEquivalent: "")
        strokeCounterItem.tag = 999 // Special tag to identify this item for updates
        menu.addItem(strokeCounterItem)
        menu.addItem(NSMenuItem(title: "Reset Stroke Counter", action: #selector(resetStrokeCounter), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Milestone notifications section
        menu.addItem(NSMenuItem(title: "Milestone Notifications 🔔", action: #selector(toggleMilestoneNotifications), keyEquivalent: ""))
                menu.addItem(NSMenuItem(title: "Update Notifications 🔄", action: #selector(toggleUpdateNotifications), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Auto-Update ⚡", action: #selector(toggleAutoUpdate), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Analytics settings
        menu.addItem(NSMenuItem(title: "Analytics & Privacy 📊", action: #selector(toggleAnalytics), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        // Position submenu
        let positionSubmenu = NSMenu()

        // Corner position options
        for corner in CornerPosition.allCases {
            if corner != .custom {
                let item = NSMenuItem(title: corner.displayName, action: #selector(setCornerPosition(_:)), keyEquivalent: "")
                item.representedObject = corner
                positionSubmenu.addItem(item)
            }
        }

        positionSubmenu.addItem(NSMenuItem.separator())
        positionSubmenu.addItem(NSMenuItem(title: "Per-App Positioning", action: #selector(togglePerAppPositioning), keyEquivalent: ""))
        positionSubmenu.addItem(NSMenuItem.separator())
        positionSubmenu.addItem(NSMenuItem(title: "Save Current Position", action: #selector(saveCurrentPositionAction), keyEquivalent: ""))
        positionSubmenu.addItem(NSMenuItem(title: "Restore Saved Position", action: #selector(restoreSavedPosition), keyEquivalent: ""))

        let positionMenuItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        positionMenuItem.submenu = positionSubmenu
        menu.addItem(positionMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Per-app hiding submenu
        let hidingSubmenu = NSMenu()
        hidingSubmenu.addItem(NSMenuItem(title: "Per-App Hiding", action: #selector(togglePerAppHiding), keyEquivalent: ""))
        hidingSubmenu.addItem(NSMenuItem.separator())
        hidingSubmenu.addItem(NSMenuItem(title: "Hide Cat for Current App", action: #selector(hideForCurrentApp), keyEquivalent: ""))
        hidingSubmenu.addItem(NSMenuItem(title: "Show Cat for Current App", action: #selector(showForCurrentApp), keyEquivalent: ""))
        hidingSubmenu.addItem(NSMenuItem.separator())
        hidingSubmenu.addItem(NSMenuItem(title: "Manage Hidden Apps...", action: #selector(manageHiddenApps), keyEquivalent: ""))

        let hidingMenuItem = NSMenuItem(title: "App Visibility", action: nil, keyEquivalent: "")
        hidingMenuItem.submenu = hidingSubmenu
        menu.addItem(hidingMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reset to Factory Defaults", action: #selector(resetToFactoryDefaults), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Buy me a coffee ☕", action: #selector(buyMeACoffee), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Tweet about BangoCat 🐦", action: #selector(tweetAboutBangoCat), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Visit Website", action: #selector(visitWebsite), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "View Changelog 📋", action: #selector(viewChangelog), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check for Updates 🔄", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Report a Bug 🐛", action: #selector(reportBug), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "About BangoCat", action: #selector(showCredits), keyEquivalent: ""))

        // Developer options (only show if analytics debug is needed)
        #if DEBUG
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "🔧 Analytics Status", action: #selector(showAnalyticsStatus), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "🧪 Test Analytics", action: #selector(testAnalytics), keyEquivalent: ""))
        #endif

        // Version info
        let versionItem = NSMenuItem(title: "Version \(getVersionString())", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false // Make it non-clickable
        menu.addItem(versionItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit BangoCat", action: #selector(quitApp), keyEquivalent: "q"))

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

        // Set initial checkmarks
        updateScaleMenuItems()
        updateScalePulseMenuItem()
        updatePositionMenuItems()
        updateRotationMenuItem()
        updateFlipMenuItem()
        updatePawBehaviorMenuItems()
        updateIgnoreClicksMenuItem()
        updateClickThroughMenuItem()
        updatePerAppPositioningMenuItem()

        // Update stroke counter after a short delay to ensure overlay window is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateStrokeCounterMenuItem()
        }

        // Update milestone notifications menu item
        updateMilestoneNotificationsMenuItem()
        updateUpdateNotificationsMenuItem()
        updateAutoUpdateMenuItem()
        updateAnalyticsMenuItem()

        print("🔧 Status bar setup complete")
    }

    private func loadStatusBarIcon() -> NSImage? {
        // Method 1: Try Bundle.module (for Swift Package Manager)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "bongo-simple", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return resizeIconForStatusBar(image, fromPath: "Bundle.module: bongo-simple.png")
        }
        #endif

        // Method 2: Try Bundle.main.path (for packaged app)
        if let bundlePath = Bundle.main.path(forResource: "bongo-simple", ofType: "png"),
           let bundleImage = NSImage(contentsOfFile: bundlePath) {
            return resizeIconForStatusBar(bundleImage, fromPath: "Bundle.main path: \(bundlePath)")
        }

        // Method 3: Try NSImage named loading (without extension)
        if let bundleImage = NSImage(named: "bongo-simple") {
            return resizeIconForStatusBar(bundleImage, fromPath: "NSImage named resource")
        }

        // Method 4: Try direct file paths (development fallback)
        let iconPaths = [
            "bongo-simple.png",
            "./bongo-simple.png",
            "Sources/BangoCat/Resources/bongo-simple.png"
        ]

        for path in iconPaths {
            if let image = NSImage(contentsOfFile: path) {
                return resizeIconForStatusBar(image, fromPath: "file path: \(path)")
            }
        }

        // Method 5: Try loading from current working directory
        let currentDir = FileManager.default.currentDirectoryPath
        let currentDirPath = "\(currentDir)/bongo-simple.png"
        if let image = NSImage(contentsOfFile: currentDirPath) {
            return resizeIconForStatusBar(image, fromPath: "current dir: \(currentDirPath)")
        }

        print("❌ Failed to load bongo-simple.png from all attempted methods")
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
        BangoCat needs accessibility access to detect your keyboard input.

        If you already granted access but still see this message, try:
        1. Remove BangoCat from Accessibility list in System Preferences
        2. Re-add it by running the app again

        This happens when running from different build locations.
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
        alert.informativeText = "This will reset all BangoCat settings to their default values:\n\n• Scale: 100%\n• Scale Pulse: Enabled\n• Rotation: Disabled\n• Flip: Disabled\n• Ignore Clicks: Disabled\n• Click Through: Enabled\n• Position: Default location\n• Per-App Positioning: Disabled\n• Per-App Hiding: Disabled (all hidden apps cleared)\n• Stroke Counter: Will be reset\n\nThis action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Track factory reset
            analytics.trackFactoryResetPerformed()
            trackFeatureUsed("factory_reset")

            // Reset all settings to factory defaults
            currentScale = 1.0
            scaleOnInputEnabled = true
            currentRotation = 0.0
            isFlippedHorizontally = false
            ignoreClicksEnabled = false
            clickThroughEnabled = true
            pawBehaviorMode = .keyboardLayout
            savedPosition = NSPoint(x: 100, y: 100)
            currentCornerPosition = .custom
            snapToCornerEnabled = false
            isPerAppPositioningEnabled = false
            perAppPositions.removeAll()
            isPerAppHidingEnabled = false
            perAppHiddenApps.removeAll()

            // Save all the reset values
            saveScale()
            saveScaleOnInputPreference()
            saveRotation()
            saveFlip()
            saveIgnoreClicksPreference()
            saveClickThroughPreference()
            savePawBehaviorPreference()
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
            updateStrokeCounterMenuItem()

            print("All settings reset to factory defaults")

            // Show confirmation
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Settings Reset"
            confirmAlert.informativeText = "All BangoCat settings have been reset to factory defaults."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()
        }
    }

    @objc private func showCredits() {
        // Track menu action
        analytics.trackMenuAction("show_credits")

        let alert = NSAlert()
        alert.messageText = "About BangoCat \(getVersionString())"
        alert.informativeText = """
        🐱 BangoCat for macOS 🐱

        Version: \(getVersionString())
        Bundle ID: \(getBundleIdentifier())

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        Created with ❤️ by \(appAuthor)
        Website: \(appWebsite)
        🐛 Report Bug: github.com/Gamma-Software/BangoCat-mac/issues/new

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

    @objc internal func tweetAboutBangoCat() {
        // Track social share
        analytics.trackMenuAction("tweet_about_bangocat")
        analytics.trackSocialShareInitiated("twitter")
        trackFeatureUsed("social_share")

        let tweetText = "Just discovered BangoCat for macOS! A Bango Cat overlay for your Mac - reacts to typing and clicks in real-time! Perfect for streamers and developers ✨ #BangoCat #macOS #Swift #OpenSource\n\nDownload: https://github.com/Gamma-Software/BangoCat-mac/releases/tag/v1.0.0\nSee it in action: https://youtu.be/ZFw8m6V3qRQ"
        if let encodedText = tweetText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let tweetURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            NSWorkspace.shared.open(tweetURL)
            print("Opening Tweet about BangoCat: \(tweetURL)")
        } else {
            print("Failed to create Tweet URL")
        }
    }

    @objc internal func reportBug() {
        // Track support action
        analytics.trackMenuAction("report_bug")
        analytics.trackSupportActionTaken("bug_report")
        trackFeatureUsed("bug_report")

        if let url = URL(string: "https://github.com/Gamma-Software/BangoCat-mac/issues/new") {
            NSWorkspace.shared.open(url)
            print("Opening bug report: https://github.com/Gamma-Software/BangoCat-mac/issues/new")
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
        alert.messageText = "BangoCat Changelog"

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
            📋 BangoCat v\(getVersionString()) - Recent Changes:

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
            if let url = URL(string: "https://github.com/Gamma-Software/BangoCat-mac/blob/develop/CHANGELOG.md") {
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
        return Bundle.main.bundleIdentifier ?? "com.bangocat.mac"
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

    func toggleBangoCatRotatePublic() {
        toggleBangoCatRotate()
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

    func tweetAboutBangoCatPublic() {
        tweetAboutBangoCat()
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

        Once configured, BangoCat will track anonymous usage data to help improve the app.
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
            currentScale = 1.0 // Default scale
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
            pawBehaviorMode = .keyboardLayout // Default to keyboard layout
        }
        print("Loaded paw behavior preference: \(pawBehaviorMode.displayName)")
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

    // MARK: - Bango Cat Rotate Management

    @objc private func toggleBangoCatRotate() {
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

        print("Bango Cat rotated to: \(currentRotation) degrees")
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
        BangoCat uses analytics to improve the app experience by tracking:

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
        • Data helps improve BangoCat for everyone

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
                "Thank you! Analytics will help us improve BangoCat." :
                "Analytics has been disabled. You can re-enable it anytime from the menu."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()

            print("Analytics toggled to: \(newState)")
        } else if response == .alertThirdButtonReturn {
            // Learn more - open privacy policy or GitHub
            if let url = URL(string: "https://github.com/Gamma-Software/BangoCat-mac#privacy") {
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

    private func updateRotationMenuItem() {
        guard let menu = statusBarItem?.menu else { return }
        for item in menu.items {
            if item.title == "Bango Cat Rotate" {
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

    private func getCornerPosition(for corner: CornerPosition) -> NSPoint {
        guard let screen = NSScreen.main else {
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

    internal func loadPerAppPositioning() {
        // Load per-app positioning preference
        if UserDefaults.standard.object(forKey: perAppPositioningKey) != nil {
            isPerAppPositioningEnabled = UserDefaults.standard.bool(forKey: perAppPositioningKey)
        } else {
            isPerAppPositioningEnabled = false // Default disabled
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
            isPerAppHidingEnabled = false // Default disabled
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
        appSwitchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
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
                print("🆕 No saved position for \(newApp), using current position")
                // Optionally, you could set a default position here
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
                showNotification(title: "BangoCat Hidden", message: "Cat will now hide when \(appName) is active")
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
                showNotification(title: "BangoCat Visible", message: "Cat will now show when \(appName) is active")
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
            "BangoCat will automatically download and install updates when available." :
            "Updates will require manual download from the GitHub releases page."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
}