// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "taylor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "taylor", targets: ["taylor"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.1"),
        .package(url: "https://github.com/rensbreur/SwiftTUI.git", exact: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "taylor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftTUI", package: "SwiftTUI")
            ],
            path: "taylor",
            linkerSettings: [
                .linkedFramework("EventKit")
            ]
        ),
        .testTarget(
            name: "taylorTests",
            dependencies: ["taylor"],
            path: "Tests/taylorTests"
        )
    ]
)
