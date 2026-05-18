// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZDTinyLayout",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v12),
        .watchOS(.v5),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "ZDTinyLayout",
            targets: ["ZDTinyLayout"]
        )
    ],
    targets: [
        .target(
            name: "ZDTinyLayout",
            dependencies: [],
            path: "Source",
            resources: [
                .process("Resource/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "ZDTinyLayoutTests",
            dependencies: ["ZDTinyLayout"],
            path: "ZDTinyLayoutTests"
        ),
    ]
)
