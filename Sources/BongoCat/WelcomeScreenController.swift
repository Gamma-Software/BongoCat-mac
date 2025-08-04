import SwiftUI
import Cocoa

class WelcomeScreenController: NSWindowController, NSWindowDelegate {
    private var appDelegate: AppDelegate

        init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate

                // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "BongoCat Setup"
        window.center()
        window.isReleasedWhenClosed = false

        // Make it stay on top and not dismiss when clicking outside
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

                // Prevent the window from being hidden when clicking outside
        window.hidesOnDeactivate = false

        super.init(window: window)

        // Set window delegate to handle manual closing (after super.init)
        window.delegate = self

        // Create the SwiftUI view after super.init
        let welcomeView = WelcomeScreen(appDelegate: appDelegate) { [weak self] in
            // Dismiss callback
            self?.hideWelcomeScreen()
        }
        let hostingView = NSHostingView(rootView: welcomeView)
        window.contentView = hostingView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWelcomeScreen() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Make the app appear in the Dock when welcome screen is open
        NSApp.setActivationPolicy(.regular)
    }

    func hideWelcomeScreen() {
        window?.close()

        // Restore accessory policy when welcome screen is closed
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Restore accessory policy when window is closed
        NSApp.setActivationPolicy(.accessory)
    }
}