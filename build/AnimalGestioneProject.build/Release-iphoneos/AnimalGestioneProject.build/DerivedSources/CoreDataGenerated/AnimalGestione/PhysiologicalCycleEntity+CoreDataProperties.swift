//
//  PhysiologicalCycleEntity+CoreDataProperties.swift
//  
//
//  Created by 垣原親伍 on 2025/05/21.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension PhysiologicalCycleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PhysiologicalCycleEntity> {
        return NSFetchRequest<PhysiologicalCycleEntity>(entityName: "PhysiologicalCycleEntity")
    }

    @NSManaged public var endDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var intensity: Int16
    @NSManaged public var notes: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var animal: AnimalEntity?

}

extension PhysiologicalCycleEntity : Identifiable {

}
