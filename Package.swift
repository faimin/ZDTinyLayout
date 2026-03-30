// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZDTinyLayout",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_11),
        .tvOS(.v9),
        .watchOS(.v7),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "ZDTinyLayout",
            targets: ["ZDTinyLayout"]
		),
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
