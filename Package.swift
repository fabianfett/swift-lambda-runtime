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
    .package(url: "https://github.com/swift-server/async-http-client.git", .branch("master")),
    .package(url: "https://github.com/fabianfett/swift-base64-kit.git", .upToNextMajor(from: "0.2.0")),
  ],
  targets: [
    .target(name: "LambdaEvents", dependencies: [
      "NIO",
      "NIOHTTP1",
      "NIOFoundationCompat",
      "Base64Kit"
    ]),
    .target(name: "LambdaRuntime", dependencies: [
      "LambdaEvents",
      "AsyncHTTPClient",
      "NIO",
      "NIOHTTP1",
      "NIOFoundationCompat",
      "Logging"
    ]),
    .target(name: "LambdaRuntimeTestUtils", dependencies: [
      "NIOHTTP1",
      "LambdaRuntime"
    ]),
    .testTarget(name: "LambdaRuntimeTests", dependencies: [
      "LambdaEvents",
      "LambdaRuntime",
      "LambdaRuntimeTestUtils",
      "NIO",
      "NIOTestUtils",
      "Logging",
    ])
  ]
)
