// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "SwiftPicoPlayground",
  platforms: [.macOS(.v10_15)],
  products: [
    .library(name: "App", type: .static, targets: ["App"])
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
    .package(
      url: "git@github.com:ckaik/CPicoSDK.git",
      branch: "ai-hang-fix",
      traits: [
        .init(name: "Platform_RP2350"),
        .init(name: "BootStage2_W25Q080"),

        // - Pico 2 W
        .init(name: "Variant_RP2350A"),
        .init(name: "Radio_CYW43439"),
      ]
    ),
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        "CPicoSDK",
        "Common",
        "MongooseKit",
        "PicoKit",
        "HomeAssistantKit",
      ]
    ),
    .target(name: "CMath"),
    .target(name: "CMongoose"),
    .target(name: "Common", dependencies: ["CPicoSDK", "CMath"]),
    .target(
      name: "HomeAssistantKit", dependencies: ["Common", "MongooseKit"]),
    .target(name: "MongooseKit", dependencies: ["CMongoose", "Common", "MongooseKitMacros"]),
    .target(name: "PicoKit", dependencies: ["CPicoSDK", "Common"]),
    .macro(
      name: "MongooseKitMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v5]
)

for target in package.targets {
  if target.name == "MongooseKitMacros" { continue }
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(.enableExperimentalFeature("Embedded"))
}
