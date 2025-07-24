import XCTest
@testable import BangoCat

final class CatAnimationControllerTests: XCTestCase {
    var animationController: CatAnimationController!

    override func setUp() {
        super.setUp()
        animationController = CatAnimationController()
    }

    override func tearDown() {
        animationController = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(animationController.currentState, .idle)
        XCTAssertEqual(animationController.scale, 1.0)
        XCTAssertEqual(animationController.viewScale, 1.0)
        XCTAssertTrue(animationController.scaleOnInputEnabled)
        XCTAssertEqual(animationController.rotation, 0.0)
        XCTAssertFalse(animationController.isFlippedHorizontally)
        XCTAssertFalse(animationController.ignoreClicksEnabled)
    }

    func testStrokeCounterInitialization() {
        XCTAssertNotNil(animationController.strokeCounter)
        XCTAssertEqual(animationController.strokeCounter.totalStrokes, 0)
    }

    // MARK: - Scale Management Tests

    func testUpdateViewScale() {
        animationController.updateViewScale(1.5)
        XCTAssertEqual(animationController.viewScale, 1.5)
    }

    func testScaleOnInputToggle() {
        animationController.setScaleOnInputEnabled(false)
        XCTAssertFalse(animationController.scaleOnInputEnabled)

        animationController.setScaleOnInputEnabled(true)
        XCTAssertTrue(animationController.scaleOnInputEnabled)
    }

    // MARK: - Rotation Tests

    func testUpdateRotation() {
        animationController.updateRotation(13.0)
        XCTAssertEqual(animationController.rotation, 13.0)

        animationController.updateRotation(-13.0)
        XCTAssertEqual(animationController.rotation, -13.0)

        animationController.updateRotation(0.0)
        XCTAssertEqual(animationController.rotation, 0.0)
    }

    // MARK: - Flip Tests

    func testHorizontalFlip() {
        animationController.setHorizontalFlip(true)
        XCTAssertTrue(animationController.isFlippedHorizontally)

        animationController.setHorizontalFlip(false)
        XCTAssertFalse(animationController.isFlippedHorizontally)
    }

    // MARK: - Ignore Clicks Tests

    func testIgnoreClicksToggle() {
        animationController.setIgnoreClicksEnabled(true)
        XCTAssertTrue(animationController.ignoreClicksEnabled)

        animationController.setIgnoreClicksEnabled(false)
        XCTAssertFalse(animationController.ignoreClicksEnabled)
    }

    // MARK: - Input Animation Tests

    func testKeyboardDownAnimation() {
        let expectation = XCTestExpectation(description: "State change")

        // Test keyboard down
        animationController.triggerAnimation(for: .keyboardDown(key: "a"))

        // Give some time for the animation to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Should be in a paw down state
            XCTAssertTrue([.leftPawDown, .rightPawDown].contains(self.animationController.currentState))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testKeyboardUpAnimation() {
        let expectation = XCTestExpectation(description: "State transitions")

        // First trigger key down
        animationController.triggerAnimation(for: .keyboardDown(key: "a"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then trigger key up
            self.animationController.triggerAnimation(for: .keyboardUp(key: "a"))

            // Give time for the up animation and return to idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.animationController.currentState, .idle)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testLeftClickAnimation() {
        let expectation = XCTestExpectation(description: "Left click animation")

        animationController.triggerAnimation(for: .leftClickDown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.animationController.currentState, .leftPawDown)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRightClickAnimation() {
        let expectation = XCTestExpectation(description: "Right click animation")

        animationController.triggerAnimation(for: .rightClickDown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.animationController.currentState, .rightPawDown)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testIgnoredClicks() {
        animationController.setIgnoreClicksEnabled(true)

        let expectation = XCTestExpectation(description: "Ignored clicks")

        animationController.triggerAnimation(for: .leftClickDown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Should remain idle when clicks are ignored
            XCTAssertEqual(self.animationController.currentState, .idle)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Consistent Paw Assignment Tests

    func testConsistentPawAssignment() {
        let expectation = XCTestExpectation(description: "Consistent paw assignment")
        var firstPawState: CatState?
        var secondPawState: CatState?

        // First press of 'a'
        animationController.triggerAnimation(for: .keyboardDown(key: "a"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            firstPawState = self.animationController.currentState

            // Return to idle
            self.animationController.triggerAnimation(for: .keyboardUp(key: "a"))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Second press of 'a' should use same paw
                self.animationController.triggerAnimation(for: .keyboardDown(key: "a"))

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    secondPawState = self.animationController.currentState

                    XCTAssertEqual(firstPawState, secondPawState)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testAlternatingPawAssignment() {
        let expectation = XCTestExpectation(description: "Alternating paw assignment")
        var firstKeyState: CatState?
        var secondKeyState: CatState?

        // Press first key
        animationController.triggerAnimation(for: .keyboardDown(key: "a"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            firstKeyState = self.animationController.currentState

            // Return to idle
            self.animationController.triggerAnimation(for: .keyboardUp(key: "a"))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Press different key - should use different paw
                self.animationController.triggerAnimation(for: .keyboardDown(key: "b"))

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    secondKeyState = self.animationController.currentState

                    XCTAssertNotEqual(firstKeyState, secondKeyState)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Stroke Counter Integration Tests

    func testStrokeCountingIntegration() {
        let initialKeystrokes = animationController.strokeCounter.keystrokes
        let initialClicks = animationController.strokeCounter.mouseClicks

        let expectation = XCTestExpectation(description: "Stroke counting")

        // Trigger various inputs
        animationController.triggerAnimation(for: .keyboardDown(key: "a"))
        animationController.triggerAnimation(for: .keyboardDown(key: "b"))
        animationController.triggerAnimation(for: .leftClickDown)
        animationController.triggerAnimation(for: .rightClickDown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.animationController.strokeCounter.keystrokes, initialKeystrokes + 2)
            XCTAssertEqual(self.animationController.strokeCounter.mouseClicks, initialClicks + 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testIgnoredClicksNotCounted() {
        animationController.setIgnoreClicksEnabled(true)
        let initialClicks = animationController.strokeCounter.mouseClicks

        let expectation = XCTestExpectation(description: "Ignored clicks not counted")

        animationController.triggerAnimation(for: .leftClickDown)
        animationController.triggerAnimation(for: .rightClickDown)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Clicks should not be counted when ignored
            XCTAssertEqual(self.animationController.strokeCounter.mouseClicks, initialClicks)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - State Transition Tests

    func testStateTransitionSequence() {
        let expectation = XCTestExpectation(description: "State transition sequence")

        // Start with idle
        XCTAssertEqual(animationController.currentState, .idle)

        // Key down -> paw down
        animationController.triggerAnimation(for: .keyboardDown(key: "test"))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue([.leftPawDown, .rightPawDown].contains(self.animationController.currentState))

            // Key up -> paw up -> idle
            self.animationController.triggerAnimation(for: .keyboardUp(key: "test"))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertEqual(self.animationController.currentState, .idle)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Edge Case Tests

    func testEmptyKeyInput() {
        let expectation = XCTestExpectation(description: "Empty key input")

        animationController.triggerAnimation(for: .keyboardDown(key: ""))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Should still handle empty key gracefully
            XCTAssertTrue([.leftPawDown, .rightPawDown].contains(self.animationController.currentState))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSpecialCharacterKeys() {
        let specialKeys = ["⌘", "⌥", "⌃", "⇧", "←", "→", "↑", "↓", "⌫", "⌦"]
        let expectation = XCTestExpectation(description: "Special character keys")
        expectation.expectedFulfillmentCount = specialKeys.count

        for key in specialKeys {
            animationController.triggerAnimation(for: .keyboardDown(key: key))

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue([.leftPawDown, .rightPawDown].contains(self.animationController.currentState))
                expectation.fulfill()
            }

            // Reset to idle
            animationController.triggerAnimation(for: .keyboardUp(key: key))
            Thread.sleep(forTimeInterval: 0.1)
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Performance Tests

    func testRapidInputHandling() {
        let expectation = XCTestExpectation(description: "Rapid input handling")
        let inputCount = 100
        var completedInputs = 0

        for i in 0..<inputCount {
            animationController.triggerAnimation(for: .keyboardDown(key: "\(i)"))

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.01) {
                completedInputs += 1
                if completedInputs == inputCount {
                    XCTAssertTrue(completedInputs == inputCount)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
}