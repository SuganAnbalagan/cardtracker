import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers

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
    
    // Codable requirements for Backup/Restore operations
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
    
    // Backup / Restore Document states
    @State private var exportDocument: CardBackupDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    
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
                    VStack(spacing: 16) {
                        // Backup / Restore Section Controls
                        HStack(spacing: 20) {
                            Button(action: triggerBackup) {
                                Label("Backup", systemImage: "square.and.arrow.up.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { isImporting = true }) {
                                Label("Restore", systemImage: "square.and.arrow.down.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 8)
                        
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
            .sheet(isPresented: $showingAddSheet) { AddCardView() }
            // System native interaction controllers for handling local device files
            .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "CardTrackerBackup") { result in
                if case .failure(let error) = result { print("Export Error: \(error.localizedDescription)") }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    importBackup(from: url)
                case .failure(let error):
                    print("Import Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func triggerBackup() {
        if let data = try? JSONEncoder().encode(cards) {
            exportDocument = CardBackupDocument(data: data)
            isExporting = true
        }
    }
    
    private func importBackup(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        if let data = try? Data(contentsOf: url),
           let importedCards = try? JSONDecoder().decode([CreditCard].self, from: data) {
            // Flush out existing dataset configuration instances inside local database context
            for card in cards { modelContext.delete(card) }
            // Inject freshly processed data payload items
            for newCard in importedCards { modelContext.insert(newCard) }
            
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

// MARK: - Backup Document Native Wrapper File
struct CardBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { self.data = Data() }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
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
