//
//  MMCoreDataManager.swift
//
//  Created by Felix on 28.03.18.
//  Copyright © 2024 WDW. All rights reserved.

import Foundation
import CoreData
import UIKit

public class MMCoreDataManager {
    
    public static let shared = MMCoreDataManager()
    
    public let context:NSManagedObjectContext
    
    init() {
        context = MM.shared.managedObjectContext
    }
    
    class func fetchData(entityName : String, pradicate: NSPredicate?, moc: NSManagedObjectContext) -> [Any] {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        if(pradicate != nil && pradicate!.predicateFormat != "") {
            fetchRequest.predicate = pradicate
        }
        
        var results : [Any] = []
        
        do {
            results = try moc.fetch(fetchRequest)
        } catch {
            print("Failed to fetch " + entityName + " entity : \(error)")
        }
        
        return results
    }
    
    public class func deleteData(entityName : String, pradicate: NSPredicate?, moc: NSManagedObjectContext) {        
        let results = fetchData(entityName: entityName, pradicate: pradicate, moc: moc)
        
        for object in results {
            moc.delete(object as! NSManagedObject)
        }
        
        saveContext(entityName: entityName, moc: moc)
    }
    
    public class func saveContext (entityName : String, moc: NSManagedObjectContext) {
        do {
            try moc.save()
        } catch {
            print(error)
            print("Core data manager .... Failure to save ")// + entityName + " in context: \(error)")
        }
    }
    
    class func isEntityDataAvailable (entityName : String, moc: NSManagedObjectContext) -> Bool {
        
        let results = fetchData(entityName: entityName, pradicate: nil, moc: moc)
        
        if (results.count > 0) {
            return true
        }
        
        return false
    }
    
    class func cleanDBofOldReports(moc: NSManagedObjectContext) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Report")
        fetch.predicate = NSPredicate(format: "isLocal = %d AND id > %d", 0, 0)
        fetch.sortDescriptors = [NSSortDescriptor(key: "lastSeen", ascending: true)]
        var reports = ((try? moc.fetch(fetch)) as? [ReportMO]) ?? Array<ReportMO>()
        
        var toRemove : [Int] = []
        for i in 0..<reports.count {
            if reports[i].reportType?.id == nil {
                toRemove.append(i)
            }
        }
        
        while reports.count > 100 {
            let report = reports.removeFirst()
            moc.delete(report)
        }
        
    }
}
