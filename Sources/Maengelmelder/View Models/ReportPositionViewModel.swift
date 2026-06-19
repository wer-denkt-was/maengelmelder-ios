//
//  ReportPositionViewModel.swift
//  Maengelmelder
//
//  Created by Felix on 29.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import JGProgressHUD

class ReportPositionViewModel {
    
    fileprivate var viewsParentController: ReportCreationTabViewController?
    
    init(parentController: ReportCreationTabViewController) {
        self.viewsParentController = parentController
    }
    
    func updateReport(lat: NSNumber, long: NSNumber, address: String) {
        self.viewsParentController!.report!.address = address
        self.viewsParentController!.report!.lat = lat
        self.viewsParentController!.report!.long = long
        
        if !MMSettings.shared.showTypesFirst {
            if let reportType = self.viewsParentController?.report?.reportType {
                reportType.rt_description = "cloned"
                self.viewsParentController?.report?.reportType = nil
                self.viewsParentController?.report?.marker_id = 0
            }
        }
    }
    
    func getReportPosition () -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: viewsParentController!.report!.lat.doubleValue, longitude: viewsParentController!.report!.long.doubleValue)
    }
    
    func checkDuplicates(jghud: JGProgressHUD? = nil) {
        let lat = viewsParentController?.report?.lat.doubleValue ?? 0
        let lon = viewsParentController?.report?.long.doubleValue ?? 0
        
        //Do not check duplicates if we have no location
        guard let report = self.viewsParentController?.report, let type = report.reportType, type.position != "never" else {
            self.viewsParentController?.goToNextTab()
            return
        }
        
        guard report.isOffline == 0 else {
            self.viewsParentController?.goToNextTab()
            return
        }
        
        let hud:JGProgressHUD
        if jghud == nil {
            hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Prüfe auf Duplikate..."
            hud.show(in: self.viewsParentController!.view, animated: true)
        } else {
            hud = jghud!
        }
        
        MMApi.shared.getDuplicates(lat: lat, lon: lon, categoryid: type.id?.intValue ?? 0, domainid: viewsParentController?.domain?.getID() ?? MMSettings.shared.DEFAULT_DOMAIN_ID, system: viewsParentController?.system) { reports, error in
            if let duplicates = reports, duplicates.count > 0 {
                hud.dismiss(animated: true)
                
                let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
                let vcToPush = storyboard.instantiateViewController(withIdentifier: "DuplicatesViewController") as! DuplicatesViewController
                vcToPush.duplicates = duplicates
                vcToPush.title = "Duplikate"
                vcToPush.system = self.viewsParentController?.system ?? System.fallback
                self.viewsParentController?.navigationController?.pushViewController(vcToPush, animated: true)
                self.viewsParentController?.goToNextTab()
            } else {
                hud.dismiss(animated: true)
                self.viewsParentController?.goToNextTab()
            }
        }
    }
}
