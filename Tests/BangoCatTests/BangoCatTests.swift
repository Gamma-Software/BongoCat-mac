import XCTest
@testable import BangoCat

final class BangoCatTests: XCTestCase {

    // MARK: - Basic Component Tests

    func testCatViewInitialization() throws {
        let catView = CatView()
        XCTAssertNotNil(catView)
        // CatView should be a SwiftUI view - conformance verified by compilation
    }

    func testInputTypeEnum() throws {
        // Test all input types are available and have expected cases
        let keyboardDown = InputType.keyboardDown(key: "a")
        let keyboardUp = InputType.keyboardUp(key: "a")
        let leftClickDown = InputType.leftClickDown
        let leftClickUp = InputType.leftClickUp
        let rightClickDown = InputType.rightClickDown
        let rightClickUp = InputType.rightClickUp
        let scroll = InputType.scroll

        // Verify each type can be created
        XCTAssertNotNil(keyboardDown)
        XCTAssertNotNil(keyboardUp)
        XCTAssertNotNil(leftClickDown)
        XCTAssertNotNil(leftClickUp)
        XCTAssertNotNil(rightClickDown)
        XCTAssertNotNil(rightClickUp)
        XCTAssertNotNil(scroll)
    }

    func testCatStateEnum() throws {
        // Test all cat states are available
        let states: [CatState] = [
            .idle,
            .leftPawDown,
            .rightPawDown,
            .bothPawsDown,
            .leftPawUp,
            .rightPawUp,
            .typing
        ]

        XCTAssertEqual(states.count, 7)

        // Test state equality
        XCTAssertEqual(CatState.idle, CatState.idle)
        XCTAssertNotEqual(CatState.idle, CatState.leftPawDown)
    }

    func testOverlayWindowInitialization() throws {
        let overlayWindow = OverlayWindow()
        XCTAssertNotNil(overlayWindow)
        XCTAssertNotNil(overlayWindow.window)

        // Test window properties
        let window = overlayWindow.window!
        XCTAssertFalse(window.isOpaque)
        XCTAssertEqual(window.level, .screenSaver)
        XCTAssertFalse(window.ignoresMouseEvents)
    }

    // MARK: - Integration Tests

    func testOverlayWindowWithAnimationController() throws {
        let overlayWindow = OverlayWindow()
        XCTAssertNotNil(overlayWindow.catAnimationController)

        let controller = overlayWindow.catAnimationController!
        XCTAssertEqual(controller.currentState, .idle)
        XCTAssertNotNil(controller.strokeCounter)
    }

    func testCornerPositionEnum() throws {
        // Test all corner positions
        let corners = CornerPosition.allCases
        XCTAssertEqual(corners.count, 5) // topLeft, topRight, bottomLeft, bottomRight, custom

        // Test display names
        XCTAssertEqual(CornerPosition.topLeft.displayName, "Top Left")
        XCTAssertEqual(CornerPosition.bottomRight.displayName, "Bottom Right")
        XCTAssertEqual(CornerPosition.custom.displayName, "Custom")
    }

    func testAppDelegateInitialization() throws {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)

        // Test version information methods exist
        let versionString = appDelegate.getVersionString()
        let bundleId = appDelegate.getBundleIdentifier()

        XCTAssertFalse(versionString.isEmpty)
        XCTAssertFalse(bundleId.isEmpty)
    }

    // MARK: - Memory Management Tests

    func testStrokeCounterMemoryManagement() throws {
        var strokeCounter: StrokeCounter? = StrokeCounter()
        weak var weakCounter = strokeCounter

        // Verify strong reference exists
        XCTAssertNotNil(weakCounter)

        // Release strong reference
        strokeCounter = nil

        // Verify weak reference is now nil (object was deallocated)
        XCTAssertNil(weakCounter)
    }

    func testCatAnimationControllerMemoryManagement() throws {
        var controller: CatAnimationController? = CatAnimationController()
        weak var weakController = controller

        XCTAssertNotNil(weakController)

        controller = nil

        // Should be deallocated
        XCTAssertNil(weakController)
    }

    // MARK: - Thread Safety Tests

    func testStrokeCounterThreadSafety() throws {
        let strokeCounter = StrokeCounter()
        let expectation = XCTestExpectation(description: "Thread safety test")
        let iterations = 50

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            strokeCounter.incrementKeystrokes()
            strokeCounter.incrementMouseClicks()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Should have processed all increments
            XCTAssertEqual(strokeCounter.totalStrokes, iterations * 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Error Handling Tests

    func testGracefulErrorHandling() throws {
        let controller = CatAnimationController()

        // Test with invalid/edge case inputs
        controller.triggerAnimation(for: .keyboardDown(key: ""))
        controller.triggerAnimation(for: .keyboardDown(key: "\n"))
        controller.triggerAnimation(for: .keyboardDown(key: "\t"))

        // Should not crash and should handle gracefully
        XCTAssertNotNil(controller)
    }

    // MARK: - Performance Tests

    func testPerformanceRapidInputs() throws {
        let controller = CatAnimationController()

        measure {
            for i in 0..<1000 {
                controller.triggerAnimation(for: .keyboardDown(key: "\(i % 10)"))
            }
        }
    }

    func testPerformanceStrokeCounterIncrements() throws {
        let strokeCounter = StrokeCounter()

        measure {
            for _ in 0..<10000 {
                strokeCounter.incrementKeystrokes()
            }
        }
    }
}