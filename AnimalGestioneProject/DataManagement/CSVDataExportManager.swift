import Foundation
import CoreData
import UIKit

/// CSVデータのエクスポートとインポートを管理するクラス
class CSVDataExportManager {
    static let shared = CSVDataExportManager()
    
    // CoreDataストア
    private var persistenceController: PersistenceController {
        PersistenceController.shared
    }
    
    // 保存パス
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let exportDirectory: URL
    
    init() {
        // エクスポートディレクトリを作成
        exportDirectory = documentsDirectory.appendingPathComponent("Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
    }
    
    // CSVとして動物データをエクスポート
    func exportAnimalsToCSV() -> URL? {
        do {
            // 全ての動物データを取得
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Animal")
            let animals = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            // CSVヘッダーの生成
            var csvString = "ID,名前,種別,性別,誕生日,毛色,体重,メモ,最終更新日\n"
            
            // 各動物のデータを追加
            for animal in animals {
                let id = animal.value(forKey: "id") as? UUID ?? UUID()
                let name = animal.value(forKey: "name") as? String ?? ""
                let species = animal.value(forKey: "species") as? String ?? ""
                let gender = animal.value(forKey: "gender") as? String ?? ""
                let birthDate = animal.value(forKey: "birthDate") as? Date
                let birthDateString = formatDate(birthDate)
                let coatColor = animal.value(forKey: "coatColor") as? String ?? ""
                let weight = animal.value(forKey: "weight") as? Double ?? 0.0
                let notes = animal.value(forKey: "notes") as? String ?? ""
                let lastUpdated = animal.value(forKey: "lastUpdated") as? Date
                let lastUpdatedString = formatDate(lastUpdated)
                
                // CSV行を作成（CSV形式に対応するためにエスケープ処理）
                let row = "\"\(id.uuidString)\",\"\(escapeCSV(name))\",\"\(escapeCSV(species))\",\"\(escapeCSV(gender))\",\"\(birthDateString)\",\"\(escapeCSV(coatColor))\",\"\(weight)\",\"\(escapeCSV(notes))\",\"\(lastUpdatedString)\"\n"
                csvString.append(row)
            }
            
            // ファイル名を生成
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "Animals_\(timestamp).csv"
            
            // ファイルを保存
            let fileURL = exportDirectory.appendingPathComponent(fileName)
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
            
        } catch {
            print("CSVエクスポートエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // CSVとしてワクチン記録をエクスポート
    func exportVaccineRecordsToCSV() -> URL? {
        do {
            // 全てのワクチン記録を取得
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "VaccineRecord")
            let records = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            // CSVヘッダーの生成
            var csvString = "ID,動物ID,ワクチン名,接種日,次回接種予定日,メモ\n"
            
            // 各記録を追加
            for record in records {
                let id = record.value(forKey: "id") as? UUID ?? UUID()
                let animalID = (record.value(forKey: "animal") as? NSManagedObject)?.value(forKey: "id") as? UUID ?? UUID()
                let name = record.value(forKey: "name") as? String ?? ""
                let date = record.value(forKey: "date") as? Date
                let dateString = formatDate(date)
                let nextDate = record.value(forKey: "nextDate") as? Date
                let nextDateString = formatDate(nextDate)
                let notes = record.value(forKey: "notes") as? String ?? ""
                
                // CSV行を作成
                let row = "\"\(id.uuidString)\",\"\(animalID.uuidString)\",\"\(escapeCSV(name))\",\"\(dateString)\",\"\(nextDateString)\",\"\(escapeCSV(notes))\"\n"
                csvString.append(row)
            }
            
            // ファイル名を生成
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "VaccineRecords_\(timestamp).csv"
            
            // ファイルを保存
            let fileURL = exportDirectory.appendingPathComponent(fileName)
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
            
        } catch {
            print("CSVエクスポートエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // CSVとして健康診断記録をエクスポート
    func exportCheckupRecordsToCSV() -> URL? {
        do {
            // 全ての健康診断記録を取得
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CheckupRecord")
            let records = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            // CSVヘッダーの生成
            var csvString = "ID,動物ID,日付,獣医,診断,処方薬,メモ\n"
            
            // 各記録を追加
            for record in records {
                let id = record.value(forKey: "id") as? UUID ?? UUID()
                let animalID = (record.value(forKey: "animal") as? NSManagedObject)?.value(forKey: "id") as? UUID ?? UUID()
                let date = record.value(forKey: "date") as? Date
                let dateString = formatDate(date)
                let veterinarian = record.value(forKey: "veterinarian") as? String ?? ""
                let diagnosis = record.value(forKey: "diagnosis") as? String ?? ""
                let prescriptions = record.value(forKey: "prescriptions") as? String ?? ""
                let notes = record.value(forKey: "notes") as? String ?? ""
                
                // CSV行を作成
                let row = "\"\(id.uuidString)\",\"\(animalID.uuidString)\",\"\(dateString)\",\"\(escapeCSV(veterinarian))\",\"\(escapeCSV(diagnosis))\",\"\(escapeCSV(prescriptions))\",\"\(escapeCSV(notes))\"\n"
                csvString.append(row)
            }
            
            // ファイル名を生成
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "CheckupRecords_\(timestamp).csv"
            
            // ファイルを保存
            let fileURL = exportDirectory.appendingPathComponent(fileName)
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
            
        } catch {
            print("CSVエクスポートエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // CSVとして体重記録をエクスポート
    func exportWeightRecordsToCSV() -> URL? {
        do {
            // 全ての体重記録を取得
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeightRecord")
            let records = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            // CSVヘッダーの生成
            var csvString = "ID,動物ID,日付,体重,メモ\n"
            
            // 各記録を追加
            for record in records {
                let id = record.value(forKey: "id") as? UUID ?? UUID()
                let animalID = (record.value(forKey: "animal") as? NSManagedObject)?.value(forKey: "id") as? UUID ?? UUID()
                let date = record.value(forKey: "date") as? Date
                let dateString = formatDate(date)
                let weight = record.value(forKey: "weight") as? Double ?? 0.0
                let notes = record.value(forKey: "notes") as? String ?? ""
                
                // CSV行を作成
                let row = "\"\(id.uuidString)\",\"\(animalID.uuidString)\",\"\(dateString)\",\"\(weight)\",\"\(escapeCSV(notes))\"\n"
                csvString.append(row)
            }
            
            // ファイル名を生成
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "WeightRecords_\(timestamp).csv"
            
            // ファイルを保存
            let fileURL = exportDirectory.appendingPathComponent(fileName)
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
            
        } catch {
            print("CSVエクスポートエラー: \(error.localizedDescription)")
            return nil
        }
    }
    
    // CSVファイルを共有
    func shareCSV(from url: URL, presentingController: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        presentingController.present(activityViewController, animated: true)
    }
    
    // 利用可能なCSVファイルを取得
    func getAvailableCSVFiles() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: exportDirectory, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "csv" }.sorted { lhs, rhs in
                (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date() >
                (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            }
        } catch {
            print("CSVファイル取得エラー: \(error.localizedDescription)")
            return []
        }
    }
    
    // すべてのデータをCSVとしてエクスポート（アーカイブ形式）
    func exportAllDataToCSVArchive() -> URL? {
        // 一時ディレクトリにCSVファイルを作成
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // 各種データをCSVとしてエクスポート
        let animalURL = exportAnimalsToTempDir(tempDir)
        let vaccineURL = exportVaccineRecordsToTempDir(tempDir)
        let checkupURL = exportCheckupRecordsToTempDir(tempDir)
        let weightURL = exportWeightRecordsToTempDir(tempDir)
        let groomingURL = exportGroomingRecordsToTempDir(tempDir)
        let physiologicalURL = exportPhysiologicalCyclesToTempDir(tempDir)
        
        // Zipアーカイブの作成
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let zipFileName = "AnimalGestione_AllData_\(timestamp).zip"
        let zipURL = exportDirectory.appendingPathComponent(zipFileName)
        
        // TODO: 実装する場合はZipパッケージをインポートする必要があります
        // ここではサンプルとして、単一のCSV出力に代えています
        return animalURL // 実際のzipURL
    }
    
    // ヘルパーメソッド: 一時ディレクトリに動物データをエクスポート
    private func exportAnimalsToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略（exportAnimalsToCSVとほぼ同じ）
        return tempDir.appendingPathComponent("Animals.csv")
    }
    
    // ヘルパーメソッド: 一時ディレクトリにワクチン記録をエクスポート
    private func exportVaccineRecordsToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略
        return tempDir.appendingPathComponent("VaccineRecords.csv")
    }
    
    // ヘルパーメソッド: 一時ディレクトリに健康診断記録をエクスポート
    private func exportCheckupRecordsToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略
        return tempDir.appendingPathComponent("CheckupRecords.csv")
    }
    
    // ヘルパーメソッド: 一時ディレクトリに体重記録をエクスポート
    private func exportWeightRecordsToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略
        return tempDir.appendingPathComponent("WeightRecords.csv")
    }
    
    // ヘルパーメソッド: 一時ディレクトリにグルーミング記録をエクスポート
    private func exportGroomingRecordsToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略
        return tempDir.appendingPathComponent("GroomingRecords.csv")
    }
    
    // ヘルパーメソッド: 一時ディレクトリに生理周期記録をエクスポート
    private func exportPhysiologicalCyclesToTempDir(_ tempDir: URL) -> URL {
        // 実装は省略
        return tempDir.appendingPathComponent("PhysiologicalCycles.csv")
    }
    
    // ヘルパーメソッド: 日付のフォーマット
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // ヘルパーメソッド: CSV文字列のエスケープ処理
    private func escapeCSV(_ string: String) -> String {
        // ダブルクォート（"）が含まれる場合は二重にする
        return string.replacingOccurrences(of: "\"", with: "\"\"")
    }
}
