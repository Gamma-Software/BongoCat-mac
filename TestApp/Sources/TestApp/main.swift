import Cocoa
import ApplicationServices

func getActiveAppPosition() -> CGRect? {
    guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
        print("No frontmost application found.")
        return nil
    }
    let pid = frontmostApp.processIdentifier
    let appElement = AXUIElementCreateApplication(pid)
    var windowList: CFArray?
    let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)
    guard result == .success, let windows = windowList as? [AXUIElement], let firstWindow = windows.first else {
        print("No windows found for app: \(frontmostApp.localizedName ?? "Unknown")")
        return nil
    }
    var positionValue: CFTypeRef?
    let posResult = AXUIElementCopyAttributeValue(firstWindow, kAXPositionAttribute as CFString, &positionValue)
    var sizeValue: CFTypeRef?
    let sizeResult = AXUIElementCopyAttributeValue(firstWindow, kAXSizeAttribute as CFString, &sizeValue)
    if posResult == .success, sizeResult == .success,
       let pos = positionValue as? AXValue, let size = sizeValue as? AXValue {
        var point = CGPoint.zero
        var sizeStruct = CGSize.zero
        AXValueGetValue(pos, .cgPoint, &point)
        AXValueGetValue(size, .cgSize, &sizeStruct)
        return CGRect(origin: point, size: sizeStruct)
    }
    print("Could not get position/size for app: \(frontmostApp.localizedName ?? "Unknown")")
    return nil
}

func printActiveAppPosition() {
    if let app = NSWorkspace.shared.frontmostApplication {
        print("Active app: \(app.localizedName ?? "Unknown") (PID: \(app.processIdentifier))")
        if let frame = getActiveAppPosition() {
            print("Window frame: \(frame)")
        }
    } else {
        print("No active app detected.")
    }
}

// Poll every second
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    printActiveAppPosition()
}

RunLoop.main.run()