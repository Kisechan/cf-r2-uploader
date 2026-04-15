// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CFR2Uploader",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CFR2Core",
            targets: ["CFR2Core"]
        ),
        .executable(
            name: "cfr2uploader",
            targets: ["cfr2uploader"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "CFR2Core",
            dependencies: []
        ),
        .executableTarget(
            name: "cfr2uploader",
            dependencies: [
                "CFR2Core",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "CFR2CoreTests",
            dependencies: ["CFR2Core"]
        ),
    ]
)
