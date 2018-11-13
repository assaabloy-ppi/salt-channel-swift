// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SaltChannel",

    products: [
        .library(name: "saltchannel", targets: ["SaltChannel"]),
        .library(name: "saltchannel-static", type: .static, targets: ["SaltChannel"]),
        .library(name: "saltchannel-dynamic", type: .dynamic, targets: ["SaltChannel"])
    ],

    dependencies: [
        .package(url: "https://github.com/jedisct1/swift-sodium", from: "0.7.0")
    ],

    targets: [
        .target(name: "SaltChannel", path: "Sources"),
        .testTarget(name: "SaltChannel-test", dependencies: ["SaltChannel"], path: "Tests")
    ],

    swiftLanguageVersions: [4]
)
