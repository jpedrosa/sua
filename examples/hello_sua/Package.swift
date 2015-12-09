import PackageDescription

let package = Package(
  name:  "HelloSua",
  dependencies: [
    .Package(url: "../../", majorVersion: 0)
  ]
)
