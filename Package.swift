// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "YiTong",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "YiTong",
      targets: ["YiTong"]
    ),
    .executable(
      name: "YiTongExample",
      targets: ["YiTongExample"]
    ),
  ],
  targets: [
    .target(
      name: "YiTong",
      dependencies: ["YiTongCore"]
    ),
    .target(
      name: "YiTongCore",
      dependencies: ["YiTongBridge", "YiTongWebAssets"]
    ),
    .target(
      name: "YiTongBridge"
    ),
    .target(
      name: "YiTongWebAssets",
      resources: [
        .process("Resources"),
      ]
    ),
    .executableTarget(
      name: "YiTongExample",
      dependencies: ["YiTong"],
      path: "Examples/YiTongExample"
    ),
    .testTarget(
      name: "YiTongTests",
      dependencies: ["YiTong"]
    ),
    .testTarget(
      name: "YiTongCoreTests",
      dependencies: ["YiTongCore", "YiTongWebAssets"]
    ),
    .testTarget(
      name: "YiTongBridgeTests",
      dependencies: ["YiTongBridge"]
    ),
  ]
)
