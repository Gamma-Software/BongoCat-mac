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
    case keyboard
    case leftClick
    case rightClick
    case scroll
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
        .frame(maxWidth: 300, maxHeight: 250)
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
                        .frame(width: 60, height: 40)
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
                        .frame(width: 60, height: 40)
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
                        .frame(width: 60, height: 40)
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
                        .frame(width: 60, height: 40)
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
    @State private var currentState: CatState = .idle
    @State private var animationTimer: Timer?
    @State private var scale: Double = 1.0

    var body: some View {
        ZStack {
            // Transparent background for overlay
            Color.clear

            // The authentic BangoCat sprite using real images
            BangoCatSprite(state: currentState)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.08), value: currentState)
                .animation(.easeInOut(duration: 0.1), value: scale)
        }
        .frame(maxWidth: 350, maxHeight: 300)  // Accommodate real image dimensions
        .background(Color.clear)
        .onAppear {
            print("🐱 CatView appeared, current state: \(currentState)")
        }
    }

            func triggerAnimation(for inputType: InputType) {
        // Debug logging
        print("🐱 Animation triggered for: \(inputType), current state: \(currentState)")

        // Cancel existing timer
        animationTimer?.invalidate()

        // Trigger appropriate animation
        switch inputType {
        case .keyboard:
            print("⌨️ Keyboard detected - typing animation")
            triggerTypingAnimation()
        case .leftClick:
            print("🖱️ Left click detected - left paw animation")
            triggerPawAnimation(.leftPawDown)
        case .rightClick:
            print("🖱️ Right click detected - right paw animation")
            triggerPawAnimation(.rightPawDown)
        case .scroll:
            print("🔄 Scroll detected - both paws animation")
            triggerBothPawsAnimation()
        }

        // Scale animation for feedback
        withAnimation(.easeInOut(duration: 0.1)) {
            scale = 1.1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 1.0
            }
        }
    }

    private func triggerTypingAnimation() {
        currentState = .typing

        // Alternate paw animation
        animateAlternatePaws()

        // Return to idle after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animationTimer?.invalidate()
            currentState = .idle
        }
    }

    private func triggerPawAnimation(_ paw: CatState) {
        print("🎯 Setting state to: \(paw)")
        currentState = paw

        // Animate back to idle after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            print("🎯 Returning to idle state")
            currentState = .idle
        }
    }

                private func triggerBothPawsAnimation() {
        print("🎯 Setting state to: bothPawsDown")
        currentState = .bothPawsDown

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("🎯 Returning to idle state")
            currentState = .idle
        }
    }

        private func animateAlternatePaws() {
        var isLeft = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Alternate between left and right paw strikes
            if isLeft {
                currentState = .leftPawDown
                // After a short time, return to normal before switching
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    currentState = .rightPawUp  // Show right up while left is down
                }
            } else {
                currentState = .rightPawDown
                // After a short time, return to normal before switching
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    currentState = .leftPawUp   // Show left up while right is down
                }
            }
            isLeft.toggle()
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
        .background(Color.green.opacity(0.2))
}