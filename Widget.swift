import WidgetKit
import SwiftUI
import SwiftData

struct WidgetEntry: TimelineEntry {
    let date: Date
    let topCards: [WidgetCardModel]
}

struct WidgetCardModel: Identifiable, Codable {
    var id: UUID
    let name: String
    let daysLeft: Int
}

// Added @preconcurrency to fix the Swift 6 isolation checking warnings
struct Provider: @preconcurrency TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), topCards: [
            WidgetCardModel(id: UUID(), name: "Visa", daysLeft: 25),
            WidgetCardModel(id: UUID(), name: "Amex", daysLeft: 14)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        completion(WidgetEntry(date: Date(), topCards: []))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        Task {
            // Reached into SwiftData schema on an independent background actor block
            let sharedContainer = try? ModelContainer(for: CreditCard.self)
            let descriptor = FetchDescriptor<CreditCard>()
            let cards = (try? sharedContainer?.mainContext.fetch(descriptor)) ?? []
            
            let sorted = cards.map { card in
                WidgetCardModel(id: card.id, name: card.name, daysLeft: card.daysUntilStatement)
            }.sorted { $0.daysLeft > $1.daysLeft }
            
            let entry = WidgetEntry(date: Date(), topCards: Array(sorted.prefix(3)))
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800)))
            completion(timeline)
        }
    }
}

struct CardWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Top Durations")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.secondary)
            
            if entry.topCards.isEmpty {
                Text("No cards tracked")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.topCards) { card in
                        HStack {
                            Text(card.name)
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text("\(card.daysLeft)d")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.thinMaterial, for: .widget)
    }
}

@main
struct CardTrackerWidget: Widget {
    let kind: String = "CardTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Card Tracker Widget")
        .description("Displays the top 3 cards with the longest remaining duration.")
        .supportedFamilies([.systemMedium])
    }
}
