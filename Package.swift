// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AstraPet",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AstraPet", targets: ["AstraPet"])
    ],
    targets: [
        .executableTarget(
            name: "AstraPet",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "AstraPetTests",
            dependencies: ["AstraPet"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
