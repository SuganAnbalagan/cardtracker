//
//  CardDetailView.swift
//  CreditStatementTracker
//

import SwiftUI
import SwiftData

struct CardDetailView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var modelContext

    @State
    private var showingEditSheet = false

    @State
    private var showingDeleteConfirmation = false

    @Bindable
    var card: CreditCard

    var body: some View {

        List {

            headerSection

            statementSection

            paymentSection

            informationSection

        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }

            }

        }
        .sheet(isPresented: $showingEditSheet) {
            AddEditCardView(card: card)
        }
        .confirmationDialog(
            "Delete this credit card?",
            isPresented: $showingDeleteConfirmation
        ) {

            Button("Delete", role: .destructive) {
                deleteCard()
            }

            Button("Cancel", role: .cancel) { }

        }

    }

}

// MARK: Header

private extension CardDetailView {

    var headerSection: some View {

        Section {

            VStack(spacing: 18) {

                Text(card.icon)
                    .font(.system(size: 60))

                Text(card.name)
                    .font(.title2.bold())

                Text(card.bank)
                    .foregroundStyle(.secondary)

                Text("\(card.daysRemaining)")
                    .font(.system(size: 56, weight: .bold))

                Text(card.daysRemaining == 1
                     ? "day remaining"
                     : "days remaining")
                    .foregroundStyle(.secondary)

            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)

        }

    }

}

// MARK: Statement

private extension CardDetailView {

    var statementSection: some View {

        Section("Statement") {

            LabeledContent(
                "Statement Day",
                value: "\(card.statementDay)"
            )

            LabeledContent(
                "Next Statement",
                value: card.statementDateString
            )

            if card.isStatementToday {

                Label(
                    "Statement is today",
                    systemImage: "calendar.badge.clock"
                )
                .foregroundStyle(.red)

            } else if card.isStatementTomorrow {

                Label(
                    "Statement is tomorrow",
                    systemImage: "calendar"
                )
                .foregroundStyle(.orange)

            }

        }

    }

}

// MARK: Payment

private extension CardDetailView {

    var paymentSection: some View {

        Section("Payment Due") {

            if let dueDay = card.paymentDueDay {

                LabeledContent(
                    "Due Day",
                    value: "\(dueDay)"
                )

                if let next = card.paymentDateString {

                    LabeledContent(
                        "Next Due Date",
                        value: next
                    )

                }

                if let remaining = card.paymentDaysRemaining {

                    LabeledContent(
                        "Days Remaining",
                        value: "\(remaining)"
                    )

                }

            } else {

                Text("No payment due date configured.")
                    .foregroundStyle(.secondary)

            }

        }

    }

}

// MARK: Information

private extension CardDetailView {

    var informationSection: some View {

        Section("Information") {

            LabeledContent(
                "Created",
                value: card.createdAt.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )

            LabeledContent(
                "Identifier",
                value: card.id.uuidString
            )

        }

    }

}

// MARK: Helpers

private extension CardDetailView {

    func deleteCard() {

        modelContext.delete(card)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print(error.localizedDescription)
        }

    }

}

#Preview {

    let container = try! ModelContainer(
        for: CreditCard.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let card = CreditCard(
        name: "Visa Infinite",
        bank: "Example Bank",
        statementDay: 25,
        paymentDueDay: 10,
        colorHex: "#007AFF",
        icon: "💳"
    )

    container.mainContext.insert(card)

    return NavigationStack {
        CardDetailView(card: card)
    }
    .modelContainer(container)

}