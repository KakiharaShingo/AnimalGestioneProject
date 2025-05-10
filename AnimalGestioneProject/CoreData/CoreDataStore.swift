import Foundation
import Combine
import CoreData
import SwiftUI

class CoreDataStore: ObservableObject {
    private let persistenceController = PersistenceController.shared
    @Published var animals: [Animal] = []
    @Published var physiologicalCycles: [PhysiologicalCycle] = []
    @Published var healthRecords: [HealthRecord] = []
    @Published var vaccineRecords: [VaccineRecord] = []
    @Published var groomingRecords: [GroomingRecord] = []
    @Published var checkupRecords: [CheckupRecord] = []
    @Published var medicationRecords: [MedicationRecord] = []
    @Published var otherRecords: [OtherRecord] = []
    
    // Migration flag
    private let migrationCompletedKey = "coreDataMigrationCompleted"
    
    init() {
        // UserDefaultsからの移行をチェック
        checkAndMigrateFromUserDefaults()
        
        // CoreDataからデータをロード
        loadData()
        
        // 新しい記録データをロード
        loadAllRecords()
    }
    
    // MARK: - Data Loading
    
    public func loadData() {
        loadAnimals()
        loadPhysiologicalCycles()
        loadHealthRecords()
        // デバッグ出力
        print("CoreDataStoreデータ再読み込み完了 - 動物数: \(animals.count)")
    }
    
    private func loadAnimals() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            animals = entities.map { Animal.fromEntity($0) }
        } catch {
            print("Failed to fetch animals: \(error)")
        }
    }
    
    private func loadPhysiologicalCycles() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<PhysiologicalCycleEntity> = PhysiologicalCycleEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            physiologicalCycles = entities.map { PhysiologicalCycle.fromEntity($0) }
        } catch {
            print("Failed to fetch physiological cycles: \(error)")
        }
    }
    
    private func loadHealthRecords() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<HealthRecordEntity> = HealthRecordEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            healthRecords = entities.map { HealthRecord.fromEntity($0) }
        } catch {
            print("Failed to fetch health records: \(error)")
        }
    }
    
    // MARK: - Migration
    
    private func checkAndMigrateFromUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        // 既に移行済みかチェック
        if userDefaults.bool(forKey: migrationCompletedKey) {
            return
        }
        
        // UserDefaultsからデータを取得
        var animals: [Animal] = []
        var cycles: [PhysiologicalCycle] = []
        var records: [HealthRecord] = []
        
        if let animalsData = userDefaults.data(forKey: "savedAnimals"),
           let decodedAnimals = try? JSONDecoder().decode([Animal].self, from: animalsData) {
            animals = decodedAnimals
        }
        
        if let cyclesData = userDefaults.data(forKey: "savedCycles"),
           let decodedCycles = try? JSONDecoder().decode([PhysiologicalCycle].self, from: cyclesData) {
            cycles = decodedCycles
        }
        
        if let recordsData = userDefaults.data(forKey: "savedRecords"),
           let decodedRecords = try? JSONDecoder().decode([HealthRecord].self, from: recordsData) {
            records = decodedRecords
        }
        
        // データがあれば移行
        if !animals.isEmpty || !cycles.isEmpty || !records.isEmpty {
            persistenceController.migrateFromUserDefaults(animals: animals, cycles: cycles, records: records)
            
            // 移行完了フラグを設定
            userDefaults.set(true, forKey: migrationCompletedKey)
        } else {
            // データがなければ、直接移行完了とする
            userDefaults.set(true, forKey: migrationCompletedKey)
        }
    }
    
    // MARK: - Animal CRUD
    
    func addAnimal(_ animal: Animal, imageData: Data? = nil) {
        let context = persistenceController.container.viewContext
        let entity = AnimalEntity(context: context)
        
        entity.id = animal.id
        entity.name = animal.name
        entity.species = animal.species
        entity.breed = animal.breed
        entity.birthDate = animal.birthDate
        entity.gender = animal.gender.rawValue
        entity.colorHex = generateRandomColor() // ランダムな色を割り当て
        
        // 画像データの保存
        if let imageData = imageData {
            entity.imageData = imageData
        } else if let url = animal.imageUrl, let data = try? Data(contentsOf: url) {
            entity.imageData = data
        }
        
        persistenceController.save()
        loadAnimals() // リストを更新
    }
    
    func updateAnimal(_ animal: Animal, imageData: Data? = nil) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", animal.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                entity.name = animal.name
                entity.species = animal.species
                entity.breed = animal.breed
                entity.birthDate = animal.birthDate
                entity.gender = animal.gender.rawValue
                
                // 画像データの更新
                if let imageData = imageData {
                    entity.imageData = imageData
                } else if let url = animal.imageUrl, let data = try? Data(contentsOf: url) {
                    entity.imageData = data
                }
                
                persistenceController.save()
                loadAnimals() // リストを更新
            }
        } catch {
            print("Failed to update animal: \(error)")
        }
    }
    
    func deleteAnimal(id: UUID) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadData() // すべてのデータを更新
            }
        } catch {
            print("Failed to delete animal: \(error)")
        }
    }
    
    func updateAnimalColor(id: UUID, color: Color) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                entity.colorHex = color.toHex()
                persistenceController.save()
            }
        } catch {
            print("Failed to update animal color: \(error)")
        }
    }
    
    // MARK: - Physiological Cycle CRUD
    
    func addCycle(_ cycle: PhysiologicalCycle) {
        let context = persistenceController.container.viewContext
        let entity = PhysiologicalCycleEntity(context: context)
        
        entity.id = cycle.id
        entity.startDate = cycle.startDate
        entity.endDate = cycle.endDate
        entity.intensity = Int16(cycle.intensity.rawValue)
        entity.notes = cycle.notes
        
        // 関連するAnimalEntityを取得
        let animalFetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        animalFetchRequest.predicate = NSPredicate(format: "id == %@", cycle.animalId as CVarArg)
        
        do {
            let results = try context.fetch(animalFetchRequest)
            if let animalEntity = results.first {
                entity.animal = animalEntity
                persistenceController.save()
                loadPhysiologicalCycles()
            }
        } catch {
            print("Failed to add cycle: \(error)")
        }
    }
    
    func updateCycle(_ cycle: PhysiologicalCycle) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<PhysiologicalCycleEntity> = PhysiologicalCycleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", cycle.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                entity.startDate = cycle.startDate
                entity.endDate = cycle.endDate
                entity.intensity = Int16(cycle.intensity.rawValue)
                entity.notes = cycle.notes
                
                persistenceController.save()
                loadPhysiologicalCycles()
            }
        } catch {
            print("Failed to update cycle: \(error)")
        }
    }
    
    func deleteCycle(id: UUID) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<PhysiologicalCycleEntity> = PhysiologicalCycleEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadPhysiologicalCycles()
            }
        } catch {
            print("Failed to delete cycle: \(error)")
        }
    }
    
    func cyclesForAnimal(id: UUID) -> [PhysiologicalCycle] {
        return physiologicalCycles.filter { $0.animalId == id }
            .sorted(by: { $0.startDate > $1.startDate })
    }
    
    // MARK: - Health Record CRUD
    
    func addHealthRecord(_ record: HealthRecord) {
        let context = persistenceController.container.viewContext
        let entity = HealthRecordEntity(context: context)
        
        entity.id = record.id
        entity.date = record.date
        entity.weight = record.weight ?? 0
        entity.temperature = record.temperature ?? 0
        entity.appetite = Int16(record.appetite.rawValue)
        entity.activityLevel = Int16(record.activityLevel.rawValue)
        entity.notes = record.notes
        
        // 関連するAnimalEntityを取得
        let animalFetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
        animalFetchRequest.predicate = NSPredicate(format: "id == %@", record.animalId as CVarArg)
        
        do {
            let results = try context.fetch(animalFetchRequest)
            if let animalEntity = results.first {
                entity.animal = animalEntity
                persistenceController.save()
                loadHealthRecords()
            }
        } catch {
            print("Failed to add health record: \(error)")
        }
    }
    
    func updateHealthRecord(_ record: HealthRecord) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<HealthRecordEntity> = HealthRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                entity.date = record.date
                entity.weight = record.weight ?? 0
                entity.temperature = record.temperature ?? 0
                entity.appetite = Int16(record.appetite.rawValue)
                entity.activityLevel = Int16(record.activityLevel.rawValue)
                entity.notes = record.notes
                
                persistenceController.save()
                loadHealthRecords()
            }
        } catch {
            print("Failed to update health record: \(error)")
        }
    }
    
    func deleteHealthRecord(id: UUID) {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<HealthRecordEntity> = HealthRecordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                context.delete(entity)
                persistenceController.save()
                loadHealthRecords()
            }
        } catch {
            print("Failed to delete health record: \(error)")
        }
    }
    
    func healthRecordsForAnimal(id: UUID) -> [HealthRecord] {
        return healthRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Prediction
    
    func predictNextCycle(animalId: UUID) -> Date? {
        let animalCycles = cyclesForAnimal(id: animalId)
        
        // 最低2つの周期データが必要
        guard animalCycles.count >= 2 else { return nil }
        
        // 最新の2つの周期データを取得
        let sortedCycles = animalCycles.sorted(by: { $0.startDate > $1.startDate })
        let latestCycles = Array(sortedCycles.prefix(2))
        
        // 周期の間隔を計算
        guard let latestStartDate = latestCycles.first?.startDate,
              let previousStartDate = latestCycles.last?.startDate else {
            return nil
        }
        
        let interval = latestStartDate.timeIntervalSince(previousStartDate)
        
        // 次の周期予測日
        return Date(timeIntervalSinceNow: interval)
    }
    
    // カレンダーの特定日に生理周期を持つ動物を取得
    func animalsWithCycleOn(date: Date) -> [(animal: Animal, cycle: PhysiologicalCycle?)] {
        var result: [(animal: Animal, cycle: PhysiologicalCycle?)] = []
        let calendar = Calendar.current
        
        for animal in animals {
            // 実際の生理周期をチェック
            let animalCycles = cyclesForAnimal(id: animal.id)
            var hasCycle = false
            var matchedCycle: PhysiologicalCycle? = nil
            
            for cycle in animalCycles {
                // 開始日のみか、開始日から終了日の範囲内かチェック
                if calendar.isDate(cycle.startDate, inSameDayAs: date) {
                    hasCycle = true
                    matchedCycle = cycle
                    break
                } else if let endDate = cycle.endDate,
                          date >= cycle.startDate && date <= endDate {
                    hasCycle = true
                    matchedCycle = cycle
                    break
                }
            }
            
            if hasCycle {
                result.append((animal: animal, cycle: matchedCycle))
                continue
            }
            
            // 生理周期がない場合は予測をチェック
            if let predicted = predictNextCycle(animalId: animal.id),
               calendar.isDate(predicted, inSameDayAs: date) {
                result.append((animal: animal, cycle: nil))
            }
        }
        
        return result
    }
    
    // 指定された日に生理周期または予測がある動物があるかチェック
    func hasAnyCycleOnDate(_ date: Date) -> Bool {
        return !animalsWithCycleOn(date: date).isEmpty
    }
    
    // 指定された日に指定された動物の生理周期があるかチェック
    func hasCycleOnDate(_ date: Date, forAnimal animalId: UUID) -> Bool {
        let calendar = Calendar.current
        let animalCycles = cyclesForAnimal(id: animalId)
        
        // 実際の生理周期をチェック
        for cycle in animalCycles {
            if calendar.isDate(cycle.startDate, inSameDayAs: date) {
                return true
            } else if let endDate = cycle.endDate,
                      date >= cycle.startDate && date <= endDate {
                return true
            }
        }
        
        // 生理周期がない場合は予測をチェック
        if let predicted = predictNextCycle(animalId: animalId),
           calendar.isDate(predicted, inSameDayAs: date) {
            return true
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    private func generateRandomColor() -> String {
        // 明るめのパステル調の色を生成
        let predefinedColors = [
            "#FF9500", // オレンジ
            "#FF2D55", // ピンク
            "#5AC8FA", // 青
            "#4CD964", // 緑
            "#FFCC00", // 黄色
            "#AF52DE", // 紫
            "#FF6B6B", // 赤っぽいピンク
            "#48CFAD", // ミント
            "#AC92EB", // ラベンダー
            "#EC87C0"  // ローズ
        ]
        
        return predefinedColors[Int.random(in: 0..<predefinedColors.count)]
    }
}