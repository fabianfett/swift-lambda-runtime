// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "EventSources",
  dependencies: [
    .package(path: "../.."),
    .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.9.0")),
    .package(url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.1.1")),
  ],
  targets: [
    .target(
      name: "EventSources",
      dependencies: ["LambdaRuntime", "Logging", "NIO", "NIOFoundationCompat", "NIOHTTP1"]),
  ]
)
