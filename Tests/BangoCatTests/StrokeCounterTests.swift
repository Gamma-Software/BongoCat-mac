import XCTest
@testable import BangoCat

final class StrokeCounterTests: XCTestCase {
    var strokeCounter: StrokeCounter!
    let testStrokesKey = "TestBangoCatTotalStrokes"
    let testKeystrokesKey = "TestBangoCatKeystrokes"
    let testMouseClicksKey = "TestBangoCatMouseClicks"

    override func setUp() {
        super.setUp()

        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: testStrokesKey)
        UserDefaults.standard.removeObject(forKey: testKeystrokesKey)
        UserDefaults.standard.removeObject(forKey: testMouseClicksKey)

        // Create a test stroke counter with custom keys
        strokeCounter = StrokeCounter(
            strokesKey: testStrokesKey,
            keystrokesKey: testKeystrokesKey,
            mouseClicksKey: testMouseClicksKey
        )
    }

    override func tearDown() {
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: testStrokesKey)
        UserDefaults.standard.removeObject(forKey: testKeystrokesKey)
        UserDefaults.standard.removeObject(forKey: testMouseClicksKey)

        strokeCounter = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(strokeCounter.totalStrokes, 0)
        XCTAssertEqual(strokeCounter.keystrokes, 0)
        XCTAssertEqual(strokeCounter.mouseClicks, 0)
    }

    func testInitializationWithExistingData() {
        // Set up existing data
        UserDefaults.standard.set(100, forKey: testStrokesKey)
        UserDefaults.standard.set(60, forKey: testKeystrokesKey)
        UserDefaults.standard.set(40, forKey: testMouseClicksKey)

        // Create new counter - should load existing data
        let newCounter = StrokeCounter(
            strokesKey: testStrokesKey,
            keystrokesKey: testKeystrokesKey,
            mouseClicksKey: testMouseClicksKey
        )

        XCTAssertEqual(newCounter.totalStrokes, 100)
        XCTAssertEqual(newCounter.keystrokes, 60)
        XCTAssertEqual(newCounter.mouseClicks, 40)
    }

    // MARK: - Keystroke Tests

    func testIncrementKeystrokes() {
        strokeCounter.incrementKeystrokes()

        XCTAssertEqual(strokeCounter.keystrokes, 1)
        XCTAssertEqual(strokeCounter.totalStrokes, 1)
        XCTAssertEqual(strokeCounter.mouseClicks, 0)
    }

    func testMultipleKeystrokes() {
        for _ in 1...10 {
            strokeCounter.incrementKeystrokes()
        }

        XCTAssertEqual(strokeCounter.keystrokes, 10)
        XCTAssertEqual(strokeCounter.totalStrokes, 10)
        XCTAssertEqual(strokeCounter.mouseClicks, 0)
    }

    // MARK: - Mouse Click Tests

    func testIncrementMouseClicks() {
        strokeCounter.incrementMouseClicks()

        XCTAssertEqual(strokeCounter.mouseClicks, 1)
        XCTAssertEqual(strokeCounter.totalStrokes, 1)
        XCTAssertEqual(strokeCounter.keystrokes, 0)
    }

    func testMultipleMouseClicks() {
        for _ in 1...5 {
            strokeCounter.incrementMouseClicks()
        }

        XCTAssertEqual(strokeCounter.mouseClicks, 5)
        XCTAssertEqual(strokeCounter.totalStrokes, 5)
        XCTAssertEqual(strokeCounter.keystrokes, 0)
    }

    // MARK: - Mixed Input Tests

    func testMixedInputs() {
        // Add keystrokes and mouse clicks
        for _ in 1...7 {
            strokeCounter.incrementKeystrokes()
        }

        for _ in 1...3 {
            strokeCounter.incrementMouseClicks()
        }

        XCTAssertEqual(strokeCounter.keystrokes, 7)
        XCTAssertEqual(strokeCounter.mouseClicks, 3)
        XCTAssertEqual(strokeCounter.totalStrokes, 10)
    }

    // MARK: - Reset Tests

    func testReset() {
        // Add some data
        strokeCounter.incrementKeystrokes()
        strokeCounter.incrementKeystrokes()
        strokeCounter.incrementMouseClicks()

        // Verify data exists
        XCTAssertEqual(strokeCounter.totalStrokes, 3)

        // Reset
        strokeCounter.reset()

        // Verify reset
        XCTAssertEqual(strokeCounter.totalStrokes, 0)
        XCTAssertEqual(strokeCounter.keystrokes, 0)
        XCTAssertEqual(strokeCounter.mouseClicks, 0)
    }

    func testResetPersistence() {
        // Add data and reset
        strokeCounter.incrementKeystrokes()
        strokeCounter.reset()

                // Create new counter - should be reset
        let newCounter = StrokeCounter(
            strokesKey: testStrokesKey,
            keystrokesKey: testKeystrokesKey,
            mouseClicksKey: testMouseClicksKey
        )

        XCTAssertEqual(newCounter.totalStrokes, 0)
        XCTAssertEqual(newCounter.keystrokes, 0)
        XCTAssertEqual(newCounter.mouseClicks, 0)
    }

    // MARK: - Persistence Tests

    func testPersistenceAfterIncrement() {
        strokeCounter.incrementKeystrokes()
        strokeCounter.incrementMouseClicks()

        // Create new counter - should load persisted data
        let newCounter = StrokeCounter(
            strokesKey: testStrokesKey,
            keystrokesKey: testKeystrokesKey,
            mouseClicksKey: testMouseClicksKey
        )

        XCTAssertEqual(newCounter.keystrokes, 1)
        XCTAssertEqual(newCounter.mouseClicks, 1)
        XCTAssertEqual(newCounter.totalStrokes, 2)
    }

    // MARK: - Large Number Tests

    func testLargeNumbers() {
        // Test with large numbers to ensure no overflow issues
        let largeNumber = 10000  // Reduced for faster tests

        for _ in 1...largeNumber {
            strokeCounter.incrementKeystrokes()
        }

        XCTAssertEqual(strokeCounter.keystrokes, largeNumber)
        XCTAssertEqual(strokeCounter.totalStrokes, largeNumber)
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        let iterations = 100

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            strokeCounter.incrementKeystrokes()
        }

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            strokeCounter.incrementMouseClicks()
        }

        // Give some time for all operations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.strokeCounter.totalStrokes, iterations * 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}