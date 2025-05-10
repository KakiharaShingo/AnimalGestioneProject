import Foundation
import Combine

class AnimalDataStore: ObservableObject {
    @Published var animals: [Animal] = []
    @Published var physiologicalCycles: [PhysiologicalCycle] = []
    @Published var healthRecords: [HealthRecord] = []
    
    private let animalsKey = "savedAnimals"
    private let cyclesKey = "savedCycles"
    private let recordsKey = "savedRecords"
    
    init() {
        loadData()
    }
    
    // MARK: - Animal CRUD
    
    func addAnimal(_ animal: Animal) {
        animals.append(animal)
        saveAnimals()
    }
    
    func updateAnimal(_ animal: Animal) {
        if let index = animals.firstIndex(where: { $0.id == animal.id }) {
            animals[index] = animal
            saveAnimals()
        }
    }
    
    func deleteAnimal(id: UUID) {
        animals.removeAll(where: { $0.id == id })
        // 関連するサイクルと健康記録も削除
        physiologicalCycles.removeAll(where: { $0.animalId == id })
        healthRecords.removeAll(where: { $0.animalId == id })
        saveAnimals()
        saveCycles()
        saveRecords()
    }
    
    // MARK: - Physiological Cycle CRUD
    
    func addCycle(_ cycle: PhysiologicalCycle) {
        physiologicalCycles.append(cycle)
        saveCycles()
    }
    
    func updateCycle(_ cycle: PhysiologicalCycle) {
        if let index = physiologicalCycles.firstIndex(where: { $0.id == cycle.id }) {
            physiologicalCycles[index] = cycle
            saveCycles()
        }
    }
    
    func deleteCycle(id: UUID) {
        physiologicalCycles.removeAll(where: { $0.id == id })
        saveCycles()
    }
    
    func cyclesForAnimal(id: UUID) -> [PhysiologicalCycle] {
        return physiologicalCycles.filter { $0.animalId == id }
            .sorted(by: { $0.startDate > $1.startDate })
    }
    
    // MARK: - Health Record CRUD
    
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.append(record)
        saveRecords()
    }
    
    func updateHealthRecord(_ record: HealthRecord) {
        if let index = healthRecords.firstIndex(where: { $0.id == record.id }) {
            healthRecords[index] = record
            saveRecords()
        }
    }
    
    func deleteHealthRecord(id: UUID) {
        healthRecords.removeAll(where: { $0.id == id })
        saveRecords()
    }
    
    func healthRecordsForAnimal(id: UUID) -> [HealthRecord] {
        return healthRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Persistence
    
    private func saveAnimals() {
        if let encoded = try? JSONEncoder().encode(animals) {
            UserDefaults.standard.set(encoded, forKey: animalsKey)
        }
    }
    
    private func saveCycles() {
        if let encoded = try? JSONEncoder().encode(physiologicalCycles) {
            UserDefaults.standard.set(encoded, forKey: cyclesKey)
        }
    }
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(healthRecords) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    private func loadData() {
        if let animalsData = UserDefaults.standard.data(forKey: animalsKey),
           let decodedAnimals = try? JSONDecoder().decode([Animal].self, from: animalsData) {
            animals = decodedAnimals
        }
        
        if let cyclesData = UserDefaults.standard.data(forKey: cyclesKey),
           let decodedCycles = try? JSONDecoder().decode([PhysiologicalCycle].self, from: cyclesData) {
            physiologicalCycles = decodedCycles
        }
        
        if let recordsData = UserDefaults.standard.data(forKey: recordsKey),
           let decodedRecords = try? JSONDecoder().decode([HealthRecord].self, from: recordsData) {
            healthRecords = decodedRecords
        }
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
}