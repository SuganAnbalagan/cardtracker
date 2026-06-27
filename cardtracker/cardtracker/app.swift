//
//  CreditStatementTrackerApp.swift
//  CreditStatementTracker
//
//  Created by ChatGPT.
//

import SwiftUI
import SwiftData

@main
struct CreditStatementTrackerApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CreditCard.self
        ])

        let configuration = ModelConfiguration(
            "CreditStatementTracker",
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @AppStorage("isLocked")
    private var isLocked = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(sharedModelContainer)
        }
    }
}