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
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "wsenginebuild",
            dependencies: ["EngineBuilder"]
        ),
        .target(name: "EngineBuilder"),
        .testTarget(name: "EngineBuilderTests", dependencies: ["EngineBuilder"]),
    ]
)
