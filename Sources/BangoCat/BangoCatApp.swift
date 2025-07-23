import Cocoa
import SwiftUI

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

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: OverlayWindow?
    var inputMonitor: InputMonitor?
    var statusBarItem: NSStatusItem?

    // Scale management
    private var currentScale: Double = 1.0
    private let scaleKey = "BangoCatScale"

    // Scale pulse on input management
    private var scaleOnInputEnabled: Bool = true
    private let scaleOnInputKey = "BangoCatScaleOnInput"

    // Rotation management
    private var currentRotation: Double = 0.0
    private let rotationKey = "BangoCatRotation"

    // Position management
    private var snapToCornerEnabled: Bool = false
    private let snapToCornerKey = "BangoCatSnapToCorner"
    private var savedPosition: NSPoint = NSPoint(x: 100, y: 100)
    private let savedPositionXKey = "BangoCatPositionX"
    private let savedPositionYKey = "BangoCatPositionY"
    private var currentCornerPosition: CornerPosition = .custom
    private let cornerPositionKey = "BangoCatCornerPosition"

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("BangoCat starting...")
        loadSavedScale()
        loadScaleOnInputPreference()
        loadSavedRotation()
        loadPositionPreferences()
        setupStatusBarItem()
        setupOverlayWindow()
        setupInputMonitoring()
        requestAccessibilityPermissions()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        inputMonitor?.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            overlayWindow?.showWindow()
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
        positionSubmenu.addItem(NSMenuItem(title: "Save Current Position", action: #selector(saveCurrentPositionAction), keyEquivalent: ""))
        positionSubmenu.addItem(NSMenuItem(title: "Restore Saved Position", action: #selector(restoreSavedPosition), keyEquivalent: ""))

        let positionMenuItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        positionMenuItem.submenu = positionSubmenu
        menu.addItem(positionMenuItem)

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
        print("🔧 Menu attached to status bar item")

        // Set initial checkmarks
        updateScaleMenuItems()
        updateScalePulseMenuItem()
        updatePositionMenuItems()
        updateRotationMenuItem()
        print("🔧 Status bar setup complete")
    }

    private func loadStatusBarIcon() -> NSImage? {
        // First try to load from bundle resources (PNG format)
        if let bundlePath = Bundle.main.path(forResource: "bongo-simple", ofType: "png"),
           let bundleImage = NSImage(contentsOfFile: bundlePath) {
            return resizeIconForStatusBar(bundleImage, fromPath: "bundle: \(bundlePath)")
        }

        // Try NSImage named loading (without extension)
        if let bundleImage = NSImage(named: "bongo-simple") {
            return resizeIconForStatusBar(bundleImage, fromPath: "bundle named resource")
        }

        // Fallback to file system paths (for development)
        let iconPaths = [
            "bongo-simple.png",
            "./bongo-simple.png",
            "Sources/BangoCat/Resources/bongo-simple.png"
        ]

        for path in iconPaths {
            if let image = NSImage(contentsOfFile: path) {
                return resizeIconForStatusBar(image, fromPath: path)
            }
        }

        // Try loading from current working directory
        let currentDir = FileManager.default.currentDirectoryPath
        let currentDirPath = "\(currentDir)/bongo-simple.png"
        if let image = NSImage(contentsOfFile: currentDirPath) {
            return resizeIconForStatusBar(image, fromPath: currentDirPath)
        }

        print("❌ Failed to load bongo-simple.png from any path")
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
        overlayWindow?.showWindow()
        overlayWindow?.updateScale(currentScale)  // Apply the loaded scale
        overlayWindow?.updateRotation(currentRotation)  // Apply the loaded rotation
        overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)  // Apply pulse preference

        // Apply saved position
        overlayWindow?.window?.setFrameOrigin(savedPosition)

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
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Accessibility access required")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Access Required"
                alert.informativeText = "BangoCat needs accessibility access to detect your keyboard input. Please grant access in System Preferences."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Continue")

                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        } else {
            print("Accessibility access already granted")
        }
    }

    @objc private func toggleOverlay() {
        overlayWindow?.toggleVisibility()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
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

    private func saveScale() {
        UserDefaults.standard.set(currentScale, forKey: scaleKey)
        print("Saved scale: \(currentScale)")
    }

    private func saveScaleOnInputPreference() {
        UserDefaults.standard.set(scaleOnInputEnabled, forKey: scaleOnInputKey)
        print("Saved scale on input preference: \(scaleOnInputEnabled)")
    }

    private func saveRotation() {
        UserDefaults.standard.set(currentRotation, forKey: rotationKey)
        print("Saved rotation: \(currentRotation)")
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

    @objc private func toggleScalePulse() {
        scaleOnInputEnabled.toggle()
        saveScaleOnInputPreference()
        overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)  // Apply immediately
        updateScalePulseMenuItem()
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
        // Toggle between 0 degrees and 13 degrees rotation
        currentRotation = (currentRotation == 0.0) ? 13.0 : 0.0
        saveRotation()
        overlayWindow?.updateRotation(currentRotation)
        updateRotationMenuItem()
        print("Bango Cat rotated to: \(currentRotation) degrees")
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
        savedPosition = position
        currentCornerPosition = .custom
        savePositionPreferences()
        updatePositionMenuItems()
        print("Manual position saved: \(position)")
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

    private func savePositionPreferences() {
        UserDefaults.standard.set(snapToCornerEnabled, forKey: snapToCornerKey)
        UserDefaults.standard.set(savedPosition.x, forKey: savedPositionXKey)
        UserDefaults.standard.set(savedPosition.y, forKey: savedPositionYKey)
        UserDefaults.standard.set(currentCornerPosition.rawValue, forKey: cornerPositionKey)
        print("Saved position preferences - snap: \(snapToCornerEnabled), position: \(savedPosition), corner: \(currentCornerPosition)")
    }

    @objc private func saveCurrentPositionAction() {
        saveManualPosition(overlayWindow?.window?.frame.origin ?? NSPoint.zero)
    }

    @objc private func restoreSavedPosition() {
        overlayWindow?.window?.setFrameOrigin(savedPosition)
        currentCornerPosition = .custom // Assuming saved position is custom
        updatePositionMenuItems()
        print("Restored saved position: \(savedPosition)")
    }

    @objc private func setCornerPosition(_ sender: NSMenuItem) {
        guard let corner = sender.representedObject as? CornerPosition else { return }
        let position = getCornerPosition(for: corner)
        overlayWindow?.window?.setFrameOrigin(position)
        currentCornerPosition = corner
        saveManualPosition(position)
        updatePositionMenuItems()
        print("Moved cat to \(corner.displayName) at position: \(position)")
    }

    private func getCornerPosition(for corner: CornerPosition) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 100, y: 100)
        }

        let screenFrame = screen.visibleFrame
        let windowSize = overlayWindow?.window?.frame.size ?? NSSize(width: 175, height: 150)
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
}