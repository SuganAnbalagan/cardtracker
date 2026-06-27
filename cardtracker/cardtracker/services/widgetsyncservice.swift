//
//  WidgetSyncService.swift
//  cardtracker
//

import Foundation
import WidgetKit

@MainActor
final class WidgetSyncService {

    static let shared = WidgetSyncService()

    private init() {}

    /// Writes the current cards into the shared App Group so the widget
    /// extension can read them.
    func updateSnapshot(cards: [CreditCard]) {

        let widgetCards = cards
            .map(WidgetCard.init)
            .sorted { $0.daysRemaining < $1.daysRemaining }

        let snapshot = WidgetSnapshot(
            generatedAt: .now,
            cards: widgetCards
        )

        do {

            let data = try JSONEncoder().encode(snapshot)

            guard let defaults = UserDefaults(
                suiteName: SharedConstants.appGroup
            ) else {
                print("Unable to access App Group.")
                return
            }

            defaults.set(data, forKey: "widgetSnapshot")
            defaults.synchronize()

            WidgetCenter.shared.reloadAllTimelines()

        } catch {

            print("Failed to write widget snapshot: \(error)")

        }

    }

    /// Clears widget data.
    func clear() {

        guard let defaults = UserDefaults(
            suiteName: SharedConstants.appGroup
        ) else {
            return
        }

        defaults.removeObject(forKey: "widgetSnapshot")
        defaults.synchronize()

        WidgetCenter.shared.reloadAllTimelines()

    }

}