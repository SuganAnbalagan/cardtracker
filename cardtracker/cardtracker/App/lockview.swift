//
//  LockView.swift
//  cardtracker
//

import SwiftUI

struct LockView: View {

    @StateObject
    private var auth = LocalAuthenticationManager.shared

    @State
    private var authenticating = false

    var body: some View {

        Group {

            if auth.isUnlocked {

                RootView()

            } else {

                VStack(spacing: 32) {

                    Spacer()

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)

                    Text("Card Tracker")
                        .font(.largeTitle.bold())

                    Text("Authentication is required to access your credit card statements.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Button {

                        Task {
                            await unlock()
                        }

                    } label: {

                        Label(
                            "Unlock",
                            systemImage: "faceid"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()

                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)

                    Spacer()

                }
                .task {

                    if !authenticating {
                        await unlock()
                    }

                }

            }

        }

    }

}

private extension LockView {

    func unlock() async {

        guard !authenticating else {
            return
        }

        authenticating = true
        _ = await auth.authenticate()
        authenticating = false

    }

}

#Preview {

    LockView()
        .modelContainer(for: CreditCard.self, inMemory: true)

}