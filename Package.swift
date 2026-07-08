// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DocSens",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "DocSens", targets: ["DocSens"]),
    ],
    targets: [
        .target(
            name: "DocSens",
            path: "DocSens"
        ),
        .testTarget(
            name: "DocSensTests",
            dependencies: ["DocSens"],
            path: "DocSensTests"
        )
    ]
)
