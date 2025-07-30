import Foundation
import SwiftUI
import AppKit

// MARK: - Plugin Protocol
protocol CatAccessoryPlugin: Identifiable, Codable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var version: String { get }
    var price: Decimal { get }
    var isPurchased: Bool { get }
    var isEnabled: Bool { get }
    var isDownloaded: Bool { get }

    func loadAssets() -> [NSImage]
}

// MARK: - Plugin Manifest
struct PluginManifest: Codable {
    let id: String
    let name: String
    let description: String
    let version: String
    let price: Decimal
    let assets: [PluginAsset]
    let positioning: AccessoryPositioning
    let requirements: PluginRequirements?
    let metadata: PluginMetadata

    struct PluginAsset: Codable {
        let name: String
        let filename: String
        let position: PluginPoint
        let scale: Double
        let zIndex: Int
        let tintColor: String? // Hex color string
    }

    struct AccessoryPositioning: Codable {
        let anchorPoint: PluginPoint // Relative to cat sprite
        let offset: PluginPoint
        let rotationOffset: Double
        let scaleWithCat: Bool
    }

    // Custom point structure for JSON compatibility
    struct PluginPoint: Codable {
        let x: Double
        let y: Double

        init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }

        init(from point: CGPoint) {
            self.x = point.x
            self.y = point.y
        }

        var cgPoint: CGPoint {
            return CGPoint(x: x, y: y)
        }
    }

    struct PluginRequirements: Codable {
        let minimumAppVersion: String?
        let minimumOSVersion: String?
        let dependencies: [String]?
    }

    struct PluginMetadata: Codable {
        let author: String
        let category: String
        let tags: [String]
        let releaseDate: Date
        let lastUpdated: Date
    }
}

// MARK: - Plugin State
struct PluginState: Codable {
    let pluginId: String
    var isPurchased: Bool
    var isEnabled: Bool
    var isDownloaded: Bool
    var downloadDate: Date?
    var lastUsed: Date?
    var purchaseDate: Date?
    var licenseKey: String?

    init(pluginId: String) {
        self.pluginId = pluginId
        self.isPurchased = false
        self.isEnabled = false
        self.isDownloaded = false
    }
}

// MARK: - Plugin Repository Configuration
struct PluginRepositoryConfig: Codable {
    let baseURL: String
    let manifestURL: String
    let assetsURL: String
    let apiKey: String?
    let licenseValidationURL: String?

    static let `default` = PluginRepositoryConfig(
        baseURL: "http://localhost:3000",
        manifestURL: "http://localhost:3000/manifest.json",
        assetsURL: "http://localhost:3000/assets",
        apiKey: nil,
        licenseValidationURL: "http://localhost:3000/validate"
    )
}

// MARK: - Plugin Download Status
enum PluginDownloadStatus {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(Error)
}

// MARK: - Plugin Error Types
enum PluginError: Error, LocalizedError {
    case manifestNotFound
    case assetDownloadFailed
    case invalidLicense
    case networkError(Error)
    case invalidPluginData
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .manifestNotFound:
            return "Plugin manifest not found"
        case .assetDownloadFailed:
            return "Failed to download plugin assets"
        case .invalidLicense:
            return "Invalid or expired license"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidPluginData:
            return "Invalid plugin data"
        case .unsupportedVersion:
            return "Plugin version not supported"
        }
    }
}