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
        .package(url: "https://github.com/dreymonde/AppFolder.git", from: "0.2.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "0.9.0")),
        .package(url: "https://github.com/IBM-Swift/CommonCrypto.git", from: "1.0.0"),
        //.package(url: "https://github.com/WineskinCommunity/p7zip-swift.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "wsenginebuild",
            dependencies: ["EngineBuilder", "Commander"]
        ),
        .target(
            name: "EngineBuilder",
            dependencies: ["AppFolder", "CryptoSwift", "CommonCrypto"]
        ),
        .testTarget(name: "EngineBuilderTests", dependencies: ["EngineBuilder"]),
    ]
)
