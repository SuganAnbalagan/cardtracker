//
//  CreditCard.swift
//  CreditStatementTracker
//

import Foundation
import SwiftData

@Model
final class CreditCard {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var bank: String

    /// Day of month (1...31)
    var statementDay: Int

    /// Optional payment due day (1...31)
    var paymentDueDay: Int?

    /// Hex color string (#RRGGBB)
    var colorHex: String

    /// Emoji shown in the UI
    var icon: String

    /// Manual ordering if the user disables automatic sorting
    var manualOrder: Int

    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        bank: String,
        statementDay: Int,
        paymentDueDay: Int? = nil,
        colorHex: String = "#007AFF",
        icon: String = "💳",
        manualOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.bank = bank
        self.statementDay = statementDay
        self.paymentDueDay = paymentDueDay
        self.colorHex = colorHex
        self.icon = icon
        self.manualOrder = manualOrder
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties

extension CreditCard {

    var nextStatementDate: Date {
        Self.nextOccurrence(ofDay: statementDay)
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: nextStatementDate)
        ).day ?? 0
    }

    var nextPaymentDueDate: Date? {
        guard let paymentDueDay else { return nil }
        return Self.nextOccurrence(ofDay: paymentDueDay)
    }

    var paymentDaysRemaining: Int? {
        guard let nextPaymentDueDate else {
            return nil
        }

        return Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: .now),
            to: Calendar.current.startOfDay(for: nextPaymentDueDate)
        ).day
    }

    var statementDateString: String {
        Self.dateFormatter.string(from: nextStatementDate)
    }

    var paymentDateString: String? {
        guard let nextPaymentDueDate else {
            return nil
        }

        return Self.dateFormatter.string(from: nextPaymentDueDate)
    }

    var isStatementToday: Bool {
        Calendar.current.isDateInToday(nextStatementDate)
    }

    var isStatementTomorrow: Bool {
        Calendar.current.isDateInTomorrow(nextStatementDate)
    }
}

// MARK: - Helpers

private extension CreditCard {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    static func nextOccurrence(ofDay day: Int) -> Date {

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        var components = calendar.dateComponents([.year, .month], from: today)

        let maxDayThisMonth = calendar.range(
            of: .day,
            in: .month,
            for: today
        )!.count

        components.day = min(day, maxDayThisMonth)

        var candidate = calendar.date(from: components)!

        if candidate < today {

            candidate = calendar.date(
                byAdding: .month,
                value: 1,
                to: candidate
            )!

            var nextComponents = calendar.dateComponents(
                [.year, .month],
                from: candidate
            )

            let maxDayNextMonth = calendar.range(
                of: .day,
                in: .month,
                for: candidate
            )!.count

            nextComponents.day = min(day, maxDayNextMonth)

            candidate = calendar.date(from: nextComponents)!
        }

        return candidate
    }
}