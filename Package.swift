// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CardTracker",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "CardTracker", targets: ["CardTracker"])
    ],
    targets: [
        .executableTarget(
            name: "CardTracker",
            path: ".",
            sources: ["App.swift"]
        )
    ]
)
