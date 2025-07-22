import Cocoa
import SwiftUI

class OverlayWindow: NSWindowController {
    var catView: CatView?
    private var isVisible = true

    override init(window: NSWindow?) {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 200, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)
        setupWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWindow() {
        guard let window = window else { return }

        // Make window transparent and always on top
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create the cat view
        catView = CatView()
        let hostingView = NSHostingView(rootView: catView!)
        hostingView.frame = window.contentView?.bounds ?? NSRect.zero
        hostingView.autoresizingMask = [.width, .height]

        window.contentView = hostingView

        // Make window draggable
        window.isMovableByWindowBackground = true

        // Center window on screen
        window.center()
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hideWindow() {
        window?.orderOut(nil)
        isVisible = false
    }

    func toggleVisibility() {
        if isVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
}