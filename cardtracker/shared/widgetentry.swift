//
//  WidgetEntry.swift
//  cardtracker
//

import Foundation
import WidgetKit

struct CardTrackerEntry: TimelineEntry {

    let date: Date

    let snapshot: WidgetSnapshot

    static let placeholder = CardTrackerEntry(
        date: .now,
        snapshot: .empty
    )

    var cards: [WidgetCard] {
        snapshot.cards
    }

    var nextCard: WidgetCard? {
        cards.min { $0.daysRemaining < $1.daysRemaining }
    }

    var lastUpdated: Date {
        snapshot.generatedAt
    }
}