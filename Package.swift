// swift-tools-version: 5.9
import PackageDescription
import Foundation

// Lets the timestamp engine be tested on Command Line Tools installations that
// lack Xcode's SwiftData macro plugin. Normal builds always include persistence.
let engineOnly = ProcessInfo.processInfo.environment["FOCUS_ENGINE_ONLY"] == "1"
let package = Package(
    name: "Focus",
    platforms: [.macOS(.v14)],
    products: engineOnly ? [.library(name: "FocusKit", targets: ["FocusKit"])] : [
        .library(name: "FocusKit", targets: ["FocusKit"]),
        .executable(name: "Focus", targets: ["Focus"])
    ],
    targets: engineOnly ? [
        .target(name: "FocusKit", exclude: ["Models.swift", "SessionRepository.swift"]),
        .testTarget(name: "FocusKitTests", dependencies: ["FocusKit"], exclude: ["PersistenceTests.swift"])
    ] : [
        .target(name: "FocusKit"),
        .executableTarget(name: "Focus", dependencies: ["FocusKit"]),
        .testTarget(name: "FocusKitTests", dependencies: ["FocusKit"])
    ]
)
