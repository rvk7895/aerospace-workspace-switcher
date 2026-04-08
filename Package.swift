// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "aerospace-workspace-switcher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "aerospace-workspace-switcher", targets: ["aerospace-workspace-switcher"]),
        .library(name: "WorkspaceSwitcherCore", targets: ["WorkspaceSwitcherCore"]),
    ],
    targets: [
        .target(
            name: "WorkspaceSwitcherCore"
        ),
        .executableTarget(
            name: "aerospace-workspace-switcher",
            dependencies: ["WorkspaceSwitcherCore"]
        ),
        .testTarget(
            name: "WorkspaceSwitcherCoreTests",
            dependencies: ["WorkspaceSwitcherCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
