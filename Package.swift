// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BongoCat-mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "BongoCat",
            targets: ["BongoCat"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/PostHog/posthog-ios.git", from: "3.1.3")
    ],
    targets: [
        .executableTarget(
            name: "BongoCat",
            dependencies: [
                .product(name: "PostHog", package: "posthog-ios")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BongoCatTests",
            dependencies: ["BongoCat"]
        ),
    ]
)
