import SwiftUI

struct CheckupRecord: Identifiable, Codable {
    var id: UUID
    var animalId: UUID
    var date: Date
    var checkupType: String
    var nextScheduledDate: Date?
    var interval: Int? // 日数単位での健康診断間隔
    var notes: String?
    var color: Color?
    
    var scheduledDate: Date {
        return nextScheduledDate ?? Date()
    }
    
    // ColorはCodableに準拠していないため、カスタムエンコーディングが必要
    enum CodingKeys: String, CodingKey {
        case id, animalId, date, checkupType, nextScheduledDate, interval, notes, colorHex
    }
    
    init(id: UUID, animalId: UUID, date: Date, checkupType: String, nextScheduledDate: Date? = nil, interval: Int? = nil, notes: String? = nil, color: Color? = nil) {
        self.id = id
        self.animalId = animalId
        self.date = date
        self.checkupType = checkupType
        self.nextScheduledDate = nextScheduledDate
        self.interval = interval
        self.notes = notes
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        animalId = try container.decode(UUID.self, forKey: .animalId)
        date = try container.decode(Date.self, forKey: .date)
        checkupType = try container.decode(String.self, forKey: .checkupType)
        nextScheduledDate = try container.decodeIfPresent(Date.self, forKey: .nextScheduledDate)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        if let colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) {
            color = Color(hex: colorHex)
        } else {
            color = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(animalId, forKey: .animalId)
        try container.encode(date, forKey: .date)
        try container.encode(checkupType, forKey: .checkupType)
        try container.encodeIfPresent(nextScheduledDate, forKey: .nextScheduledDate)
        try container.encodeIfPresent(interval, forKey: .interval)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        if let color = color {
            try container.encode(color.toHex(), forKey: .colorHex)
        }
    }
}