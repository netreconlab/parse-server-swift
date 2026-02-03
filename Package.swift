// swift-tools-version:6.0
import PackageDescription

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
			.upToNextMajor(from: "4.121.1")

        ),
        .package(
            url: "https://github.com/netreconlab/Parse-Swift.git",
            .upToNextMajor(from: "6.0.6")
        )
    ],
    targets: [
        .target(
            name: "ParseServerSwift",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "ParseSwift", package: "Parse-Swift")
            ],
			swiftSettings: swiftSettings
		),
        .executableTarget(
            name: "App",
            dependencies: [.target(name: "ParseServerSwift")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ParseServerSwiftTests",
            dependencies: [
                .target(name: "ParseServerSwift"),
                .product(name: "XCTVapor", package: "vapor")
            ],
			swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] {
	[
		.enableUpcomingFeature("ExistentialAny")
	]
}
