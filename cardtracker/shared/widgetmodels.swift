//
//  WidgetModels.swift
//  cardtracker
//

import Foundation

struct WidgetCard: Identifiable, Codable, Hashable {

    let id: UUID
    let name: String
    let bank: String
    let icon: String
    let colorHex: String

    let statementDay: Int
    let paymentDueDay: Int?

    let nextStatementDate: Date
    let daysRemaining: Int

    init(from card: CreditCard) {

        self.id = card.id
        self.name = card.name
        self.bank = card.bank
        self.icon = card.icon
        self.colorHex = card.colorHex

        self.statementDay = card.statementDay
        self.paymentDueDay = card.paymentDueDay

        self.nextStatementDate = card.nextStatementDate
        self.daysRemaining = card.daysRemaining
    }

}

struct WidgetSnapshot: Codable {

    let generatedAt: Date

    let cards: [WidgetCard]

    static let empty = WidgetSnapshot(
        generatedAt: .now,
        cards: []
    )

}