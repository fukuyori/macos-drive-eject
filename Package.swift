// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "eject",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "eject", targets: ["EjectCLI"])
    ],
    targets: [
        .target(name: "EjectCore"),
        .executableTarget(
            name: "EjectCLI",
            dependencies: ["EjectCore"]
        ),
        .testTarget(
            name: "EjectCoreTests",
            dependencies: ["EjectCore"]
        )
    ]
)
