//
//  ReportCommentMO.swift
//  Maengelmelder
//
//  Created by Felix on 28.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(ReportCommentMO)
class ReportCommentMO: NSManagedObject {
    
    @NSManaged var text : String?
    @NSManaged var id : NSNumber
    
    convenience init(ctext: String, cid: NSNumber) {
        
        let context = MM.shared.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: CoreDataEntityNames.REPORT_COMMENT, in: context)!
        
        self.init(entity: entity, insertInto: context)
        
        text = ctext
        id = cid
    }
}
