#!/usr/bin/env swift

import Foundation

// Simulate the same logic as PostHogAnalyticsManager
func loadConfiguration() -> (apiKey: String, host: String, source: String)? {
    // 1. Try environment variables

    // 2. Try local analytics-config.plist file
    if let configPath = Bundle.main.path(forResource: "analytics-config", ofType: "plist"),
       let configDict = NSDictionary(contentsOfFile: configPath),
       let configApiKey = configDict["POSTHOG_API_KEY"] as? String,
       !configApiKey.isEmpty && configApiKey != "YOUR_POSTHOG_API_KEY" {
        let configHost = configDict["POSTHOG_HOST"] as? String ?? "https://us.i.posthog.com"
        return (apiKey: configApiKey, host: configHost, source: "analytics-config.plist")
    }

    // 3. Try Info.plist
    if let plistApiKey = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_API_KEY") as? String,
       !plistApiKey.isEmpty && plistApiKey != "YOUR_POSTHOG_API_KEY" {
        let plistHost = Bundle.main.object(forInfoDictionaryKey: "POSTHOG_HOST") as? String ?? "https://us.i.posthog.com"
        return (apiKey: plistApiKey, host: plistHost, source: "Info.plist")
    }

    return nil
}

print("Testing PostHog Configuration...")
print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "none")")
print("Bundle Path: \(Bundle.main.bundlePath)")

if let config = loadConfiguration() {
    print("✅ PostHog configured from \(config.source)")
    print("   API Key: \(String(config.apiKey.prefix(8)))...")
    print("   Host: \(config.host)")
} else {
    print("❌ PostHog not configured")

    // Debug info
    print("\nEnvironment variables:")
    print("  POSTHOG_API_KEY: \(ProcessInfo.processInfo.environment["POSTHOG_API_KEY"] ?? "not set")")
    print("  POSTHOG_HOST: \(ProcessInfo.processInfo.environment["POSTHOG_HOST"] ?? "not set")")

    print("\nChecking for analytics-config.plist...")
    if let configPath = Bundle.main.path(forResource: "analytics-config", ofType: "plist") {
        print("  Found at: \(configPath)")
        if let configDict = NSDictionary(contentsOfFile: configPath) {
            print("  Contents: \(configDict)")
        }
    } else {
        print("  analytics-config.plist not found in bundle")
    }
}