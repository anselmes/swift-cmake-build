// ExampleSys - System-level functionality for the example

// #if canImport(Foundation)
// import Foundation
// #endif

@_exported import Example

// A simple structure representing the ExampleSys module
public struct ExampleStruct {
  public private(set) var text = "Hello, World!"

  public init() {}

  // Function to get system information
  // #if canImport(Foundation)
  // public func systemInfo() -> String {
  //   return "ExampleSys running on \(ProcessInfo.processInfo.operatingSystemVersionString)"
  // }
  // #endif
}

@c @implementation
public func external_example() {
  print("Hello from extern_example (implemented in Swift)!")
}
