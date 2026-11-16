// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Ada",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "Ada", targets: ["Ada"])],
    targets: [
        .target(name: "AdaCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .executableTarget(name: "Ada", dependencies: ["AdaCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "AdaCoreTests", dependencies: ["AdaCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
