//
//  AnimalEntity+CoreDataProperties.swift
//  
//
//  Created by 垣原親伍 on 2025/05/22.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension AnimalEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AnimalEntity> {
        return NSFetchRequest<AnimalEntity>(entityName: "AnimalEntity")
    }

    @NSManaged public var birthDate: Date?
    @NSManaged public var breed: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var gender: String?
    @NSManaged public var id: UUID?
    @NSManaged public var imageData: Data?
    @NSManaged public var name: String?
    @NSManaged public var species: String?
    @NSManaged public var healthRecords: NSSet?
    @NSManaged public var physiologicalCycles: NSSet?

}

// MARK: Generated accessors for healthRecords
extension AnimalEntity {

    @objc(addHealthRecordsObject:)
    @NSManaged public func addToHealthRecords(_ value: HealthRecordEntity)

    @objc(removeHealthRecordsObject:)
    @NSManaged public func removeFromHealthRecords(_ value: HealthRecordEntity)

    @objc(addHealthRecords:)
    @NSManaged public func addToHealthRecords(_ values: NSSet)

    @objc(removeHealthRecords:)
    @NSManaged public func removeFromHealthRecords(_ values: NSSet)

}

// MARK: Generated accessors for physiologicalCycles
extension AnimalEntity {

    @objc(addPhysiologicalCyclesObject:)
    @NSManaged public func addToPhysiologicalCycles(_ value: PhysiologicalCycleEntity)

    @objc(removePhysiologicalCyclesObject:)
    @NSManaged public func removeFromPhysiologicalCycles(_ value: PhysiologicalCycleEntity)

    @objc(addPhysiologicalCycles:)
    @NSManaged public func addToPhysiologicalCycles(_ values: NSSet)

    @objc(removePhysiologicalCycles:)
    @NSManaged public func removeFromPhysiologicalCycles(_ values: NSSet)

}

extension AnimalEntity : Identifiable {

}
