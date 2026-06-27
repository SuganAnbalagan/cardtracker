//
//  cardtrackerApp.swift
//  cardtracker
//

import SwiftUI
import SwiftData

@main
struct cardtrackerApp: App {

    private let modelContainer: ModelContainer

    @Environment(\.scenePhase)
    private var scenePhase

    init() {

        do {

            let schema = Schema([
                CreditCard.self
            ])

            let configuration = ModelConfiguration(
                "cardtracker",
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )

            Task {
                _ = await NotificationManager.shared.requestAuthorization()
            }

        } catch {

            fatalError("Unable to create ModelContainer: \(error)")

        }

    }

    var body: some Scene {

        WindowGroup {

            LockView()
                .modelContainer(modelContainer)

        }
        .onChange(of: scenePhase) { _, newPhase in

            guard newPhase == .active else {
                return
            }

            Task {

                let context = modelContainer.mainContext

                let descriptor = FetchDescriptor<CreditCard>()

                let cards = (try? context.fetch(descriptor)) ?? []

                WidgetSyncService.shared.updateSnapshot(cards: cards)

                CloudSyncManager.shared.applicationDidBecomeActive(
                    cards: cards
                )

            }

        }

    }

}