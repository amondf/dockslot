// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DockSlot",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "DockSlotCore"),
        .executableTarget(name: "DockSlot", dependencies: ["DockSlotCore"]),
        .testTarget(name: "DockSlotCoreTests", dependencies: ["DockSlotCore"]),
    ]
)
