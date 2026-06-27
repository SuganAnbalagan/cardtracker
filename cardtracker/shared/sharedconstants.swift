//
//  SharedConstants.swift
//  cardtracker
//

import Foundation

enum SharedConstants {

    // MARK: App

    static let appName = "Card Tracker"

    static let appGroup = "group.com.sugan.cardtracker"

    // MARK: UserDefaults Keys

    enum Defaults {

        static let notificationsEnabled = "notificationsEnabled"

        static let faceIDEnabled = "faceIDEnabled"

        static let sortDescending = "sortDescending"

        static let useManualOrdering = "useManualOrdering"

        static let showBankName = "showBankName"

        static let showPaymentDate = "showPaymentDate"

    }

    // MARK: Widget

    enum Widget {

        static let kind = "CardTrackerWidget"

        static let refreshMinutes = 15

    }

    // MARK: Notifications

    enum NotificationIdentifier {

        static let statementPrefix = "statement-"

        static let paymentPrefix = "payment-"

    }

}