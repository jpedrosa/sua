import PackageDescription

let package = Package(
  name:  "Sua",
  dependencies: [
    .Package(url: "../csua_module", majorVersion: 0)
  ]
)
