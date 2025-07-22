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
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            print("⌨️ Keyboard event detected: \(event.charactersIgnoringModifiers ?? "unknown")")
            self?.callback(.keyboard)
        }
    }

    private func startMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .scrollWheel]) { [weak self] event in
            switch event.type {
            case .leftMouseDown:
                print("🖱️ Left mouse click detected")
                self?.callback(.leftClick)
            case .rightMouseDown:
                print("🖱️ Right mouse click detected")
                self?.callback(.rightClick)
            case .scrollWheel:
                print("🔄 Mouse scroll detected")
                self?.callback(.scroll)
            default:
                break
            }
        }
    }
}