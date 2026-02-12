// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SafaShared",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SafaShared", targets: ["SafaShared"]),
    ],
    targets: [
        .target(name: "SafaShared"),
        .testTarget(name: "SafaSharedTests", dependencies: ["SafaShared"]),
    ]
)
