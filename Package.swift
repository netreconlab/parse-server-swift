// swift-tools-version:5.6
import PackageDescription

// swiftlint:disable line_length

let package = Package(
    name: "ParseServerSwift",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
            .library(name: "ParseServerSwift", targets: ["ParseServerSwift"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "4.77.0")),
        .package(url: "https://github.com/netreconlab/Parse-Swift.git",
                 .upToNextMajor(from: "5.8.0"))
    ],
    targets: [
        .target(
            name: "ParseServerSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ParseSwift", package: "Parse-Swift")
            ]),
        .executableTarget(name: "App",
                          dependencies: [.target(name: "ParseServerSwift")],
                          swiftSettings: [
                              // Enable better optimizations when building in Release configuration. Despite the use of
                              // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                              // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                              .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
                          ]),
        .testTarget(name: "ParseServerSwiftTests", dependencies: [
            .target(name: "ParseServerSwift"),
            .product(name: "XCTVapor", package: "vapor")
        ])
    ]
)
