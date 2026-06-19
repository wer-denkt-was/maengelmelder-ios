//
//  GeometryMO.swift
//  Maengelmelder
//
//  Created by Felix on 22.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import Foundation
import CoreData

@objc(GeometryMO)
class GeometryMO : NSManagedObject {
    
    @NSManaged var id : NSNumber
    @NSManaged var part_id : NSNumber
    @NSManaged var part_wkt : String?
    @NSManaged var min_lat : NSNumber
    @NSManaged var max_lat : NSNumber
    @NSManaged var min_long : NSNumber
    @NSManaged var max_long : NSNumber
    
    private enum Keys: String, SerializationKey {
        
        case id
        case part_wkt = "wkt"
    }
    
    convenience init (serialization: Serialization, geo_id : NSNumber) {
        
        let context = MM.shared.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "Geometry", in: context)!
        
        self.init(entity: entity, insertInto: context)
        
        id = geo_id
        
        let str_id = serialization.value(forKey: Keys.id) ?? ""
        part_id = NSNumber(value: Int(str_id) ?? 0)
        
        part_wkt = serialization.value(forKey: Keys.part_wkt) ?? ""
        min_lat = 0
        max_lat = 0
        min_long = 0
        max_long = 0
    }
    
    func clone (context: NSManagedObjectContext) -> GeometryMO {
        
        let clonedEntity = NSEntityDescription.insertNewObject(forEntityName: CoreDataEntityNames.GEOMETRY, into: context) as! GeometryMO
        
        clonedEntity.id = self.id
        clonedEntity.part_id = self.part_id
        clonedEntity.part_wkt = self.part_wkt!
        clonedEntity.max_lat = self.max_lat
        clonedEntity.min_lat = self.min_lat
        clonedEntity.max_long = self.max_long
        clonedEntity.min_long = self.min_long
        
        return clonedEntity
    }
    
}
