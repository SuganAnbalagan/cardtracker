import Foundation
import SwiftData

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
