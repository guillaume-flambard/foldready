// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "foldready",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "foldready", path: "Sources/foldready"),
        .testTarget(name: "foldreadyTests", dependencies: ["foldready"], path: "Tests/foldreadyTests")
    ]
)
