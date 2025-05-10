import Foundation
import SwiftUI
import CoreData

// CoreDataStore拡張: 体重記録、ワクチン記録、トリミング記録の機能
extension CoreDataStore {
    // MARK: - Data Loading
    
    func loadAllRecords() {
        loadVaccineRecords()
        loadGroomingRecords()
        loadCheckupRecords()
        loadMedicationRecords()
        loadOtherRecords()
    }
    
    private func loadVaccineRecords() {
        // 仮実装: UserDefaultsから読み込む
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "savedVaccineRecords"),
           let decoded = try? JSONDecoder().decode([VaccineRecord].self, from: data) {
            vaccineRecords = decoded
        }
    }
    
    private func loadGroomingRecords() {
        // 仮実装: UserDefaultsから読み込む
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "savedGroomingRecords"),
           let decoded = try? JSONDecoder().decode([GroomingRecord].self, from: data) {
            groomingRecords = decoded
        }
    }
    
    private func loadCheckupRecords() {
        // 仮実装: UserDefaultsから読み込む
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "savedCheckupRecords"),
           let decoded = try? JSONDecoder().decode([CheckupRecord].self, from: data) {
            checkupRecords = decoded
        }
    }
    
    private func loadMedicationRecords() {
        // 仮実装: UserDefaultsから読み込む
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "savedMedicationRecords"),
           let decoded = try? JSONDecoder().decode([MedicationRecord].self, from: data) {
            medicationRecords = decoded
        }
    }
    
    private func loadOtherRecords() {
        // 仮実装: UserDefaultsから読み込む
        let userDefaults = UserDefaults.standard
        if let data = userDefaults.data(forKey: "savedOtherRecords"),
           let decoded = try? JSONDecoder().decode([OtherRecord].self, from: data) {
            otherRecords = decoded
        }
    }
    
    private func saveVaccineRecordsToUserDefaults() {
        // 仮実装: UserDefaultsに保存
        let userDefaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(vaccineRecords) {
            userDefaults.set(encoded, forKey: "savedVaccineRecords")
        }
    }
    
    private func saveGroomingRecordsToUserDefaults() {
        // 仮実装: UserDefaultsに保存
        let userDefaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(groomingRecords) {
            userDefaults.set(encoded, forKey: "savedGroomingRecords")
        }
    }
    
    private func saveCheckupRecordsToUserDefaults() {
        // 仮実装: UserDefaultsに保存
        let userDefaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(checkupRecords) {
            userDefaults.set(encoded, forKey: "savedCheckupRecords")
        }
    }
    
    private func saveMedicationRecordsToUserDefaults() {
        // 仮実装: UserDefaultsに保存
        let userDefaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(medicationRecords) {
            userDefaults.set(encoded, forKey: "savedMedicationRecords")
        }
    }
    
    private func saveOtherRecordsToUserDefaults() {
        // 仮実装: UserDefaultsに保存
        let userDefaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(otherRecords) {
            userDefaults.set(encoded, forKey: "savedOtherRecords")
        }
    }
    
    // MARK: - Weight Record CRUD
    
    func weightRecordsForAnimal(id: UUID) -> [WeightRecord] {
        // 健康記録から体重データを取得
        let healthRecords = healthRecordsForAnimal(id: id)
        
        // 体重データがあるレコードだけをフィルタリングして変換
        return healthRecords.compactMap { record -> WeightRecord? in
            guard let weight = record.weight else { return nil }
            
            return WeightRecord(
                id: record.id,
                animalId: record.animalId,
                date: record.date,
                weight: weight,
                notes: record.notes
            )
        }
    }
    
    // MARK: - Vaccine Record CRUD
    
    func addVaccineRecord(_ record: VaccineRecord) {
        vaccineRecords.append(record)
        saveVaccineRecordsToUserDefaults()
    }
    
    func updateVaccineRecord(_ record: VaccineRecord) {
        if let index = vaccineRecords.firstIndex(where: { $0.id == record.id }) {
            vaccineRecords[index] = record
            saveVaccineRecordsToUserDefaults()
        }
    }
    
    func deleteVaccineRecord(_ record: VaccineRecord) {
        vaccineRecords.removeAll(where: { $0.id == record.id })
        saveVaccineRecordsToUserDefaults()
    }
    
    func vaccineRecordsForAnimal(id: UUID) -> [VaccineRecord] {
        return vaccineRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    func getNextScheduledVaccine(animalId: UUID) -> VaccineRecord? {
        let records = vaccineRecords.filter { 
            $0.animalId == animalId && 
            $0.nextScheduledDate != nil && 
            $0.nextScheduledDate! >= Date().addingTimeInterval(-60*60*24*30) // 30日以上過ぎていないもの
        }
        
        // 日付が近い順にソート
        let sortedRecords = records.sorted { 
            guard let date1 = $0.nextScheduledDate, let date2 = $1.nextScheduledDate else {
                return false
            }
            return date1 < date2
        }
        
        return sortedRecords.first
    }
    
    // MARK: - Grooming Record CRUD
    
    func addGroomingRecord(_ record: GroomingRecord) {
        groomingRecords.append(record)
        saveGroomingRecordsToUserDefaults()
    }
    
    func updateGroomingRecord(_ record: GroomingRecord) {
        if let index = groomingRecords.firstIndex(where: { $0.id == record.id }) {
            groomingRecords[index] = record
            saveGroomingRecordsToUserDefaults()
        }
    }
    
    func deleteGroomingRecord(_ record: GroomingRecord) {
        groomingRecords.removeAll(where: { $0.id == record.id })
        saveGroomingRecordsToUserDefaults()
    }
    
    func groomingRecordsForAnimal(id: UUID) -> [GroomingRecord] {
        return groomingRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    func getNextScheduledGrooming(animalId: UUID) -> GroomingRecord? {
        let records = groomingRecords.filter { 
            $0.animalId == animalId && 
            $0.nextScheduledDate != nil && 
            $0.nextScheduledDate! >= Date().addingTimeInterval(-60*60*24*30) // 30日以上過ぎていないもの
        }
        
        // 日付が近い順にソート
        let sortedRecords = records.sorted { 
            guard let date1 = $0.nextScheduledDate, let date2 = $1.nextScheduledDate else {
                return false
            }
            return date1 < date2
        }
        
        return sortedRecords.first
    }
    
    // MARK: - Checkup Record CRUD
    
    func addCheckupRecord(_ record: CheckupRecord) {
        checkupRecords.append(record)
        saveCheckupRecordsToUserDefaults()
    }
    
    func updateCheckupRecord(_ record: CheckupRecord) {
        if let index = checkupRecords.firstIndex(where: { $0.id == record.id }) {
            checkupRecords[index] = record
            saveCheckupRecordsToUserDefaults()
        }
    }
    
    func deleteCheckupRecord(_ record: CheckupRecord) {
        checkupRecords.removeAll(where: { $0.id == record.id })
        saveCheckupRecordsToUserDefaults()
    }
    
    func checkupRecordsForAnimal(id: UUID) -> [CheckupRecord] {
        return checkupRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Medication Record CRUD
    
    func addMedicationRecord(_ record: MedicationRecord) {
        medicationRecords.append(record)
        saveMedicationRecordsToUserDefaults()
    }
    
    func updateMedicationRecord(_ record: MedicationRecord) {
        if let index = medicationRecords.firstIndex(where: { $0.id == record.id }) {
            medicationRecords[index] = record
            saveMedicationRecordsToUserDefaults()
        }
    }
    
    func deleteMedicationRecord(_ record: MedicationRecord) {
        medicationRecords.removeAll(where: { $0.id == record.id })
        saveMedicationRecordsToUserDefaults()
    }
    
    func medicationRecordsForAnimal(id: UUID) -> [MedicationRecord] {
        return medicationRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Other Record CRUD
    
    func addOtherRecord(_ record: OtherRecord) {
        otherRecords.append(record)
        saveOtherRecordsToUserDefaults()
    }
    
    func updateOtherRecord(_ record: OtherRecord) {
        if let index = otherRecords.firstIndex(where: { $0.id == record.id }) {
            otherRecords[index] = record
            saveOtherRecordsToUserDefaults()
        }
    }
    
    func deleteOtherRecord(_ record: OtherRecord) {
        otherRecords.removeAll(where: { $0.id == record.id })
        saveOtherRecordsToUserDefaults()
    }
    
    func otherRecordsForAnimal(id: UUID) -> [OtherRecord] {
        return otherRecords.filter { $0.animalId == id }
            .sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Calendar Events
    
    // カレンダーの特定日にスケジュールされたイベントを取得
    func scheduledEventsOn(date: Date) -> [ScheduledEvent] {
        let calendar = Calendar.current
        var events: [ScheduledEvent] = []
        
        // 1. ワクチン予定をチェック
        for animal in animals {
            let animalVaccines = vaccineRecords.filter { $0.animalId == animal.id }
            
            for vaccine in animalVaccines {
                // 現在日か次の予定日のいずれかが合致するかチェック
                if calendar.isDate(vaccine.date, inSameDayAs: date) || 
                   (vaccine.nextScheduledDate != nil && calendar.isDate(vaccine.nextScheduledDate!, inSameDayAs: date)) {
                    let eventType = EventType.vaccine(vaccine)
                    let event = ScheduledEvent(
                        id: UUID(),
                        animalId: animal.id,
                        animalName: animal.name,
                        date: calendar.isDate(vaccine.date, inSameDayAs: date) ? vaccine.date : vaccine.nextScheduledDate!,
                        type: eventType,
                        title: "\(animal.name)の\(vaccine.vaccineName)接種"
                    )
                    events.append(event)
                }
            }
        }
        
        // 2. トリミング予定をチェック
        for animal in animals {
            let animalGroomings = groomingRecords.filter { $0.animalId == animal.id }
            
            for grooming in animalGroomings {
                // 現在日か次の予定日のいずれかが合致するかチェック
                if calendar.isDate(grooming.date, inSameDayAs: date) || 
                   (grooming.nextScheduledDate != nil && calendar.isDate(grooming.nextScheduledDate!, inSameDayAs: date)) {
                    let groomingTypeStr = grooming.groomingType ?? "トリミング"
                    let eventType = EventType.grooming(grooming)
                    let event = ScheduledEvent(
                        id: UUID(),
                        animalId: animal.id,
                        animalName: animal.name,
                        date: calendar.isDate(grooming.date, inSameDayAs: date) ? grooming.date : grooming.nextScheduledDate!,
                        type: eventType,
                        title: "\(animal.name)の\(groomingTypeStr)"
                    )
                    events.append(event)
                }
            }
        }
        
        // 3. 健康診断予定をチェック
        for animal in animals {
            let animalCheckups = checkupRecords.filter { $0.animalId == animal.id }
            
            for checkup in animalCheckups {
                // 現在日か次の予定日のいずれかが合致するかチェック
                if calendar.isDate(checkup.date, inSameDayAs: date) || 
                   (checkup.nextScheduledDate != nil && calendar.isDate(checkup.nextScheduledDate!, inSameDayAs: date)) {
                    let eventType = EventType.checkup(checkup)
                    let event = ScheduledEvent(
                        id: UUID(),
                        animalId: animal.id,
                        animalName: animal.name,
                        date: calendar.isDate(checkup.date, inSameDayAs: date) ? checkup.date : checkup.nextScheduledDate!,
                        type: eventType,
                        title: "\(animal.name)の\(checkup.checkupType)"
                    )
                    events.append(event)
                }
            }
        }
        
        // 4. 投薬予定をチェック
        for animal in animals {
            let animalMedications = medicationRecords.filter { $0.animalId == animal.id }
            
            for medication in animalMedications {
                // 現在日か次の予定日のいずれかが合致するかチェック
                if calendar.isDate(medication.date, inSameDayAs: date) || 
                   (medication.nextScheduledDate != nil && calendar.isDate(medication.nextScheduledDate!, inSameDayAs: date)) {
                    let eventType = EventType.medication(medication)
                    let event = ScheduledEvent(
                        id: UUID(),
                        animalId: animal.id,
                        animalName: animal.name,
                        date: calendar.isDate(medication.date, inSameDayAs: date) ? medication.date : medication.nextScheduledDate!,
                        type: eventType,
                        title: "\(animal.name)の\(medication.medicationName)投与"
                    )
                    events.append(event)
                }
            }
        }
        
        // 5. その他の予定をチェック
        for animal in animals {
            let animalOthers = otherRecords.filter { $0.animalId == animal.id }
            
            for other in animalOthers {
                // 現在日か次の予定日のいずれかが合致するかチェック
                if calendar.isDate(other.date, inSameDayAs: date) || 
                   (other.nextScheduledDate != nil && calendar.isDate(other.nextScheduledDate!, inSameDayAs: date)) {
                    let eventType = EventType.other(other)
                    let event = ScheduledEvent(
                        id: UUID(),
                        animalId: animal.id,
                        animalName: animal.name,
                        date: calendar.isDate(other.date, inSameDayAs: date) ? other.date : other.nextScheduledDate!,
                        type: eventType,
                        title: "\(animal.name)の\(other.title)"
                    )
                    events.append(event)
                }
            }
        }
        
        // 6. 生理周期をチェック
        let cycleEvents = animalsWithCycleOn(date: date)
        for (animal, cycle) in cycleEvents {
            let isForecast = cycle == nil
            let eventType = EventType.physiologicalCycle(cycle, isForecast: isForecast, animalColor: animal.color)
            let title = isForecast ? "\(animal.name)の生理予測" : "\(animal.name)の生理周期"
            
            let event = ScheduledEvent(
                id: UUID(),
                animalId: animal.id,
                animalName: animal.name,
                date: date,
                type: eventType,
                title: title
            )
            events.append(event)
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    // 指定した日付に何らかのイベントがあるかチェック
    func hasAnyEventOnDate(_ date: Date) -> Bool {
        return !scheduledEventsOn(date: date).isEmpty
    }
}

// イベントタイプを識別するための列挙型
enum EventType {
    case vaccine(VaccineRecord)
    case grooming(GroomingRecord)
    case checkup(CheckupRecord)
    case medication(MedicationRecord)
    case other(OtherRecord)
    case physiologicalCycle(PhysiologicalCycle?, isForecast: Bool, animalColor: Color?)
    
    var color: Color {
        // どのイベントタイプでも動物の色を優先して表示
        switch self {
        case .vaccine(let record):
            // 動物の色が設定されていない場合はデフォルトの色を使用
            return record.color ?? .green
        case .grooming(let record):
            return record.color ?? .purple
        case .checkup(let record):
            return record.color ?? .blue
        case .medication(let record):
            return record.color ?? .orange
        case .other(let record):
            return record.color ?? .gray
        case .physiologicalCycle(let cycle, _, let animalColor):
            // 動物の色が設定されていればそれを使用
            if let color = animalColor {
                return color
            }
            // 生理周期の場合は強度に応じた色分けを使用
            if let cycle = cycle {
                switch cycle.intensity {
                case .light:
                    return .orange.opacity(0.7)
                case .medium:
                    return .orange
                case .heavy:
                    return .red
                }
            } else {
                return .orange.opacity(0.5) // 予測は薄い色
            }
        }
    }
    
    var icon: String {
        switch self {
        case .vaccine:
            return "syringe"
        case .grooming:
            return "scissors"
        case .checkup:
            return "stethoscope"
        case .medication:
            return "pill"
        case .other:
            return "calendar.badge.plus"
        case .physiologicalCycle:
            return "drop.fill"
        }
    }
}

// カレンダーイベントのモデル
struct ScheduledEvent: Identifiable {
    var id: UUID
    var animalId: UUID
    var animalName: String
    var date: Date
    var type: EventType
    var title: String
    
    var color: Color {
        return type.color
    }
    
    var icon: String {
        return type.icon
    }
}