import SwiftUI
import Cocoa

struct FirstLaunchGuide: View {
    @State private var currentStep = 0
    @State private var isAccessibilityEnabled = false
    @State private var showingSystemPreferences = false

    private let steps = [
        "Welcome to BongoCat!",
        "Accessibility Permissions",
        "How to Enable",
        "Test Your Setup",
        "You're Ready!"
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Text("BongoCat Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Let's get your cat companion ready!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.horizontal)

            // Step content
            VStack(spacing: 20) {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    permissionsStep
                case 2:
                    howToEnableStep
                case 3:
                    testStep
                case 4:
                    readyStep
                default:
                    EmptyView()
                }
            }
            .frame(minHeight: 200)
            .padding(.horizontal, 30)

            // Navigation buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button(currentStep == steps.count - 2 ? "Finish" : "Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started!") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkAccessibilityStatus()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 15) {
            Text("🐱 Welcome to BongoCat!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("BongoCat is an animated cat overlay that responds to your keyboard and mouse input. To work properly, it needs accessibility permissions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Monitors keyboard and mouse input")
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Remembers position for each app")
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Customizable appearance and behavior")
                }
            }
            .padding(.top, 10)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 15) {
            Text("🔐 Accessibility Permissions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("BongoCat needs accessibility permissions to monitor your keyboard and mouse input. This allows the cat to react to your actions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: isAccessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isAccessibilityEnabled ? .green : .red)
                    .font(.title2)

                Text(isAccessibilityEnabled ? "Accessibility is enabled" : "Accessibility is not enabled")
                    .fontWeight(.medium)
            }
            .padding(.top, 10)

            if !isAccessibilityEnabled {
                Button("Open System Preferences") {
                    showingSystemPreferences = true
                }
                .buttonStyle(.borderedProminent)
                .onTapGesture {
                    openSystemPreferences()
                }
            }
        }
    }

    private var howToEnableStep: some View {
        VStack(spacing: 15) {
            Text("📋 How to Enable Accessibility")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                StepRow(number: 1, text: "Open System Preferences")
                StepRow(number: 2, text: "Go to Security & Privacy")
                StepRow(number: 3, text: "Click the Privacy tab")
                StepRow(number: 4, text: "Select Accessibility from the left sidebar")
                StepRow(number: 5, text: "Click the lock icon and enter your password")
                StepRow(number: 6, text: "Check the box next to BongoCat")
            }
            .padding(.top, 10)

            Button("Open System Preferences") {
                openSystemPreferences()
            }
            .buttonStyle(.bordered)
        }
    }

    private var testStep: some View {
        VStack(spacing: 15) {
            Text("🧪 Test Your Setup")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Let's verify that accessibility permissions are working correctly.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: isAccessibilityEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isAccessibilityEnabled ? .green : .red)
                    .font(.title2)

                Text(isAccessibilityEnabled ? "✅ Permissions working!" : "❌ Permissions not detected")
                    .fontWeight(.medium)
            }
            .padding(.top, 10)

            if !isAccessibilityEnabled {
                Text("Please enable accessibility permissions and try again.")
                    .foregroundColor(.orange)
                    .font(.caption)
            }

            Button("Check Again") {
                checkAccessibilityStatus()
            }
            .buttonStyle(.bordered)
        }
    }

    private var readyStep: some View {
        VStack(spacing: 15) {
            Text("🎉 You're Ready!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("BongoCat is now ready to use! The cat will appear and respond to your keyboard and mouse input.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Right-click the cat for options")
                }

                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Use the menu bar icon for settings")
                }

                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("The cat remembers its position per app")
                }
            }
            .padding(.top, 10)
        }
    }

    private func checkAccessibilityStatus() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func openSystemPreferences() {
        let script = """
        tell application "System Preferences"
            activate
            set current pane to pane id "com.apple.preference.security"
        end tell
        """

        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(nil)
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    FirstLaunchGuide()
}