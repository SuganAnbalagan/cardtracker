//
//  WidgetView.swift
//  cardtracker
//

import SwiftUI
import WidgetKit

struct CardTrackerWidgetView: View {

    @Environment(\.widgetFamily)
    private var family

    let entry: CardTrackerEntry

    var body: some View {

        switch family {

        case .systemSmall:
            smallWidget

        case .systemMedium:
            mediumWidget

        case .systemLarge:
            largeWidget

        case .accessoryRectangular:
            rectangularAccessory

        case .accessoryInline:
            inlineAccessory

        case .accessoryCircular:
            circularAccessory

        @unknown default:
            mediumWidget
        }

    }

}

// MARK: - Small

private extension CardTrackerWidgetView {

    var smallWidget: some View {

        Group {

            if let card = entry.nextCard {

                VStack(alignment: .leading, spacing: 8) {

                    Text(card.icon)
                        .font(.largeTitle)

                    Text(card.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Text("\(card.daysRemaining)")
                        .font(.system(size: 34, weight: .bold))

                    Text(card.daysRemaining == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                }
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .topLeading)

            } else {

                ContentUnavailableView(
                    "No Cards",
                    systemImage: "creditcard"
                )

            }

        }

    }

}

// MARK: - Medium

private extension CardTrackerWidgetView {

    var mediumWidget: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Upcoming Statements")
                .font(.headline)

            ForEach(entry.cards.prefix(3)) { card in

                HStack {

                    Text(card.icon)

                    VStack(alignment: .leading) {

                        Text(card.name)
                            .lineLimit(1)

                        Text(card.bank)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                    }

                    Spacer()

                    Text("\(card.daysRemaining)d")
                        .bold()

                }

            }

            Spacer()

        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .topLeading)

    }

}

// MARK: - Large

private extension CardTrackerWidgetView {

    var largeWidget: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Credit Card Statements")
                .font(.headline)

            Divider()

            ForEach(entry.cards.prefix(8)) { card in

                HStack {

                    Text(card.icon)

                    VStack(alignment: .leading) {

                        Text(card.name)

                        Text(card.bank)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    }

                    Spacer()

                    VStack(alignment: .trailing) {

                        Text("\(card.daysRemaining)")
                            .bold()

                        Text("days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                    }

                }

            }

            Spacer()

        }

    }

}

// MARK: - Lock Screen

private extension CardTrackerWidgetView {

    var rectangularAccessory: some View {

        if let card = entry.nextCard {

            VStack(alignment: .leading) {

                Text(card.name)
                    .font(.caption)

                Text("\(card.daysRemaining) days")
                    .font(.headline)

            }

        } else {

            Text("No Cards")

        }

    }

    var inlineAccessory: some View {

        if let card = entry.nextCard {

            Text("\(card.icon) \(card.daysRemaining)d")

        } else {

            Text("No Cards")

        }

    }

    var circularAccessory: some View {

        ZStack {

            Circle()

            if let card = entry.nextCard {

                VStack(spacing: 2) {

                    Text(card.icon)
                        .font(.caption)

                    Text("\(card.daysRemaining)")
                        .font(.caption2)
                        .bold()

                }

            }

        }

    }

}