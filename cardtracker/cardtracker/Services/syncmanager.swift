//
//  CloudSyncManager.swift
//  cardtracker
//

import Foundation
import WidgetKit

@MainActor
final class CloudSyncManager {

    static let shared = CloudSyncManager()

    private init() { }

    /// Call after cards are added, edited or deleted.
    func dataDidChange(cards: [CreditCard]) {

        Task {

            await NotificationManager.shared.rebuildNotifications(cards: cards)

            reloadWidgets()

        }

    }

    /// Call when the application becomes active.
    func applicationDidBecomeActive(cards: [CreditCard]) {

        Task {

            await NotificationManager.shared.rebuildNotifications(cards: cards)

            reloadWidgets()

        }

    }

    /// Call after a CloudKit sync finishes.
    func cloudKitDidImport(cards: [CreditCard]) {

        Task {

            await NotificationManager.shared.rebuildNotifications(cards: cards)

            reloadWidgets()

        }

    }

    func reloadWidgets() {

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif

    }

}