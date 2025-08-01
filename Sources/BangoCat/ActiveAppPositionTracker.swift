import Cocoa
import ApplicationServices

/// Tracks the position and size of the current active application window
/// Uses macOS Accessibility APIs to get window information
class ActiveAppPositionTracker: ObservableObject {

    // MARK: - Published Properties

    @Published var currentAppInfo: AppInfo?
    @Published var windowFrame: CGRect?
    @Published var isTracking: Bool = false

    // MARK: - Private Properties

    private var trackingTimer: Timer?
    private let trackingInterval: TimeInterval = 1.0

    // MARK: - App Info Structure

    struct AppInfo {
        let bundleIdentifier: String
        let localizedName: String
        let processIdentifier: pid_t
        let windowFrame: CGRect?

        var displayName: String {
            return localizedName.isEmpty ? bundleIdentifier : localizedName
        }
    }

    // MARK: - Public Methods

    /// Start tracking the active app position
    func startTracking() {
        guard !isTracking else { return }

        isTracking = true
        trackingTimer = Timer.scheduledTimer(withTimeInterval: trackingInterval, repeats: true) { [weak self] _ in
            self?.updateActiveAppInfo()
        }

        // Get initial app info
        updateActiveAppInfo()

        print("🔍 Active app position tracking started")
    }

    /// Stop tracking the active app position
    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        trackingTimer?.invalidate()
        trackingTimer = nil

        currentAppInfo = nil
        windowFrame = nil

        print("🔍 Active app position tracking stopped")
    }

    /// Get current active app information
    func getCurrentActiveAppInfo() -> AppInfo? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return nil
        }

        let bundleID = frontmostApp.bundleIdentifier ?? "unknown"
        let appName = frontmostApp.localizedName ?? "Unknown App"
        let pid = frontmostApp.processIdentifier

        let windowFrame = getWindowFrame(for: pid)

        return AppInfo(
            bundleIdentifier: bundleID,
            localizedName: appName,
            processIdentifier: pid,
            windowFrame: windowFrame
        )
    }

    /// Print current active app information to console
    func printCurrentAppInfo() {
        guard let appInfo = getCurrentActiveAppInfo() else {
            print("❌ No active app detected")
            return
        }

        print("📱 Active App: \(appInfo.displayName)")
        print("   Bundle ID: \(appInfo.bundleIdentifier)")
        print("   Process ID: \(appInfo.processIdentifier)")

        if let frame = appInfo.windowFrame {
            print("   Window Frame: \(frame)")
            print("   Position: (\(frame.origin.x), \(frame.origin.y))")
            print("   Size: \(frame.size.width) × \(frame.size.height)")
        } else {
            print("   Window Frame: Not available")
        }
        print("---")
    }

    // MARK: - Private Methods

    private func updateActiveAppInfo() {
        let newAppInfo = getCurrentActiveAppInfo()

        // Update published properties
        currentAppInfo = newAppInfo
        windowFrame = newAppInfo?.windowFrame

        // Print to console for debugging
        printCurrentAppInfo()
    }

    private func getWindowFrame(for processID: pid_t) -> CGRect? {
        let appElement = AXUIElementCreateApplication(processID)

        // Get window list
        var windowList: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        guard windowResult == .success,
              let windows = windowList as? [AXUIElement],
              let firstWindow = windows.first else {
            return nil
        }

        // Get window position
        var positionValue: CFTypeRef?
        let posResult = AXUIElementCopyAttributeValue(firstWindow, kAXPositionAttribute as CFString, &positionValue)

        // Get window size
        var sizeValue: CFTypeRef?
        let sizeResult = AXUIElementCopyAttributeValue(firstWindow, kAXSizeAttribute as CFString, &sizeValue)

                guard posResult == .success,
              sizeResult == .success,
              let positionValue = positionValue,
              let sizeValue = sizeValue else {
            return nil
        }

        // Extract position and size
        var point = CGPoint.zero
        var sizeStruct = CGSize.zero

        let pointResult = AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
        let sizeValueResult = AXValueGetValue(sizeValue as! AXValue, .cgSize, &sizeStruct)

        guard pointResult && sizeValueResult else {
            return nil
        }

        return CGRect(origin: point, size: sizeStruct)
    }
}

// MARK: - Convenience Extensions

extension ActiveAppPositionTracker {

    /// Start tracking with console output
    func startTrackingWithConsoleOutput() {
        startTracking()
        print("🔍 Active app position tracker started")
        print("Press Ctrl+C to stop tracking")
    }

    /// Get formatted position string
    func getFormattedPosition() -> String {
        guard let appInfo = currentAppInfo else {
            return "No active app"
        }

        var result = "App: \(appInfo.displayName)"

        if let frame = appInfo.windowFrame {
            result += "\nPosition: (\(Int(frame.origin.x)), \(Int(frame.origin.y)))"
            result += "\nSize: \(Int(frame.size.width)) × \(Int(frame.size.height))"
        } else {
            result += "\nWindow frame: Not available"
        }

        return result
    }
}