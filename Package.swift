// swift-tools-version:5.5.2
import PackageDescription

let package = Package(
    name: "ParseServerSwift",
    platforms: [
       .macOS(.v12)
    ],
    products: [
            .library(name: "ParseServerSwift", targets: ["ParseServerSwift"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.69.1")),
        .package(url: "https://github.com/netreconlab/Parse-Swift.git",
                 .upToNextMajor(from: "5.0.0-beta.3")),
    ],
    targets: [
        .target(
            name: "ParseServerSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ParseSwift", package: "Parse-Swift")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "ParseServerSwift")]),
        .testTarget(name: "ParseServerSwiftTests", dependencies: [
            .target(name: "ParseServerSwift"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
