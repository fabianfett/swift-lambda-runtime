// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-aws-lambda",
  products: [
    .library(
      name: "AWSLambda",
      targets: ["AWSLambda"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.1.1")),
    .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMajor(from: "1.0.0"))
  ],
  targets: [
    .target(
      name: "AWSLambda",
      dependencies: ["AsyncHTTPClient", "NIO", "NIOHTTP1", "NIOFoundationCompat", "Logging"]
    ),
    .testTarget(name: "AWSLambdaTests", dependencies: ["AWSLambda", "NIOTestUtils", "Logging"])
  ]
)
