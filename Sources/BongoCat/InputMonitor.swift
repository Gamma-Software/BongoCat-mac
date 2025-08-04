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
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            let key = event.charactersIgnoringModifiers ?? "unknown"

            switch event.type {
            case .keyDown:
                if event.isARepeat {
                    print("🔄 Key is being held down (repeat event): \(key)")
                    // Key is being held - do nothing or handle differently
                    return
                } else {
                    print("⌨️ New key press detected: \(key)")
                    self?.callback(.keyboardDown(key: key))
                }

            case .keyUp:
                print("⌨️ Key released: \(key)")
                self?.callback(.keyboardUp(key: key))

            default:
                break
            }
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