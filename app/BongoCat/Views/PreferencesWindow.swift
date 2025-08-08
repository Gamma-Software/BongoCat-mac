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
                        Text("Scale")
                            .frame(width: 200, alignment: .leading)

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

                    HStack {
                        Text("Scale pulse on input")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.scaleOnInputEnabled },
                            set: { newValue in
                                if newValue != appDelegate.scaleOnInputEnabled {
                                    appDelegate.toggleScalePulse()
                                }
                            }
                        ))
                        Spacer()
                    }

                    HStack {
                        Text("Rotate cat")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.currentRotation != 0.0 },
                            set: { newValue in
                                if newValue {
                                    // When enabling rotation, use 13° if not flipped, -13° if flipped
                                    appDelegate.currentRotation = appDelegate.isFlippedHorizontally ? -13.0 : 13.0
                                } else {
                                    // When disabling rotation, always go back to 0°
                                    appDelegate.currentRotation = 0.0
                                }
                                appDelegate.saveRotation()
                                appDelegate.updateOverlay()
                            }
                        ))
                        Spacer()
                    }

                    HStack {
                        Text("Flip horizontally")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.isFlippedHorizontally },
                            set: { newValue in
                                appDelegate.isFlippedHorizontally = newValue

                                // If the cat is currently rotated, adjust the rotation for the new flip state
                                if appDelegate.currentRotation != 0.0 {
                                    appDelegate.currentRotation = newValue ? -13.0 : 13.0
                                    appDelegate.saveRotation()
                                }

                                appDelegate.saveFlip()
                                appDelegate.updateOverlay()
                            }
                        ))
                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "App Behavior") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Auto-start at launch")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.autoStartAtLaunchEnabled },
                            set: { newValue in
                                if newValue != appDelegate.autoStartAtLaunchEnabled {
                                    appDelegate.toggleAutoStartAtLaunch()
                                }
                            }
                        ))
                        Spacer()
                    }
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
                        Text("Paw behavior")
                            .frame(width: 200, alignment: .leading)

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

                    HStack {
                        Text("Ignore mouse clicks")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.ignoreClicksEnabled },
                            set: { newValue in
                                if newValue != appDelegate.ignoreClicksEnabled {
                                    appDelegate.toggleIgnoreClicks()
                                }
                            }
                        ))
                        Spacer()
                    }

                    HStack {
                        Text("Click through (Hold ⌘ to drag)")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.clickThroughEnabled },
                            set: { newValue in
                                if newValue != appDelegate.clickThroughEnabled {
                                    appDelegate.toggleClickThrough()
                                }
                            }
                        ))
                        Spacer()
                    }
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
                        Text("Corner position")
                            .frame(width: 200, alignment: .leading)

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

                    HStack {
                        Text("Per-app positioning")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.isPerAppPositioningEnabled },
                            set: { newValue in
                                if newValue != appDelegate.isPerAppPositioningEnabled {
                                    appDelegate.togglePerAppPositioning()
                                }
                            }
                        ))
                        Spacer()
                    }

                    HStack {
                        Text("Save current position")
                            .frame(width: 200, alignment: .leading)
                        Button("Save Current Position") {
                            appDelegate.saveCurrentPositionAction()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }

                    HStack {
                        Text("Restore saved position")
                            .frame(width: 200, alignment: .leading)
                        Button("Restore Saved Position") {
                            appDelegate.restoreSavedPosition()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                }
            }

                        if appDelegate.isPerAppPositioningEnabled {
                PreferencesSection(title: "Saved App Positions") {
                    VStack(alignment: .leading, spacing: 8) {
                        let savedPositions = appDelegate.getSavedPositionsWithAppNames()

                        if savedPositions.isEmpty {
                            Text("No saved positions")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            HStack {
                                Text("\(savedPositions.count) saved position\(savedPositions.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Button("Clear All") {
                                    appDelegate.clearAllSavedPositions()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.bottom, 4)

                                                        ForEach(savedPositions, id: \.bundleID) { position in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(position.appName)
                                            .font(.system(size: 13, weight: .medium))
                                        HStack(spacing: 4) {
                                            Text(position.bundleID)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                            Text(position.screenName)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text("(\(Int(position.position.x)), \(Int(position.position.y)))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .monospacedDigit()

                                    Button("Delete") {
                                        appDelegate.deleteSavedPosition(for: position.bundleID)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.vertical, 4)

                                if position.bundleID != savedPositions.last?.bundleID {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }

            if appDelegate.isPerAppPositioningEnabled {
                PreferencesSection(title: "Screen Management") {
                    VStack(alignment: .leading, spacing: 8) {
                        let screenInfo = appDelegate.getScreenInfo()

                        if screenInfo.isEmpty {
                            Text("No screens detected")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text("Current Screen: \(appDelegate.getCurrentScreen().map { appDelegate.getScreenName($0) } ?? "Unknown")")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(screenInfo, id: \.index) { info in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(appDelegate.getScreenName(info.screen))
                                                .font(.system(size: 13, weight: .medium))
                                            if info.isCurrent {
                                                Text("(Current)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        Text("\(Int(info.screen.frame.width))x\(Int(info.screen.frame.height))")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if !info.isCurrent {
                                        Button("Move Here") {
                                            appDelegate.moveOverlayToScreen(info.screen)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(.vertical, 4)

                                if info.index != screenInfo.last?.index {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }

            PreferencesSection(title: "App Visibility") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Per-app hiding")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
                            get: { appDelegate.isPerAppHidingEnabled },
                            set: { newValue in
                                if newValue != appDelegate.isPerAppHidingEnabled {
                                    appDelegate.togglePerAppHiding()
                                }
                            }
                        ))
                        Spacer()
                    }

                    if appDelegate.isPerAppHidingEnabled {
                        HStack {
                            Text("Hide for current app")
                                .frame(width: 200, alignment: .leading)
                            Button("Hide for Current App") {
                                appDelegate.hideForCurrentApp()
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }

                        HStack {
                            Text("Show for current app")
                                .frame(width: 200, alignment: .leading)
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
                                .padding(.leading, 200)
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
            PreferencesSection(title: "Updates") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Check for updates")
                            .frame(width: 200, alignment: .leading)
                        Button("Check for Updates 🔄") {
                            appDelegate.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }

                    HStack {
                        Text("Update notifications")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
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
                        Spacer()
                    }

                    HStack {
                        Text("Auto-update")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
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
                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "Notifications") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Milestone notifications")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
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
                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "Privacy") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Analytics & Privacy")
                            .frame(width: 200, alignment: .leading)
                        Toggle("", isOn: Binding(
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
                        Spacer()
                    }

                    Text("Help improve BongoCat by sharing anonymous usage data. No personal information is collected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 0)
                }
            }

            PreferencesSection(title: "Statistics") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Total strokes")
                            .frame(width: 200, alignment: .leading)
                        Text(strokeCount)
                        Spacer()
                    }

                    HStack {
                        Text("Reset counter")
                            .frame(width: 200, alignment: .leading)
                        Button("Reset Stroke Counter") {
                            appDelegate.resetStrokeCounter()
                            updateStrokeCount()
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                }
            }

            PreferencesSection(title: "Reset") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Factory defaults")
                            .frame(width: 200, alignment: .leading)
                        Button("Reset to Factory Defaults") {
                            appDelegate.resetToFactoryDefaults()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        Spacer()
                    }

                    Text("This will reset all settings to their default values.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 200)
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

                        Button("Tweet about BongoCat 🐦") {
                            appDelegate.tweetAboutBongoCat()
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

                    HStack {
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

        window.title = "BongoCat Preferences"
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")

        // Make it stay on top and not dismiss when clicking outside
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Prevent the window from being hidden when clicking outside
        window.hidesOnDeactivate = false

        window.contentView = NSHostingView(rootView: PreferencesWindow(appDelegate: appDelegate))

        self.init(window: window)
    }
}