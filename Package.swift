// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "xkill-mac",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "xkill-mac",
            path: "Sources/xkill-mac",
            exclude: ["Info.plist"],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=minimal"])
            ]
        )
    ]
)
