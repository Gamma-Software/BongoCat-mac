import Cocoa
import SwiftUI

class OverlayWindow: NSWindowController, NSWindowDelegate {
    var catAnimationController: CatAnimationController?
    private var isVisible = true
    weak var appDelegate: AppDelegate? // Reference to save position changes

    override init(window: NSWindow?) {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 175, height: 200),
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

        // Create the animation controller and cat view
        catAnimationController = CatAnimationController()
        // Note: appDelegate will be set later in updateAppDelegate()
        let catView = CatView().environmentObject(catAnimationController!)
        let hostingView = NSHostingView(rootView: catView)
        hostingView.frame = window.contentView?.bounds ?? NSRect.zero
        hostingView.autoresizingMask = [.width, .height]

        window.contentView = hostingView

        // Make window draggable
        window.isMovableByWindowBackground = true

        // Set up window delegate to track position changes
        window.delegate = self

        // Center window on screen
        window.center()
    }

    func updateAppDelegate() {
        catAnimationController?.appDelegate = appDelegate
        print("AppDelegate reference updated in CatAnimationController: \(appDelegate != nil)")
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

    func updateScale(_ scale: Double) {
        guard let animationController = catAnimationController else { return }

        // Update the cat view scale
        animationController.updateViewScale(scale)

        // Calculate new window size based on scale
        let baseWidth: CGFloat = 175
        let baseHeight: CGFloat = 200
        let newWidth = baseWidth * scale
        let newHeight = baseHeight * scale

        // Update window size
        if let window = window {
            let currentFrame = window.frame
            let newFrame = NSRect(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y,
                width: newWidth,
                height: newHeight
            )
            window.setFrame(newFrame, display: true, animate: true)
        }

        print("Window scale updated to: \(scale)")
    }

    func updateRotation(_ rotation: Double) {
        guard let animationController = catAnimationController else { return }

        // Update the cat rotation
        animationController.updateRotation(rotation)

        print("Cat rotation updated to: \(rotation) degrees")
    }

    func updateFlip(_ flipped: Bool) {
        guard let animationController = catAnimationController else { return }

        // Update the cat horizontal flip
        animationController.setHorizontalFlip(flipped)

        print("Cat horizontal flip updated to: \(flipped)")
    }

    func windowDidMove(_ notification: Notification) {
        if let window = window {
            appDelegate?.saveManualPosition(window.frame.origin)
        }
    }
}