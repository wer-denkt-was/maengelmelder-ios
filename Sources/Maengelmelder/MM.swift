//
//  AppDelegate.swift
//  MM
//
//  Created by Felix on 30.01.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

public class MM {
    
    /** The shared instance to access the Maengelmelder-Module*/
    public static let shared = MM()

    var dbName: String = ""
    var errorHandler: (Error) -> Void = {_ in }
    
    public let bundle = Bundle.module
    
    /**
     Returns the ViewController to start the Module.
     */
    public func start(with url: URL? = nil) -> UIViewController? {
        UserDefaults.standard.removeObject(forKey: "user_filter")
        UserDefaults.standard.removeObject(forKey: "fuss_list_page")
        UserDefaults.standard.removeObject(forKey: "fuss_filter_checknumber")
        
        let s = UIStoryboard(name: "MMMain", bundle: bundle)
        let vc = s.instantiateInitialViewController() as? UINavigationController
        (vc?.viewControllers.first as? ViewController)?.openUrl = url
        return vc
    }
    
    /**
     Delete all locally saved data.
     */
    public func reset() {
        let reports = MMCoreDataManager.fetchData(entityName: "Report", pradicate: NSPredicate(format: "isLocal == %d", 1), moc: MMCoreDataManager.shared.context) as? [ReportMO]
        for report in reports ?? [] {
            let imagesPaths = report.attachments.array as! [String]
            
            for path in imagesPaths {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        
        MMCoreDataManager.deleteData(entityName: "Report", pradicate: nil, moc: MMCoreDataManager.shared.context)
        
        MMCoreDataManager.deleteData(entityName: "ReportType", pradicate: nil, moc: MMCoreDataManager.shared.context)
    }
    
    private func getCacheNameForScheme() -> String {        
        return MMSettings.shared.APP_NAME + "Cache"
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jqsoftware.MMDataModel" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = bundle.url(forResource: "MM", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent(getCacheNameForScheme())
        
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url,
                                               options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                                         NSInferMappingModelAutomaticallyOption: true])
            
        } catch {
            // Report any error we got.
            NSLog("CoreData error \(error), \(String(describing: error._userInfo))")
            self.errorHandler(error)
        }
        
        return coordinator
    }()
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var mainManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainManagedObjectContext.persistentStoreCoordinator = coordinator
        mainManagedObjectContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        return mainManagedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = self.managedObjectContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

