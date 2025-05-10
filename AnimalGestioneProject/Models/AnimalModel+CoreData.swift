import Foundation
import CoreData
import SwiftUI

// CoreDataとの連携のための拡張
extension Animal {
    // AnimalEntityからAnimalへの変換
    static func fromEntity(_ entity: AnimalEntity) -> Animal {
        var animal = Animal(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            species: entity.species ?? "",
            gender: Animal.Gender(rawValue: entity.gender ?? "不明") ?? .unknown
        )
        
        animal.breed = entity.breed
        animal.birthDate = entity.birthDate
        
        // 画像データからURLを作成
        if let imageData = entity.imageData {
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let imageURL = documentDirectory.appendingPathComponent("\(entity.id?.uuidString ?? UUID().uuidString).jpg")
            
            if !fileManager.fileExists(atPath: imageURL.path) {
                try? imageData.write(to: imageURL)
            }
            
            animal.imageUrl = imageURL
        }
        
        return animal
    }
    
    // 色設定用の拡張
    var color: Color {
        get {
            // 保存されている動物の色を取得
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let entity = results.first, let hexColor = entity.colorHex {
                    return Color(hex: hexColor)
                }
            } catch {
                print("Failed to fetch animal color: \(error)")
            }
            
            return Color.gray
        }
        set {
            // 新しい色を保存
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", self.id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let entity = results.first {
                    entity.colorHex = newValue.toHex()
                    try context.save()
                }
            } catch {
                print("Failed to update animal color: \(error)")
            }
        }
    }
}

extension PhysiologicalCycle {
    // PhysiologicalCycleEntityからPhysiologicalCycleへの変換
    static func fromEntity(_ entity: PhysiologicalCycleEntity) -> PhysiologicalCycle {
        let cycle = PhysiologicalCycle(
            id: entity.id ?? UUID(),
            animalId: entity.animal?.id ?? UUID(),
            startDate: entity.startDate ?? Date(),
            endDate: entity.endDate,
            intensity: Intensity(rawValue: Int(entity.intensity)) ?? .medium,
            notes: entity.notes
        )
        
        return cycle
    }
}

extension HealthRecord {
    // HealthRecordEntityからHealthRecordへの変換
    static func fromEntity(_ entity: HealthRecordEntity) -> HealthRecord {
        var record = HealthRecord(
            id: entity.id ?? UUID(),
            animalId: entity.animal?.id ?? UUID(),
            date: entity.date ?? Date(),
            appetite: Appetite(rawValue: Int(entity.appetite)) ?? .normal,
            activityLevel: ActivityLevel(rawValue: Int(entity.activityLevel)) ?? .normal
        )
        
        if entity.weight > 0 {
            record.weight = entity.weight
        }
        
        if entity.temperature > 0 {
            record.temperature = entity.temperature
        }
        
        record.notes = entity.notes
        
        return record
    }
}