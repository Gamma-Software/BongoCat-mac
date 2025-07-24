import Cocoa
import SwiftUI

class OverlayWindow: NSWindowController, NSWindowDelegate {
    var catAnimationController: CatAnimationController?
    private var isVisible = true
    weak var appDelegate: AppDelegate? // Reference to save position changes
    private var isMovingProgrammatically = false // Flag to prevent saving during automatic moves
    private var clickThroughEnabled = true // Track click through state
    private var commandKeyMonitor: Any? // Monitor for command key events

    override init(window: NSWindow?) {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 150, height: 125), // Reduced from 175x200 to 150x125 to fit cat only
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
        //window.backgroundColor = .blue // DEBUG
        window.level = .screenSaver
        window.ignoresMouseEvents = false // Will be updated based on ignore clicks setting
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Create the animation controller and cat view
        catAnimationController = CatAnimationController()
        // Note: appDelegate will be set later in updateAppDelegate()
        let catView = CatView().environmentObject(catAnimationController!)
        let hostingView = NSHostingView(rootView: catView)
        hostingView.frame = window.contentView?.bounds ?? NSRect.zero
        hostingView.autoresizingMask = [.width, .height]

        window.contentView = hostingView

        // Make window draggable (will be disabled when ignoring mouse events)
        window.isMovableByWindowBackground = true

        // Set up window delegate to track position changes
        window.delegate = self

        // Set up command key monitoring for conditional dragging
        setupCommandKeyMonitoring()

        // Center window on screen
        window.center()
    }

    func updateIgnoreMouseEvents(_ ignoreClicks: Bool) {

        clickThroughEnabled = ignoreClicks
        updateMouseEventHandling()

        print("Click through enabled: \(ignoreClicks)")
    }

    private func setupCommandKeyMonitoring() {
        // Monitor for command key events globally
        commandKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        // Also monitor local events when window is key
        NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let commandPressed = event.modifierFlags.contains(.command)
        updateMouseEventHandling(commandKeyPressed: commandPressed)
    }

    private func updateMouseEventHandling(commandKeyPressed: Bool = false) {
        guard let window = window else { return }

        if clickThroughEnabled {
            // If click through is enabled, only allow interaction when command is pressed
            let allowInteraction = commandKeyPressed
            window.ignoresMouseEvents = !allowInteraction
            window.isMovableByWindowBackground = allowInteraction

            if allowInteraction {
                print("Command held - cat is draggable")
            } else {
                print("Command released - click through active")
            }
        } else {
            // If click through is disabled, always allow interaction
            window.ignoresMouseEvents = false
            window.isMovableByWindowBackground = true
        }
    }

    deinit {
        if let monitor = commandKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
        let baseWidth: CGFloat = 150  // Reduced from 175 to match cat size
        let baseHeight: CGFloat = 125 // Reduced from 200 to match cat size
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

    func setPositionProgrammatically(_ position: NSPoint) {
        isMovingProgrammatically = true
        window?.setFrameOrigin(position)
        // Small delay to ensure the move is processed before allowing saves again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isMovingProgrammatically = false
        }
    }

    func windowDidMove(_ notification: Notification) {
        // Only save position if it's a manual move (not programmatic)
        if !isMovingProgrammatically, let window = window {
            appDelegate?.saveManualPosition(window.frame.origin)
        }
    }
}