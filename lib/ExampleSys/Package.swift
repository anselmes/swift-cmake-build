// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ExampleSys",
  platforms: [.macOS(.v14)],
  products: [
    .library(name: "ExampleC", type: .static, targets: ["ExampleC"]),
    .library(name: "ExampleSys", type: .static, targets: ["ExampleSys"]),
  ],
  targets: [
    .target(name: "ExampleC"),
    .target(
      name: "ExampleSys",
      dependencies: ["ExampleC"],
    ),
  ]
)
