// swift-tools-version:5.1
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
    .target(
      name: "LambdaRuntime",
      dependencies: ["AsyncHTTPClient", "NIO", "NIOHTTP1", "NIOFoundationCompat", "Logging", "Base64Kit"]
    ),
    .target(
      name: "LambdaRuntimeTestUtils",
      dependencies: ["NIOHTTP1", "LambdaRuntime"]
    ),
    .testTarget(name: "LambdaRuntimeTests", dependencies: [
        "LambdaRuntime",
        "LambdaRuntimeTestUtils",
        "NIOTestUtils",
        "Logging",
    ])
  ]
)
