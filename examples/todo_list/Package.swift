import PackageDescription

let package = Package(
  name:  "TodoList",
  dependencies: [
    .Package(url: "../../", majorVersion: 0)
  ]
)
