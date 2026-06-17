import ProjectDescription

let project = Project(
    name: "CardTracker",
    targets: [
        .target(
            name: "CardTracker",
            destinations: .iOS,
            product: .app,
            bundleId: "com.yourname.cardtracker",
            infoPlist: .default,
            sources: ["App.swift"]
        )
    ]
)
