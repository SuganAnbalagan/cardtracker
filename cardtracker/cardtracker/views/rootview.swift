//
//  RootView.swift
//  CreditStatementTracker
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Environment(\.modelContext)
    private var modelContext

    @Query(animation: .default)
    private var cards: [CreditCard]

    @State
    private var showingAddCard = false

    @AppStorage("sortDescending")
    private var sortDescending = true

    @AppStorage("useManualOrdering")
    private var useManualOrdering = false

    private var displayedCards: [CreditCard] {

        if useManualOrdering {
            return cards.sorted {
                $0.manualOrder < $1.manualOrder
            }
        }

        return cards.sorted {

            if sortDescending {
                return $0.daysRemaining > $1.daysRemaining
            } else {
                return $0.daysRemaining < $1.daysRemaining
            }
        }
    }

    var body: some View {

        NavigationStack {

            Group {

                if displayedCards.isEmpty {
                    emptyView
                } else {
                    cardList
                }

            }
            .navigationTitle("Statements")
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }

                }

                ToolbarItem(placement: .topBarTrailing) {

                    Button {
                        showingAddCard = true
                    } label: {
                        Image(systemName: "plus")
                    }

                }

            }
            .sheet(isPresented: $showingAddCard) {
                AddEditCardView()
            }

        }

    }

}

// MARK: - List

private extension RootView {

    var cardList: some View {

        List {

            ForEach(displayedCards) { card in

                NavigationLink {
                    CardDetailView(card: card)
                } label: {

                    HStack(spacing: 16) {

                        Text(card.icon)
                            .font(.largeTitle)

                        VStack(alignment: .leading, spacing: 6) {

                            Text(card.name)
                                .font(.headline)

                            Text(card.bank)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Statement: \(card.statementDateString)")
                                .font(.caption)

                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {

                            Text("\(card.daysRemaining)")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(card.daysRemaining == 1 ? "day" : "days")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if card.isStatementToday {

                                Text("TODAY")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(.red)

                            } else if card.isStatementTomorrow {

                                Text("TOMORROW")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(.orange)

                            }

                        }

                    }
                    .padding(.vertical, 6)

                }
                .swipeActions(edge: .trailing) {

                    Button(role: .destructive) {
                        delete(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                }

            }

        }
        .listStyle(.insetGrouped)

    }

}

// MARK: - Empty State

private extension RootView {

    var emptyView: some View {

        ContentUnavailableView {

            Label(
                "No Credit Cards",
                systemImage: "creditcard"
            )

        } description: {

            Text("Tap + to add your first credit card.")

        } actions: {

            Button("Add Card") {
                showingAddCard = true
            }

        }

    }

}

// MARK: - Helpers

private extension RootView {

    func delete(_ card: CreditCard) {

        modelContext.delete(card)

        do {
            try modelContext.save()
        } catch {
            print(error.localizedDescription)
        }

    }

}

#Preview {

    RootView()
        .modelContainer(for: CreditCard.self, inMemory: true)

}