import CoreData

struct PersistenceController {
    // シングルトンインスタンス
    static let shared = PersistenceController()
    
    // テスト用のインスタンス（プレビュー用）
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // サンプルデータを追加
        let viewContext = controller.container.viewContext
        
        // サンプル動物を追加
        let sampleAnimal = AnimalEntity(context: viewContext)
        sampleAnimal.id = UUID()
        sampleAnimal.name = "モモ"
        sampleAnimal.species = "猫"
        sampleAnimal.breed = "雑種"
        sampleAnimal.gender = "メス"
        sampleAnimal.birthDate = Date().addingTimeInterval(-31536000) // 約1年前
        sampleAnimal.colorHex = "#FF9500" // オレンジ色
        
        // サンプル生理周期を追加
        let cycle = PhysiologicalCycleEntity(context: viewContext)
        cycle.id = UUID()
        cycle.startDate = Date().addingTimeInterval(-1209600) // 約2週間前
        cycle.endDate = Date().addingTimeInterval(-1036800) // 開始から2日後
        cycle.intensity = 2 // 中程度
        cycle.notes = "通常の周期"
        cycle.animal = sampleAnimal
        
        // サンプル健康記録を追加
        let healthRecord = HealthRecordEntity(context: viewContext)
        healthRecord.id = UUID()
        healthRecord.date = Date().addingTimeInterval(-604800) // 約1週間前
        healthRecord.weight = 4.2
        healthRecord.temperature = 38.5
        healthRecord.appetite = 2 // 普通
        healthRecord.activityLevel = 3 // 高い
        healthRecord.notes = "元気です"
        healthRecord.animal = sampleAnimal
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    // NSPersistentContainer
    let container: NSPersistentContainer
    
    // イニシャライザ
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AnimalGestione")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // エラーハンドリング
                fatalError("Persistent store failed to load: \(error.localizedDescription)")
            }
        }
        
        // マージポリシーを設定
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // 変更を保存するヘルパーメソッド
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // UserDefaultsからのデータ移行
    func migrateFromUserDefaults(animals: [Animal], cycles: [PhysiologicalCycle], records: [HealthRecord]) {
        let context = container.viewContext
        
        // 動物データを移行
        for animal in animals {
            let animalEntity = AnimalEntity(context: context)
            animalEntity.id = animal.id
            animalEntity.name = animal.name
            animalEntity.species = animal.species
            animalEntity.breed = animal.breed
            animalEntity.birthDate = animal.birthDate
            animalEntity.gender = animal.gender.rawValue
            
            // 画像データの移行
            if let imageUrl = animal.imageUrl {
                do {
                    let imageData = try Data(contentsOf: imageUrl)
                    animalEntity.imageData = imageData
                } catch {
                    print("Failed to load image: \(error)")
                }
            }
            
            // ランダムな色を割り当て（後で変更可能）
            animalEntity.colorHex = generateRandomColor()
        }
        
        // 生理周期データを移行
        for cycle in cycles {
            let cycleEntity = PhysiologicalCycleEntity(context: context)
            cycleEntity.id = cycle.id
            cycleEntity.startDate = cycle.startDate
            cycleEntity.endDate = cycle.endDate
            cycleEntity.intensity = Int16(cycle.intensity.rawValue)
            cycleEntity.notes = cycle.notes
            
            // 対応する動物を見つけて関連付け
            let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", cycle.animalId as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let animal = results.first {
                    cycleEntity.animal = animal
                }
            } catch {
                print("Failed to find animal for cycle: \(error)")
            }
        }
        
        // 健康記録データを移行
        for record in records {
            let recordEntity = HealthRecordEntity(context: context)
            recordEntity.id = record.id
            recordEntity.date = record.date
            recordEntity.weight = record.weight ?? 0
            recordEntity.temperature = record.temperature ?? 0
            recordEntity.appetite = Int16(record.appetite.rawValue)
            recordEntity.activityLevel = Int16(record.activityLevel.rawValue)
            recordEntity.notes = record.notes
            
            // 対応する動物を見つけて関連付け
            let fetchRequest: NSFetchRequest<AnimalEntity> = AnimalEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.animalId as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                if let animal = results.first {
                    recordEntity.animal = animal
                }
            } catch {
                print("Failed to find animal for health record: \(error)")
            }
        }
        
        // 変更を保存
        save()
    }
    
    // ランダムな色を生成（HEX形式）
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