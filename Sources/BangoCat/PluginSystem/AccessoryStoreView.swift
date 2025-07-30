import SwiftUI
import AppKit

// MARK: - Accessory Store View
struct AccessoryStoreView: View {
    @ObservedObject var pluginManager = AccessoryPluginManager.shared
    @State private var selectedPlugin: PluginManifest?
    @State private var showingPurchaseDialog = false
    @State private var licenseKey = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Accessory Store")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Refresh") {
                    pluginManager.refreshAvailablePlugins()
                }
                .disabled(pluginManager.isLoading)
            }
            .padding()

            Divider()

            if pluginManager.isLoading {
                // Loading state
                VStack {
                    ProgressView("Loading accessories...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if pluginManager.availablePlugins.isEmpty {
                // Empty state
                VStack {
                    Image(systemName: "bag")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No accessories available")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Check back later for new accessories!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Plugin grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(pluginManager.availablePlugins, id: \.id) { plugin in
                            PluginCardView(
                                plugin: plugin,
                                isPurchased: pluginManager.isPluginPurchased(plugin.id),
                                isEnabled: pluginManager.isPluginEnabled(plugin.id),
                                downloadStatus: pluginManager.downloadStatuses[plugin.id] ?? .notDownloaded,
                                onPurchase: { selectedPlugin = plugin; showingPurchaseDialog = true },
                                onEnable: { pluginManager.enablePlugin(plugin.id) },
                                onDisable: { pluginManager.disablePlugin(plugin.id) },
                                onDownload: { pluginManager.downloadPlugin(plugin.id) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showingPurchaseDialog) {
            PurchaseDialogView(
                plugin: selectedPlugin,
                licenseKey: $licenseKey,
                onPurchase: { key in
                    if let plugin = selectedPlugin {
                        pluginManager.purchasePlugin(plugin.id, licenseKey: key)
                    }
                    showingPurchaseDialog = false
                    licenseKey = ""
                },
                onCancel: {
                    showingPurchaseDialog = false
                    licenseKey = ""
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(pluginManager.$lastError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .onAppear {
            pluginManager.refreshAvailablePlugins()
        }
    }
}

// MARK: - Plugin Card View
struct PluginCardView: View {
    let plugin: PluginManifest
    let isPurchased: Bool
    let isEnabled: Bool
    let downloadStatus: PluginDownloadStatus
    let onPurchase: () -> Void
    let onEnable: () -> Void
    let onDisable: () -> Void
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plugin image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "puzzlepiece")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                )

            // Plugin info
            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(plugin.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("$\(NSDecimalNumber(decimal: plugin.price).doubleValue, specifier: "%.2f")")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()

                    if isPurchased {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }

            // Action buttons
            VStack(spacing: 4) {
                if !isPurchased {
                    Button("Purchase") {
                        onPurchase()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    switch downloadStatus {
                    case .notDownloaded:
                        Button("Download") {
                            onDownload()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    case .downloading(let progress):
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)

                    case .downloaded:
                        if isEnabled {
                            Button("Disable") {
                                onDisable()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        } else {
                            Button("Enable") {
                                onEnable()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                    case .failed:
                        Button("Retry Download") {
                            onDownload()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEnabled ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Purchase Dialog View
struct PurchaseDialogView: View {
    let plugin: PluginManifest?
    @Binding var licenseKey: String
    let onPurchase: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Purchase Accessory")
                .font(.title2)
                .fontWeight(.bold)

            if let plugin = plugin {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plugin.name)
                        .font(.headline)

                    Text(plugin.description)
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Price:")
                        Spacer()
                        Text("$\(NSDecimalNumber(decimal: plugin.price).doubleValue, specifier: "%.2f")")
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("License Key")
                    .font(.headline)

                TextField("Enter your license key", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)

                Text("Enter the license key you received after purchase")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Purchase") {
                    onPurchase(licenseKey)
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

// MARK: - Store Window Controller
class AccessoryStoreWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "BangoCat Accessory Store"
        window.center()

        let contentView = AccessoryStoreView()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}