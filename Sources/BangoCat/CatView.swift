import SwiftUI

// MARK: - Stroke Counter
class StrokeCounter: ObservableObject {
    @Published private(set) var totalStrokes: Int = 0
    @Published private(set) var keystrokes: Int = 0
    @Published private(set) var mouseClicks: Int = 0

    private let strokesKey: String
    private let keystrokesKey: String
    private let mouseClicksKey: String

    init(strokesKey: String = "BangoCatTotalStrokes",
         keystrokesKey: String = "BangoCatKeystrokes",
         mouseClicksKey: String = "BangoCatMouseClicks") {
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
    }

    func incrementMouseClicks() {
        mouseClicks += 1
        totalStrokes += 1
        saveCounts()
        print("🔢 Mouse click count: \(mouseClicks), Total: \(totalStrokes)")
    }

    func reset() {
        totalStrokes = 0
        keystrokes = 0
        mouseClicks = 0
        saveCounts()
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

    // Reference to AppDelegate for context menu actions
    weak var appDelegate: AppDelegate?

    // Stroke counter
    let strokeCounter = StrokeCounter()

    private var animationTimer: Timer?
    private var useLeftPaw: Bool = true  // Track which paw to use next
    private var lastPressedKey: String = ""  // Track the last pressed key
    private var keyToPawMapping: [String: Bool] = [:]  // Track which paw each key uses (true = left, false = right)
    private var lastPawDownTime: Date = Date()  // Track when paw went down
    private var minimumAnimationDuration: TimeInterval = 0.1  // Minimum animation duration
    private var keyHeldDown: Bool = false  // Track if a key is currently held down

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

        // Check if this key has been used before
        let pawToUse: Bool
        if let existingPaw = keyToPawMapping[key] {
            // Same key pressed again - use the same paw
            pawToUse = existingPaw
            print("🎯 Same key '\(key)' pressed again - using same paw: \(pawToUse ? "left" : "right")")
        } else {
            // New key - use the next available paw and store the mapping
            pawToUse = useLeftPaw
            keyToPawMapping[key] = pawToUse
            useLeftPaw.toggle()  // Alternate for the next new key
            print("🎯 New key '\(key)' pressed - assigning \(pawToUse ? "left" : "right") paw")
        }

        // Set the appropriate paw state
        let pawState: CatState = pawToUse ? .leftPawDown : .rightPawDown
        let pawName = pawToUse ? "left" : "right"

        print("🎯 Setting \(pawName) paw down for key '\(key)'")
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

// MARK: - Authentic BangoCat Sprite System using Real Images
struct BangoCatSprite: View {
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



    // Helper function to load images from bundle resources
    private func loadImage(_ name: String) -> NSImage? {
        // Method 1: Try Bundle.module (for Swift Package Manager)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Images"),
           let image = NSImage(contentsOf: url) {
            print("✅ Loaded image from Bundle.module: Images/\(name).png")
            return image
        }
        #endif

        // Method 2: Try Bundle.main with Images subdirectory (for packaged app)
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Images"),
           let image = NSImage(contentsOf: url) {
            print("✅ Loaded image from Bundle.main Images subdirectory: Images/\(name).png")
            return image
        }

        // Method 3: Try Bundle.main at root level (fallback for packaged app)
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            print("✅ Loaded image from Bundle.main root: \(name).png")
            return image
        }

        // Method 4: Try direct file paths (development fallback)
        let possiblePaths = [
            "Sources/BangoCat/Resources/Images/\(name).png",
            "Resources/Images/\(name).png",
            "Images/\(name).png",
            "\(name).png"
        ]

        for path in possiblePaths {
            if let image = NSImage(contentsOfFile: path) {
                print("✅ Loaded image from file path: \(path)")
                return image
            }
        }

        print("❌ Failed to load image: \(name).png from all attempted methods")
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

                    // The authentic BangoCat sprite using real images
                    BangoCatSprite(state: animationController.currentState)
                        .scaleEffect(animationController.scale)
                        .scaleEffect(x: animationController.isFlippedHorizontally ? -1 : 1, y: 1)  // Apply horizontal flip
                        .rotationEffect(.degrees(animationController.rotation))  // Apply rotation
                        .animation(.easeInOut(duration: 0.08), value: animationController.currentState)
                        .animation(.easeInOut(duration: 0.1), value: animationController.scale)
                        .animation(.easeInOut(duration: 0.3), value: animationController.rotation)  // Smooth rotation transitions
                        .animation(.easeInOut(duration: 0.3), value: animationController.isFlippedHorizontally)  // Smooth flip transitions
                        .contentShape(Rectangle()) // Make the entire sprite area tappable
                        .contextMenu {
                            // Scale options
                            Menu("Scale") {
                                Button("Small") {
                                    print("🔧 Context menu: Setting scale to 0.65, appDelegate: \(animationController.appDelegate != nil)")
                                    animationController.appDelegate?.setScalePublic(0.65)
                                }
                                Button("Medium") {
                                    print("🔧 Context menu: Setting scale to 0.75, appDelegate: \(animationController.appDelegate != nil)")
                                    animationController.appDelegate?.setScalePublic(0.75)
                                }
                                Button("Big") {
                                    print("🔧 Context menu: Setting scale to 1.0, appDelegate: \(animationController.appDelegate != nil)")
                                    animationController.appDelegate?.setScalePublic(1.0)
                                }
                            }

                            Divider()

                            // Toggle options
                            Button(animationController.scaleOnInputEnabled ? "Disable Scale Pulse" : "Enable Scale Pulse") {
                                print("🔧 Context menu: Toggling scale pulse, appDelegate: \(animationController.appDelegate != nil)")
                                animationController.appDelegate?.toggleScalePulsePublic()
                            }

                            Button(animationController.rotation != 0.0 ? "Disable Rotation" : "Enable Rotation") {
                                print("🔧 Context menu: Toggling rotation, appDelegate: \(animationController.appDelegate != nil)")
                                animationController.appDelegate?.toggleBangoCatRotatePublic()
                            }

                            Button(animationController.isFlippedHorizontally ? "Unflip Horizontally" : "Flip Horizontally") {
                                print("🔧 Context menu: Toggling horizontal flip, appDelegate: \(animationController.appDelegate != nil)")
                                animationController.appDelegate?.toggleHorizontalFlipPublic()
                            }

                            Button(animationController.ignoreClicksEnabled ? "Enable Clicks" : "Ignore Clicks") {
                                print("🔧 Context menu: Toggling ignore clicks, appDelegate: \(animationController.appDelegate != nil)")
                                animationController.appDelegate?.toggleIgnoreClicksPublic()
                            }

                            Divider()

                            // Position options
                            Menu("Position") {
                                Button("Top Left") {
                                    animationController.appDelegate?.setCornerPositionPublic(.topLeft)
                                }
                                Button("Top Right") {
                                    animationController.appDelegate?.setCornerPositionPublic(.topRight)
                                }
                                Button("Bottom Left") {
                                    animationController.appDelegate?.setCornerPositionPublic(.bottomLeft)
                                }
                                Button("Bottom Right") {
                                    animationController.appDelegate?.setCornerPositionPublic(.bottomRight)
                                }
                                Divider()
                                Button("Save Current Position") {
                                    animationController.appDelegate?.saveCurrentPositionActionPublic()
                                }
                                Button("Restore Saved Position") {
                                    animationController.appDelegate?.restoreSavedPositionPublic()
                                }
                            }

                            Divider()

                            // Utility options
                            Button("Hide BangoCat") {
                                animationController.appDelegate?.toggleOverlayPublic()
                            }

                            Button("Reset Stroke Counter") {
                                animationController.appDelegate?.resetStrokeCounterPublic()
                            }

                            Divider()

                            Button("Buy me a coffee ☕") {
                                animationController.appDelegate?.buyMeACoffeePublic()
                            }

                            Button("Visit Website") {
                                animationController.appDelegate?.visitWebsitePublic()
                            }

                            Button("About BangoCat") {
                                animationController.appDelegate?.showCreditsPublic()
                            }

                            Divider()

                            Button("Quit BangoCat") {
                                animationController.appDelegate?.quitAppPublic()
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