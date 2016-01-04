import PackageDescription

let package = Package(
  name:  "SocketHello",
  dependencies: [
    .Package(url: "../../", majorVersion: 0)
  ]
)
