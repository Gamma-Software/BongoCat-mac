import SwiftUI

// MARK: - Stroke Counter
class StrokeCounter: ObservableObject {
    @Published private(set) var totalStrokes: Int = 0
    @Published private(set) var keystrokes: Int = 0
    @Published private(set) var mouseClicks: Int = 0

    private let strokesKey: String
    private let keystrokesKey: String
    private let mouseClicksKey: String

    // Milestone notification manager
    private let milestoneManager = MilestoneNotificationManager.shared

    init(strokesKey: String = "BongoCatTotalStrokes",
         keystrokesKey: String = "BongoCatKeystrokes",
         mouseClicksKey: String = "BongoCatMouseClicks") {
        self.strokesKey = strokesKey
        self.keystrokesKey = keystrokesKey
        self.mouseClicksKey = mouseClicksKey
        loadSavedCounts()
    }

    func incrementKeystrokes() {
        keystrokes += 1
        totalStrokes += 1
        saveCounts()
        print("🔢 Keystroke count: \(keystrokes), Total: \(totalStrokes)")

        // Check for milestone notifications
        milestoneManager.checkKeystrokeMilestone(keystrokes)
        milestoneManager.checkTotalStrokeMilestone(totalStrokes)
    }

    func incrementMouseClicks() {
        mouseClicks += 1
        totalStrokes += 1
        saveCounts()
        print("🔢 Mouse click count: \(mouseClicks), Total: \(totalStrokes)")

        // Check for milestone notifications
        milestoneManager.checkMouseClickMilestone(mouseClicks)
        milestoneManager.checkTotalStrokeMilestone(totalStrokes)
    }

    func reset() {
        totalStrokes = 0
        keystrokes = 0
        mouseClicks = 0
        saveCounts()

        // Reset milestone tracking as well
        milestoneManager.resetMilestoneTracking()

        print("🔢 Stroke counter reset")
    }

    internal func loadSavedCounts() {
        totalStrokes = UserDefaults.standard.integer(forKey: strokesKey)
        keystrokes = UserDefaults.standard.integer(forKey: keystrokesKey)
        mouseClicks = UserDefaults.standard.integer(forKey: mouseClicksKey)
        print("🔢 Loaded stroke counts - Total: \(totalStrokes), Keys: \(keystrokes), Mouse: \(mouseClicks)")
    }

    internal func saveCounts() {
        UserDefaults.standard.set(totalStrokes, forKey: strokesKey)
        UserDefaults.standard.set(keystrokes, forKey: keystrokesKey)
        UserDefaults.standard.set(mouseClicks, forKey: mouseClicksKey)
    }
}

// MARK: - Paw Behavior Modes
enum PawBehaviorMode: String, CaseIterable {
    case keyboardLayout = "Keyboard Layout"
    case random = "Random"
    case alternating = "Alternating"

    var displayName: String {
        return self.rawValue
    }
}

enum CatState {
    case idle
    case leftPawDown
    case rightPawDown
    case bothPawsDown
    case leftPawUp
    case rightPawUp
    case typing
}

enum InputType {
    case keyboardDown(key: String)
    case keyboardUp(key: String)
    case leftClickDown
    case leftClickUp
    case rightClickDown
    case rightClickUp
    case scroll
    case trackpadTouch
}

// MARK: - Observable Cat Animation Controller
class CatAnimationController: ObservableObject {
    @Published var currentState: CatState = .idle
    @Published var scale: Double = 1.0
    @Published var viewScale: Double = 1.0  // New scale property for view size
    @Published var scaleOnInputEnabled: Bool = true  // Control scale pulse on input
    @Published var rotation: Double = 0.0  // New rotation property for cat rotation
    @Published var isFlippedHorizontally: Bool = false  // New property for horizontal flip
    @Published var ignoreClicksEnabled: Bool = false  // Control whether to ignore mouse clicks
    @Published var pawBehaviorMode: PawBehaviorMode = .alternating  // Control paw behavior mode

    // Reference to AppDelegate for context menu actions
    weak var appDelegate: AppDelegate?

    // Stroke counter
    let strokeCounter = StrokeCounter()

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

    private var animationTimer: Timer?
    private var lastPressedKey: String = ""  // Track the last pressed key
    private var lastPawDownTime: Date = Date()  // Track when paw went down
    private var minimumAnimationDuration: TimeInterval = 0.1  // Minimum animation duration
    private var keyHeldDown: Bool = false  // Track if a key is currently held down
    private var isAlternatingLeft: Bool = true  // Track alternating paw state (starts with left)

    // Trackpad touch tracking
    private var trackpadTouchTimer: Timer?
    private let trackpadTouchTimeout: TimeInterval = 0.3  // Time to wait after last trackpad event before returning to idle

    init() {
    }

    deinit {
    }

    // MARK: - Keyboard Layout-Based Paw Mapping
    private let leftPawKeys: Set<String> = [
        // Numbers (left side)
        "1", "2", "3", "4", "5",
        // Top row (left side)
        "q", "w", "e", "r", "t",
        "Q", "W", "E", "R", "T",
        // Middle row (left side)
        "a", "s", "d", "f", "g",
        "A", "S", "D", "F", "G",
        // Bottom row (left side)
        "z", "x", "c", "v", "b",
        "Z", "X", "C", "V", "B",
        // Special keys typically used by left hand
        "\t",    // Tab
        " ",     // Space (left thumb)
        "`", "~", // Backtick/Tilde
        "-", "_", // Minus/Underscore (though on right side, often typed with left pinky)
                                // Special keys (left side)
        "Escape", "ESC", "esc",     // Escape key
        // Modifier key symbols (if they come through as characters)
        "⇧", "shift", "Shift",     // Shift (left)
        "⌃", "ctrl", "Ctrl", "control", "Control",   // Control (left)
        "⌥", "alt", "Alt", "option", "Option",       // Option/Alt (left)
        "⌘", "cmd", "Cmd", "command", "Command",     // Command (left)
    ]

    private let rightPawKeys: Set<String> = [
        // Numbers (right side)
        "6", "7", "8", "9", "0",
        // Top row (right side)
        "y", "u", "i", "o", "p",
        "Y", "U", "I", "O", "P",
        // Middle row (right side)
        "h", "j", "k", "l",
        "H", "J", "K", "L",
        // Bottom row (right side)
        "n", "m",
        "N", "M",
        // Punctuation typically typed with right hand
        ";", ":", "'", "\"",
        ",", "<", ".", ">", "/", "?",
        "[", "{", "]", "}", "\\", "|",
        "=", "+",
        // Special keys
        "\r",    // Enter/Return
        "\u{7f}", // Delete/Backspace
        "\u{8}",  // Backspace (alternative code)
        // Arrow keys (typically right hand)
        "←", "→", "↑", "↓",           // Arrow symbols
        // Page navigation keys (typically right hand)
        "Home", "End", "PageUp", "PageDown",
        // Modifier keys (right side) - if they come through as text
        "⇧R", "shiftR", "ShiftR",     // Right Shift
        "⌃R", "ctrlR", "CtrlR",       // Right Control
        "⌥R", "altR", "AltR",         // Right Option/Alt
        "⌘R", "cmdR", "CmdR",         // Right Command
    ]

    func updateViewScale(_ newScale: Double) {
        viewScale = newScale
        print("Cat view scale updated to: \(newScale)")
    }

    func setScaleOnInputEnabled(_ enabled: Bool) {
        scaleOnInputEnabled = enabled
        print("Scale on input \(enabled ? "enabled" : "disabled")")
    }

    func updateRotation(_ newRotation: Double) {
        rotation = newRotation
        print("Cat rotation updated to: \(newRotation) degrees")
    }

    func setHorizontalFlip(_ flipped: Bool) {
        isFlippedHorizontally = flipped
        print("Cat horizontal flip updated to: \(flipped)")
    }

    func setIgnoreClicksEnabled(_ enabled: Bool) {
        ignoreClicksEnabled = enabled
        print("Ignore clicks \(enabled ? "enabled" : "disabled")")
    }

    func setPawBehaviorMode(_ mode: PawBehaviorMode) {
        pawBehaviorMode = mode
        print("Paw behavior mode set to: \(mode.displayName)")
    }

    // MARK: - Paw Assignment Based on Behavior Mode
    private func getPawForKey(_ key: String) -> Bool {
        switch pawBehaviorMode {
        case .keyboardLayout:
            return getKeyboardLayoutPaw(for: key)
        case .random:
            return getRandomPaw(for: key)
        case .alternating:
            return getAlternatingPaw()
        }
    }

    private func getKeyboardLayoutPaw(for key: String) -> Bool {
        // Check if key is in left paw set
        if leftPawKeys.contains(key) {
            return true  // Left paw
        }
        // Check if key is in right paw set
        else if rightPawKeys.contains(key) {
            return false  // Right paw
        }
        // For unknown keys, use a simple rule based on first character
        else {
            // For special characters or unknown keys, try to be smart about assignment
            let firstChar = key.first ?? "a"
            let asciiValue = firstChar.asciiValue ?? 97

            // Use ASCII value to determine paw (even = left, odd = right)
            // This ensures consistent assignment for unknown keys
            let isLeftPaw = (asciiValue % 2 == 0)
            print("🎯 Unknown key '\(key)' - assigning to \(isLeftPaw ? "left" : "right") paw based on ASCII value")
            return isLeftPaw
        }
    }

    private func getRandomPaw(for key: String) -> Bool {
        let isLeftPaw = Bool.random()
        print("🎲 Random paw for key '\(key)' - using \(isLeftPaw ? "left" : "right") paw")
        return isLeftPaw
    }

    private func getAlternatingPaw() -> Bool {
        let currentPaw = isAlternatingLeft
        isAlternatingLeft.toggle()  // Switch for next key
        print("🔄 Alternating paw - using \(currentPaw ? "left" : "right") paw")
        return currentPaw
    }

    func triggerAnimation(for inputType: InputType) {
        // Debug logging
        print("🐱 Animation triggered for: \(inputType), current state: \(currentState)")

        // Cancel existing timer
        animationTimer?.invalidate()

        // Trigger appropriate animation and count strokes
        switch inputType {
        case .keyboardDown(let key):
            print("⌨️ Keyboard down detected - key: \(key)")
            strokeCounter.incrementKeystrokes()
            triggerKeyboardDown(for: key)
        case .keyboardUp(let key):
            print("⌨️ Keyboard up detected - key: \(key)")
            triggerKeyboardUp(for: key)
        case .leftClickDown:
            if ignoreClicksEnabled {
                print("🖱️ Left click ignored (ignore clicks enabled)")
                return
            }
            print("🖱️ Left click down detected - left paw animation")
            strokeCounter.incrementMouseClicks()
            triggerPawAnimation(.leftPawDown)
        case .leftClickUp:
            if ignoreClicksEnabled {
                print("🖱️ Left click up ignored (ignore clicks enabled)")
                return
            }
            print("🖱️ Left click up detected - left paw up animation")
            triggerPawAnimation(.leftPawUp)
        case .rightClickDown:
            if ignoreClicksEnabled {
                print("🖱️ Right click ignored (ignore clicks enabled)")
                return
            }
            print("🖱️ Right click down detected - right paw animation")
            strokeCounter.incrementMouseClicks()
            triggerPawAnimation(.rightPawDown)
        case .rightClickUp:
            if ignoreClicksEnabled {
                print("🖱️ Right click up ignored (ignore clicks enabled)")
                return
            }
            print("🖱️ Right click up detected - right paw up animation")
            triggerPawAnimation(.rightPawUp)
        case .trackpadTouch:
            print("👆 Trackpad touch detected - both paws down animation")
            analytics.trackTrackpadGestureDetected("touch")
            triggerTrackpadTouch()
        //case .scroll:
        //    print("🔄 Scroll detected - both paws animation")
        //    triggerBothPawsAnimation()
        default:
            // Handle any other input types (like scroll if uncommented later)
            break
        }

        // Scale animation for feedback - only if enabled
        if scaleOnInputEnabled {
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 1.1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.scale = 1.0
                }
            }
        }
    }

    private func triggerKeyboardDown(for key: String) {
        // Cancel any existing animation timer
        animationTimer?.invalidate()

        // Record the time when paw goes down
        lastPawDownTime = Date()

        // Determine which paw to use based on keyboard layout
        let pawToUse = getPawForKey(key)
        let pawName = pawToUse ? "left" : "right"
        let handSide = pawToUse ? "left side" : "right side"

        print("🎯 Key '\(key)' on \(handSide) of keyboard - using \(pawName) paw")

        // Set the appropriate paw state
        let pawState: CatState = pawToUse ? .leftPawDown : .rightPawDown
        currentState = pawState

        // Store the last pressed key
        lastPressedKey = key

        // No automatic return to idle - paws stay down until keyboardUp
    }

    private func triggerKeyboardUp(for key: String) {
        // Cancel any existing animation timer
        animationTimer?.invalidate()

        print("🎯 Key '\(key)' released")

        // Calculate how long the paw has been down
        let elapsedTime = Date().timeIntervalSince(lastPawDownTime)
        let remainingTime = max(0, minimumAnimationDuration - elapsedTime)

        if remainingTime > 0 {
            // Wait for the remaining time before returning to idle
            print("🎯 Waiting \(remainingTime)s before returning to idle (minimum duration)")
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                print("🎯 Returning paws to idle after minimum duration")
                self.currentState = .idle
            }
        } else {
            // Minimum duration already passed, return to idle immediately
            print("🎯 Returning paws to idle (keyboard released)")
            currentState = .idle
        }
    }

    private func triggerTypingAnimation() {
        currentState = .typing

        // Alternate paw animation
        animateAlternatePaws()

        // Return to idle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animationTimer?.invalidate()
            self.currentState = .idle
        }
    }

    private func triggerPawAnimation(_ paw: CatState) {
        print("🎯 Setting state to: \(paw)")
        currentState = paw

        // Record time for minimum duration tracking
        lastPawDownTime = Date()

        // Handle different paw states appropriately
        switch paw {
        case .leftPawUp, .rightPawUp:
            // Up states return to idle after minimum duration
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumAnimationDuration) {
                print("🎯 Returning to idle from up position after minimum duration")
                if self.currentState == paw { // Only change if still in same state
                    self.currentState = .idle
                }
            }
        case .leftPawDown, .rightPawDown:
            break
        default:
            // Other states return to idle after minimum duration
            DispatchQueue.main.asyncAfter(deadline: .now() + minimumAnimationDuration) {
                print("🎯 Returning to idle state after minimum duration")
                if self.currentState == paw { // Only change if still in same state
                    self.currentState = .idle
                }
            }
        }
    }

    private func triggerBothPawsAnimation() {
        print("🎯 Setting state to: bothPawsDown")
        currentState = .bothPawsDown

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("🎯 Returning to idle state")
            self.currentState = .idle
        }
    }

        private func triggerTrackpadTouch() {
        // Cancel any existing trackpad timer
        trackpadTouchTimer?.invalidate()

        // Put both paws down immediately
        print("🎯 Setting state to: bothPawsDown (trackpad)")
        currentState = .bothPawsDown

        // Start a new timer to return to idle after no trackpad activity
        trackpadTouchTimer = Timer.scheduledTimer(withTimeInterval: trackpadTouchTimeout, repeats: false) { [weak self] _ in
            print("🎯 Trackpad timeout - returning to idle")
            self?.currentState = .idle
            self?.trackpadTouchTimer = nil
        }
    }

    func returnToIdleFromTrackpad() {
        // Cancel the trackpad timer and immediately return to idle
        trackpadTouchTimer?.invalidate()
        trackpadTouchTimer = nil

        print("🎯 Returning to idle immediately (no more trackpad touches)")
        currentState = .idle
    }

    private func animateAlternatePaws() {
        var isLeft = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Alternate between left and right paw strikes
            if isLeft {
                self.currentState = .leftPawDown
                // After a short time, return to normal before switching
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.currentState = .rightPawUp  // Show right up while left is down
                }
            } else {
                self.currentState = .rightPawDown
                // After a short time, return to normal before switching
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.currentState = .leftPawUp   // Show left up while right is down
                }
            }
            isLeft.toggle()
        }
    }
}

// MARK: - Authentic BongoCat Sprite System using Real Images
struct BongoCatSprite: View {
    let state: CatState

    // Pre-load all images to avoid loading issues during animation
    @State private var baseImage: NSImage?
    @State private var leftUpImage: NSImage?
    @State private var leftDownImage: NSImage?
    @State private var rightUpImage: NSImage?
    @State private var rightDownImage: NSImage?

    var body: some View {
        ZStack {
            // Base cat image (without hands)
            if let baseImage = baseImage {
                Image(nsImage: baseImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .overlay(Text("Loading base..."))
            }

            // Left hand - show appropriate image based on state
            leftHandView

            // Right hand - show appropriate image based on state
            rightHandView
        }
        .frame(maxWidth: 150, maxHeight: 125)
        .onAppear {
            loadAllImages()
        }
        .onChange(of: state) { newValue in
            print("🔄 State changed to: \(newValue)")
        }
    }

    private var leftHandView: some View {
        Group {
            switch state {
            case .leftPawDown, .bothPawsDown, .typing:
                if let leftDownImage = leftDownImage {
                    Image(nsImage: leftDownImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 30, height: 20)
                        .overlay(Text("L-DOWN\nMISSING").font(.caption))
                }
            default:
                if let leftUpImage = leftUpImage {
                    Image(nsImage: leftUpImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 30, height: 20)
                        .overlay(Text("L-UP\nMISSING").font(.caption))
                }
            }
        }
    }

    private var rightHandView: some View {
        Group {
            switch state {
            case .rightPawDown, .bothPawsDown, .typing:
                if let rightDownImage = rightDownImage {
                    Image(nsImage: rightDownImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 30, height: 20)
                        .overlay(Text("R-DOWN\nMISSING").font(.caption))
                }
            default:
                if let rightUpImage = rightUpImage {
                    Image(nsImage: rightUpImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 30, height: 20)
                        .overlay(Text("R-UP\nMISSING").font(.caption))
                }
            }
        }
    }

    private func loadAllImages() {
        print("🎨 Loading all sprite images...")
        baseImage = loadImage("base")
        leftUpImage = loadImage("left-up")
        leftDownImage = loadImage("left-down")
        rightUpImage = loadImage("right-up")
        rightDownImage = loadImage("right-down")

        print("🎨 Image loading complete:")
        print("  base: \(baseImage != nil ? "✅" : "❌")")
        print("  left-up: \(leftUpImage != nil ? "✅" : "❌")")
        print("  left-down: \(leftDownImage != nil ? "✅" : "❌")")
        print("  right-up: \(rightUpImage != nil ? "✅" : "❌")")
        print("  right-down: \(rightDownImage != nil ? "✅" : "❌")")
    }



<<<<<<< Updated upstream
    // Helper function to load images from bundle resources
    private func loadImage(_ name: String) -> NSImage? {
        let analytics = PostHogAnalyticsManager.shared
        let loadStartTime = Date()

        // Method 1: Try Bundle.module (for Swift Package Manager)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Images"),
           let image = NSImage(contentsOf: url) {
=======
    /// Loads a cat sprite image by name, searching in the module bundle (Bundle.module) first for SwiftPM,
    /// then falling back to the app bundle and other locations for development and CLI scenarios.
    private func loadImage(_ name: String) -> NSImage? {
        let analytics = PostHogAnalyticsManager.shared
        let loadStartTime = Date()
        let filename = "\(name).png"
        print("🔍 [loadImage] Attempting to load image: \(filename)")

        // 0. Try Bundle.module (SwiftPM resource bundle)
        #if SWIFT_PACKAGE
        print("🔎 [loadImage] Checking Bundle.module: Resources/\(filename)")
        if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Resources"),
           let image = NSImage(contentsOf: url) {
            let loadTime = Date().timeIntervalSince(loadStartTime)
            analytics.trackResourceLoadTime("image", loadTime: loadTime)
            print("✅ Loaded image from Bundle.module: Resources/\(filename)")
            return image
        } else {
            print("❌ [loadImage] Not found in Bundle.module/Resources")
            analytics.trackImageLoadError(name, method: "Bundle.module/Resources")
        }
        #endif

        // 1. Try Bundle.main.resourceURL/Images (the correct way for packaged macOS apps)
        print("🔎 [loadImage] Checking Bundle.main.resourceURL: Images/\(filename)")
        if let resourceURL = Bundle.main.resourceURL?.appendingPathComponent("\(filename)"),
           let image = NSImage(contentsOf: resourceURL) {
>>>>>>> Stashed changes
            let loadTime = Date().timeIntervalSince(loadStartTime)
            analytics.trackResourceLoadTime("image", loadTime: loadTime)
            print("✅ Loaded image from Bundle.module: Images/\(name).png")
            return image
        } else {
<<<<<<< Updated upstream
            analytics.trackImageLoadError(name, method: "Bundle.module")
=======
            print("❌ [loadImage] Not found in Bundle.main.resourceURL/Images")
            analytics.trackImageLoadError(name, method: "Bundle.main.resourceURL/Images")
>>>>>>> Stashed changes
        }
        #endif

<<<<<<< Updated upstream
        // Method 2: Try Bundle.main with Images subdirectory (for packaged app)
=======
        // 2. Try Bundle.main.url(forResource:inDirectory:) (legacy, but sometimes works)
        print("🔎 [loadImage] Checking Bundle.main.url(forResource:inDirectory:): \(filename)")
>>>>>>> Stashed changes
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Images"),
           let image = NSImage(contentsOf: url) {
            let loadTime = Date().timeIntervalSince(loadStartTime)
            analytics.trackResourceLoadTime("image", loadTime: loadTime)
            print("✅ Loaded image from Bundle.main Images subdirectory: Images/\(name).png")
            return image
        } else {
<<<<<<< Updated upstream
            analytics.trackImageLoadError(name, method: "Bundle.main_subdirectory")
        }

        // Method 3: Try Bundle.main at root level (fallback for packaged app)
=======
            print("❌ [loadImage] Not found in Bundle.main.url_subdirectory")
            analytics.trackImageLoadError(name, method: "Bundle.main.url_subdirectory")
        }

        // 3. Try Bundle.main at root level (fallback for packaged app)
        print("🔎 [loadImage] Checking Bundle.main root: \(filename)")
>>>>>>> Stashed changes
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            let loadTime = Date().timeIntervalSince(loadStartTime)
            analytics.trackResourceLoadTime("image", loadTime: loadTime)
            print("✅ Loaded image from Bundle.main root: \(name).png")
            return image
        } else {
            print("❌ [loadImage] Not found in Bundle.main_root")
            analytics.trackImageLoadError(name, method: "Bundle.main_root")
        }

<<<<<<< Updated upstream
        // Method 4: Try executable directory paths (for CLI execution)
=======
        // 4. Try NSImage(named:) (works if image is in asset catalog or registered in bundle)
        print("🔎 [loadImage] Checking NSImage(named: \(name))")
        if let bundleImage = NSImage(named: name) {
            let loadTime = Date().timeIntervalSince(loadStartTime)
            analytics.trackResourceLoadTime("image", loadTime: loadTime)
            print("✅ Loaded image from NSImage(named: \(name))")
            return bundleImage
        } else {
            print("❌ [loadImage] Not found in NSImage(named: \(name))")
        }

        // 5. Try in-place next to executable (for CLI/dev scenarios)
>>>>>>> Stashed changes
        if let executablePath = Bundle.main.executablePath {
            let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
            let possibleExecutablePaths = [
                executableDir.appendingPathComponent("Sources/BongoCat/Resources/Images/\(name).png"),
                executableDir.appendingPathComponent("Resources/Images/\(name).png"),
                executableDir.appendingPathComponent("Images/\(name).png"),
                executableDir.appendingPathComponent("\(name).png")
            ]
<<<<<<< Updated upstream

            for path in possibleExecutablePaths {
=======
            print("🔎 [loadImage] Checking executable directory paths:")
            for path in possiblePaths {
                print("    - \(path.path)")
>>>>>>> Stashed changes
                if let image = NSImage(contentsOf: path) {
                    let loadTime = Date().timeIntervalSince(loadStartTime)
                    analytics.trackResourceLoadTime("image", loadTime: loadTime)
                    print("✅ Loaded image from executable directory: \(path.path)")
                    return image
                }
            }
            print("❌ [loadImage] Not found in any executable directory path")
        } else {
            print("⚠️ [loadImage] Bundle.main.executablePath is nil")
        }

        // Method 5: Try current working directory paths (for CLI execution)
        let currentDir = FileManager.default.currentDirectoryPath
        let possibleCurrentDirPaths = [
            "\(currentDir)/Sources/BongoCat/Resources/Images/\(name).png",
            "\(currentDir)/Resources/Images/\(name).png",
            "\(currentDir)/Images/\(name).png",
            "\(currentDir)/\(name).png"
        ]
<<<<<<< Updated upstream

        for path in possibleCurrentDirPaths {
=======
        print("🔎 [loadImage] Checking current working directory paths:")
        for path in cwdPaths {
            print("    - \(path)")
>>>>>>> Stashed changes
            if let image = NSImage(contentsOfFile: path) {
                let loadTime = Date().timeIntervalSince(loadStartTime)
                analytics.trackResourceLoadTime("image", loadTime: loadTime)
                print("✅ Loaded image from current directory: \(path)")
                return image
            }
        }
        print("❌ [loadImage] Not found in any current working directory path")

        // Method 6: Try relative paths from project root (development fallback)
        let possibleRelativePaths = [
            "Sources/BongoCat/Resources/Images/\(name).png",
            "Resources/Images/\(name).png",
            "Images/\(name).png",
            "\(name).png"
        ]
<<<<<<< Updated upstream

        for path in possibleRelativePaths {
=======
        print("🔎 [loadImage] Checking relative paths:")
        for path in relativePaths {
            print("    - \(path)")
>>>>>>> Stashed changes
            if let image = NSImage(contentsOfFile: path) {
                let loadTime = Date().timeIntervalSince(loadStartTime)
                analytics.trackResourceLoadTime("image", loadTime: loadTime)
                print("✅ Loaded image from relative path: \(path)")
                return image
            }
        }
        print("❌ [loadImage] Not found in any relative path")

<<<<<<< Updated upstream
=======
        // 8. (Optional) Try loading from a resource bundle if present (for SPM plugin/dev)
        let allBundles = Bundle.allBundles
        if !allBundles.isEmpty {
            print("🔎 [loadImage] Checking all bundles for Images/\(filename)")
            for bundle in allBundles {
                print("    - \(bundle.bundlePath)")
                if let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Images"),
                   let image = NSImage(contentsOf: url) {
                    let loadTime = Date().timeIntervalSince(loadStartTime)
                    analytics.trackResourceLoadTime("image", loadTime: loadTime)
                    print("✅ Loaded image from bundle: \(bundle.bundlePath)/Images/\(filename)")
                    return image
                }
            }
            print("❌ [loadImage] Not found in any Bundle.allBundles")
        } else {
            print("⚠️ [loadImage] Bundle.allBundles is empty")
        }

>>>>>>> Stashed changes
        // All methods failed
        analytics.trackImageLoadError(name, method: "all_methods_failed")
        print("❌ Failed to load image: \(name).png from all attempted methods")
        print("🔍 Debug info:")
        print("  - Bundle.main.bundlePath: \(Bundle.main.bundlePath)")
        print("  - Bundle.main.executablePath: \(Bundle.main.executablePath ?? "nil")")
        print("  - Current working directory: \(FileManager.default.currentDirectoryPath)")
        print("  - Home directory: \(FileManager.default.homeDirectoryForCurrentUser.path)")
        print("  - Searched paths (relative): \(relativePaths)")
        print("  - Searched paths (cwd): \(cwdPaths)")
        return nil
    }
}

struct CatView: View {
    @EnvironmentObject private var animationController: CatAnimationController

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Clear background area (18.5% of total height to match original 25px/135px)
                Color.clear
                    .frame(height: geometry.size.height * 0.185)

                // Red cat area (81.5% of total height to match original 110px/135px)
                ZStack {
                    Color.clear
                    //Color.red //DEBUG

                    // The authentic BongoCat sprite using real images
                    BongoCatSprite(state: animationController.currentState)
                        .scaleEffect(animationController.scale)
                        .scaleEffect(x: animationController.isFlippedHorizontally ? -1 : 1, y: 1)  // Apply horizontal flip
                        .rotationEffect(.degrees(animationController.rotation))  // Apply rotation
                        .animation(.easeInOut(duration: 0.08), value: animationController.currentState)
                        .animation(.easeInOut(duration: 0.1), value: animationController.scale)
                        .animation(.easeInOut(duration: 0.3), value: animationController.rotation)  // Smooth rotation transitions
                        .animation(.easeInOut(duration: 0.3), value: animationController.isFlippedHorizontally)  // Smooth flip transitions
                        .contentShape(Rectangle()) // Make the entire sprite area tappable
                        .contextMenu {
                            Button("Show/Hide Overlay") {
                                animationController.appDelegate?.toggleOverlayPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "toggle_overlay")
                            }

                            Divider()

                            Button("Settings...") {
                                animationController.appDelegate?.openPreferencesPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "open_settings")
                            }

                            Divider()

                            Button("Buy me a coffee ☕") {
                                animationController.appDelegate?.buyMeACoffeePublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "buy_coffee")
                            }

                            Button("Tweet about BongoCat 🐦") {
                                animationController.appDelegate?.tweetAboutBongoCatPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "tweet_about_bongocat")
                            }

                            Button("Check for Updates 🔄") {
                                animationController.appDelegate?.checkForUpdatesPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "check_for_updates")
                            }

                            Button("Auto-Start at Launch 🚀") {
                                animationController.appDelegate?.toggleAutoStartAtLaunchPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "toggle_auto_start")
                            }

                            Divider()

                            Button("About BongoCat") {
                                animationController.appDelegate?.showCreditsPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "about_bongocat")
                            }

                            Divider()

                            Button("Quit BongoCat") {
                                animationController.appDelegate?.quitAppPublic()
                                PostHogAnalyticsManager.shared.trackContextMenuUsed("right_click", action: "quit_app")
                            }
                        }
                }
                .frame(height: geometry.size.height * 0.815)
            }
        }
        .scaleEffect(animationController.viewScale)  // Apply view scaling
        .animation(.easeInOut(duration: 0.3), value: animationController.viewScale)  // Smooth scale transitions
        .onAppear {
            print("🐱 CatView appeared, current state: \(animationController.currentState)")
        }
    }
}

// Simple triangle shape for ears
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

#Preview {
    CatView()
        .environmentObject(CatAnimationController())
        .background(Color.green.opacity(0.2))
}