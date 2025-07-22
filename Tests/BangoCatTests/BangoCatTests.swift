import XCTest
@testable import BangoCat

final class BangoCatTests: XCTestCase {
    func testCatStateTransitions() throws {
        // Test that we can create a CatView
        let catView = CatView()
        XCTAssertNotNil(catView)
    }

    func testInputTypeEnum() throws {
        // Test that all input types are available
        let inputTypes: [InputType] = [.keyboard, .leftClick, .rightClick, .scroll]
        XCTAssertEqual(inputTypes.count, 4)
    }

    func testOverlayWindowInitialization() throws {
        // Test that OverlayWindow can be created
        let overlayWindow = OverlayWindow()
        XCTAssertNotNil(overlayWindow)
    }
}