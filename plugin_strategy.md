I'll help you explore ways to implement in-app paid accessories as downloadable plugins. Let me first examine the current codebase to understand the existing structure and then provide implementation ideas.

Search files...
Ran tool
Ran tool
Read file: Sources/BangoCat/CatView.swift
Search files...
Based on my analysis of the BangoCat codebase, I can see that you already have a basic accessory system in place (there's a `santa-hat.png` in the `Assets/accessories/` directory), but it's not yet implemented in the app. Let me provide you with comprehensive implementation ideas for a paid accessories plugin system.

## Implementation Ideas for Paid Accessories Plugin System

### 1. **Plugin Architecture Overview**

Here's a modular approach that would work well with your existing codebase:

#### **Core Plugin System**
```swift
// Plugin protocol for accessories
protocol CatAccessoryPlugin {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var price: Decimal { get }
    var isPurchased: Bool { get }
    var isEnabled: Bool { get }

    func loadAssets() -> [NSImage]
    func applyToCat(_ catView: BangoCatSprite) -> some View
}

// Plugin manager
class AccessoryPluginManager: ObservableObject {
    @Published var availablePlugins: [CatAccessoryPlugin] = []
    @Published var enabledPlugins: Set<String> = []

    func loadPlugins()
    func purchasePlugin(_ pluginId: String)
    func enablePlugin(_ pluginId: String)
    func disablePlugin(_ pluginId: String)
}
```

### 2. **Plugin Distribution Methods**

#### **A. Built-in Plugin Store**
- Store plugin metadata and assets within the app bundle
- Download plugin assets on purchase
- Store in `~/Library/Application Support/BangoCat/Plugins/`

#### **B. External Plugin Repository**
- JSON manifest file hosted on your server
- Plugin assets served via CDN
- Version management and updates

#### **C. GitHub Releases Integration**
- Leverage your existing GitHub releases infrastructure
- Plugin packages as `.bangoaccessory` files
- Automatic discovery and installation

### 3. **Implementation Strategies**

#### **Strategy A: Simple Asset Overlay System**
```swift
// Extend BangoCatSprite to support accessories
struct BangoCatSprite: View {
    @State private var accessoryImages: [NSImage] = []
    @EnvironmentObject var pluginManager: AccessoryPluginManager

    var body: some View {
        ZStack {
            // Existing cat sprite
            baseCatView

            // Accessory overlays
            ForEach(accessoryImages.indices, id: \.self) { index in
                Image(nsImage: accessoryImages[index])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
```

#### **Strategy B: Advanced Plugin System**
```swift
// Plugin manifest structure
struct PluginManifest: Codable {
    let id: String
    let name: String
    let version: String
    let description: String
    let price: Decimal
    let assets: [PluginAsset]
    let positioning: AccessoryPositioning
}

struct PluginAsset: Codable {
    let name: String
    let url: String
    let position: CGPoint
    let scale: Double
    let zIndex: Int
}
```

### 4. **Payment Integration Options**

#### **A. In-App Purchase (App Store)**
- Use StoreKit 2 for macOS App Store distribution
- Automatic receipt validation
- Apple handles payment processing

#### **B. External Payment System**
- Stripe integration for direct payments
- PayPal integration
- Custom payment flow with receipt validation

#### **C. License Key System**
- Generate license keys for purchased accessories
- Offline validation
- Simple implementation with UserDefaults

### 5. **User Interface Integration**

#### **Accessories Menu**
```swift
// Add to your existing menu structure
private func setupAccessoriesMenu() {
    let accessoriesMenu = NSMenu()

    // Available accessories
    for plugin in pluginManager.availablePlugins {
        let item = NSMenuItem(title: plugin.name, action: #selector(toggleAccessory(_:)), keyEquivalent: "")
        item.representedObject = plugin.id
        item.state = plugin.isEnabled ? .on : .off
        accessoriesMenu.addItem(item)
    }

    accessoriesMenu.addItem(NSMenuItem.separator())

    // Accessory store
    let storeItem = NSMenuItem(title: "Accessory Store...", action: #selector(openAccessoryStore), keyEquivalent: "")
    accessoriesMenu.addItem(storeItem)
}
```

#### **Accessory Store Window**
```swift
struct AccessoryStoreView: View {
    @ObservedObject var pluginManager: AccessoryPluginManager
    @State private var selectedPlugin: CatAccessoryPlugin?

    var body: some View {
        VStack {
            // Plugin grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(pluginManager.availablePlugins, id: \.id) { plugin in
                    PluginCardView(plugin: plugin)
                }
            }

            // Purchase/Enable buttons
            if let selected = selectedPlugin {
                PluginDetailView(plugin: selected)
            }
        }
    }
}
```

### 6. **Storage and Persistence**

#### **Plugin State Management**
```swift
// Extend your existing UserDefaults system
extension AppDelegate {
    private let purchasedPluginsKey = "BangoCatPurchasedPlugins"
    private let enabledPluginsKey = "BangoCatEnabledPlugins"

    func loadPluginPreferences() {
        // Load purchased and enabled plugins
        if let purchased = UserDefaults.standard.array(forKey: purchasedPluginsKey) as? [String] {
            // Restore purchased state
        }

        if let enabled = UserDefaults.standard.array(forKey: enabledPluginsKey) as? [String] {
            // Restore enabled state
        }
    }
}
```

### 7. **Recommended Implementation Path**

#### **Phase 1: Basic Accessory System**
1. Create `AccessoryPluginManager` class
2. Extend `BangoCatSprite` to support accessory overlays
3. Add accessories menu to existing UI
4. Implement simple asset loading from `Assets/accessories/`

#### **Phase 2: Plugin Store**
1. Create plugin manifest system
2. Build accessory store UI
3. Implement purchase flow (start with license keys)
4. Add plugin download and installation

#### **Phase 3: Advanced Features**
1. Add plugin updates and versioning
2. Implement advanced positioning system
3. Add plugin-specific animations
4. Create plugin development SDK

### 8. **Example Plugin Implementation**

```swift
// Example: Santa Hat Plugin
class SantaHatPlugin: CatAccessoryPlugin {
    let id = "santa-hat"
    let name = "Santa Hat"
    let description = "Festive Santa hat for your cat"
    let price: Decimal = 2.99
    var isPurchased: Bool { /* check UserDefaults */ }
    var isEnabled: Bool { /* check UserDefaults */ }

    func loadAssets() -> [NSImage] {
        return [NSImage(named: "santa-hat")].compactMap { $0 }
    }

    func applyToCat(_ catView: BangoCatSprite) -> some View {
        // Return overlay view for the accessory
    }
}
```

### 9. **Integration with Existing Features**

Your existing features like per-app positioning, scaling, and rotation would work seamlessly with accessories:

- **Scaling**: Accessories scale with the cat
- **Rotation**: Accessories rotate with the cat
- **Per-app positioning**: Accessories stay with the cat
- **Flip**: Accessories flip with the cat

This system would be a natural extension of your existing architecture while providing a monetization path that doesn't interfere with the core free functionality.

Would you like me to help you implement any specific part of this system, or would you like me to explore any of these approaches in more detail?