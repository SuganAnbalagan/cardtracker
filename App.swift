import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Data Model with iCloud Support
@Model
final class CreditCard: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var statementDay: Int = 1
    
    init(name: String, statementDay: Int) {
        self.name = name
        self.statementDay = statementDay
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

// MARK: - Main Application Entry Point
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
    
    var sortedCards: [CreditCard] {
        cards.sorted { $0.daysUntilStatement > $1.daysUntilStatement }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass Style Mesh Background
                LinearGradient(colors: [Color.indigo.opacity(0.6), Color.purple.opacity(0.4), Color.black], 
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if sortedCards.isEmpty {
                            Text("No Cards Added Yet")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 100)
                        } else {
                            ForEach(sortedCards) { card in
                                GlassmorphicCardView(card: card)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Card Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCardView()
            }
        }
    }
}

// MARK: - Glassmorphic Fluid Design View
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
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(card.daysUntilStatement)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.cyan)
                Text("days remaining")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Delete Button inside row
            Button(action: {
                modelContext.delete(card)
                WidgetCenter.shared.reloadAllTimelines()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.leading, 8)
            }
        }
        .padding()
        // Clean native iOS 17 Ultra Thin Glassmorphism
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
    }
}

// MARK: - Modular Add Card Form
struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var cardName = ""
    @State private var statementDay = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Configuration")) {
                    TextField("Card Provider Name", text: $cardName)
                    Picker("Closing Day", selection: $statementDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }
            }
            .navigationTitle("New Card Configuration")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newCard = CreditCard(name: cardName, statementDay: statementDay)
                        modelContext.insert(newCard)
                        WidgetCenter.shared.reloadAllTimelines()
                        dismiss()
                    }
                    .disabled(cardName.isEmpty)
                }
            }
        }
    }
}
