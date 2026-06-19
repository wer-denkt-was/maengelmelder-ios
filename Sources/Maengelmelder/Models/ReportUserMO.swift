//
//  ReportUserMO.swift
//  Maengelmelder
//
//  Created by Felix on 28.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(ReportUserMO)
class ReportUserMO: NSManagedObject {
    
    @NSManaged var public_name : String?
    @NSManaged var id : NSNumber
    
    convenience init(name: String, uid: NSNumber) {
        
        let context = MM.shared.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: CoreDataEntityNames.REPORT_USER, in: context)!
        
        self.init(entity: entity, insertInto: context)
        
        public_name = name
        id = uid
    }
}
