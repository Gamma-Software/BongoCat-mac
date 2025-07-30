import Foundation
import SwiftUI
import AppKit

// MARK: - Plugin Integration
class PluginIntegration {
    static let shared = PluginIntegration()

    private let pluginManager = AccessoryPluginManager.shared
    private let renderer = AccessoryPluginRenderer.shared

    private init() {}

    // MARK: - Cat View Integration

    func integrateWithCatView(_ catView: BangoCatSprite, state: CatState) -> some View {
        return renderer.renderAccessories(for: catView, state: state)
    }

    // MARK: - Menu Integration

    func setupAccessoriesMenu(for appDelegate: AppDelegate) {
        let accessoriesMenu = NSMenu()

        // Available accessories
        for plugin in pluginManager.availablePlugins {
            let item = NSMenuItem(title: plugin.name, action: #selector(appDelegate.toggleAccessory(_:)), keyEquivalent: "")
            item.representedObject = plugin.id
            item.state = pluginManager.isPluginEnabled(plugin.id) ? .on : .off
            accessoriesMenu.addItem(item)
        }

        accessoriesMenu.addItem(NSMenuItem.separator())

        // Accessory store
        let storeItem = NSMenuItem(title: "Accessory Store...", action: #selector(appDelegate.openAccessoryStore), keyEquivalent: "")
        accessoriesMenu.addItem(storeItem)

        // Add to main menu
        if let mainMenu = NSApp.mainMenu {
            let accessoriesMenuItem = NSMenuItem(title: "Accessories", action: nil, keyEquivalent: "")
            accessoriesMenuItem.submenu = accessoriesMenu
            mainMenu.addItem(accessoriesMenuItem)
        }
    }

    // MARK: - Context Menu Integration

    func addAccessoriesToContextMenu(_ menu: NSMenu) {
        let enabledPlugins = pluginManager.getEnabledPlugins()

        if !enabledPlugins.isEmpty {
            menu.addItem(NSMenuItem.separator())

            let accessoriesItem = NSMenuItem(title: "Accessories", action: nil, keyEquivalent: "")
            let accessoriesSubmenu = NSMenu()

            for plugin in enabledPlugins {
                let item = NSMenuItem(title: plugin.name, action: #selector(AppDelegate.toggleAccessory(_:)), keyEquivalent: "")
                item.representedObject = plugin.id
                item.state = pluginManager.isPluginEnabled(plugin.id) ? .on : .off
                accessoriesSubmenu.addItem(item)
            }

            accessoriesItem.submenu = accessoriesSubmenu
            menu.addItem(accessoriesItem)
        }
    }
}

// MARK: - App Delegate Extensions
extension AppDelegate {

        @objc func toggleAccessory(_ sender: NSMenuItem) {
        guard let pluginId = sender.representedObject as? String else { return }

        let pluginManager = AccessoryPluginManager.shared
        if pluginManager.isPluginEnabled(pluginId) {
            pluginManager.disablePlugin(pluginId)
            sender.state = .off
        } else {
            pluginManager.enablePlugin(pluginId)
            sender.state = .on
        }

        // Update the cat view to reflect changes
        updateCatViewWithAccessories()
    }

    @objc func openAccessoryStore() {
        let storeController = AccessoryStoreWindowController()
        storeController.showWindow(nil)
        storeController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateCatViewWithAccessories() {
        // Trigger a redraw of the cat view with accessories
        overlayWindow?.updateCatView()
    }
}

// MARK: - Overlay Window Extensions
extension OverlayWindow {

    func updateCatView() {
        // This will be called when accessories are toggled
        // The cat view will automatically re-render with the new accessory state
        if let catView = window?.contentView?.subviews.first(where: { $0 is NSHostingView<CatView> }) as? NSHostingView<CatView> {
            catView.rootView = CatView()
        }
    }
}



// MARK: - Plugin State Management Extensions
extension AppDelegate {

    func loadPluginPreferences() {
        // Plugin states are automatically loaded by the plugin manager
        // This is called during app initialization
        print("🔌 Plugin preferences loaded")
    }

    func savePluginPreferences() {
        // Plugin states are automatically saved by the plugin manager
        // This is called when the app terminates
        print("🔌 Plugin preferences saved")
    }

    func resetPluginPreferences() {
        // Clear all plugin states
        let pluginManager = AccessoryPluginManager.shared
        pluginManager.pluginStates.removeAll()
        // Note: savePluginStates is private, so we can't call it directly
        print("🔌 Plugin preferences reset")
    }
}

// MARK: - Analytics Extensions
extension PostHogAnalyticsManager {

    func trackAccessoryUsage(_ pluginId: String, action: String) {
        track(event: "accessory_usage", properties: [
            "plugin_id": pluginId,
            "action": action
        ])
    }

    func trackAccessoryStoreOpened() {
        track(event: "accessory_store_opened")
    }

    func trackAccessoryPurchaseAttempt(_ pluginId: String) {
        track(event: "accessory_purchase_attempt", properties: [
            "plugin_id": pluginId
        ])
    }
}