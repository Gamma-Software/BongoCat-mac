import Cocoa
import SwiftUI

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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("BangoCat starting...")
        loadSavedScale()
        loadScaleOnInputPreference()
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
            button.title = "🐱"
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
        scaleSubmenu.addItem(NSMenuItem(title: "50%", action: #selector(setScale050), keyEquivalent: ""))
        scaleSubmenu.addItem(NSMenuItem(title: "75%", action: #selector(setScale075), keyEquivalent: ""))
        scaleSubmenu.addItem(NSMenuItem(title: "100%", action: #selector(setScale100), keyEquivalent: ""))

        let scaleMenuItem = NSMenuItem(title: "Scale", action: nil, keyEquivalent: "")
        scaleMenuItem.submenu = scaleSubmenu
        menu.addItem(scaleMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Scale pulse option
        menu.addItem(NSMenuItem(title: "Scale Pulse on Input", action: #selector(toggleScalePulse), keyEquivalent: ""))

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
        print("🔧 Status bar setup complete")
    }

    private func setupOverlayWindow() {
        overlayWindow = OverlayWindow()
        overlayWindow?.showWindow()
        overlayWindow?.updateScale(currentScale)  // Apply the loaded scale
        overlayWindow?.catAnimationController?.setScaleOnInputEnabled(scaleOnInputEnabled)  // Apply pulse preference
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

    private func saveScale() {
        UserDefaults.standard.set(currentScale, forKey: scaleKey)
        print("Saved scale: \(currentScale)")
    }

    private func saveScaleOnInputPreference() {
        UserDefaults.standard.set(scaleOnInputEnabled, forKey: scaleOnInputKey)
        print("Saved scale on input preference: \(scaleOnInputEnabled)")
    }

    @objc private func setScale050() {
        setScale(0.5)
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
}