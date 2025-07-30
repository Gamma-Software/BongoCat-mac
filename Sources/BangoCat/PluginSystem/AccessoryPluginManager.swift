import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - Plugin Manager
class AccessoryPluginManager: ObservableObject {
    static let shared = AccessoryPluginManager()

    // Published properties for SwiftUI
    @Published var availablePlugins: [PluginManifest] = []
    @Published var pluginStates: [String: PluginState] = [:]
    @Published var downloadStatuses: [String: PluginDownloadStatus] = [:]
    @Published var isLoading: Bool = false
    @Published var lastError: PluginError?

    // Configuration
    private let config: PluginRepositoryConfig
    private let fileManager = FileManager.default
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()

    // File paths
    private var pluginsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("BangoCat/Plugins")
    }

    private var assetsDirectory: URL {
        pluginsDirectory.appendingPathComponent("Assets")
    }

    private var statesFile: URL {
        pluginsDirectory.appendingPathComponent("plugin_states.json")
    }

    // Analytics
    private let analytics = PostHogAnalyticsManager.shared

    private init() {
        self.config = PluginRepositoryConfig.default
        setupDirectories()
        loadPluginStates()
    }

    // MARK: - Setup

    private func setupDirectories() {
        try? fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Plugin Discovery

    func refreshAvailablePlugins() {
        isLoading = true
        lastError = nil

        guard let url = URL(string: config.manifestURL) else {
            lastError = .manifestNotFound
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        // Add authentication if needed
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        print("🔌 Fetching manifest from: \(url)")
        session.dataTaskPublisher(for: request)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                print("🔌 Received \(data.count) bytes")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("🔌 JSON response: \(jsonString.prefix(200))...")
                }
            })
            .decode(type: [PluginManifest].self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("🔌 Plugin manifest decode error: \(error)")
                        self?.lastError = .networkError(error)
                    }
                },
                receiveValue: { [weak self] plugins in
                    print("🔌 Successfully loaded \(plugins.count) plugins")
                    self?.availablePlugins = plugins
                    self?.analytics.trackPluginDiscovery(plugins.count)
                }
            )
            .store(in: &cancellables)
    }

    // MARK: - Plugin Download

    func downloadPlugin(_ pluginId: String) {
        guard let plugin = availablePlugins.first(where: { $0.id == pluginId }) else {
            lastError = .manifestNotFound
            return
        }

        downloadStatuses[pluginId] = .downloading(progress: 0.0)

        // Download each asset
        let assetDownloads = plugin.assets.map { asset in
            downloadAsset(asset, for: pluginId)
        }

        Publishers.MergeMany(assetDownloads)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.downloadStatuses[pluginId] = .failed(error)
                        self?.lastError = .assetDownloadFailed
                    } else {
                        self?.downloadStatuses[pluginId] = .downloaded
                        self?.updatePluginState(pluginId) { state in
                            state.isDownloaded = true
                            state.downloadDate = Date()
                        }
                        self?.analytics.trackPluginDownloaded(pluginId)
                    }
                },
                receiveValue: { _ in
                    // All assets downloaded successfully
                }
            )
            .store(in: &cancellables)
    }

    private func downloadAsset(_ asset: PluginManifest.PluginAsset, for pluginId: String) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(config.assetsURL)/\(pluginId)/\(asset.filename)") else {
            return Fail(error: PluginError.assetDownloadFailed).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .tryMap { [weak self] data in
                guard let self = self else { throw PluginError.assetDownloadFailed }

                let assetURL = self.assetsDirectory.appendingPathComponent("\(pluginId)_\(asset.filename)")
                try data.write(to: assetURL)
                return ()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - License Management

    func purchasePlugin(_ pluginId: String, licenseKey: String) {
        validateLicense(pluginId, licenseKey) { [weak self] isValid in
            DispatchQueue.main.async {
                if isValid {
                    self?.updatePluginState(pluginId) { state in
                        state.isPurchased = true
                        state.purchaseDate = Date()
                        state.licenseKey = licenseKey
                    }
                    self?.analytics.trackPluginPurchased(pluginId)
                } else {
                    self?.lastError = .invalidLicense
                }
            }
        }
    }

    private func validateLicense(_ pluginId: String, _ licenseKey: String, completion: @escaping (Bool) -> Void) {
        guard let validationURL = config.licenseValidationURL,
              let url = URL(string: validationURL) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "pluginId": pluginId,
            "licenseKey": licenseKey,
            "deviceId": getDeviceId()
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("License validation error: \(error)")
                completion(false)
                return
            }

            guard let data = data,
                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isValid = response["valid"] as? Bool else {
                completion(false)
                return
            }

            completion(isValid)
        }.resume()
    }

    private func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: "BangoCatDeviceId") {
            return deviceId
        }

        let newDeviceId = UUID().uuidString
        UserDefaults.standard.set(newDeviceId, forKey: "BangoCatDeviceId")
        return newDeviceId
    }

    // MARK: - Plugin State Management

    func enablePlugin(_ pluginId: String) {
        updatePluginState(pluginId) { state in
            state.isEnabled = true
            state.lastUsed = Date()
        }
        analytics.trackPluginEnabled(pluginId)
    }

    func disablePlugin(_ pluginId: String) {
        updatePluginState(pluginId) { state in
            state.isEnabled = false
        }
        analytics.trackPluginDisabled(pluginId)
    }

    private func updatePluginState(_ pluginId: String, _ update: (inout PluginState) -> Void) {
        var state = pluginStates[pluginId] ?? PluginState(pluginId: pluginId)
        update(&state)
        pluginStates[pluginId] = state
        savePluginStates()
    }

    // MARK: - Asset Loading

    func loadPluginAssets(_ pluginId: String) -> [NSImage] {
        guard let plugin = availablePlugins.first(where: { $0.id == pluginId }),
              let state = pluginStates[pluginId],
              state.isDownloaded else {
            return []
        }

        return plugin.assets.compactMap { asset in
            let assetURL = assetsDirectory.appendingPathComponent("\(pluginId)_\(asset.filename)")
            return NSImage(contentsOf: assetURL)
        }
    }

    // MARK: - Persistence

    private func loadPluginStates() {
        guard let data = try? Data(contentsOf: statesFile),
              let states = try? JSONDecoder().decode([String: PluginState].self, from: data) else {
            return
        }

        pluginStates = states
    }

    private func savePluginStates() {
        guard let data = try? JSONEncoder().encode(pluginStates) else { return }
        try? data.write(to: statesFile)
    }

    // MARK: - Utility Methods

    func isPluginEnabled(_ pluginId: String) -> Bool {
        return pluginStates[pluginId]?.isEnabled ?? false
    }

    func isPluginPurchased(_ pluginId: String) -> Bool {
        return pluginStates[pluginId]?.isPurchased ?? false
    }

    func isPluginDownloaded(_ pluginId: String) -> Bool {
        return pluginStates[pluginId]?.isDownloaded ?? false
    }

    func getEnabledPlugins() -> [PluginManifest] {
        return availablePlugins.filter { isPluginEnabled($0.id) }
    }

    func getPurchasedPlugins() -> [PluginManifest] {
        return availablePlugins.filter { isPluginPurchased($0.id) }
    }
}