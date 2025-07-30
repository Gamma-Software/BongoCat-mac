import Foundation
import SwiftUI
import AppKit

// MARK: - Accessory Renderer
class AccessoryPluginRenderer: ObservableObject {
    static let shared = AccessoryPluginRenderer()

    private let pluginManager = AccessoryPluginManager.shared

    private init() {}

    // MARK: - Main Rendering Function

    func renderAccessories(for catView: BangoCatSprite, state: CatState) -> some View {
        let enabledPlugins = pluginManager.getEnabledPlugins()

                return ZStack {
            // Base cat view (existing)
            catView

            // Render each enabled accessory
            ForEach(enabledPlugins, id: \.id) { plugin in
                self.renderAccessory(plugin, for: state)
            }
        }
    }

    // MARK: - Individual Accessory Rendering

    private func renderAccessory(_ plugin: PluginManifest, for state: CatState) -> some View {
        let assets = pluginManager.loadPluginAssets(plugin.id)

        return ZStack {
            ForEach(Array(plugin.assets.enumerated()), id: \.offset) { index, asset in
                if index < assets.count {
                    self.renderAsset(assets[index], asset: asset, plugin: plugin, state: state)
                }
            }
        }
    }

    private func renderAsset(_ image: NSImage, asset: PluginManifest.PluginAsset, plugin: PluginManifest, state: CatState) -> some View {
        let positioning = plugin.positioning

        return Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(asset.scale)
            .offset(x: asset.position.cgPoint.x, y: asset.position.cgPoint.y)
            .rotationEffect(.degrees(positioning.rotationOffset))
            .zIndex(Double(asset.zIndex))
            .modifier(AccessoryTransformModifier(
                positioning: positioning,
                asset: asset,
                state: state
            ))
    }
}

// MARK: - Transform Modifier
struct AccessoryTransformModifier: ViewModifier {
    let positioning: PluginManifest.AccessoryPositioning
    let asset: PluginManifest.PluginAsset
    let state: CatState

    @EnvironmentObject var animationController: CatAnimationController

    func body(content: Content) -> some View {
        content
            .offset(x: positioning.offset.cgPoint.x, y: positioning.offset.cgPoint.y)
            .scaleEffect(positioning.scaleWithCat ? animationController.viewScale : 1.0)
            .rotationEffect(.degrees(animationController.rotation))
            .scaleEffect(x: animationController.isFlippedHorizontally ? -1 : 1, y: 1)
            .modifier(AccessoryAnimationModifier(state: state, asset: asset))
    }
}

// MARK: - Animation Modifier
struct AccessoryAnimationModifier: ViewModifier {
    let state: CatState
    let asset: PluginManifest.PluginAsset

    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.1), value: state)
            .modifier(AccessoryStateModifier(state: state, asset: asset))
    }
}

// MARK: - State Modifier
struct AccessoryStateModifier: ViewModifier {
    let state: CatState
    let asset: PluginManifest.PluginAsset

    func body(content: Content) -> some View {
        content
            .opacity(getOpacity())
            .scaleEffect(getScale())
    }

    private func getOpacity() -> Double {
        // Some accessories might have different opacity based on cat state
        switch state {
        case .idle:
            return 1.0
        case .leftPawDown, .rightPawDown, .bothPawsDown, .typing:
            return 1.0
        default:
            return 1.0
        }
    }

    private func getScale() -> Double {
        // Some accessories might have different scale based on cat state
        switch state {
        case .leftPawDown, .rightPawDown, .bothPawsDown, .typing:
            return 1.05 // Slight scale up during animation
        default:
            return 1.0
        }
    }
}

// MARK: - Tint Color Support
extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }

        let image = NSImage(size: self.size)
        image.lockFocus()

        color.set()
        NSRect(origin: .zero, size: self.size).fill()

        let imageRect = NSRect(origin: .zero, size: self.size)
        NSGraphicsContext.current?.compositingOperation = .destinationIn
        NSImage(cgImage: cgImage, size: self.size).draw(in: imageRect)

        image.unlockFocus()
        return image
    }
}

// MARK: - Color Utilities
extension String {
    func toNSColor() -> NSColor? {
        guard self.hasPrefix("#") else { return nil }

        let hex = String(self.dropFirst())
        guard hex.count == 6 else { return nil }

        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0

        guard scanner.scanHexInt64(&rgbValue) else { return nil }

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}