// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "Example",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(name: "ExampleSys", path: "../lib/ExampleSys"),
    .package(name: "ExampleSwift", path: "../lib/ExampleSwift"),
  ],
  targets: [
    .executableTarget(
      name: "Example",
      dependencies: [
        "ExampleSys",
        "ExampleSwift",
      ],
    ),
  ]
)
