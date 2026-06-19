//
//  ReportListViewModel.swift
//  MM
//
//  Created by Felix on 28.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData

class ReportListViewModel: NSObject, UITableViewDataSource {
    
    enum SortOption {
        case Name
        case Typ
        case State
    }
    
    private let controller:ReportListViewController
    private var reports = Array<ReportMO>()
    private var filterdReports = Array<ReportMO>()
    	
    private var system: System?
    
    init(_ vc: ReportListViewController, group: ReportGroup?) {
        self.controller = vc
        super.init()
        
        if group == nil {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Report")
            fetch.predicate = NSPredicate(format: "(isLocal = 0 OR isLocal = 2) AND (id > %d) AND (domainid = %d)", 0, controller.currentDomainID)
            fetch.sortDescriptors = [NSSortDescriptor(key: "lastSeen", ascending: false)]
            reports = ((try? MMCoreDataManager.shared.context.fetch(fetch)) as? [ReportMO]) ?? Array<ReportMO>()
            filterdReports.append(contentsOf: self.reports)
        } else {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Report")
            fetch.predicate = NSPredicate(format: "id IN %@", group!.getReports().map({ (marker) -> Int in
                return marker.reportID.intValue
            }))
            fetch.sortDescriptors = [NSSortDescriptor(key: "lastSeen", ascending: false)]
            reports = ((try? MMCoreDataManager.shared.context.fetch(fetch)) as? [ReportMO]) ?? Array<ReportMO>()
            filterdReports.append(contentsOf: self.reports)
        }
        
        self.fetchSystems()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("filter_settings"), object: nil, queue: nil) { (notification) in
            if let userInfo = notification.userInfo as? Dictionary<String, Any> {
                self.filterdReports = GenericUtility.applyFilters(filters: userInfo, reports: self.reports)
            }
        }
        
        self.filterdReports = GenericUtility.applyFilters(filters: UserDefaults.standard.dictionary(forKey: "user_filter") ?? [:], reports: self.reports)
    }
    
    private func fetchSystems() {
        MMApi.shared.getSystems(lat: controller.currentLat, lon: controller.currentLon) { systems, error in
            self.searchForDomain(systems: systems ?? [])
        }
    }
    
    private func searchForDomain(systems: [System]) {
        let lat = controller.currentLat
        let lon = controller.currentLon
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        for sys in systems {
            if sys.external || !hasExternal {		
                MMApi.shared.getDomain(lat: lat, lon: lon, system: sys) { domain, error in
                    MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                    if self.controller.currentDomainID == domain?.getID() {
                        self.system = sys
                    }
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterdReports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let report = self.filterdReports[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell") as! ReportTableViewCell
        cell.idLabel.text = String.init(format: LocalizedString("MESSAGE_DETAIL_PAGE_TITLE", comment: ""), report.id.intValue)
        
        var name = report.typeName ?? ""
        if var index = name.firstIndex(of: ">") {
            if String(name[index...]).starts(with: " ") {
                index = name.index(index, offsetBy: 2)
            } else {
                index = name.index(index, offsetBy: 1)
            }
            name = String(name[index...])
        }
        cell.favImage.isHidden = report.isLocal != 2
        cell.favImage.tintColor = tableView.isDarkMode() ? MMColorScheme.shared.getColor(view: cell, type: .secondaryAppTheme) : MMColorScheme.shared.getColor(view: cell, type: .appTheme)

        if report.text != nil && !report.text!.isEmpty {
            cell.titleLabel.text = report.text
            cell.subtitleLabel.text = name + " | " + (report.state_german ?? "")
        } else {
            cell.titleLabel.text = name + " | " + (report.state_german ?? "")
            cell.subtitleLabel.text = ""
        }
        
        cell.markerView.image = CategoryConfig.getMarkerTo(report: report)
        
        return cell
    }
    
    func didSelectRowAt(indexPath: IndexPath) -> UIAlertController {
        let report = self.filterdReports[indexPath.row]
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: LocalizedString("REPORT_LIST_SHOW_DETAILS", comment: ""), style: .default, handler: { (action) in
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportDetailController") as! ReportDetailViewController
            vcToPush.reportId = report.id
            vcToPush.domainId = report.domainid
            vcToPush.system = self.system ?? System(appid: MMSettings.shared.APP_ID, host: MMApi.shared.SERVER_URL, name: "", external: false)
            self.controller.navigationController?.pushViewController(vcToPush, animated: true)
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("REPORT_LIST_SHOW_ON_MAP", comment: ""), style: .default, handler: { (action) in
            let not = Notification(name: Notification.Name("newLocation"), object: self, userInfo: ["lat":report.lat.doubleValue, "lon":report.long.doubleValue, "id":report.id.intValue])
            NotificationCenter.default.post(not)
            self.controller.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("REPORT_LIST_MARK_FAVORIT", comment: ""), style: .default, handler: { (action) in
            report.isLocal = report.isLocal == 0 ? 2 : 0
            self.controller.tableView.reloadRows(at: [indexPath], with: .none)
            MMCoreDataManager.saveContext(entityName: "Report", moc: MMCoreDataManager.shared.context)
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        return alert
    }
    
    func sort(_ option: SortOption) {
        switch option {
        case .Name:
            self.filterdReports.sort { (r1, r2) -> Bool in
                return r1.text?.compare(r2.text ?? "") == .orderedAscending
            }
        case .State:
            self.filterdReports.sort { (r1, r2) -> Bool in
                return r1.state?.compare(r2.state ?? "") == .orderedAscending
            }
        case .Typ:
            self.filterdReports.sort { (r1, r2) -> Bool in
                return r1.marker_id.compare(r2.marker_id) == .orderedAscending
            }
        }
    }

}
