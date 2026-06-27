//
//  LocalAuthenticationManager.swift
//  cardtracker
//

import Foundation
import LocalAuthentication

@MainActor
final class LocalAuthenticationManager: ObservableObject {

    static let shared = LocalAuthenticationManager()

    @Published private(set) var isUnlocked = false

    private init() {}

    func lock() {
        isUnlocked = false
    }

    func unlockWithoutAuthentication() {
        isUnlocked = true
    }

    func authenticate() async -> Bool {

        let enabled = UserDefaults.standard.bool(forKey: "faceIDEnabled")

        guard enabled else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &error
        ) else {
            isUnlocked = true
            return true
        }

        do {

            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Card Tracker"
            )

            isUnlocked = success
            return success

        } catch {

            isUnlocked = false
            return false

        }
    }
}