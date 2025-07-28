import SwiftUI
import Cocoa

struct PreferencesWindow: View {
    @ObservedObject var appDelegate: AppDelegate
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                PreferencesTabButton(
                    title: "General",
                    systemImage: "gearshape",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }

                PreferencesTabButton(
                    title: "Behavior",
                    systemImage: "hand.tap",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }

                PreferencesTabButton(
                    title: "Position",
                    systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }

                PreferencesTabButton(
                    title: "Advanced",
                    systemImage: "slider.horizontal.3",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }

                PreferencesTabButton(
                    title: "About",
                    systemImage: "info.circle",
                    isSelected: selectedTab == 4
                ) {
                    selectedTab = 4
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Divider()
                .padding(.top, 10)

            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case 0:
                        GeneralPreferencesView(appDelegate: appDelegate)
                    case 1:
                        BehaviorPreferencesView(appDelegate: appDelegate)
                    case 2:
                        PositionPreferencesView(appDelegate: appDelegate)
                    case 3:
                        AdvancedPreferencesView(appDelegate: appDelegate)
                    case 4:
                        AboutPreferencesView(appDelegate: appDelegate)
                    default:
                        GeneralPreferencesView(appDelegate: appDelegate)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PreferencesTabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .accentColor : .secondary)

                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

struct GeneralPreferencesView: View {
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferencesSection(title: "Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scale:")
                            .frame(width: 120, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { appDelegate.currentScale },
                            set: { newValue in
                                appDelegate.currentScale = newValue
                                appDelegate.saveScale()
                                appDelegate.updateOverlay()
                            }
                        )) {
                            Text("Small (65%)").tag(0.65)
                            Text("Medium (75%)").tag(0.75)
                            Text("Big (100%)").tag(1.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)

                        Spacer()
                    }

                    Toggle("Scale Pulse on Input", isOn: Binding(
                        get: { appDelegate.scaleOnInputEnabled },
                        set: { newValue in
                            if newValue != appDelegate.scaleOnInputEnabled {
                                appDelegate.toggleScalePulse()
                            }
                        }
                    ))

                    Toggle("Rotate Cat", isOn: Binding(
                        get: { appDelegate.currentRotation != 0.0 },
                        set: { newValue in
                            appDelegate.currentRotation = newValue ? 13.0 : 0.0
                            appDelegate.saveRotation()
                            appDelegate.updateOverlay()
                        }
                    ))

                    Toggle("Flip Horizontally", isOn: Binding(
                        get: { appDelegate.isFlippedHorizontally },
                        set: { newValue in
                            appDelegate.isFlippedHorizontally = newValue
                            appDelegate.saveFlip()
                            appDelegate.updateOverlay()
                        }
                    ))
                }
            }
        }
    }
}

struct BehaviorPreferencesView: View {
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferencesSection(title: "Input Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Paw Behavior:")
                            .frame(width: 120, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { appDelegate.pawBehaviorMode },
                            set: { newValue in
                                appDelegate.pawBehaviorMode = newValue
                                appDelegate.savePawBehaviorPreference()
                            }
                        )) {
                            Text("Keyboard Layout").tag(PawBehaviorMode.keyboardLayout)
                            Text("Random").tag(PawBehaviorMode.random)
                            Text("Alternating").tag(PawBehaviorMode.alternating)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)

                        Spacer()
                    }

                    Toggle("Ignore Mouse Clicks", isOn: Binding(
                        get: { appDelegate.ignoreClicksEnabled },
                        set: { newValue in
                            if newValue != appDelegate.ignoreClicksEnabled {
                                appDelegate.toggleIgnoreClicks()
                            }
                        }
                    ))

                    Toggle("Click Through (Hold ⌘ to Drag)", isOn: Binding(
                        get: { appDelegate.clickThroughEnabled },
                        set: { newValue in
                            if newValue != appDelegate.clickThroughEnabled {
                                appDelegate.toggleClickThrough()
                            }
                        }
                    ))
                }
            }
        }
    }
}

struct PositionPreferencesView: View {
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferencesSection(title: "Window Position") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Corner Position:")
                            .frame(width: 120, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { appDelegate.currentCornerPosition },
                            set: { newValue in
                                appDelegate.currentCornerPosition = newValue
                                appDelegate.savePositionPreferences()
                                if newValue != .custom {
                                    appDelegate.setPosition(to: newValue)
                                }
                            }
                        )) {
                            ForEach(CornerPosition.allCases.filter { $0 != .custom }, id: \.self) { corner in
                                Text(corner.displayName).tag(corner)
                            }
                            Text("Custom").tag(CornerPosition.custom)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)

                        Spacer()
                    }

                    Toggle("Per-App Positioning", isOn: Binding(
                        get: { appDelegate.isPerAppPositioningEnabled },
                        set: { newValue in
                            if newValue != appDelegate.isPerAppPositioningEnabled {
                                appDelegate.togglePerAppPositioning()
                            }
                        }
                    ))

                    HStack {
                        Button("Save Current Position") {
                            appDelegate.saveCurrentPositionAction()
                        }
                        .buttonStyle(.bordered)

                        Button("Restore Saved Position") {
                            appDelegate.restoreSavedPosition()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "App Visibility") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Per-App Hiding", isOn: Binding(
                        get: { appDelegate.isPerAppHidingEnabled },
                        set: { newValue in
                            if newValue != appDelegate.isPerAppHidingEnabled {
                                appDelegate.togglePerAppHiding()
                            }
                        }
                    ))

                    if appDelegate.isPerAppHidingEnabled {
                                                HStack {
                            Button("Hide for Current App") {
                                appDelegate.hideForCurrentApp()
                            }
                            .buttonStyle(.bordered)

                            Button("Show for Current App") {
                                appDelegate.showForCurrentApp()
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }

                        if !appDelegate.perAppHiddenApps.isEmpty {
                            Text("Hidden Apps: \(appDelegate.perAppHiddenApps.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

struct AdvancedPreferencesView: View {
    @ObservedObject var appDelegate: AppDelegate
    @State private var strokeCount: String = "Loading..."

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferencesSection(title: "Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                                                                                Toggle("Milestone Notifications 🔔", isOn: Binding(
                        get: {
                            let enabled = appDelegate.milestoneManager.isNotificationsEnabled()
                            print("🔔 Getting milestone notifications enabled: \(enabled)")
                            return enabled
                        },
                        set: { newValue in
                            print("🔔 Setting milestone notifications enabled: \(newValue)")
                            appDelegate.milestoneManager.setNotificationsEnabled(newValue)
                            appDelegate.updateMilestoneNotificationsMenuItem()
                            appDelegate.triggerSettingsUpdate()
                        }
                    ))

                                                            Toggle("Update Notifications 🔄", isOn: Binding(
                        get: {
                            let enabled = appDelegate.updateChecker.isUpdateNotificationsEnabled()
                            print("🔄 Getting update notifications enabled: \(enabled)")
                            return enabled
                        },
                        set: { newValue in
                            print("🔄 Setting update notifications enabled: \(newValue)")
                            appDelegate.updateChecker.setUpdateNotificationsEnabled(newValue)
                            appDelegate.updateUpdateNotificationsMenuItem()
                            appDelegate.triggerSettingsUpdate()
                        }
                    ))

                                                            Toggle("Auto-Update ⚡", isOn: Binding(
                        get: {
                            let enabled = appDelegate.updateChecker.isAutoUpdateEnabled()
                            print("⚡ Getting auto-update enabled: \(enabled)")
                            return enabled
                        },
                        set: { newValue in
                            print("⚡ Setting auto-update enabled: \(newValue)")
                            appDelegate.updateChecker.setAutoUpdateEnabled(newValue)
                            appDelegate.updateAutoUpdateMenuItem()
                            appDelegate.triggerSettingsUpdate()
                        }
                    ))
                }
            }

            PreferencesSection(title: "Privacy") {
                VStack(alignment: .leading, spacing: 12) {
                                                            Toggle("Analytics & Privacy 📊", isOn: Binding(
                        get: {
                            let enabled = appDelegate.analytics.isAnalyticsEnabled
                            print("📊 Getting analytics enabled: \(enabled)")
                            return enabled
                        },
                        set: { newValue in
                            print("📊 Setting analytics enabled: \(newValue)")
                            appDelegate.analytics.setAnalyticsEnabled(newValue)
                            appDelegate.updateAnalyticsMenuItem()
                            appDelegate.triggerSettingsUpdate()
                        }
                    ))

                    Text("Help improve BangoCat by sharing anonymous usage data. No personal information is collected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            PreferencesSection(title: "Statistics") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Total Strokes:")
                            .frame(width: 120, alignment: .leading)
                        Text(strokeCount)
                        Spacer()
                    }

                    Button("Reset Stroke Counter") {
                        appDelegate.resetStrokeCounter()
                        updateStrokeCount()
                    }
                    .buttonStyle(.bordered)
                }
            }

            PreferencesSection(title: "Reset") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Reset to Factory Defaults") {
                        appDelegate.resetToFactoryDefaults()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)

                    Text("This will reset all settings to their default values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            updateStrokeCount()
        }
    }

    private func updateStrokeCount() {
        if let strokeCounter = appDelegate.overlayWindow?.catAnimationController?.strokeCounter {
            strokeCount = "\(strokeCounter.totalStrokes)"
        } else {
            strokeCount = "0"
        }
    }
}

struct AboutPreferencesView: View {
    @ObservedObject var appDelegate: AppDelegate

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PreferencesSection(title: "Application Information") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version:")
                            .frame(width: 80, alignment: .leading)
                        Text(appDelegate.getVersionString())
                        Spacer()
                    }

                    HStack {
                        Text("Author:")
                            .frame(width: 80, alignment: .leading)
                        Text("Valentin Rudloff")
                        Spacer()
                    }

                    HStack {
                        Text("Website:")
                            .frame(width: 80, alignment: .leading)
                        Button("https://valentin.pival.fr") {
                            if let url = URL(string: "https://valentin.pival.fr") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "Support") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Buy me a coffee ☕") {
                            appDelegate.buyMeACoffee()
                        }
                        .buttonStyle(.bordered)

                        Button("Tweet about BangoCat 🐦") {
                            appDelegate.tweetAboutBangoCat()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    HStack {
                        Button("Visit Website") {
                            appDelegate.visitWebsite()
                        }
                        .buttonStyle(.bordered)

                        Button("View Changelog 📋") {
                            appDelegate.viewChangelog()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "Updates & Support") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Check for Updates 🔄") {
                            appDelegate.checkForUpdates()
                        }
                        .buttonStyle(.bordered)

                        Button("Report a Bug 🐛") {
                            appDelegate.reportBug()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }
        }
    }
}

struct PreferencesSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            content
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

class PreferencesWindowController: NSWindowController {
    convenience init(appDelegate: AppDelegate) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "BangoCat Preferences"
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.contentView = NSHostingView(rootView: PreferencesWindow(appDelegate: appDelegate))

        self.init(window: window)
    }
}