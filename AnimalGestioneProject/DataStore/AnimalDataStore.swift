import Foundation
import Combine
import SwiftUI
import CoreData

// This class serves as a compatibility layer for views that still use AnimalDataStore
// It delegates all operations to CoreDataStore
class AnimalDataStore: ObservableObject {
    private let coreDataStore: CoreDataStore
    
    @Published var animals: [Animal] = []
    @Published var physiologicalCycles: [PhysiologicalCycle] = []
    @Published var healthRecords: [HealthRecord] = []
    
    init() {
        self.coreDataStore = CoreDataStore()
        updateData()
        
        // Set up publishers to keep data in sync
        coreDataStore.$animals.assign(to: &$animals)
        coreDataStore.$physiologicalCycles.assign(to: &$physiologicalCycles)
        coreDataStore.$healthRecords.assign(to: &$healthRecords)
    }
    
    private func updateData() {
        self.animals = coreDataStore.animals
        self.physiologicalCycles = coreDataStore.physiologicalCycles
        self.healthRecords = coreDataStore.healthRecords
    }
    
    // MARK: - Animal CRUD
    
    func addAnimal(_ animal: Animal) {
        coreDataStore.addAnimal(animal)
    }
    
    func updateAnimal(_ animal: Animal) {
        coreDataStore.updateAnimal(animal)
    }
    
    func deleteAnimal(id: UUID) {
        coreDataStore.deleteAnimal(id: id)
    }
    
    // MARK: - Physiological Cycle CRUD
    
    func addCycle(_ cycle: PhysiologicalCycle) {
        coreDataStore.addCycle(cycle)
    }
    
    func updateCycle(_ cycle: PhysiologicalCycle) {
        coreDataStore.updateCycle(cycle)
    }
    
    func deleteCycle(id: UUID) {
        coreDataStore.deleteCycle(id: id)
    }
    
    func cyclesForAnimal(id: UUID) -> [PhysiologicalCycle] {
        return coreDataStore.cyclesForAnimal(id: id)
    }
    
    // MARK: - Health Record CRUD
    
    func addHealthRecord(_ record: HealthRecord) {
        coreDataStore.addHealthRecord(record)
    }
    
    func updateHealthRecord(_ record: HealthRecord) {
        coreDataStore.updateHealthRecord(record)
    }
    
    func deleteHealthRecord(id: UUID) {
        coreDataStore.deleteHealthRecord(id: id)
    }
    
    func healthRecordsForAnimal(id: UUID) -> [HealthRecord] {
        return coreDataStore.healthRecordsForAnimal(id: id)
    }
    
    // MARK: - Prediction
    
    func predictNextCycle(animalId: UUID) -> Date? {
        return coreDataStore.predictNextCycle(animalId: animalId)
    }
}