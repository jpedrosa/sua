import PackageDescription

let package = Package(
  name:  "WordCounter",
  dependencies: [
    .Package(url: "../../", majorVersion: 0)
  ]
)
