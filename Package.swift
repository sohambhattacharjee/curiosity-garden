// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "CuriosityGarden", platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "GardenCore", targets: ["GardenCore"])],
    targets: [
        .target(name: "GardenCore"),
        // Compile the same state/PIN sources used by the iOS target for unit tests.
        .target(name: "GardenAppLogic", dependencies: ["GardenCore"], path: "App", exclude: ["CuriosityGardenApp.swift", "questions.json", "Assets.xcassets"]),
        .testTarget(name: "GardenCoreTests", dependencies: ["GardenCore"]),
        .testTarget(name: "GardenAppLogicTests", dependencies: ["GardenAppLogic", "GardenCore"])
    ])
