//
//  cardtrackerwidget.swift
//  cardtrackerwidget
//

import WidgetKit
import SwiftUI

@main
struct cardtrackerwidget: WidgetBundle {

    var body: some Widget {
        CardTrackerWidget()
    }

}

struct CardTrackerWidget: Widget {

    let kind = SharedConstants.Widget.kind

    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider: CardTrackerProvider()
        ) { entry in

            CardTrackerWidgetView(entry: entry)

        }
        .configurationDisplayName("Credit Card Statements")
        .description("Shows your upcoming credit card statement dates.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])

    }

}