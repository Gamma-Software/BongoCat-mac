import SwiftUI
import Cocoa
import UserNotifications
import ServiceManagement

struct WelcomeScreen: View {
    @State private var currentStep = 0
    @State private var isAccessibilityEnabled = false
    @State private var areNotificationsEnabled = false
    @State private var isAutoStartEnabled = false
    @State private var showingSystemPreferences = false
    @State private var showingNotificationSettings = false

    @ObservedObject var appDelegate: AppDelegate
    var onDismiss: (() -> Void)?

    init(appDelegate: AppDelegate, onDismiss: @escaping () -> Void = {}) {
        self.appDelegate = appDelegate
        self.onDismiss = onDismiss
    }

        private let steps = [
        "Welcome",
        "Accessibility",
        "Notifications",
        "Auto-Start",
        "Position Setup",
        "Usage Guide",
        "Settings Overview",
        "Complete!"
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Header with progress
            VStack(spacing: 15) {
                HStack {
                    Text("BongoCat Setup")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    Button("Skip Setup") {
                        onDismiss?()
                    }
                    .buttonStyle(.bordered)
                }

                // Progress indicator
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }

                Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)

            // Step content
            ScrollView {
                VStack(spacing: 20) {
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        accessibilityStep
                    case 2:
                        notificationsStep
                    case 3:
                        autoStartStep
                    case 4:
                        positionSetupStep
                    case 5:
                        usageGuideStep
                    case 6:
                        settingsOverviewStep
                    case 7:
                        completeStep
                    default:
                        EmptyView()
                    }
                }
                .frame(minHeight: 300)
                .padding(.horizontal, 30)
            }

            // Navigation buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < steps.count - 1 {
                    Button("Next") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started!") {
                        onDismiss?()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkAllStatuses()
        }
    }

    // MARK: - Step Views

        private var welcomeStep: some View {
        VStack(spacing: 20) {
            // Use the BongoCat logo instead of paw print
            if let logoImage = loadLogoImage() {
                Image(nsImage: logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
            } else {
                // Fallback to system icon if logo can't be loaded
                Image(systemName: "cat.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
            }

            Text("Welcome to BongoCat! 🐱")
                .font(.title)
                .fontWeight(.bold)

            Text("Your animated cat companion that responds to your keyboard and mouse input. Let's get everything set up for the best experience!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "keyboard", title: "Keyboard & Mouse Tracking", description: "Monitors your input to animate the cat")
                FeatureRow(icon: "app.badge", title: "Per-App Positioning", description: "Remembers cat position for each application")
                FeatureRow(icon: "slider.horizontal.3", title: "Customizable", description: "Scale, rotation, and visual options")
                FeatureRow(icon: "chart.bar", title: "Stroke Counter", description: "Track your typing and clicking activity")
            }
            .padding(.top, 10)
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: isAccessibilityEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(isAccessibilityEnabled ? .green : .orange)

                VStack(alignment: .leading) {
                    Text("Accessibility Permissions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(isAccessibilityEnabled ? "✅ Enabled" : "⚠️ Required")
                        .foregroundColor(isAccessibilityEnabled ? .green : .orange)
                        .fontWeight(.medium)
                }
            }

            Text("BongoCat needs accessibility permissions to monitor your keyboard and mouse input. This is essential for the cat to respond to your actions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if !isAccessibilityEnabled {
                VStack(spacing: 12) {
                    Text("How to enable:")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        StepInstruction(number: 1, text: "Open System Preferences")
                        StepInstruction(number: 2, text: "Go to Privacy & Security")
                        StepInstruction(number: 3, text: "Select Accessibility from the left sidebar")
                        StepInstruction(number: 4, text: "Click the lock icon and enter your password")
                        StepInstruction(number: 5, text: "Check the box next to BongoCat")
                    }

                    Button("Open System Preferences") {
                        openSystemPreferences()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Button("Check Again") {
                checkAccessibilityStatus()
            }
            .buttonStyle(.bordered)
        }
    }

        private var notificationsStep: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: areNotificationsEnabled ? "bell.fill" : "bell.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(areNotificationsEnabled ? .green : .blue)

                VStack(alignment: .leading) {
                    Text("Notification Settings")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(areNotificationsEnabled ? "✅ Enabled" : "📱 Optional")
                        .foregroundColor(areNotificationsEnabled ? .green : .blue)
                        .fontWeight(.medium)
                }
            }

            // Check if we're in development mode
            let bundleURL = Bundle.main.bundleURL
            let isDevelopmentMode = bundleURL.path.contains(".build") || bundleURL.path.contains("debug")

            if isDevelopmentMode {
                Text("Notifications are not available when running in development mode. They will work when the app is properly packaged.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("Enable notifications to get milestone alerts and update notifications. This helps you track your progress and stay updated.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                FeatureRow(icon: "trophy.fill", title: "Milestone Notifications", description: "Celebrate typing achievements")
                FeatureRow(icon: "arrow.down.circle.fill", title: "Update Notifications", description: "Stay informed about new versions")
                FeatureRow(icon: "gear", title: "Customizable", description: "Enable/disable anytime from menu")
            }

            if !areNotificationsEnabled && !isDevelopmentMode {
                Button("Enable Notifications") {
                    requestNotificationPermissions()
                }
                .buttonStyle(.borderedProminent)
            }

            if isDevelopmentMode {
                Button("Development Mode - Notifications Disabled") {
                    // Show info about development mode
                    let alert = NSAlert()
                    alert.messageText = "Development Mode"
                    alert.informativeText = "Notifications are not available when running in development mode. They will work when the app is properly packaged and distributed."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                .buttonStyle(.bordered)
                .disabled(true)
            } else {
                Button("Check Status") {
                    checkNotificationStatus()
                }
                .buttonStyle(.bordered)
            }
        }
    }

        private var autoStartStep: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: isAutoStartEnabled ? "power.fill" : "power")
                    .font(.system(size: 50))
                    .foregroundColor(isAutoStartEnabled ? .green : .blue)

                VStack(alignment: .leading) {
                    Text("Auto-Start at Launch")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(isAutoStartEnabled ? "✅ Enabled" : "⚙️ Optional")
                        .foregroundColor(isAutoStartEnabled ? .green : .blue)
                        .fontWeight(.medium)
                }
            }

            Text("Automatically start BongoCat when you log in to your Mac. This ensures your cat companion is always ready when you need it.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                FeatureRow(icon: "checkmark.circle.fill", title: "Convenient", description: "No need to manually start each time")
                FeatureRow(icon: "gear", title: "Manageable", description: "Can be toggled anytime from menu")
                FeatureRow(icon: "shield", title: "Secure", description: "Uses macOS system services")
            }

            HStack(spacing: 20) {
                Button("Enable Auto-Start") {
                    enableAutoStart()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAutoStartEnabled)

                Button("Disable Auto-Start") {
                    disableAutoStart()
                }
                .buttonStyle(.bordered)
                .disabled(!isAutoStartEnabled)
            }

            Button("Check Status") {
                checkAutoStartStatus()
            }
            .buttonStyle(.bordered)
        }
    }

    private var positionSetupStep: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Position Setup")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("📍 Configure")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }

            Text("Let's set up where your cat companion should appear on screen. You can always change this later.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                PositionOption(
                    icon: "arrow.up.left",
                    title: "Top-Left Corner",
                    description: "Cat appears in the top-left corner of the screen"
                ) {
                    appDelegate.setCornerPositionPublic(.topLeft)
                }

                PositionOption(
                    icon: "arrow.up.right",
                    title: "Top-Right Corner",
                    description: "Cat appears in the top-right corner of the screen"
                ) {
                    appDelegate.setCornerPositionPublic(.topRight)
                }

                PositionOption(
                    icon: "arrow.down.left",
                    title: "Bottom-Left Corner",
                    description: "Cat appears in the bottom-left corner of the screen"
                ) {
                    appDelegate.setCornerPositionPublic(.bottomLeft)
                }

                PositionOption(
                    icon: "arrow.down.right",
                    title: "Bottom-Right Corner",
                    description: "Cat appears in the bottom-right corner of the screen"
                ) {
                    appDelegate.setCornerPositionPublic(.bottomRight)
                }
            }

            Text("The cat will remember its position for each application you use.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var usageGuideStep: some View {
        VStack(spacing: 20) {
            Text("How to Use BongoCat")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Here are the basics to get you started:")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                UsageInstruction(
                    icon: "menubar.dock.rectangle",
                    title: "Menu Bar Icon",
                    description: "Click the cat icon in the menu bar for options and settings"
                )

                UsageInstruction(
                    icon: "cursorarrow.click",
                    title: "Right-Click the Cat",
                    description: "Right-click on the cat overlay for quick actions and positioning"
                )

                UsageInstruction(
                    icon: "arrow.up.left.and.arrow.down.right",
                    title: "Drag to Move",
                    description: "Hold ⌘ and drag the cat to reposition it"
                )

                UsageInstruction(
                    icon: "app.badge",
                    title: "Per-App Memory",
                    description: "The cat remembers its position for each application"
                )

                UsageInstruction(
                    icon: "chart.bar",
                    title: "Stroke Counter",
                    description: "View your typing and clicking statistics in the menu"
                )
            }
        }
    }

    private var settingsOverviewStep: some View {
        VStack(spacing: 20) {
            Text("Settings Overview")
                .font(.title2)
                .fontWeight(.semibold)

            Text("BongoCat offers many customization options:")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 15) {
                SettingsCategory(
                    title: "Appearance",
                    items: ["Scale (size)", "Rotation", "Horizontal Flip", "Scale Pulse on Input"]
                )

                SettingsCategory(
                    title: "Behavior",
                    items: ["Paw Behavior (Random/Keyboard/Alternating)", "Ignore Clicks", "Click Through"]
                )

                SettingsCategory(
                    title: "Positioning",
                    items: ["Per-App Positioning", "Corner Positions", "Manual Positioning"]
                )

                SettingsCategory(
                    title: "Advanced",
                    items: ["Per-App Hiding", "Stroke Counter", "Milestone Notifications"]
                )
            }

            Text("Access all settings from the menu bar icon or right-click the cat overlay.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var completeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            Text("You're All Set! 🎉")
                .font(.title)
                .fontWeight(.bold)

            Text("BongoCat is ready to be your typing companion! The cat will appear and respond to your keyboard and mouse input.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                StatusRow(icon: "checkmark.circle.fill", text: "Accessibility permissions configured", isEnabled: isAccessibilityEnabled)
                StatusRow(icon: "bell.fill", text: "Notifications configured", isEnabled: areNotificationsEnabled)
                StatusRow(icon: "power.fill", text: "Auto-start configured", isEnabled: isAutoStartEnabled)
            }
            .padding(.top, 10)

            Text("You can always access this setup guide from the menu bar icon under 'Welcome Guide'.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helper Methods

    private func checkAllStatuses() {
        checkAccessibilityStatus()
        checkNotificationStatus()
        checkAutoStartStatus()
    }

    private func checkAccessibilityStatus() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func checkNotificationStatus() {
        // Check if we're running in development mode (not as a proper app bundle)
        let bundleURL = Bundle.main.bundleURL
        let isDevelopmentMode = bundleURL.path.contains(".build") || bundleURL.path.contains("debug")

        if isDevelopmentMode {
            // In development mode, assume notifications are not available
            DispatchQueue.main.async {
                areNotificationsEnabled = false
            }
            return
        }

        // Only check notifications if we're running as a proper app
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                areNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func checkAutoStartStatus() {
        // Check if auto-start is enabled in our settings
        isAutoStartEnabled = appDelegate.autoStartAtLaunchEnabled
    }

    private func requestNotificationPermissions() {
        // Check if we're running in development mode
        let bundleURL = Bundle.main.bundleURL
        let isDevelopmentMode = bundleURL.path.contains(".build") || bundleURL.path.contains("debug")

        if isDevelopmentMode {
            // In development mode, show a message that notifications aren't available
            DispatchQueue.main.async {
                areNotificationsEnabled = false
            }

            // Show an alert to inform the user
            let alert = NSAlert()
            alert.messageText = "Notifications Not Available"
            alert.informativeText = "Notifications are not available when running in development mode. They will work when the app is properly packaged."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        // Only request notifications if we're running as a proper app
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                areNotificationsEnabled = granted
                if granted {
                    // Enable milestone notifications
                    appDelegate.milestoneManager.setNotificationsEnabled(true)
                    // Enable update notifications
                    appDelegate.updateChecker.setUpdateNotificationsEnabled(true)
                }
            }
        }
    }

    private func enableAutoStart() {
        appDelegate.autoStartAtLaunchEnabled = true
        appDelegate.saveAutoStartAtLaunchPreference()
        checkAutoStartStatus()
    }

    private func disableAutoStart() {
        appDelegate.autoStartAtLaunchEnabled = false
        appDelegate.saveAutoStartAtLaunchPreference()
        checkAutoStartStatus()
    }

        private func loadLogoImage() -> NSImage? {
        // Try to load the logo from various possible locations
        let possiblePaths = [
            "logo.png",
            "Assets/Icons/logo.png",
            "Sources/BongoCat/Resources/logo.png",
            "Assets/logo.png",
            Bundle.main.path(forResource: "logo", ofType: "png")
        ]

        for path in possiblePaths.compactMap({ $0 }) {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }

        // Try Bundle.module for Swift Package Manager
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: "logo", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        #endif

        // Try Bundle.main for packaged app
        if let bundleImage = NSImage(named: "logo") {
            return bundleImage
        }

        return nil
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

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct StepInstruction: View {
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

struct UsageInstruction: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SettingsCategory: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.orange)

            ForEach(items, id: \.self) { item in
                HStack {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct StatusRow: View {
    let icon: String
    let text: String
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .green : .gray)
                .frame(width: 20)

            Text(text)
                .font(.body)
                .foregroundColor(isEnabled ? .primary : .secondary)

            Spacer()
        }
    }
}

struct PositionOption: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WelcomeScreen(appDelegate: AppDelegate()) {
        // Preview dismiss
    }
}