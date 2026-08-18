// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EvaDesktopPet",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "EvaDesktopPet", targets: ["EvaDesktopPet"])
    ],
    targets: [
        .executableTarget(
            name: "EvaDesktopPet",
            exclude: ["Resources"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "EvaDesktopPetTests",
            dependencies: ["EvaDesktopPet"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
