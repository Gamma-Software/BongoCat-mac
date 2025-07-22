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
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BangoCat",
            dependencies: []
        ),
        .testTarget(
            name: "BangoCatTests",
            dependencies: ["BangoCat"]
        ),
    ]
)