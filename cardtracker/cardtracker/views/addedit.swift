//
//  AddEditCardView.swift
//  CreditStatementTracker
//

import SwiftUI
import SwiftData

struct AddEditCardView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

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
        "💳",
        "🏦",
        "💰",
        "💵",
        "💎",
        "🪙",
        "⭐️",
        "🚀",
        "🦁",
        "🔥",
        "🛍️",
        "✈️"
    ]

    init(card: CreditCard? = nil) {
        self.editingCard = card
    }

    var body: some View {

        NavigationStack {

            Form {

                cardSection

                statementSection

                paymentSection

                appearanceSection

            }
            .navigationTitle(editingCard == nil ? "New Card" : "Edit Card")
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
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                }

            }
            .onAppear {
                loadCard()
            }

        }

    }

}

// MARK: Sections

private extension AddEditCardView {

    var cardSection: some View {

        Section("Card") {

            TextField("Card Name", text: $name)

            TextField("Bank", text: $bank)

        }

    }

    var statementSection: some View {

        Section("Statement") {

            Picker("Statement Day", selection: $statementDay) {

                ForEach(1...31, id: \.self) { day in
                    Text("\(day)")
                        .tag(day)
                }

            }

        }

    }

    var paymentSection: some View {

        Section("Payment Due") {

            Toggle(
                "Has Payment Due Date",
                isOn: $hasPaymentDueDate
            )

            if hasPaymentDueDate {

                Picker("Payment Day", selection: $paymentDueDay) {

                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)")
                            .tag(day)
                    }

                }

            }

        }

    }

    var appearanceSection: some View {

        Section("Appearance") {

            VStack(alignment: .leading) {

                Text("Icon")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 6)
                ) {

                    ForEach(emojis, id: \.self) { emoji in

                        Button {

                            selectedEmoji = emoji

                        } label: {

                            Text(emoji)
                                .font(.title2)
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedEmoji == emoji
                                    ? Color.accentColor.opacity(0.25)
                                    : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                        }
                        .buttonStyle(.plain)

                    }

                }

            }

            VStack(alignment: .leading) {

                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 4)
                ) {

                    ForEach(colors, id: \.self) { hex in

                        Button {

                            selectedColor = hex

                        } label: {

                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay {

                                    if selectedColor == hex {

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

}

// MARK: Save

private extension AddEditCardView {

    func save() {

        if let editingCard {

            editingCard.name = name
            editingCard.bank = bank
            editingCard.statementDay = statementDay
            editingCard.paymentDueDay = hasPaymentDueDate ? paymentDueDay : nil
            editingCard.colorHex = selectedColor
            editingCard.icon = selectedEmoji

        } else {

            let card = CreditCard(
                name: name,
                bank: bank,
                statementDay: statementDay,
                paymentDueDay: hasPaymentDueDate ? paymentDueDay : nil,
                colorHex: selectedColor,
                icon: selectedEmoji
            )

            modelContext.insert(card)

        }

        try? modelContext.save()

        dismiss()

    }

    func loadCard() {

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

}

// MARK: Preview

#Preview {

    AddEditCardView()
        .modelContainer(for: CreditCard.self, inMemory: true)

}