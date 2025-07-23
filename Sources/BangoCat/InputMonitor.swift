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
            switch event.type {
            case .keyDown:
                print("⌨️ Keyboard DOWN event detected: \(event.charactersIgnoringModifiers ?? "unknown")")
                self?.callback(.keyboardDown)
            case .keyUp:
                print("⌨️ Keyboard UP event detected: \(event.charactersIgnoringModifiers ?? "unknown")")
                self?.callback(.keyboardUp)
            default:
                break
            }
        }
    }

    private func startMouseMonitoring() {
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .scrollWheel]) { [weak self] event in
            switch event.type {
            case .leftMouseDown:
                print("🖱️ Left mouse DOWN detected")
                self?.callback(.leftClickDown)
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
                print("🔄 Mouse scroll detected")
                self?.callback(.scroll)
            default:
                break
            }
        }
    }
}