// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuadrantApp",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "QuadrantApp",
            path: "Sources"
        )
    ]
)
