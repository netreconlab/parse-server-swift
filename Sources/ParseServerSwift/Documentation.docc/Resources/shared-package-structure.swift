// Package.swift - Create a shared Swift Package for your models
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MySharedModels",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "MySharedModels",
            targets: ["MySharedModels"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/netreconlab/Parse-Swift", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "MySharedModels",
            dependencies: [
                .product(name: "ParseSwift", package: "Parse-Swift")
            ]
        )
    ]
)

// Then add your ParseObjects in Sources/MySharedModels/:
// - GameScore.swift
// - Post.swift
// - etc.

// Use this package in both your iOS app and ParseServerSwift server
