// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "nio-h2",
    products: [
		.executable(
			name: "nio-h2-example",
			targets: ["NIOH2Example"]),
        .library(
            name: "NIOH2",
            targets: ["NIOH2"]),
    ],
    dependencies: [
		.package(url: "https://github.com/apple/swift-nio", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio-ssl", from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio-http2", .upToNextMinor(from: "0.1.0")),
    ],
    targets: [
		.target(
			name: "NIOH2Example",
			dependencies: ["NIOH2"]),
        .target(
            name: "NIOH2",
            dependencies: ["NIO", "NIOOpenSSL", "NIOHTTP1", "NIOHTTP2"]),
    ]
)

