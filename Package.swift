// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Ferret",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Ferret",
            targets: ["Ferret"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "Ferret",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "Markdown", package: "swift-markdown")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
