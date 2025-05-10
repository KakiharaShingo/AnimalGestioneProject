import Foundation
import CoreData
import SwiftUI
import UIKit

/// データのエクスポートとインポートを管理するクラス
class DataExportImportManager: ObservableObject {
    static let shared = DataExportImportManager()
    
    // CoreDataストア
    private var persistenceController: PersistenceController {
        PersistenceController.shared
    }
    
    // バックアップ情報
    @Published var lastBackupDate: Date? = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // ローカル保存パス
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let backupDirectory: URL
    
    init() {
        // バックアップディレクトリを作成
        backupDirectory = documentsDirectory.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        
        // 古いバックアップ情報を読み込む
        loadBackupInfo()
    }
    
    // バックアップ情報を読み込む
    private func loadBackupInfo() {
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }
    
    // バックアップ情報を保存
    private func saveBackupInfo() {
        UserDefaults.standard.set(lastBackupDate, forKey: "lastBackupDate")
    }
    
    // データをJSONとしてエクスポート
    func exportData() -> URL? {
        isExporting = true
        errorMessage = nil
        successMessage = nil
        
        do {
            // 全ての動物データを取得
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AnimalEntity")
            let animals = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            // シリアライズ可能なディクショナリの配列に変換
            var animalDicts: [[String: Any]] = []
            
            for animal in animals {
                var animalDict: [String: Any] = [:]
                
                // 各プロパティをディクショナリに追加
                for attribute in animal.entity.attributesByName {
                    if let value = animal.value(forKey: attribute.key) {
                        // Date型をタイムスタンプに変換
                        if let date = value as? Date {
                            animalDict[attribute.key] = date.timeIntervalSince1970
                        }
                        // Data型をBase64文字列に変換
                        else if let data = value as? Data {
                            animalDict[attribute.key] = data.base64EncodedString()
                        }
                        // UUID型を文字列に変換
                        else if let uuid = value as? UUID {
                            animalDict[attribute.key] = uuid.uuidString
                        }
                        // その他の基本型はそのまま
                        else {
                            animalDict[attribute.key] = value
                        }
                    }
                }
                
                // 関連レコードを取得
                // 生理周期記録
                if let cycleRecords = animal.value(forKey: "physiologicalCycles") as? NSSet {
                    var cycleArray: [[String: Any]] = []
                    for cycleRecord in cycleRecords {
                        if let record = cycleRecord as? NSManagedObject {
                            var recordDict: [String: Any] = [:]
                            for attribute in record.entity.attributesByName {
                                if let value = record.value(forKey: attribute.key) {
                                    if let date = value as? Date {
                                        recordDict[attribute.key] = date.timeIntervalSince1970
                                    } else if let uuid = value as? UUID {
                                        recordDict[attribute.key] = uuid.uuidString
                                    } else {
                                        recordDict[attribute.key] = value
                                    }
                                }
                            }
                            cycleArray.append(recordDict)
                        }
                    }
                    animalDict["physiologicalCycles"] = cycleArray
                }
                
                // 健康記録
                if let healthRecords = animal.value(forKey: "healthRecords") as? NSSet {
                    var healthArray: [[String: Any]] = []
                    for healthRecord in healthRecords {
                        if let record = healthRecord as? NSManagedObject {
                            var recordDict: [String: Any] = [:]
                            for attribute in record.entity.attributesByName {
                                if let value = record.value(forKey: attribute.key) {
                                    if let date = value as? Date {
                                        recordDict[attribute.key] = date.timeIntervalSince1970
                                    } else if let uuid = value as? UUID {
                                        recordDict[attribute.key] = uuid.uuidString
                                    } else {
                                        recordDict[attribute.key] = value
                                    }
                                }
                            }
                            healthArray.append(recordDict)
                        }
                    }
                    animalDict["healthRecords"] = healthArray
                }
                
                animalDicts.append(animalDict)
            }
            
            // アプリ情報と日時を含むメタデータ
            let metadata: [String: Any] = [
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                "buildVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
                "exportDate": Date().timeIntervalSince1970,
                "deviceName": UIDevice.current.name,
                "systemVersion": UIDevice.current.systemVersion
            ]
            
            // 全データを含む辞書を作成
            let exportDict: [String: Any] = [
                "metadata": metadata,
                "animals": animalDicts
            ]
            
            // JSONデータに変換
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted)
            
            // タイムスタンプ付きのファイル名を生成
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "AnimalGestione_Backup_\(timestamp).json"
            
            // ファイルを保存
            let fileURL = backupDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: fileURL)
            
            // 最終バックアップ日時を更新
            lastBackupDate = Date()
            saveBackupInfo()
            
            successMessage = "バックアップが完了しました"
            isExporting = false
            return fileURL
            
        } catch {
            print("データエクスポートエラー: \(error.localizedDescription)")
            errorMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
            isExporting = false
            return nil
        }
    }
    
    // バックアップファイルからデータをインポート
    func importData(from url: URL, completion: @escaping (Bool, String) -> Void) {
        isImporting = true
        errorMessage = nil
        successMessage = nil
        
        // データを読み込む
        do {
            let jsonData = try Data(contentsOf: url)
            guard let importDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let metadata = importDict["metadata"] as? [String: Any],
                  let animals = importDict["animals"] as? [[String: Any]] else {
                throw NSError(domain: "DataImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "無効なバックアップファイル形式です"])
            }
            
            // メタデータを確認
            if let exportDateTimestamp = metadata["exportDate"] as? Double {
                let exportDate = Date(timeIntervalSince1970: exportDateTimestamp)
                print("バックアップ日時: \(exportDate)")
            }
            
            // 一時的なコンテキストを作成してインポート処理を行う
            let tempContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            tempContext.parent = persistenceController.container.viewContext
            
            // 既存のデータを全て削除
            let deleteRequests = ["AnimalEntity", "PhysiologicalCycleEntity", "HealthRecordEntity"]
            for entityName in deleteRequests {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                try persistenceController.container.persistentStoreCoordinator.execute(deleteRequest, with: tempContext)
            }
            
            // 動物データをインポート
            for animalDict in animals {
                let animal = NSEntityDescription.insertNewObject(forEntityName: "AnimalEntity", into: tempContext)
                
                // 基本プロパティの設定
                for (key, value) in animalDict {
                    // 関連レコードは別途処理
                    if !["physiologicalCycles", "healthRecords"].contains(key) {
                        // 値を適切な型に変換
                        if let attributeType = animal.entity.attributesByName[key]?.attributeType {
                            switch attributeType {
                            case .dateAttributeType:
                                if let timestamp = value as? Double {
                                    animal.setValue(Date(timeIntervalSince1970: timestamp), forKey: key)
                                }
                            case .binaryDataAttributeType:
                                if let base64String = value as? String {
                                    animal.setValue(Data(base64Encoded: base64String), forKey: key)
                                }
                            case .UUIDAttributeType:
                                if let uuidString = value as? String {
                                    animal.setValue(UUID(uuidString: uuidString), forKey: key)
                                }
                            default:
                                animal.setValue(value, forKey: key)
                            }
                        } else {
                            animal.setValue(value, forKey: key)
                        }
                    }
                }
                
                // 生理周期記録のインポート
                if let cycleRecords = animalDict["physiologicalCycles"] as? [[String: Any]] {
                    for recordDict in cycleRecords {
                        let record = NSEntityDescription.insertNewObject(forEntityName: "PhysiologicalCycleEntity", into: tempContext)
                        for (key, value) in recordDict {
                            if let attributeType = record.entity.attributesByName[key]?.attributeType {
                                switch attributeType {
                                case .dateAttributeType:
                                    if let timestamp = value as? Double {
                                        record.setValue(Date(timeIntervalSince1970: timestamp), forKey: key)
                                    }
                                case .UUIDAttributeType:
                                    if let uuidString = value as? String {
                                        record.setValue(UUID(uuidString: uuidString), forKey: key)
                                    }
                                default:
                                    record.setValue(value, forKey: key)
                                }
                            } else {
                                record.setValue(value, forKey: key)
                            }
                        }
                        record.setValue(animal, forKey: "animal")
                    }
                }
                
                // 健康記録のインポート
                if let healthRecords = animalDict["healthRecords"] as? [[String: Any]] {
                    for recordDict in healthRecords {
                        let record = NSEntityDescription.insertNewObject(forEntityName: "HealthRecordEntity", into: tempContext)
                        for (key, value) in recordDict {
                            if let attributeType = record.entity.attributesByName[key]?.attributeType {
                                switch attributeType {
                                case .dateAttributeType:
                                    if let timestamp = value as? Double {
                                        record.setValue(Date(timeIntervalSince1970: timestamp), forKey: key)
                                    }
                                case .UUIDAttributeType:
                                    if let uuidString = value as? String {
                                        record.setValue(UUID(uuidString: uuidString), forKey: key)
                                    }
                                default:
                                    record.setValue(value, forKey: key)
                                }
                            } else {
                                record.setValue(value, forKey: key)
                            }
                        }
                        record.setValue(animal, forKey: "animal")
                    }
                }
            }
            
            // 変更を保存
            try tempContext.save()
            try persistenceController.container.viewContext.save()
            
            successMessage = "データのインポートが完了しました"
            isImporting = false
            completion(true, "データのインポートが完了しました")
            
        } catch {
            print("データインポートエラー: \(error.localizedDescription)")
            errorMessage = "インポートに失敗しました: \(error.localizedDescription)"
            isImporting = false
            completion(false, "インポートに失敗しました: \(error.localizedDescription)")
        }
    }
    
    // バックアップ共有機能
    func shareBackup(from url: URL, presentingController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        presentingController.present(activityViewController, animated: true)
    }
    
    // 利用可能なバックアップファイルを取得
    func getAvailableBackups() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "json" }.sorted { lhs, rhs in
                (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date() >
                (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            }
        } catch {
            print("バックアップファイル取得エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    // バックアップファイルの削除
    func deleteBackup(url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("バックアップ削除エラー: \(error.localizedDescription)")
            return false
        }
    }
}

// UIViewControllerRepresentable for document picker
struct DocumentPickerView: UIViewControllerRepresentable {
    let onSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onSelected(url)
        }
    }
}
