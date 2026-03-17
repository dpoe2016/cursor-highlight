// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cursor-highlight",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "cursor-highlight",
            path: "Sources"
        )
    ]
)
