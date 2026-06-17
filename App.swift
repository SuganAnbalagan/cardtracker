import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Data Model
@Model
final class CreditCard: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    var statementDay: Int = 1
    
    init(name: String, statementDay: Int) {
        self.name = name
        self.statementDay = statementDay
    }
    
    enum CodingKeys: CodingKey { case id, name, statementDay }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.statementDay = try container.decode(Int.self, forKey: .statementDay)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(statementDay, forKey: .statementDay)
    }
    
    var daysUntilStatement: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: now)
        var targetComponents = currentComponents
        targetComponents.day = statementDay
        if let currentDay = currentComponents.day, currentDay > statementDay {
            targetComponents.month = (targetComponents.month ?? 1) + 1
        }
        guard let targetDate = calendar.date(from: targetComponents) else { return 0 }
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfTarget).day ?? 0
    }
}

// MARK: - Main Application
@main
struct CardTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CreditCard.self)
    }
}

// MARK: - Fluid UI View Dashboard
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [CreditCard]
    @State private var showingAddSheet = false
    
    // Text migration modal states
    @State private var showingRestoreAlert = false
    @State private var inputBackupString = ""
    @State private var showingSuccessAlert = false
    @State private var alertMessage = ""
    
    var sortedCards: [CreditCard] {
        cards.sorted { $0.daysUntilStatement > $1.daysUntilStatement }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.4), Color.black], 
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Perfectly Aligned Backup and Restore Buttons
                        HStack(spacing: 16) {
                            Button(action: copyBackupToClipboard) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                    Text("Copy Backup")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(14)
                            }
                            
                            Button(action: { showingRestoreAlert = true }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                    Text("Paste Restore")
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // 2. Modern Styled Add New Card Button Placement
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
                        
                        // 3. Dynamic Card Stack Display
                        if sortedCards.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 54))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("No Cards Tracked")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 80)
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
            // Custom text processing dialogue modals
            .alert("Paste Restore Data", isPresented: $showingRestoreAlert) {
                TextField("Paste backup code here", text: $inputBackupString)
                Button("Cancel", role: .cancel) { inputBackupString = "" }
                Button("Restore Data") { processRestoreString() }
            } message: {
                Text("Paste the string code you copied earlier to restore your card list configuration.")
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
            alertMessage = "Your cards database backup string has been copied safely to your Clipboard! Save it anywhere in Notes or an Email."
            showingSuccessAlert = true
        }
    }
    
    private func processRestoreString() {
        guard !inputBackupString.isEmpty,
              let data = inputBackupString.data(using: .utf8) else { return }
        do {
            let importedCards = try JSONDecoder().decode([CreditCard].self, from: data)
            for card in cards { modelContext.delete(card) }
            for newCard in importedCards { modelContext.insert(newCard) }
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            inputBackupString = ""
            alertMessage = "Database Restored Successfully!"
            showingSuccessAlert = true
        } catch {
            alertMessage = "Invalid backup code string. Please verify and try again."
            showingSuccessAlert = true
        }
    }
}

// MARK: - Premium Glassmorphic Card View Row
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
                Text("Statement Day: \(card.statementDay)")
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
                WidgetCenter.shared.reloadAllTimelines()
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

// MARK: - Premium iOS 26 Glassmorphic Add Form
struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var cardName = ""
    @State private var statementDay = 1
    
    var body: some View {
        ZStack {
            // Replaces the standard white form with the liquid mesh theme
            LinearGradient(colors: [Color.indigo.opacity(0.5), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Frosted Title Area Bar
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
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.cyan)
                    .disabled(cardName.isEmpty)
                }
                .padding()
                .background(.white.opacity(0.05))
                
                VStack(spacing: 20) {
                    // Glass input field wrapper
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Card Designation Name")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        TextField("", text: $cardName, prompt: Text("e.g. Sapphire Preferred").foregroundColor(.white.opacity(0.3)))
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statement Cycle End Day")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Picker("Closing Day", selection: $statementDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("Every Day \(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
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
