//
//  WidgetProvider.swift
//  cardtracker
//

import Foundation
import WidgetKit

struct CardTrackerProvider: TimelineProvider {

    func placeholder(in context: Context) -> CardTrackerEntry {
        .placeholder
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (CardTrackerEntry) -> Void
    ) {

        completion(
            CardTrackerEntry(
                date: .now,
                snapshot: loadSnapshot()
            )
        )

    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<CardTrackerEntry>) -> Void
    ) {

        let snapshot = loadSnapshot()

        let entry = CardTrackerEntry(
            date: .now,
            snapshot: snapshot
        )

        let nextRefresh = Calendar.current.date(
            byAdding: .minute,
            value: SharedConstants.Widget.refreshMinutes,
            to: .now
        ) ?? .now.addingTimeInterval(900)

        let timeline = Timeline(
            entries: [entry],
            policy: .after(nextRefresh)
        )

        completion(timeline)

    }

}

// MARK: - Loading

private extension CardTrackerProvider {

    func loadSnapshot() -> WidgetSnapshot {

        guard
            let defaults = UserDefaults(
                suiteName: SharedConstants.appGroup
            ),
            let data = defaults.data(forKey: "widgetSnapshot")
        else {
            return .empty
        }

        do {

            return try JSONDecoder().decode(
                WidgetSnapshot.self,
                from: data
            )

        } catch {

            print("Widget decode failed:", error)
            return .empty

        }

    }

}