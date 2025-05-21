//
//  HealthRecordEntity+CoreDataProperties.swift
//  
//
//  Created by 垣原親伍 on 2025/05/21.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension HealthRecordEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HealthRecordEntity> {
        return NSFetchRequest<HealthRecordEntity>(entityName: "HealthRecordEntity")
    }

    @NSManaged public var activityLevel: Int16
    @NSManaged public var appetite: Int16
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var temperature: Double
    @NSManaged public var weight: Double
    @NSManaged public var animal: AnimalEntity?

}

extension HealthRecordEntity : Identifiable {

}
