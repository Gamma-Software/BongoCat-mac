//
//  PersistenceController.swift
//  BongoCat
//

import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Generic helpers

    func set<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        if userDefaults.object(forKey: key) == nil { return defaultValue }
        return userDefaults.bool(forKey: key)
    }

    func double(forKey key: String, default defaultValue: Double = 0.0) -> Double {
        if userDefaults.object(forKey: key) == nil { return defaultValue }
        return userDefaults.double(forKey: key)
    }

    func string(forKey key: String, default defaultValue: String? = nil) -> String? {
        return userDefaults.string(forKey: key) ?? defaultValue
    }

    func data(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }

    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}


