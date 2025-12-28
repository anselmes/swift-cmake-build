// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "ExampleApp",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(name: "ExampleSys", path: "../lib/ExampleSys"),
    .package(name: "ExampleSwift", path: "../lib/Example"),
  ],
  targets: [
    .executableTarget(
      name: "ExampleApp",
      dependencies: [
        "ExampleSwift",
        "ExampleSys",
      ],
    ),
  ]
)
