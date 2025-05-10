import Foundation
import CoreData
import SwiftUI
import UIKit

/// リレーションシップ情報をデバッグするための簡易クラス
class DebugDataExport {
    static let shared = DebugDataExport()
    
    // CoreDataストア
    private var persistenceController: PersistenceController {
        PersistenceController.shared
    }
    
    // エンティティの情報を出力する - 無効化
    func printEntityInfo() {
        // 出力を無効化
        return;
        do {
            // 全てのエンティティタイプを取得
            let modelDescription = persistenceController.container.managedObjectModel.entitiesByName
            
            print("\n\n======== データモデル情報 ========\n")
            
            // 全てのエンティティについて詳細を表示
            for (entityName, entityDescription) in modelDescription {
                print("エンティティ: \(entityName)")
                
                // 属性を表示
                print("  属性:")
                for (attrName, _) in entityDescription.attributesByName {
                    print("    - \(attrName)")
                }
                
                // リレーションシップを表示
                print("  リレーションシップ:")
                for (relName, relationship) in entityDescription.relationshipsByName {
                    let destinationName = relationship.destinationEntity?.name ?? "不明"
                    let isToMany = relationship.isToMany ? "複数" : "単一"
                    print("    - \(relName) (\(destinationName)への\(isToMany)リレーション)")
                }
                
                print("")
            }
            
            // AnimalEntityのインスタンスがあれば詳細を表示
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "AnimalEntity")
            let animals = try persistenceController.container.viewContext.fetch(fetchRequest) as! [NSManagedObject]
            
            if let firstAnimal = animals.first {
                print("\n====== AnimalEntityのサンプルインスタンス ======\n")
                
                // 属性値を表示
                print("属性値:")
                for (attrName, _) in firstAnimal.entity.attributesByName {
                    if let value = firstAnimal.value(forKey: attrName) {
                        print("  \(attrName) = \(value)")
                    } else {
                        print("  \(attrName) = nil")
                    }
                }
                
                // リレーションシップの値を表示
                print("\nリレーションシップ値:")
                for (relName, _) in firstAnimal.entity.relationshipsByName {
                    print("  \(relName)")
                    if let value = firstAnimal.value(forKey: relName) {
                        if let set = value as? NSSet {
                            print("    = \(set.count)個の関連オブジェクト")
                        } else {
                            print("    = \(value)")
                        }
                    } else {
                        print("    = nil")
                    }
                }
            } else {
                print("\nAnimalEntityのインスタンスはありません")
            }
            
            print("\n======================================\n")
            
        } catch {
            print("エンティティ情報の出力エラー: \(error.localizedDescription)")
        }
    }
}
