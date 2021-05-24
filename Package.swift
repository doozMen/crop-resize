// swift-tools-version:5.3
import PackageDescription

let toolname = "crop-scale"

let package = Package(
    name: toolname,
    products: [
        .executable(name: toolname, targets: [toolname]),
        .library(name: "CropScale", targets: ["CropScale"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "0.4.0")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .upToNextMajor(from: "0.2.2"))
    ],
    targets: [
        .target(name: toolname, dependencies: ["CropScale"]),
        .target(
            name: "CropScale",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core")
            ]
        ),
        .testTarget(name: "crop-scaleTests", dependencies: ["crop-scale"])
    ]
)
