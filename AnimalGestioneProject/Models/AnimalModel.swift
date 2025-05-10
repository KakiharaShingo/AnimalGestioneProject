import Foundation

struct Animal: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var species: String
    var breed: String?
    var birthDate: Date?
    var gender: Gender
    var imageUrl: URL?
    
    enum Gender: String, Codable, CaseIterable {
        case male = "オス"
        case female = "メス"
        case unknown = "不明"
    }
}

struct PhysiologicalCycle: Identifiable, Codable {
    var id = UUID()
    var animalId: UUID
    var startDate: Date
    var endDate: Date?
    var intensity: Intensity
    var notes: String?
    
    enum Intensity: Int, Codable, CaseIterable {
        case light = 1
        case medium = 2
        case heavy = 3
        
        var description: String {
            switch self {
            case .light: return "軽度"
            case .medium: return "中度"
            case .heavy: return "重度"
            }
        }
    }
}

struct HealthRecord: Identifiable, Codable {
    var id = UUID()
    var animalId: UUID
    var date: Date
    var weight: Double?
    var temperature: Double?
    var appetite: Appetite
    var activityLevel: ActivityLevel
    var notes: String?
    
    enum Appetite: Int, Codable, CaseIterable {
        case poor = 1
        case normal = 2
        case good = 3
        
        var description: String {
            switch self {
            case .poor: return "食欲不振"
            case .normal: return "普通"
            case .good: return "食欲旺盛"
            }
        }
    }
    
    enum ActivityLevel: Int, Codable, CaseIterable {
        case low = 1
        case normal = 2
        case high = 3
        
        var description: String {
            switch self {
            case .low: return "低活動"
            case .normal: return "普通"
            case .high: return "活発"
            }
        }
    }
}