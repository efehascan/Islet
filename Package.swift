// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Islet",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "Islet", targets: ["Islet"])],
    targets: [
        .target(name: "IsletCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .executableTarget(name: "Islet", dependencies: ["IsletCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "IsletCoreTests", dependencies: ["IsletCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
