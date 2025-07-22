#!/bin/bash

# Create the necessary directories
mkdir -p Sources/BangoCat/Resources/Images
mkdir -p Sources/BangoCat/Resources/Sounds
mkdir -p Tests/BangoCatTests

# Create a basic test file
cat > Tests/BangoCatTests/BangoCatTests.swift << 'EOF'
import XCTest
@testable import BangoCat

final class BangoCatTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        XCTAssertTrue(true)
    }
}
EOF

echo "Project structure created successfully!"
echo ""
echo "To run the project:"
echo "1. Open terminal in the project directory"
echo "2. Run: swift run BangoCat"
echo ""
echo "Note: You'll need to grant Accessibility permissions when prompted."