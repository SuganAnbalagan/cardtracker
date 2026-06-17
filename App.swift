import SwiftUI
import SwiftData
import WidgetKit

@main
struct CardTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CreditCard.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [CreditCard]
    @State private var showingAddSheet = false
    
    @State private var showingRestoreAlert = false
    @State private var inputBackupString = ""
    @State private var showingSuccessAlert = false
    @State private var alertMessage = ""
    
    var sortedCards: [CreditCard] {
        cards.sorted { $0.daysUntilStatement > $1.daysUntilStatement }
    }
    
    var topThreeCards: [CreditCard] {
        Array(sortedCards.prefix(3))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.4), Color.black], 
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            Button(action: copyBackupToClipboard) {
                                Label("Copy Backup", systemImage: "doc.on.doc.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(14)
                            }
                            
                            Button(action: { showingRestoreAlert = true }) {
                                Label("Paste Restore", systemImage: "doc.text.magnifyingglass")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        if !topThreeCards.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "square.text.square.fill")
                                        .foregroundColor(.cyan)
                                    Text("TOP 3 DURATION WIDGET")
                                        .font(.system(size: 12, weight: .black))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)
                                
                                VStack(spacing: 10) {
                                    ForEach(topThreeCards) { card in
                                        HStack {
                                            Text(card.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(card.daysUntilStatement) days left")
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(.cyan)
                                        }
                                        .padding(.vertical, 4)
                                        if card.id != topThreeCards.last?.id {
                                            Divider().background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.25))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: { showingAddSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add New Card")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        
                        if sortedCards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 54))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("No Cards Tracked")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(sortedCards) { card in
                                    GlassmorphicCardView(card: card)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Card Tracker")
            .sheet(isPresented: $showingAddSheet) { AddCardView() }
            .alert("Paste Restore Data", isPresented: $showingRestoreAlert) {
                TextField("Paste backup code here", text: $inputBackupString)
                Button("Cancel", role: .cancel) { inputBackupString = "" }
                Button("Restore Data") { processRestoreString() }
            } message: {
                Text("Paste your backup string code to replace your tracking configurations.")
            }
            .alert("Notice", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func copyBackupToClipboard() {
        if let data = try? JSONEncoder().encode(cards),
           let jsonString = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = jsonString
            alertMessage = "Cards backup code string copied to clipboard!"
            showingSuccessAlert = true
        }
    }
    
    private func processRestoreString() {
        guard !inputBackupString.isEmpty, let data = inputBackupString.data(using: .utf8) else { return }
        do {
            let importedCards = try JSONDecoder().decode([CreditCard].self, from: data)
            for card in cards { modelContext.delete(card) }
            for newCard in importedCards { modelContext.insert(newCard) }
            try modelContext.save()
            inputBackupString = ""
            alertMessage = "Database Restored Successfully!"
            showingSuccessAlert = true
        } catch {
            alertMessage = "Invalid verification code string profile."
            showingSuccessAlert = true
        }
    }
}

struct GlassmorphicCardView: View {
    let card: CreditCard
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Statement Date: \(card.statementDay)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(card.daysUntilStatement)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.cyan)
                Text("days left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.trailing, 8)
            
            Button(action: {
                modelContext.delete(card)
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding()
        .background(.white.opacity(0.07))
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var cardName = ""
    @State private var statementDay = 1
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.indigo.opacity(0.5), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("New Configuration")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Save") {
                        let newCard = CreditCard(name: cardName, statementDay: statementDay)
                        modelContext.insert(newCard)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.cyan)
                    .disabled(cardName.isEmpty)
                }
                .padding()
                .background(.white.opacity(0.05))
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Name")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        TextField("", text: $cardName, prompt: Text("e.g. Sapphire Preferred").foregroundColor(.white.opacity(0.3)))
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statement Date")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Picker("Closing Day", selection: $statementDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 140)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}
