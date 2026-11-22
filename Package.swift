// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "CuriosityGarden", platforms: [.macOS(.v14), .iOS(.v17)], products: [.library(name: "GardenCore", targets: ["GardenCore"])], targets: [.target(name: "GardenCore"), .testTarget(name: "GardenCoreTests", dependencies: ["GardenCore"])])
