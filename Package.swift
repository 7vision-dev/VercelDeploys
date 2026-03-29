// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VercelDeploys",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VercelDeploys",
            path: "VercelDeploys",
            resources: [
                .process("Assets.xcassets")
            ],
            linkerSettings: [
                .linkedFramework("Security")
            ]
        )
    ]
)
