//
//  InternetUtility.swift
//
//  Copyright © 2024 WDW. All rights reserved.
//

import Reachability
import Foundation

protocol InternetUtilityDelegate {
    func onlineStatusChanged(_ isOnline: Bool)
}

class InternetUtility {
    
    static let shared = InternetUtility()
        
    var delegate : InternetUtilityDelegate?
    
    private let reachability : Reachability
    private var hasConnection = true
    private var manualOfflineMode = false
    private var loadedOfflineData = false
        
    init() {
        //declare this property where it won't go out of scope relative to your listener
        reachability = try! Reachability()
        
        reachability.whenReachable = { reachability in
            self.hasConnection = true
            
            if !self.loadedOfflineData {
                self.loadOfflineData()
            }
            self.delegate?.onlineStatusChanged(self.isOnline())
        }
        reachability.whenUnreachable = { _ in
            self.hasConnection = false
            self.delegate?.onlineStatusChanged(self.isOnline())
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func isOnline() -> Bool {
        return !manualOfflineMode && hasConnection
    }
    
    func loadOfflineData() {
        MMCoreDataManager.deleteData(entityName: "ReportType", pradicate: NSPredicate(format: "domainID == %d AND rt_description = nil", MMSettings.shared.DEFAULT_DOMAIN_ID), moc: MMCoreDataManager.shared.context)
        
        MMApi.shared.getCategories(domainID: MMSettings.shared.DEFAULT_DOMAIN_ID, system: System.fallback, completion: { types, error in
            // Delete only if it is successful
            if error == nil {
                self.loadedOfflineData = true
                MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                
                // Save the date
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                UserDefaults.standard.set(formatter.string(from: Date()), forKey: "offlineDataLastUpdate")
            } else {
                print("Error loading offline data: \(String(describing: error))")
            }
        })
    }
    
    func setManualOfflineMode(_ isOffline: Bool) {
        self.manualOfflineMode = isOffline
        self.delegate?.onlineStatusChanged(self.isOnline())
    }
    
    func getManualOfflineMode() -> Bool {
        return manualOfflineMode
    }
    
    func isOfflineDataAvailable() -> Bool {
        return MMCoreDataManager.isEntityDataAvailable(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
    }
}
