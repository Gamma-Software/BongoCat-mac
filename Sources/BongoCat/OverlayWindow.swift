import Cocoa
import SwiftUI

class TouchDetectionView: NSView {
    weak var catAnimationController: CatAnimationController?
    private var activeTouchCount: Int = 0

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTouchDetection()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTouchDetection()
    }

    private func setupTouchDetection() {
        // Accept touch events on this view using the newer API
        self.allowedTouchTypes = [.indirect] // Trackpad touches are indirect
        self.wantsRestingTouches = false // We don't need resting touches for this use case
    }

    override func touchesBegan(with event: NSEvent) {
        print("👆 Trackpad touches began")

        // Track new touches
        let touches = event.touches(matching: .began, in: self)
        activeTouchCount += touches.count

        // Track trackpad gesture patterns
        analytics.trackTrackpadGestureDetected("began_\(touches.count)_fingers")

        catAnimationController?.triggerAnimation(for: .trackpadTouch)
        super.touchesBegan(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        // Continuous trackpad contact - keep paws down
        let touches = event.touches(matching: .moved, in: self)
        if touches.count > 0 {
            analytics.trackTrackpadGestureDetected("moved_\(touches.count)_fingers")
        }

        catAnimationController?.triggerAnimation(for: .trackpadTouch)
        super.touchesMoved(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        print("👆 Trackpad touches ended")

        // Remove ended touches
        let touches = event.touches(matching: .ended, in: self)
        activeTouchCount -= touches.count

        // Track gesture end
        analytics.trackTrackpadGestureDetected("ended_\(touches.count)_fingers")

        // If no more active touches, immediately return to idle
        if activeTouchCount <= 0 {
            activeTouchCount = 0 // Ensure it doesn't go negative
            print("👆 All trackpad touches ended - returning to idle immediately")
            catAnimationController?.returnToIdleFromTrackpad()
        }

        super.touchesEnded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        print("👆 Trackpad touches cancelled")

        // Remove cancelled touches
        let touches = event.touches(matching: .cancelled, in: self)
        activeTouchCount -= touches.count

        // Track gesture cancellation
        analytics.trackTrackpadGestureDetected("cancelled_\(touches.count)_fingers")

        // If no more active touches, immediately return to idle
        if activeTouchCount <= 0 {
            activeTouchCount = 0 // Ensure it doesn't go negative
            print("👆 All trackpad touches cancelled - returning to idle immediately")
            catAnimationController?.returnToIdleFromTrackpad()
        }

        super.touchesCancelled(with: event)
    }
}

class OverlayWindow: NSWindowController, NSWindowDelegate {
    var catAnimationController: CatAnimationController?
    private var isVisible = true
    weak var appDelegate: AppDelegate? // Reference to save position changes
    private var isMovingProgrammatically = false // Flag to prevent saving during automatic moves
    private var clickThroughEnabled = true // Track click through state
    private var commandKeyMonitor: Any? // Monitor for command key events

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

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

        // Create touch detection view as container
        let touchDetectionView = TouchDetectionView(frame: window.contentView?.bounds ?? NSRect.zero)
        touchDetectionView.catAnimationController = catAnimationController
        touchDetectionView.autoresizingMask = [.width, .height]

        // Create SwiftUI hosting view and add it as subview
        let catView = CatView().environmentObject(catAnimationController!)
        let hostingView = NSHostingView(rootView: catView)
        hostingView.frame = touchDetectionView.bounds
        hostingView.autoresizingMask = [.width, .height]
        touchDetectionView.addSubview(hostingView)

        window.contentView = touchDetectionView

        // Make window draggable (will be disabled when ignoring mouse events)
        window.isMovableByWindowBackground = true

        // Set up window delegate to track position changes
        window.delegate = self

        // Set up command key monitoring for conditional dragging
        setupCommandKeyMonitoring()

        // Center window on screen
        window.center()

        // Track window setup
        analytics.trackConfigurationLoaded("window", success: true)
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
        analytics.trackVisibilityToggled(true, method: "programmatic")
    }

    func hideWindow() {
        window?.orderOut(nil)
        isVisible = false
        analytics.trackVisibilityToggled(false, method: "programmatic")
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