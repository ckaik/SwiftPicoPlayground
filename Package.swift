// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "SwiftPicoPlayground",
  products: [
    .library(name: "App", type: .static, targets: ["App"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/gonzalolarralde/CPicoSDK",
      exact: "2.2.2",
      traits: [
        .init(name: "Platform_RP2350"),
        .init(name: "BootStage2_W25Q080"),

        // - Pico 2 W
        .init(name: "Variant_RP2350A"),
        .init(name: "Radio_CYW43439"),
      ]
    )
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        "CPicoSDK",
        "Common",
        "MongooseKit",
        "PicoKit",
      ]
    ),
    .target(name: "PicoKit", dependencies: ["CPicoSDK", "Common"]),
    .target(name: "Common", dependencies: ["CPicoSDK", "CMath"]),
    .target(name: "CMath"),
    .target(name: "CMongoose"),
    .target(name: "MongooseKit", dependencies: ["CMongoose"]),
  ],
  swiftLanguageModes: [.v5]
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(.enableExperimentalFeature("Embedded"))
}
