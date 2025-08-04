import Cocoa

// Create the application
let app = NSApplication.shared

// Create and set the delegate
let delegate = AppDelegate()
app.delegate = delegate

// Set as accessory app (doesn't appear in Dock)
app.setActivationPolicy(.accessory)

// Run the application
app.run()