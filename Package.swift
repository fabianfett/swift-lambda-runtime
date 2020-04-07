// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-lambda-runtime",
  products: [
    .library(
      name: "LambdaRuntime",
      targets: ["LambdaRuntime"]
    ),
    .library(
      name: "LambdaEvents",
      targets: ["LambdaEvents"]
    ),
    .library(
      name: "LambdaRuntimeTestUtils",
      targets: ["LambdaRuntimeTestUtils"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.1.1")),
    .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/fabianfett/swift-base64-kit.git", .upToNextMajor(from: "0.2.0")),
  ],
  targets: [
    .target(name: "LambdaEvents", dependencies: [
      .product(name: "NIO", package: "swift-nio"),
      .product(name: "NIOHTTP1", package: "swift-nio"),
      .product(name: "NIOFoundationCompat", package: "swift-nio"),
      .product(name: "Base64Kit", package: "swift-base64-kit")
    ]),
    .target(name: "LambdaRuntime", dependencies: [
      "LambdaEvents",
      .product(name: "AsyncHTTPClient", package: "async-http-client"),
      .product(name: "NIO", package: "swift-nio"),
      .product(name: "NIOHTTP1", package: "swift-nio"),
      .product(name: "NIOFoundationCompat", package: "swift-nio"),
      .product(name: "Logging", package: "swift-log"),
    ]),
    .target(name: "LambdaRuntimeTestUtils", dependencies: [
      .product(name: "NIOHTTP1", package: "swift-nio"),
      "LambdaRuntime"
    ]),
    .testTarget(name: "LambdaRuntimeTests", dependencies: [
      "LambdaEvents",
      "LambdaRuntime",
      "LambdaRuntimeTestUtils",
      .product(name: "NIO", package: "swift-nio"),
      .product(name: "NIOTestUtils", package: "swift-nio"),
      .product(name: "Logging", package: "swift-log"),
    ])
  ]
)
