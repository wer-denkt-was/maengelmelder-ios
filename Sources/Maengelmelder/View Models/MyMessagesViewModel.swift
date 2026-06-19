//
//  MyMessagesViewModel.swift
//  MM
//
//  Created by Felix on 13.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import JGProgressHUD

class MyMessagesViewModel: NSObject, UITableViewDataSource {
    
    fileprivate var uploadedMaengel = Array<ReportMO>()
    fileprivate var notUploadedMaengel = Array<ReportMO>()
    fileprivate var uploadedIdeas = Array<ReportMO>()
    fileprivate var notUploadedIdeas = Array<ReportMO>()
    fileprivate var fetchRequests = Array<() -> Void>()
    fileprivate let uploadUtil : UploadUtility?
    
    fileprivate var loadedSystems = Dictionary<Int, System>()
    
    fileprivate var numberToFetch = 0
    fileprivate var numberFetched = 0
    
    private var tableView: UITableView?
    private var loadingView : UIView?
    
    private var isIdea = false
    
    override init() {
    
        self.uploadUtil = UploadUtility()
        super.init()
        //self.fetchReportsFromCoreData()
    }
    
    func reload(loadingView: UIView) {
        self.loadingView = loadingView
        self.loadingView?.isHidden = false
        self.fetchReportsFromCoreData()
    }
    
    func setIdea(_ isIdea: Bool) {
        self.isIdea = isIdea
    }
    
    fileprivate func fetchReportsFromCoreData(){        
        notUploadedIdeas.removeAll()
        notUploadedMaengel.removeAll()
        uploadedIdeas.removeAll()
        uploadedMaengel.removeAll()
        
        numberFetched = 0
        numberToFetch = 0
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Report")
        fetch.predicate = NSPredicate(format: "isLocal == %d", 1)
        if let array = try? MM.shared.managedObjectContext.fetch(fetch) as? [ReportMO] {
            for report in array {
                if report.state == GlobalFlagValues.REPORT_CREATED_STATE {
                    if GlobalArrays.MODE_IDEA_CATEGORIES.contains(report.reportType?.id?.intValue ?? 0) {
                        notUploadedIdeas.append(report)
                    } else {
                        notUploadedMaengel.append(report)
                    }
                } else {
                    if !MMSettings.shared.isIdeaModuleActivated {
                        self.uploadedMaengel.append(report)
                    }
                    
                    numberToFetch += 1
                    self.fetchRequests.append {
                        if let system = self.loadedSystems[report.domainid?.intValue ?? 32] {
                            self.updateReport(report: report, system: system) {
                                self.numberFetched += 1
                                if self.fetchRequests.count > 0 {
                                    self.fetchRequests.removeFirst()()
                                }
                            }
                        } else {
                            self.fetchSystems(report: report) { (sys) in
                                let system = sys ?? System.fallback
                                self.loadedSystems[report.domainid?.intValue ?? 32] = system
                                self.updateReport(report: report, system: system) {
                                    self.numberFetched += 1
                                    if self.fetchRequests.count > 0 {
                                        self.fetchRequests.removeFirst()()
                                    }
                                }
                            }
                        }
                    }
                    if numberToFetch == 1 {
                        self.fetchRequests.removeFirst()()
                    }
                }
                
            }
        }
        self.checkIfAllFetched()
    }
    
    private func checkIfAllFetched() {
        if numberFetched == numberToFetch {
            self.tableView?.reloadSections([1], with: .automatic)
            self.loadUploadedFromServer()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkIfAllFetched()
            }
        }
    }
    
    private func loadUploadedFromServer() {
        if UserDefaults.standard.string(forKey: "token") != nil {
            // Use the system object saved in UserDefaults. Case for domains outside the main system
            var system: System? = nil
            let systemData = UserDefaults.standard.data(forKey: "user.system")
            do {
                let decoder = JSONDecoder()
                if systemData != nil {
                    system = try decoder.decode(System.self, from: systemData!)
                }
            } catch {
                system = nil
            }
            MMApi.shared.getMessagesForList(checkNumber: nil, owner: UserDefaults.standard.string(forKey: "user.id"), page: 1, system: system) { reports, error in
                for report in reports ?? [] {
                    if GlobalArrays.MODE_IDEA_CATEGORIES.contains(report.reportType?.id?.intValue ?? 0) {
                        self.uploadedIdeas.append(report)
                    } else {
                        self.uploadedMaengel.append(report)
                    }
                }
                self.tableView?.reloadSections([1], with: .automatic)
                self.loadingView?.isHidden = true
            }
        } else {
            self.loadingView?.isHidden = true
        }
    }
    
    private func updateReport(report: ReportMO, system: System, completion: @escaping () -> Void) {
        MMApi.shared.getMessageDetail(id: report.id.intValue, domainid: report.domainid?.intValue ?? 32, system: system) { detailsO, error in
            if let details = detailsO {
                report.marker_color = details.markerColor
                report.state_german = details.state
                report.typeName = details.details[1].value
                
                if GlobalArrays.MODE_IDEA_CATEGORIES.contains(details.typeid) {
                    self.uploadedIdeas.append(report)
                }
            }
            completion()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.tableView = tableView
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isIdea ? notUploadedIdeas.count : notUploadedMaengel.count
        } else {
            return isIdea ? uploadedIdeas.count : uploadedMaengel.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let report = isIdea ? notUploadedIdeas[indexPath.row] : notUploadedMaengel[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell", for: indexPath) as! MyMessagesTableViewCell
            cell.titleLabel.text = ((report.reportType?.has_title ?? 0) == 1) ? report.title : report.text
            cell.markerView.image = UIImage(named: String(format:"marker-%@-%d.png", report.marker_color ?? "white", report.marker_id.intValue), in: MM.shared.bundle, compatibleWith: nil) ?? UIImage()
            
            let color = tableView.isDarkMode() ? MMColorScheme.shared.getColor(view: cell, type: .secondaryAppTheme) : MMColorScheme.shared.getColor(view: cell, type: .appTheme)
            cell.step1View.tintColor = color
            cell.step2View.tintColor = report.attachments.count > 0 ? color : UIColor.lightGray
            cell.step3View.tintColor = report.reportType?.name == nil ? UIColor.lightGray : color
            cell.step4View.tintColor = (((report.reportType?.has_title ?? 0) == 0 ||  report.title != nil) && report.text != nil) ? color : UIColor.lightGray
            
            cell.accessibilityTraits = .button
            cell.accessibilityLabel = "Erstellte Meldung \(report.reportType != nil ? "mit" : "ohne") Kategorie \(report.reportType?.name ?? "")"
            
            return cell
        } else {
            let report = isIdea ? uploadedIdeas[indexPath.row] : uploadedMaengel[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "uploadedReportCell", for: indexPath) as! ReportTableViewCell
            cell.idLabel.text = String.init(format: LocalizedString("MESSAGE_DETAIL_PAGE_TITLE", comment: ""), report.id.intValue)
            cell.titleLabel.text = report.text
            
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
            
            var state = report.state == GlobalFlagValues.REPORT_UPLOADED_STATE ? "Hochgeladen" : (report.state_german ?? "")
            if state.isEmpty {
                state = "Hochgeladen"
            }
            
            cell.accessibilityTraits = .button
            
            cell.subtitleLabel.text = name + " | " + state
            cell.markerView.image = UIImage(named: String(format:"marker-%@-%d.png", report.marker_color ?? "white", report.marker_id.intValue), in: MM.shared.bundle, compatibleWith: nil) ?? UIImage()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && self.tableView(tableView, numberOfRowsInSection: section) > 0 {
            return "Noch nicht hochgeladen"
        } else if self.tableView(tableView, numberOfRowsInSection: section) > 0 {
            return "Hochgeladen"
        } else {
            return nil
        }
    }
    
    func editReport (indexPath : IndexPath, tab : Int = 0) -> ReportCreationTabViewController {
        let report = isIdea ? notUploadedIdeas[indexPath.row] : notUploadedMaengel [indexPath.row]
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: "ReportCreationTabViewController") as! ReportCreationTabViewController
        vc.screenMode = self.isIdea ? GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA : GlobalFlagValues.REPORT_SCREEN_EDIT_MODE
        vc.report = report
        vc.startIndex = tab
        return vc
    }
    
    func deleteReport(indexPath: IndexPath) {
        let report = indexPath.section == 0 ? (isIdea ? notUploadedIdeas.remove(at: indexPath.row) : notUploadedMaengel.remove(at: indexPath.row)) : (isIdea ? uploadedIdeas.remove(at: indexPath.row) : uploadedMaengel.remove(at: indexPath.row))
            
        let imagesPaths = report.attachments.array as! [String]
        
        for path in imagesPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
    
        MMCoreDataManager.deleteData(entityName: "Report", pradicate: NSPredicate(format: "id == \(report.id.intValue)"), moc: MMCoreDataManager.shared.context)
    }
    
    func showDetails(indexPath: IndexPath, compleation: @escaping (UIViewController) -> Void) {
        let report = isIdea ? uploadedIdeas[indexPath.row] : uploadedMaengel[indexPath.row]

        self.fetchSystems(report: report, compleation: { system in
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "ReportDetailController") as! ReportDetailViewController
            vc.reportId = report.id
            vc.domainId = report.domainid ?? MMSettings.shared.DEFAULT_DOMAIN_ID as NSNumber
            vc.system = system
            compleation(vc)
        })
    }
    
    func getDomainName(_ indexPath: IndexPath) -> String {
        let report = isIdea ? notUploadedIdeas[indexPath.row] : notUploadedMaengel[indexPath.row]
        return report.domainName ?? "Mängelmelder.de"
    }
    
    func uploadReportToserver (indexPath : IndexPath,  viewForHud: UIView, compleation: @escaping (Bool) -> Void) {
        let report = isIdea ? notUploadedIdeas[indexPath.row] : notUploadedMaengel[indexPath.row]
        
        self.fetchSystems(report: report, compleation: { system in
            self.uploadUtil!.uploadReport(report: report, system: system ?? System.fallback, viewForHud: viewForHud, compleation:  { (Bool) in
                self.fetchReportsFromCoreData()
                compleation(Bool)
            })
        })
    }
    
    /**
     Checks if the message is in the domain associated with the current APPID.
     */
    func checkCategoryAtPosition(indexPath: IndexPath, system: System?, callback: @escaping (Bool) -> Void) {
        let report = isIdea ? notUploadedIdeas[indexPath.row] : notUploadedMaengel[indexPath.row]
        
        guard report.isOffline == 1 || MMSettings.shared.showTypesFirst else {
            callback(true)
            return
        }
        
        if (report.reportType?.position ?? "") == "never" || MMSettings.shared.disableCategoryCheckOnPosition {
            callback(true)
            return
        }
        
        if system == nil {
            self.fetchSystems(report: report) { system in
                callback(system != nil)
            }
            return
        }        
        
        let lat = report.lat.doubleValue
        let lon = report.long.doubleValue
        
        MMApi.shared.getDomain(lat: lat, lon: lon, system: system, appid: 1) { domainO, error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            if let domain = domainO {
                if domain.getID() == report.reportType?.domainID?.intValue {
                    for type in domain.getTypes() {
                        if type.id == report.reportType?.id {
                            callback(true)
                            return
                        }
                    }
                }
            }
            callback(false)
            return
        }
    }
    
    private func fetchSystems(report: ReportMO, compleation: @escaping (System?) -> Void) {
        MMApi.shared.getSystems(lat: report.lat.doubleValue, lon: report.long.doubleValue) { systems, _ in
            self.searchForDomain(systems: systems ?? [], report: report) { system in
                compleation(system)
            }
        }
    }
    
    private func searchForDomain(systems: [System], report: ReportMO, compleation: @escaping (System?) -> Void) {
        let lat = report.lat.doubleValue
        let lon = report.long.doubleValue
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        for sys in systems {
            if sys.external || !hasExternal {
                MMApi.shared.getDomain(lat: lat, lon: lon, system: sys) { domain, error in
                    MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                    if report.domainid?.intValue ?? MMSettings.shared.DEFAULT_DOMAIN_ID == domain?.getID() {
                        compleation(sys)
                    } else {
                        compleation(nil)
                    }
                }
            }
        }
    }
}

