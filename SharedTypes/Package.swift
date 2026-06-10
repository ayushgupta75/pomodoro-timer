// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedTypes",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedTypes", targets: ["SharedTypes"]),
    ],
    targets: [
        .target(name: "SharedTypes", dependencies: []),
    ]
)
