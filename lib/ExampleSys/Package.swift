// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ExampleSys",

  platforms: [.macOS(.v14)],
  products: [
    .library(name: "Example", type: .static, targets: ["Example"]),
    .library(name: "ExampleSys", type: .static, targets: ["ExampleSys"]),
  ],
  targets: [
    .target(name: "Example"),
    .target(
      name: "ExampleSys",
      dependencies: ["Example"],
    ),
  ]
)
