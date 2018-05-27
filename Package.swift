// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wsenginebuild",
    products: [
        .library(name: "EngineBuilder", targets: ["EngineBuilder"]),
        .executable(name: "wsenginebuild", targets: ["wsenginebuild"]),
        ],
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "wsenginebuild",
            dependencies: ["EngineBuilder", "Commander"]
        ),
        .target(name: "EngineBuilder"),
        .testTarget(name: "EngineBuilderTests", dependencies: ["EngineBuilder"]),
    ]
)
