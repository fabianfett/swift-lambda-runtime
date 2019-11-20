// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TodoAPIGateway",
  products: [
    .executable(name: "TodoAPIGateway", targets: ["TodoAPIGateway"]),
    .library(name: "TodoService", targets: ["TodoService"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.1.1")),
    .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", .branch("master")),
    .package(path: "../../"),
  ],
  targets: [
    .target(
      name: "TodoAPIGateway",
      dependencies: ["AWSLambda", "Logging", "TodoService", "NIO", "NIOHTTP1", "DynamoDB"]),
    .testTarget(
      name: "TodoAPIGatewayTests",
      dependencies: ["TodoAPIGateway"]),
    .target(
      name: "TodoService",
      dependencies: ["DynamoDB"]),
    .testTarget(
      name: "TodoServiceTests",
      dependencies: ["TodoService"])
  ]
)
