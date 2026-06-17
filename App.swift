import SwiftUI

struct CreditCard: Identifiable, Codable {
    var id = UUID()
    let name: String
    let statementDay: Int
    
    // Calculates how many days are left from today until the NEXT statement date
    var daysUntilStatement: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: now)
        
        var targetComponents = currentComponents
        targetComponents.day = statementDay
        
        // If the statement day has already passed this month, target next month
        if let currentDay = currentComponents.day, currentDay > statementDay {
            targetComponents.month = (targetComponents.month ?? 1) + 1
        }
        
        guard let targetDate = calendar.date(from: targetComponents) else { return 0 }
        
        // Return difference in days
        let startOfToday = calendar.startOfDay(for: now)
        let startOfTarget = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        
        return components.day ?? 0
    }
}

class CardViewModel: ObservableObject {
    @Published var cards: [CreditCard] = [] {
        didSet {
            saveCards()
        }
    }
    
    init() {
        loadCards()
    }
    
    // Sorted with the LONGEST duration (highest days remaining) first
    var sortedCards: [CreditCard] = [] {
        cards.sorted { $0.daysUntilStatement > $1.daysUntilStatement }
    }
    
    func addCard(name: String, day: Int) {
        let newCard = CreditCard(name: name, statementDay: day)
        cards.append(newCard)
    }
    
    func deleteCard(at offsets: IndexSet) {
        // Map the sorted index back to the source array to delete correctly
        let sorted = sortedCards
        for index in offsets {
            let cardToDelete = sorted[index]
            cards.removeAll { $0.id == cardToDelete.id }
        }
    }
    
    private func saveCards() {
        if let encoded = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(encoded, forKey: "SavedCards")
        }
    }
    
    private func loadCards() {
        if let data = UserDefaults.standard.data(forKey: "SavedCards"),
           let decoded = try? JSONDecoder().decode([CreditCard].self, from: data) {
            self.cards = decoded
        }
    }
}

@main
struct CardTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = CardViewModel()
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sortedCards) { card in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(card.name)
                                .font(.headline)
                            Text("Statement Day: \(card.statementDay)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(card.daysUntilStatement) days")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.deleteCard)
            }
            .navigationTitle("Card Statement Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddCardView(viewModel: viewModel)
            }
        }
    }
}

struct AddCardView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CardViewModel
    
    @State private var cardName = ""
    @State private var statementDay = 1
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Details")) {
                    TextField("Card Name", text: $cardName)
                    
                    Picker("Statement Day", selection: $statementDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }
            }
            .navigationTitle("Add New Card")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !cardName.isEmpty {
                            viewModel.addCard(name: cardName, day: statementDay)
                            dismiss()
                        }
                    }
                    .disabled(cardName.isEmpty)
                }
            }
        }
    }
}
