import SwiftUI

struct WeightRecord: Identifiable, Codable {
    var id: UUID
    var animalId: UUID
    var date: Date
    var weight: Double
    var notes: String?
}
