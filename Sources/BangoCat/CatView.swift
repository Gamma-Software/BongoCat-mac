import SwiftUI

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

    func triggerAnimation(for inputType: InputType) {
        // Debug logging
        print("🐱 Animation triggered for: \(inputType), current state: \(currentState)")

        // Cancel existing timer
        animationTimer?.invalidate()

        // Trigger appropriate animation
        switch inputType {
        case .keyboardDown(let key):
            print("⌨️ Keyboard down detected - key: \(key)")
            triggerKeyboardDown(for: key)
        case .keyboardUp(let key):
            print("⌨️ Keyboard up detected - key: \(key)")
            triggerKeyboardUp(for: key)
        case .leftClickDown:
            print("🖱️ Left click down detected - left paw animation")
            triggerPawAnimation(.leftPawDown)
        case .leftClickUp:
            print("🖱️ Left click up detected - left paw up animation")
            triggerPawAnimation(.leftPawUp)
        case .rightClickDown:
            print("🖱️ Right click down detected - right paw animation")
            triggerPawAnimation(.rightPawDown)
        case .rightClickUp:
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
        // Try to load from bundle resources
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            print("✅ Loaded image: \(name).png")
            return image
        }

        // Try alternative paths
        let possiblePaths = [
            "Sources/BangoCat/Resources/Images/\(name).png",
            "Resources/Images/\(name).png",
            "\(name).png"
        ]

        for path in possiblePaths {
            if let image = NSImage(contentsOfFile: path) {
                print("✅ Loaded image from path: \(path)")
                return image
            }
        }

        print("❌ Failed to load image: \(name).png")
        return nil
    }
}

struct CatView: View {
    @EnvironmentObject private var animationController: CatAnimationController

    var body: some View {
        ZStack {
            // Transparent background for overlay
            Color.clear

            // The authentic BangoCat sprite using real images
            BangoCatSprite(state: animationController.currentState)
                .scaleEffect(animationController.scale)
                .rotationEffect(.degrees(animationController.rotation))  // Apply rotation
                .animation(.easeInOut(duration: 0.08), value: animationController.currentState)
                .animation(.easeInOut(duration: 0.1), value: animationController.scale)
                .animation(.easeInOut(duration: 0.3), value: animationController.rotation)  // Smooth rotation transitions
        }
        .scaleEffect(animationController.viewScale)  // Apply view scaling
        .animation(.easeInOut(duration: 0.3), value: animationController.viewScale)  // Smooth scale transitions
        .frame(maxWidth: 175, maxHeight: 150)  // Accommodate real image dimensions
        .background(Color.clear)
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