// swift-tools-version:5.10
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
            .library(
                name: "ParseServerSwift",
                targets: ["ParseServerSwift"]
            )
    ],
    dependencies: [
        .package(
            url: "https://github.com/vapor/vapor.git",
			exact: Version(4, 117, 2)

        ),
        .package(
            url: "https://github.com/netreconlab/Parse-Swift.git",
            .upToNextMajor(from: "5.12.3")
        ),
        .package(
          url: "https://github.com/apple/swift-collections.git",
          exact: Version(1, 1, 6)

        ),
        .package(
          url: "https://github.com/apple/swift-nio.git",
          exact: Version(2, 86, 2)

        ),
        .package(
          url: "https://github.com/apple/swift-nio-http2.git",
          exact: Version(1, 38, 0)

        ),
        .package(
          url: "https://github.com/apple/swift-log.git",
          exact: Version(1, 6, 4)

        ),
        .package(
          url: "https://github.com/apple/swift-nio-ssl.git",
          exact: Version(2, 34, 1)

        ),
        .package(
          url: "https://github.com/apple/swift-crypto.git",
          exact: Version(3, 15, 1)

        ),
        .package(
          url: "https://github.com/swift-server/async-http-client.git",
          exact: Version(1, 29, 1)

        ),
        .package(
          url: "https://github.com/apple/swift-nio-extras.git",
          exact: Version(1, 29, 0)

        ),
        .package(
          url: "https://github.com/apple/swift-asn1.git",
          exact: Version(1, 4, 0)

        ),
        .package(
          url: "https://github.com/apple/swift-async-algorithms.git",
          exact: Version(1, 0, 4)

        ),
        .package(
          url: "https://github.com/apple/swift-certificates.git",
          exact: Version(1, 15, 1)

        ),
        .package(
          url: "https://github.com/apple/swift-http-structured-headers.git",
          exact: Version(1, 4, 0)

        ),
        .package(
          url: "https://github.com/apple/swift-nio-transport-services.git",
          exact: Version(1, 25, 2)

        )
    ],
    targets: [
        .target(
            name: "ParseServerSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ParseSwift", package: "Parse-Swift")
            ]),
        .executableTarget(
            name: "App",
            dependencies: [.target(name: "ParseServerSwift")],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .testTarget(
            name: "ParseServerSwiftTests",
            dependencies: [
                .target(name: "ParseServerSwift"),
                .product(name: "XCTVapor", package: "vapor")
            ]
        )
    ]
)
