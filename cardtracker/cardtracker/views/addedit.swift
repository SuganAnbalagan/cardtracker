//
//  AddEditCardView.swift
//  cardtracker
//

import SwiftUI
import SwiftData

struct AddEditCardView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @Query
    private var allCards: [CreditCard]

    private let editingCard: CreditCard?

    @State private var name = ""
    @State private var bank = ""

    @State private var statementDay = 1

    @State private var hasPaymentDueDate = false
    @State private var paymentDueDay = 1

    @State private var selectedColor = "#007AFF"
    @State private var selectedEmoji = "💳"

    private let colors = [
        "#007AFF",
        "#34C759",
        "#FF9500",
        "#FF3B30",
        "#AF52DE",
        "#30B0C7",
        "#8E8E93",
        "#000000"
    ]

    private let emojis = [
        "💳","🏦","💰","💵","💎","🪙",
        "⭐️","🚀","🦁","🔥","🛍️","✈️"
    ]

    init(card: CreditCard? = nil) {
        editingCard = card
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Card") {

                    TextField("Card Name", text: $name)

                    TextField("Bank", text: $bank)

                }

                Section("Statement") {

                    Picker("Statement Day", selection: $statementDay) {

                        ForEach(1...31, id: \.self) {
                            Text("\($0)").tag($0)
                        }

                    }

                }

                Section("Payment Due") {

                    Toggle(
                        "Has Payment Due Date",
                        isOn: $hasPaymentDueDate
                    )

                    if hasPaymentDueDate {

                        Picker("Payment Day", selection: $paymentDueDay) {

                            ForEach(1...31, id: \.self) {
                                Text("\($0)").tag($0)
                            }

                        }

                    }

                }

                Section("Appearance") {

                    VStack(alignment: .leading) {

                        Text("Icon")
                            .font(.caption)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: 6
                            )
                        ) {

                            ForEach(emojis, id: \.self) { emoji in

                                Button {

                                    selectedEmoji = emoji

                                } label: {

                                    Text(emoji)
                                        .font(.title2)
                                        .frame(maxWidth: .infinity)
                                        .padding(8)
                                        .background(
                                            selectedEmoji == emoji
                                            ? Color.accentColor.opacity(0.25)
                                            : .clear
                                        )
                                        .clipShape(
                                            RoundedRectangle(
                                                cornerRadius: 8
                                            )
                                        )

                                }
                                .buttonStyle(.plain)

                            }

                        }

                    }

                    VStack(alignment: .leading) {

                        Text("Color")
                            .font(.caption)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible()),
                                count: 4
                            )
                        ) {

                            ForEach(colors, id: \.self) { color in

                                Button {

                                    selectedColor = color

                                } label: {

                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay {

                                            if selectedColor == color {

                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.white)

                                            }

                                        }

                                }
                                .buttonStyle(.plain)

                            }

                        }

                    }

                }

            }
            .navigationTitle(
                editingCard == nil ? "New Card" : "Edit Card"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }

                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Save") {
                        save()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )

                }

            }
            .onAppear {
                load()
            }

        }

    }

}

// MARK: - Helpers

private extension AddEditCardView {

    func load() {

        guard let card = editingCard else {
            return
        }

        name = card.name
        bank = card.bank
        statementDay = card.statementDay

        if let due = card.paymentDueDay {
            hasPaymentDueDate = true
            paymentDueDay = due
        }

        selectedColor = card.colorHex
        selectedEmoji = card.icon

    }

    func save() {

        if let editingCard {

            editingCard.name = name
            editingCard.bank = bank
            editingCard.statementDay = statementDay
            editingCard.paymentDueDay = hasPaymentDueDate ? paymentDueDay : nil
            editingCard.colorHex = selectedColor
            editingCard.icon = selectedEmoji

        } else {

            let newCard = CreditCard(
                name: name,
                bank: bank,
                statementDay: statementDay,
                paymentDueDay: hasPaymentDueDate ? paymentDueDay : nil,
                colorHex: selectedColor,
                icon: selectedEmoji,
                manualOrder: allCards.count
            )

            modelContext.insert(newCard)

        }

        do {

            try modelContext.save()

            WidgetSyncService.shared.updateSnapshot(cards: allCards)

            CloudSyncManager.shared.dataDidChange(cards: allCards)

            dismiss()

        } catch {

            print(error.localizedDescription)

        }

    }

}

#Preview {

    AddEditCardView()
        .modelContainer(for: CreditCard.self, inMemory: true)

}