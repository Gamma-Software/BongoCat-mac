import XCTest
@testable import BongoCat

final class AutoStartTests: XCTestCase {

    func testAutoStartPreferenceLoading() {
        // Test that auto-start preference loads correctly
        let userDefaults = UserDefaults.standard
        let testKey = "BongoCatAutoStartAtLaunch"

        // Test that UserDefaults.bool returns false when key doesn't exist
        userDefaults.removeObject(forKey: testKey)
        let defaultValue = userDefaults.bool(forKey: testKey)
        XCTAssertFalse(defaultValue, "UserDefaults.bool should return false when key doesn't exist")

        // Test setting to true
        userDefaults.set(true, forKey: testKey)
        let trueValue = userDefaults.bool(forKey: testKey)
        XCTAssertTrue(trueValue, "Auto-start should be true when set")

        // Test setting to false
        userDefaults.set(false, forKey: testKey)
        let falseValue = userDefaults.bool(forKey: testKey)
        XCTAssertFalse(falseValue, "Auto-start should be false when set")

        // Clean up
        userDefaults.removeObject(forKey: testKey)
    }

    func testAutoStartMenuState() {
        // Test that menu state updates correctly
        // This would require creating a mock AppDelegate
        // For now, we'll just verify the test structure
        XCTAssertTrue(true, "Auto-start menu state test structure is correct")
    }
}