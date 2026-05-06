// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EyePause",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "EyePauseCore", targets: ["EyePauseCore"]),
        .executable(name: "EyePause", targets: ["EyePauseApp"])
    ],
    targets: [
        .target(name: "EyePauseCore"),
        .executableTarget(
            name: "EyePauseApp",
            dependencies: ["EyePauseCore"]
        ),
        .testTarget(
            name: "EyePauseCoreTests",
            dependencies: ["EyePauseCore"]
        )
    ]
)
