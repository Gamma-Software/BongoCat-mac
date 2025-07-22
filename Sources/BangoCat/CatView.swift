import SwiftUI

enum CatState {
    case idle
    case typing
    case leftPaw
    case rightPaw
    case bothPaws
}

enum InputType {
    case keyboard
    case leftClick
    case rightClick
    case scroll
}

struct CatView: View {
    @State private var currentState: CatState = .idle
    @State private var animationTimer: Timer?
    @State private var scale: Double = 1.0
    @State private var leftPawOffset: CGFloat = 0
    @State private var rightPawOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Cat body (circle for now)
            Circle()
                .fill(Color.orange)
                .frame(width: 80, height: 80)
                .scaleEffect(scale)

            // Cat face
            VStack(spacing: 2) {
                // Eyes
                HStack(spacing: 15) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                }

                // Nose
                Circle()
                    .fill(Color.pink)
                    .frame(width: 4, height: 4)
            }
            .offset(y: -5)

            // Left paw
            Circle()
                .fill(Color.orange)
                .frame(width: 20, height: 20)
                .offset(x: -50, y: 30 + leftPawOffset)

            // Right paw
            Circle()
                .fill(Color.orange)
                .frame(width: 20, height: 20)
                .offset(x: 50, y: 30 + rightPawOffset)

            // Ears
            HStack(spacing: 40) {
                Triangle()
                    .fill(Color.orange)
                    .frame(width: 15, height: 15)
                Triangle()
                    .fill(Color.orange)
                    .frame(width: 15, height: 15)
            }
            .offset(y: -45)
        }
        .frame(width: 160, height: 160)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.1), value: leftPawOffset)
        .animation(.easeInOut(duration: 0.1), value: rightPawOffset)
    }

        func triggerAnimation(for inputType: InputType) {
        // Debug logging
        print("🐱 Animation triggered for: \(inputType)")

        // Cancel existing timer
        animationTimer?.invalidate()

        // Trigger appropriate animation
        switch inputType {
        case .keyboard:
            print("⌨️ Keyboard detected - typing animation")
            triggerTypingAnimation()
        case .leftClick:
            print("🖱️ Left click detected - left paw animation")
            triggerPawAnimation(.leftPaw)
        case .rightClick:
            print("🖱️ Right click detected - right paw animation")
            triggerPawAnimation(.rightPaw)
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
            resetPaws()
        }
    }

        private func triggerPawAnimation(_ paw: CatState) {
        currentState = paw

        if paw == .leftPaw {
            withAnimation(.easeInOut(duration: 0.15)) {
                leftPawOffset = -25  // Increased movement for visibility
            }
        } else {
            withAnimation(.easeInOut(duration: 0.15)) {
                rightPawOffset = -25  // Increased movement for visibility
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentState = .idle
            resetPaws()
        }
    }

        private func triggerBothPawsAnimation() {
        currentState = .bothPaws

        withAnimation(.easeInOut(duration: 0.15)) {
            leftPawOffset = -25  // Increased movement for visibility
            rightPawOffset = -25  // Increased movement for visibility
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            currentState = .idle
            resetPaws()
        }
    }

    private func animateAlternatePaws() {
        var isLeft = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                if isLeft {
                    leftPawOffset = -25  // Increased movement for visibility
                    rightPawOffset = 0
                } else {
                    leftPawOffset = 0
                    rightPawOffset = -25  // Increased movement for visibility
                }
            }
            isLeft.toggle()
        }
    }

    private func resetPaws() {
        withAnimation(.easeInOut(duration: 0.2)) {
            leftPawOffset = 0
            rightPawOffset = 0
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