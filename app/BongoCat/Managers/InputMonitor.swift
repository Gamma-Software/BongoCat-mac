import Cocoa

class InputMonitor {
    private var keyboardEventMonitor: Any?
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
        if let monitor = keyboardEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitor = nil
        }

        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }

    private func startKeyboardMonitoring() {
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            switch event.type {
            case .keyDown:
                if event.isARepeat { return }
                let key = event.charactersIgnoringModifiers ?? "unknown"
                print("⌨️ New key press detected: \(key)")
                self?.callback(.keyboardDown(key: key))

            case .keyUp:
                let key = event.charactersIgnoringModifiers ?? "unknown"
                print("⌨️ Key released: \(key)")
                self?.callback(.keyboardUp(key: key))

            case .flagsChanged:
                let flags = event.modifierFlags
                switch event.keyCode {
                case 55, 54:
                    self?.callback(flags.contains(.command)  ? .keyboardDown(key: "⌘") : .keyboardUp(key: "⌘"))
                case 58, 61:
                    self?.callback(flags.contains(.option)   ? .keyboardDown(key: "⌥") : .keyboardUp(key: "⌥"))
                case 59, 62:
                    self?.callback(flags.contains(.control)  ? .keyboardDown(key: "⌃") : .keyboardUp(key: "⌃"))
                case 56, 60:
                    self?.callback(flags.contains(.shift)    ? .keyboardDown(key: "⇧") : .keyboardUp(key: "⇧"))
                case 57:
                    self?.callback(flags.contains(.capsLock) ? .keyboardDown(key: "⇪") : .keyboardUp(key: "⇪"))
                case 63:
                    self?.callback(flags.contains(.function) ? .keyboardDown(key: "fn") : .keyboardUp(key: "fn"))
                default:
                    break
                }

            default:
                break
            }
        }

        if keyboardEventMonitor == nil {
            print("❌ Keyboard monitor failed to register — Input Monitoring permission likely not granted")
        } else {
            print("✅ Keyboard monitor registered successfully")
        }
    }

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
                //print("🔄 Scroll wheel detected (likely trackpad)")
                //self?.callback(.trackpadTouch)
                break
            case .mouseMoved:
                if event.subtype == .touch {
                    //print("👆 Trackpad touch detected (via mouse movement)")
                    //self?.callback(.trackpadTouch)
                }
                // Don't print for regular mouse movements to avoid spam
            default:
                break
            }
        }
    }
}
