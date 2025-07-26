// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BangoCat-mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BangoCat",
            targets: ["BangoCat"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.1.3")
    ],
    targets: [
        .executableTarget(
            name: "BangoCat",
            dependencies: [
                .product(name: "PostHog", package: "posthog-ios")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BangoCatTests",
            dependencies: ["BangoCat"]
        ),
    ]
)