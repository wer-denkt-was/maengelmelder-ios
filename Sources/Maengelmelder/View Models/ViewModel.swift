//
//  ViewModel.swift
//  Maengelmelder
//
//  Created by Felix on 27.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit
import WebKit

protocol MapViewDelegate {
    func updateDomain(title: String, id: Int, lat: Double, lon: Double)
    func getMapRegion(completion: @escaping (BoundingBox) -> Void)
}

class ViewModel: NSObject, CLLocationManagerDelegate {
    
    fileprivate var reportsFromServer: [ReportMO]?
    fileprivate var delegate:MapViewDelegate?
    fileprivate var systems = Array<System>()
    
    fileprivate var fetchedSystem : System?
    
    fileprivate var locationManager: CLLocationManager
    
    fileprivate var domainLoaded = false
    fileprivate var domain:Domain?
    
    init (delegate: MapViewDelegate) {
        locationManager = CLLocationManager()
        super.init()        
        locationManager.delegate = self
        self.delegate = delegate
        
        if MMSettings.shared.loadDomainBeforeReports && !domainLoaded {
            self.loadDomain()
        }
    }
    
    func startInitialFetching() -> Bool {
        guard (reportsFromServer ?? []).isEmpty else {
            //Seems like initial fetching already happend
            return true
        }
        
        switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                return true
            case .authorizedWhenInUse, .authorizedAlways:
                delegate?.getMapRegion(completion: { (bb) in
                    self.fetchSystems(bb: bb)
                })
                return true
            case .denied, .restricted:
                return false
            @unknown default:
                print("error while authorization of location")
                return false
        }
    }
    
    func fetchSystems(bb: BoundingBox) {
        if MMSettings.shared.onlyShowDefaultDomain {
            self.fetchReports(neCoord: bb.ne, swCoord: bb.sw, system: System.fallback)
            return
        }
        
        MMApi.shared.getSystems(lat: bb.center.latitude, lon: bb.center.longitude) { systems, error in
            self.systems = systems ?? []
            self.fetchReportsForSystems(neCoord: bb.ne, swCoord: bb.sw, center: bb.center)
        }
    }
    
    private func fetchReportsForSystems(neCoord: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D, center: CLLocationCoordinate2D) {
        let hasExternal = self.systems.contains(where: { (system) -> Bool in
            return system.external
        })
        for sys in self.systems {
            if sys.external || !hasExternal {
                self.fetchReports(neCoord: neCoord, swCoord: swCoord, system: sys)
            }
        }
    }
    
    fileprivate func fetchReports (neCoord: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D, system: System) {
        if MMSettings.shared.loadDomainBeforeReports && !domainLoaded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.fetchReports(neCoord: neCoord, swCoord: swCoord, system: system)
            })
            return
        }
        
        MMApi.shared.getNearestMessages(boundingBox: BoundingBox(ne: neCoord, sw: swCoord), filter: (UserDefaults.standard.dictionary(forKey: "user_filter") ?? [:]), system: system) { data, error in
            guard let reports = data else {
                return
            }
            
            self.fetchedSystem = system
            self.reportsFromServer = reports
            if (reports.count > 0) {
                self.delegate?.updateDomain(title: reports.last?.domainName ?? "", id: reports.last?.domainid?.intValue ?? MMSettings.shared.DEFAULT_DOMAIN_ID, lat: neCoord.latitude, lon: neCoord.longitude)
            }
            self.applyFilterAndNotify(system: system)
            
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT, moc: MMCoreDataManager.shared.context)
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MMCoreDataManager.shared.context)
        }
    }
    
    func applyFilterAndNotify(system: System?) {
        var reportMarkers = Array<ReportMapMarker>()
        reportMarkers = GenericUtility.applyFilters(filters: UserDefaults.standard.dictionary(forKey: "user_filter") ?? [:], reports: self.reportsFromServer ?? []).map({ report in
            return report.markerGraphicForMap(system: system ?? self.fetchedSystem ?? System.fallback)
        })
        
        if reportMarkers.count > MMSettings.shared.maximumMarker {
            reportMarkers.removeLast(reportMarkers.count - MMSettings.shared.maximumMarker)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("reportMarkers"), object: reportMarkers, userInfo:nil)
        }
    }
    
    func loadDomain() {
        MMApi.shared.getDomain(lat: 0, lon: 0, system: System.fallback) { domain, error in
            self.domain = domain
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            self.domainLoaded = true
        }
    }
    
    //MARK: terms and privacy
    
    func isPrivacyAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: "privacy-v2")
    }
    
    func isTermsAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: "terms-v1")
    }
    
    func isWelcomeAccepted() -> Bool {
        return !MMSettings.shared.showWelcomeOnFirstStart || UserDefaults.standard.bool(forKey: "welcome-v1")
    }
    
    func loadInfoPage(webView: WKWebView, type: InfoPage.Kind) {
        if let page = GenericUtility.getInfoPage(for: type) {
            if page.loadFromHTML {
                let file = Bundle.main.path(forResource: page.type.rawValue.lowercased() + "_" + MMSettings.shared.APP_NAME.lowercased(), ofType: "html") ?? ""
                let textColor = webView.isDarkMode() ? "#FFFFFF" : "#000000"
                let content = try? String(contentsOfFile: file, encoding: .utf8).appending("<style>body{color: \(textColor)}</style>")
                webView.loadHTMLString(content ?? "ERROR", baseURL: URL(fileURLWithPath: file))
            } else {
                let url = URL(string: page.url ?? "")
                let request = URLRequest(url: url!)
                webView.load(request)
            }
        }
    }
    
    //MARK: view buttons actions
    
    func createNewReport () -> ReportCreationTabViewController {        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: "ReportCreationTabViewController") as! ReportCreationTabViewController
        vc.domain = self.domain
        return vc
    }
    
    func acceptTermsOrPrivacy() {
        if !UserDefaults.standard.bool(forKey: "welcome-v1") {
            UserDefaults.standard.set(true, forKey: "welcome-v1")
        } else if !UserDefaults.standard.bool(forKey: "terms-v1") {
            UserDefaults.standard.set(true, forKey: "terms-v1")
        } else if !UserDefaults.standard.bool(forKey: "privacy-v2") {
            UserDefaults.standard.set(true, forKey: "privacy-v2")
        }
    }
    
    //MARK: location manager delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedAlways {
            _ = startInitialFetching()
        }
    }
}
