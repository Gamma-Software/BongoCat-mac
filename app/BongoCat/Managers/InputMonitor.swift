import Cocoa

class InputMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var mouseEventMonitor: Any?
    private let callback: (InputType) -> Void

    init(callback: @escaping (InputType) -> Void) {
        self.callback = callback
    }

    func start() {
        startKeyboardMonitoring()
        startMouseMonitoring()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
        if let monitor = keyboardEventMonitorFallback {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitorFallback = nil
        }
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }

    // MARK: - CGEventTap keyboard monitoring (works during Mission Control)

    private func startKeyboardMonitoring() {
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, refcon -> Unmanaged<CGEvent>? in
                if let refcon = refcon {
                    let monitor = Unmanaged<InputMonitor>.fromOpaque(refcon).takeUnretainedValue()
                    monitor.handleCGKeyEvent(type: type, cgEvent: event)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: selfPtr
        )

        if let tap = tap {
            eventTap = tap
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("✅ CGEventTap keyboard monitor registered successfully")
        } else {
            print("⚠️ CGEventTap unavailable (Accessibility permission needed) — falling back to NSEvent")
            startKeyboardMonitoringFallback()
        }
    }

    // Fallback if CGEventTap fails (e.g. Accessibility not granted yet)
    private var keyboardEventMonitorFallback: Any?
    private func startKeyboardMonitoringFallback() {
        keyboardEventMonitorFallback = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            switch event.type {
            case .keyDown:
                if event.isARepeat { return }
                let key = event.charactersIgnoringModifiers ?? "unknown"
                self.callback(.keyboardDown(key: key))
            case .keyUp:
                let key = event.charactersIgnoringModifiers ?? "unknown"
                self.callback(.keyboardUp(key: key))
            case .flagsChanged:
                self.handleFlagsChangedNSEvent(event)
            default:
                break
            }
        }
        if keyboardEventMonitorFallback == nil {
            print("❌ Keyboard monitor failed to register — Input Monitoring permission likely not granted")
        } else {
            print("✅ NSEvent fallback keyboard monitor registered")
        }
    }

    // MARK: - CGEvent handling

    // CGEventKeyboardGetUnicodeString returns empty for function/special keys.
    // Map their keycodes to the same private-use-area chars that NSEvent would return.
    private static let keycodeToChar: [Int64: String] = [
        123: "\u{F702}", // Left Arrow
        124: "\u{F703}", // Right Arrow
        125: "\u{F701}", // Down Arrow
        126: "\u{F700}", // Up Arrow
        122: "\u{F704}", // F1
        120: "\u{F705}", // F2
         99: "\u{F706}", // F3
        118: "\u{F707}", // F4
         96: "\u{F708}", // F5
         97: "\u{F709}", // F6
         98: "\u{F70A}", // F7
        100: "\u{F70B}", // F8
        101: "\u{F70C}", // F9
        109: "\u{F70D}", // F10
        103: "\u{F70E}", // F11
        111: "\u{F70F}", // F12
        117: "\u{F728}", // Forward Delete
        115: "\u{F729}", // Home
        119: "\u{F72B}", // End
        116: "\u{F72C}", // Page Up
        121: "\u{F72D}", // Page Down
    ]

    func handleCGKeyEvent(type: CGEventType, cgEvent: CGEvent) {
        switch type {
        case .keyDown:
            let isRepeat = cgEvent.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if isRepeat { return }
            let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
            let key = InputMonitor.keycodeToChar[keyCode] ?? cgEventCharacters(cgEvent)
            print("⌨️ New key press detected (CGEventTap): \(key)")
            callback(.keyboardDown(key: key))

        case .keyUp:
            let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
            let key = InputMonitor.keycodeToChar[keyCode] ?? cgEventCharacters(cgEvent)
            print("⌨️ Key released (CGEventTap): \(key)")
            callback(.keyboardUp(key: key))

        case .flagsChanged:
            let flags = cgEvent.flags
            let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
            switch keyCode {
            case 55, 54:
                callback(flags.contains(.maskCommand)    ? .keyboardDown(key: "⌘") : .keyboardUp(key: "⌘"))
            case 58, 61:
                callback(flags.contains(.maskAlternate)  ? .keyboardDown(key: "⌥") : .keyboardUp(key: "⌥"))
            case 59, 62:
                callback(flags.contains(.maskControl)    ? .keyboardDown(key: "⌃") : .keyboardUp(key: "⌃"))
            case 56, 60:
                callback(flags.contains(.maskShift)      ? .keyboardDown(key: "⇧") : .keyboardUp(key: "⇧"))
            case 57:
                callback(flags.contains(.maskAlphaShift) ? .keyboardDown(key: "⇪") : .keyboardUp(key: "⇪"))
            case 63:
                callback(flags.contains(.maskSecondaryFn) ? .keyboardDown(key: "fn") : .keyboardUp(key: "fn"))
            default:
                break
            }

        default:
            break
        }
    }

    private func cgEventCharacters(_ cgEvent: CGEvent) -> String {
        var length: Int = 0
        var chars = [UniChar](repeating: 0, count: 4)
        cgEvent.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
        guard length > 0 else { return "unknown" }
        return NSString(characters: chars, length: length) as String
    }

    private func handleFlagsChangedNSEvent(_ event: NSEvent) {
        let flags = event.modifierFlags
        switch event.keyCode {
        case 55, 54:
            callback(flags.contains(.command)  ? .keyboardDown(key: "⌘") : .keyboardUp(key: "⌘"))
        case 58, 61:
            callback(flags.contains(.option)   ? .keyboardDown(key: "⌥") : .keyboardUp(key: "⌥"))
        case 59, 62:
            callback(flags.contains(.control)  ? .keyboardDown(key: "⌃") : .keyboardUp(key: "⌃"))
        case 56, 60:
            callback(flags.contains(.shift)    ? .keyboardDown(key: "⇧") : .keyboardUp(key: "⇧"))
        case 57:
            callback(flags.contains(.capsLock) ? .keyboardDown(key: "⇪") : .keyboardUp(key: "⇪"))
        case 63:
            callback(flags.contains(.function) ? .keyboardDown(key: "fn") : .keyboardUp(key: "fn"))
        default:
            break
        }
    }

    // MARK: - Mouse monitoring

    private func startMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .scrollWheel, .mouseMoved]) { [weak self] event in
            switch event.type {
            case .leftMouseDown:
                if event.subtype == .touch {
                    print("👆 Trackpad touch detected (via mouse down subtype) - treating as left click")
                    self?.callback(.leftClickDown)
                } else {
                    print("🖱️ Left mouse DOWN detected")
                    self?.callback(.leftClickDown)
                }
            case .leftMouseUp:
                print("🖱️ Left mouse UP detected")
                self?.callback(.leftClickUp)
            case .rightMouseDown:
                print("🖱️ Right mouse DOWN detected")
                self?.callback(.rightClickDown)
            case .rightMouseUp:
                print("🖱️ Right mouse UP detected")
                self?.callback(.rightClickUp)
            case .scrollWheel:
                break
            case .mouseMoved:
                break
            default:
                break
            }
        }
    }
}
