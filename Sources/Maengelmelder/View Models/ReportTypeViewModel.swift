//
//  ReportTypeViewModel.swift
//  Maengelmelder
//
//  Created by Felix on 04.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import JGProgressHUD

class ReportTypeViewModel : NSObject, UITableViewDataSource, UITableViewDelegate {
    
    fileprivate var viewsParentController: ReportCreationTabViewController?
    fileprivate let rubricInfoLabel: UILabel
    fileprivate let rubricInfoHeightConstraint: NSLayoutConstraint
    fileprivate let rubricButton : UIButton
    fileprivate let rubricInfoContainer : UIView
    
    private var tableView : UITableView?
    
    fileprivate var mapDomainToSystem = Dictionary<Int, System>()
    fileprivate var reportTypes = Dictionary<Int, [ReportTypeMO]>()
    fileprivate var filteredTypes = Array<ReportTypeMO>()
    fileprivate var selectedDomain = MMSettings.shared.DEFAULT_DOMAIN_ID
    
    fileprivate var searchedTypes : Array<(name: String, types: Array<ReportTypeMO>)>?
    
    fileprivate var oldTypeId : NSNumber? {
        return viewsParentController?.report?.reportType?.id
    }
    
    var oldTypeIndexPath : IndexPath?
    var openFuss = true
    var offline = false
    
    fileprivate var selectedRubric : String?
    fileprivate var selectedGroup : String?
    
    fileprivate var typesInCategories = Dictionary<Int, Array<(name: String, types: Array<ReportTypeMO>)>>()
    fileprivate var filteredCategories = Array<(name: String, types: Array<ReportTypeMO>)>()
    
    init(parentController: ReportCreationTabViewController, rubricInfoContainer: UIView, rubricInfoLabel: UILabel, rubricButton: UIButton, rubricHeightConstraint: NSLayoutConstraint) {
        self.viewsParentController = parentController
        self.rubricInfoLabel = rubricInfoLabel
        self.rubricButton = rubricButton
        self.rubricInfoHeightConstraint = rubricHeightConstraint
        self.rubricInfoContainer = rubricInfoContainer
    }
    
    func fetchSystems(_ compleation: @escaping () -> Void) {
        self.filteredTypes.removeAll()
        if !InternetUtility.shared.isOnline() {
            self.offline = true
            //Default Domain Settings
            let pradicate = NSPredicate(format: "domainID = %d", MMSettings.shared.DEFAULT_DOMAIN_ID)
            let results = MMCoreDataManager.fetchData(entityName: CoreDataEntityNames.REPORT_TYPE, pradicate: pradicate, moc: MMCoreDataManager.shared.context) as! [ReportTypeMO]
            var types : [ReportTypeMO] = []
            for t in results {
                if !types.contains(where: { type in
                    return type.id == t.id
                }) {
                    types.append(t)
                }
            }
            
            let domain = Domain(isDefault: true, domainID: MMSettings.shared.DEFAULT_DOMAIN_ID, domainName: MMSettings.shared.APP_NAME, types: types)
            
            self.fetchedDomain(domain, system: System.fallback)
            self.buildExpandableArray(domainid: self.selectedDomain)
            compleation()
        } else {
            self.offline = false
            let lat = viewsParentController?.report?.lat.doubleValue ?? 0
            let lon = viewsParentController?.report?.long.doubleValue ?? 0
            MMApi.shared.getSystems(lat: lat, lon: lon) { systems, error in
                self.fetchDomains(lat: lat, lon: lon, systems: systems  ?? [], compleation: compleation)
            }
        }
    }
    
    private func fetchDomains(lat: Double, lon: Double, systems: [System], compleation: @escaping () -> Void) {
        self.reportTypes.removeAll()
        self.mapDomainToSystem.removeAll()
        self.selectedRubric = nil
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        let numberOfCalls = hasExternal ? systems.count-1 : systems.count
        var finishedCalls = 0
        for sys in systems {
            if sys.external || !hasExternal {
                MMApi.shared.getDomain(lat: lat, lon: lon, system: sys, appid: MMSettings.shared.APP_ID == 1 ? nil : MMSettings.shared.APP_ID) { domainO, error in
                    
                    MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MMCoreDataManager.shared.context)
                    if let domain = domainO {
                        self.fetchedDomain(domain, system: sys)
                        
                        finishedCalls=finishedCalls+1
                        if(finishedCalls == numberOfCalls) {	
                            self.buildExpandableArray(domainid: self.selectedDomain)
                            compleation()
                        }
                    }
                }
            }
        }
    }
    
    private func fetchedDomain(_ domain: Domain, system: System) {
        self.selectedDomain = domain.getID()
        self.viewsParentController?.domain = domain
        
        for type in domain.getTypes() {
            
            if !(self.mapDomainToSystem.keys.contains(type.domainID?.intValue ?? 0)) {
                self.mapDomainToSystem[type.domainID?.intValue ?? 0] = system
            }
            if !(self.reportTypes.keys.contains(type.domainID?.intValue ?? 0)) {
                self.reportTypes[type.domainID?.intValue ?? 0] = Array<ReportTypeMO>()
            }
            if (self.viewsParentController?.screenMode == GlobalFlagValues.REPORT_SCREEN_NEW_IDEA || self.viewsParentController?.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA) {
                if (GlobalArrays.MODE_IDEA_CATEGORIES.contains(type.id?.intValue ?? 0) ) {
                    self.reportTypes[type.domainID?.intValue ?? 0]?.append(type.clone(context: MMCoreDataManager.shared.context))
                }
            } else {
                if !(GlobalArrays.MODE_IDEA_CATEGORIES.contains(type.id?.intValue ?? 0) ) {
                    self.reportTypes[type.domainID?.intValue ?? 0]?.append(type.clone(context: MMCoreDataManager.shared.context))
                }
            }
        }
        
        // If only default domainid, only build types for that domain
        for (id, _) in self.mapDomainToSystem {
            if (!MMSettings.shared.onlyShowDefaultDomain || id == MMSettings.shared.DEFAULT_DOMAIN_ID) {
                self.buildExpandableArray(domainid: id)
            }
        }
        
        if MMSettings.shared.onlyShowDefaultDomain && domain.getID() != MMSettings.shared.DEFAULT_DOMAIN_ID {
            self.typesInCategories[domain.getID()]?.removeAll()
            self.reportTypes[domain.getID()]?.removeAll()
        }
        
        if let type = self.viewsParentController?.report?.reportType, hasRubric(domainid: selectedDomain) {
            selectRubric(type.rubric)
            if type.group != nil && !type.group!.isEmpty {
                selectGroup(type.group)
            }
        }
    }
    
    private func buildExpandableArray(domainid: Int) {
        if (MMSettings.shared.onlyShowDefaultDomain && domainid != MMSettings.shared.DEFAULT_DOMAIN_ID) {
            return
        }
        
        guard self.needsExpandableList(domainid: domainid) else {
            self.reportTypes[domainid]?.sort(by: { (r1, r2) -> Bool in
                return (r1.name ?? "").compare(r2.name ?? "") == .orderedAscending
            })
            self.filteredTypes = (self.reportTypes[domainid] ?? []).filter({ type in
                return self.selectedRubric == nil || self.selectedRubric == type.rubric
            })
            return
        }
        
        self.typesInCategories[domainid] = Array<(name: String, types: Array<ReportTypeMO>)>()
        var dict = Dictionary<String, Array<ReportTypeMO>>()
        for t in self.reportTypes[domainid] ?? [] {
            if let catName = t.group {
                if dict.keys.contains(catName) {
                    dict[catName]?.append(t)
                } else {
                    dict[catName] = [t]
                }
            }	
        }
        
        for (key, value) in dict {
            let sorted = value.sorted { (r1, r2) -> Bool in
                return (r1.name ?? "").compare(r2.name ?? "") == .orderedAscending
            }
            self.typesInCategories[domainid]?.append((name: key, types: sorted))
        }
        
        self.typesInCategories[domainid]?.sort(by: { (e1, e2) -> Bool in
            return e1.name.compare(e2.name) == .orderedAscending
        })
        var filteredCategory = Array<(name: String, types: Array<ReportTypeMO>)>()
        for category in typesInCategories[domainid] ?? [] {
            let filtered = category.types.filter { type in
                return self.selectedRubric == nil || type.rubric == self.selectedRubric
            }
            if filtered.count > 0 {
                filteredCategory.append((category.name, filtered))
            }
        }
        self.filteredCategories = filteredCategory
        self.filteredCategories.sort(by: { (e1, e2) -> Bool in
            let cat1Max = e1.types.max(by: { (r1, r2) -> Bool in
                return r1.ordering?.intValue ?? 0 > r2.ordering?.intValue ?? 0
            })
            let cat2Max = e2.types.max(by: { (r1, r2) -> Bool in
                return r1.ordering?.intValue ?? 0 > r2.ordering?.intValue ?? 0
            })
            return cat2Max?.ordering?.intValue ?? 0 > cat1Max?.ordering?.intValue ?? 0
        })        
    }
    
    func getSelectedDomainName() -> String {
        return self.reportTypes[selectedDomain]?.first?.domainTitle ?? "Mängelmelder"
    }
    
    func getSelectedDomainID() -> Int {
        return selectedDomain
    }
    
    func hasMultipleDomains() -> Bool {
        return reportTypes.filter({ domain in
            return domain.value.count > 0
        }).count > 1
    }
    
    func isEmpty() -> Bool {
        for domainid in self.mapDomainToSystem.keys {
            if (needsExpandableList(domainid: domainid) && !self.typesInCategories[domainid]!.isEmpty) { return false }
            if (!needsExpandableList(domainid: domainid) && !self.reportTypes[domainid]!.isEmpty) { return false }
        }
        return true
    }
    
    func needsReload() -> Bool {
        if isEmpty() {
            return true
        }
        if self.reportTypes[self.selectedDomain]?.first?.name == nil {
            for (_, list) in self.reportTypes {
                for type in list {
                    do {
                        _ = try MMCoreDataManager.shared.context.existingObject(with: type.objectID) as? ReportTypeMO
                        //print(refreshedType ?? "")
                    } catch let error {
                        print(error.localizedDescription)
                    }
                    
                }
            }
            return false
        }
        
        return false
    }
    
    func updateReportType(_ indexPath: IndexPath?) {
        if let path = indexPath {
            self.viewsParentController?.report?.domainid = self.selectedDomain as NSNumber
            self.viewsParentController?.report?.isOffline = self.offline ? 1 : 0
            
            let newType:ReportTypeMO?
            if searchedTypes != nil {
                newType = searchedTypes![path.section].types[path.row]
            } else if needsExpandableList(domainid: self.selectedDomain) {
                if MMSettings.shared.showGroupAsHeader {
                    newType = filteredCategories[path.section].types[path.row]
                } else if let selectedGroup = self.selectedGroup {
                    newType = self.filteredCategories.first { group in
                        return group.name == selectedGroup
                    }?.types[path.row]
                } else {
                    if self.filteredCategories.count == 1 {
                        newType = self.filteredCategories[0].types[path.row]
                    } else {
                        newType = nil
                    }
                }
            } else {
                newType = filteredTypes[path.row]
            }
            
            guard let newtType = newType else { return }
            
            self.viewsParentController?.report?.domainName = newtType.domainTitle ?? getSelectedDomainName()
            if let currentReportType = viewsParentController?.report?.reportType { //already have type
                if (newtType.id ?? 0) != currentReportType.id { //type updated with another type
                    self.viewsParentController?.report?.reportType?.rt_description = "cloned"
                    
                    newtType.updateReportTypeAttributesAnswers(oldType: self.viewsParentController!.report!.reportType!)
                    
                    self.viewsParentController!.report!.reportType = newtType
                    self.viewsParentController?.report?.marker_id = newtType.marker_id ?? 0
                    self.viewsParentController!.report!.reportType!.rt_description = "cloned_in_report"
                }
            } else if(viewsParentController!.report!.reportType == nil) { // first time type assigned to report
                newtType.rt_description = "cloned_in_report"
                
                self.fillInFromUser(newtType)
                
                self.viewsParentController!.report!.reportType = newtType
                self.viewsParentController?.report?.marker_id = newtType.marker_id ?? 0
            }
            
            if (self.viewsParentController?.report?.reportType?.position == "never") {
                if (self.viewsParentController?.viewControllers?.count == 5) {
                    self.viewsParentController?.viewControllers?.remove(at: self.viewsParentController?.indexOfPositionTab ?? 0)
                }
            }
        }
        try? MMCoreDataManager.shared.context.save()
    }
    
    func updateReportType(_ id: Int) {
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Prüfe auf Duplikate..."
        hud.show(in: self.viewsParentController!.view, animated: true)
        
        MMApi.shared.getCategoryDetails(id: id, system: System.fallback) { reportType, error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MMCoreDataManager.shared.context)
            if let newType = reportType {
                self.selectedDomain = newType.domainID?.intValue ?? MMSettings.shared.DEFAULT_DOMAIN_ID
                self.viewsParentController?.report?.domainName = newType.domainTitle ?? self.getSelectedDomainName()
                if let currentReportType = self.viewsParentController?.report?.reportType { //already have type
                    if (newType.id ?? 0) != currentReportType.id { //type updated with another type
                        self.viewsParentController?.report?.reportType?.rt_description = "cloned"

                        newType.updateReportTypeAttributesAnswers(oldType: self.viewsParentController!.report!.reportType!)

                        self.viewsParentController!.report!.reportType = newType
                        self.viewsParentController?.report?.marker_id = newType.marker_id ?? 0
                        self.viewsParentController!.report!.reportType!.rt_description = "cloned_in_report"
                    }
                } else if(self.viewsParentController!.report!.reportType == nil) { // first time type assigned to report
                    newType.rt_description = "cloned_in_report"

                    self.fillInFromUser(newType)
                    
                    self.viewsParentController!.report!.reportType = newType
                    self.viewsParentController?.report?.marker_id = newType.marker_id ?? 0
                }
                MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT, moc: MMCoreDataManager.shared.context)
                self.checkDuplicates(type: newType, jghud: hud)
            }
        }
    }
    
    private func fillInFromUser(_ newType: ReportTypeMO) {
        for att in newType.getAttributesFor(update: false) {
            if att.code == "firstname" || att.code == "first_name" {
                att.answer = UserDefaults.standard.string(forKey: "user.firstname")
            } else if att.code == "lastname" || att.code == "last_name" {
                att.answer = UserDefaults.standard.string(forKey: "user.lastname")
            } else if att.code == "email" {
                att.answer = UserDefaults.standard.string(forKey: "user.email")
            }
        }
    }
    
    private func needsExpandableList(domainid: Int) -> Bool {
        if self.typesInCategories[domainid]?.count ?? 0 > 0 {
            return true
        }
        return reportTypes[domainid]?.contains(where: { type in
            return type.group != nil && type.group != ""
        }) ?? false
    }
    
    func hasRubric(domainid: Int) -> Bool {
        return getRubrics(domainid: domainid).count > 1
    }
    
    func shouldShowRubricsTable() -> Bool {
        return hasRubric(domainid: selectedDomain) && self.selectedRubric == nil && self.searchedTypes == nil
    }
    
    func shouldShowRubricsInfo() -> Bool {
        return hasRubric(domainid: selectedDomain) && self.selectedRubric != nil
    }
    
    func getRubrics(domainid: Int) -> [String] {
        return Array(Set(reportTypes[domainid] != nil ? reportTypes[domainid]!.map({ type in
            return type.rubric ?? ""
        }) : [])).filter { rubric in
            return rubric != "" && rubric != " "
        }.sorted()
    }
    
    func selectRubric(_ rubric: String?) {
        self.selectedRubric = rubric
        if rubric != nil {self.rubricInfoLabel.text = String.init(format: "Rubrik: %@", rubric!)}
        self.rubricInfoContainer.isHidden = rubric == nil
        self.rubricInfoHeightConstraint.constant = 65
        self.rubricButton.setTitle("Zurück", for: .normal)
        self.buildExpandableArray(domainid: self.selectedDomain)
        self.tableView?.reloadData()
    }
    
    private func selectGroup(_ group: String?) {
        self.selectedGroup = group
        if group == nil {
            self.rubricInfoHeightConstraint.constant = 65
            self.rubricInfoContainer.isHidden = self.selectedRubric == nil
            if self.selectedRubric != nil {self.rubricInfoLabel.text = String.init(format: "Rubrik: %@", self.selectedRubric!)}
        } else {
            self.rubricInfoHeightConstraint.constant = 90
            self.rubricInfoLabel.text = String.init(format: "Rubrik: %@\nOberkategorie: %@", self.selectedRubric!, group!)
        }
        self.rubricButton.setTitle("Zurück", for: .normal)
        self.tableView?.reloadData()
    }
    
    func rubricsButtonPressed() {
        if self.selectedGroup != nil {
            self.selectGroup(nil)
        } else if self.selectedRubric != nil {
            self.selectRubric(nil)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        self.tableView = tableView
        
        if searchedTypes != nil {
            return searchedTypes!.count
        } else if !MMSettings.shared.showGroupAsHeader {
            return 1
        } else if !needsExpandableList(domainid: self.selectedDomain) {
            return 1
        } else if selectedRubric != nil {
            return self.filteredCategories.count
        } else {
            return typesInCategories[self.selectedDomain]?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchedTypes != nil {
            return self.searchedTypes![section].types.count
        } else if needsExpandableList(domainid: self.selectedDomain) {
            if MMSettings.shared.showGroupAsHeader {
                return self.filteredCategories[section].types.count
            } else if let selectedGroup = self.selectedGroup {
                return self.filteredCategories.first { group in
                    return group.name == selectedGroup
                }?.types.count ?? 0
            } else {
                return self.filteredCategories.count == 1 ? self.filteredCategories.first?.types.count ?? 0 : self.filteredCategories.count
            }
        } else {
            return self.filteredTypes.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.searchedTypes != nil {
            return self.searchedTypes![section].name
        }
        if !MMSettings.shared.showGroupAsHeader {
            return nil
        }
        if needsExpandableList(domainid: self.selectedDomain) {
            return "  " + filteredCategories[section].name
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = MMFontScheme.shared.titleTextFont
        header.textLabel?.textColor = header.isDarkMode() ? .white : MMColorScheme.shared.getColor(view: header, type: .tableViewCellText)
        header.contentView.backgroundColor = MMColorScheme.shared.getColor(view: header, type: .tableViewHeaderBg)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportTypeCell") as! ReportTypeTableViewCell
        cell.explanationButton.tintColor = MMColorScheme.shared.getColor(view: cell, type: .tableViewCellText)
        var type : ReportTypeMO?
        var group : String?
        if searchedTypes != nil {
            type = searchedTypes![indexPath.section].types[indexPath.row]
        } else if needsExpandableList(domainid: self.selectedDomain) {
            if MMSettings.shared.showGroupAsHeader {
                type = filteredCategories[indexPath.section].types[indexPath.row]
            } else if let selectedGroup = self.selectedGroup {
                type = self.filteredCategories.first { group in
                    return group.name == selectedGroup
                }?.types[indexPath.row]
            } else {
                if self.filteredCategories.count == 1 {
                    type = self.filteredCategories[0].types[indexPath.row]
                } else {
                    group = self.filteredCategories[indexPath.row].name
                }
            }
        } else {
            type = filteredTypes[indexPath.row]
        }
        
        if let type = type {
            if type.id == oldTypeId {
                oldTypeIndexPath = indexPath
            }
            
            var name = type.name
            if var index = (name ?? "").firstIndex(of: ">") {
                if String((name ?? "")[index...]).starts(with: " ") {
                    index = (name ?? "").index(index, offsetBy: 2)
                } else {
                    index = (name ?? "").index(index, offsetBy: 1)
                }
                name = String((name ?? "")[index...])
            }
            
            if type.explanation == nil || type.explanation!.isEmpty {
                cell.explanationButton.isHidden = true
            } else {
                cell.explanationButton.isHidden = false
                cell.explanationButton.tag = type.id?.intValue ?? 0
                cell.explanationButton.addTarget(self, action: #selector(showTypeExplanation(sender:)), for: .touchUpInside)
            }
                    
            cell.reportTypeNameLabel.text = name
            cell.reportTypeMarkerImageView.image = UIImage(named: String.init(format: "marker-white-%d", type.marker_id?.intValue ?? 0), in: MM.shared.bundle, compatibleWith: nil)
            if searchedTypes != nil {
                cell.reportTypeDomainLabel.text = type.rubric
            } else {
                cell.reportTypeDomainLabel.text = MMSettings.shared.onlyShowDefaultDomain ? " " : type.domainTitle ?? getSelectedDomainName()
            }
        } else if let group = group {
            cell.explanationButton.isHidden = true
            cell.reportTypeNameLabel.text = group
            cell.reportTypeMarkerImageView.image = nil
            cell.reportTypeDomainLabel.text = MMSettings.shared.onlyShowDefaultDomain ? " " : getSelectedDomainName()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let currentType = self.viewsParentController?.report?.reportType else { return }
        
        var type : ReportTypeMO?
        if searchedTypes != nil {
            type = searchedTypes![indexPath.section].types[indexPath.row]
        } else if needsExpandableList(domainid: self.selectedDomain) {
            if MMSettings.shared.showGroupAsHeader {
                type = filteredCategories[indexPath.section].types[indexPath.row]
            } else if let selectedGroup = self.selectedGroup {
                type = self.filteredCategories.first { group in
                    return group.name == selectedGroup
                }?.types[indexPath.row]
            } else {
                if self.filteredCategories.count == 1 {
                    type = self.filteredCategories[0].types[indexPath.row]
                } else {
                    //Group selection - ignore
                    return
                }
            }
        } else {
            type = filteredTypes[indexPath.row]
        }
        
        if type?.id == currentType.id {
            cell.setSelected(true, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        //If we hava a forced type from a URL, then do not allow to change the type
        if self.viewsParentController?.externalData?.shouldForceTypeId() ?? false {
            let alert = UIAlertController(title: nil, message: "Die Kategorie in dieser Meldung kann nicht verändert werden. Wenn Sie einne andere Kategorie auswählen möchten, müssen Sie eine neue Meldung erstellen.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.viewsParentController?.present(alert, animated: true)
            return nil
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var type : ReportTypeMO?
        if searchedTypes != nil {
            type = searchedTypes![indexPath.section].types[indexPath.row]
        } else if needsExpandableList(domainid: self.selectedDomain) {
            if MMSettings.shared.showGroupAsHeader {
                type = filteredCategories[indexPath.section].types[indexPath.row]
            } else if let selectedGroup = self.selectedGroup {
                type = self.filteredCategories.first { group in
                    return group.name == selectedGroup
                }?.types[indexPath.row]
            } else {
                if self.filteredCategories.count == 1 {
                    type = self.filteredCategories[0].types[indexPath.row]
                } else {
                    self.selectGroup(self.filteredCategories[indexPath.row].name)
                    return
                }
            }
        } else {
            type = filteredTypes[indexPath.row]
        }
        
        guard let type = type else {return}
        
        if let externalUri = type.externalUri {
            let alert = UIAlertController(title: nil, message: String.init(format: "Meldungen für die Kategorie \"%@\" werden mit dieser App nicht entgegen genommen. Sie werden für das Thema auf eine externe Seite weitergeleitet. Möchten Sie fortfahren?", type.name ?? "", externalUri), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                if UIApplication.shared.canOpenURL(URL(string: externalUri)!) {
                    UIApplication.shared.open(URL(string: externalUri)!, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
            self.viewsParentController?.present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        var dict = UserDefaults.standard.dictionary(forKey: "explanations-seen") ?? Dictionary<String, Any>()
        if !(dict[type.id?.stringValue ?? ""] as? Bool ?? false) {
            let button = UIButton()
            button.isHidden = true
            button.tag = type.id?.intValue ?? 0
            showTypeExplanation(sender: button, loadDuplicates: true)
            
            dict[type.id?.stringValue ?? ""] = true
            UserDefaults.standard.set(dict, forKey: "explanations-seen")
        } else {
            checkDuplicates(type: type)
        }
    }
    
    func checkDuplicates(type: ReportTypeMO, jghud: JGProgressHUD? = nil) {
        //Do not check duplicates if the type needs no location or if we have shown type selection first
        guard type.position != "never", !MMSettings.shared.showTypesFirst else {
            self.viewsParentController?.goToNextTab()
            return
        }
        
        //Do not check duplicates when there is no internet connection
        guard !offline else {
            self.viewsParentController?.goToNextTab()
            return
        }
        
        
        if self.selectedDomain != UserDefaults.standard.integer(forKey: "user.domainID") {
            URLSession.shared.reset {
                MMApi.shared.getDomainSettings(domainid: self.selectedDomain, system: self.mapDomainToSystem[self.selectedDomain]) { settings, error in
                    if let settings = settings, !settings.anonQuestions {
                        self.tableView?.deselectRow(at: self.tableView!.indexPathForSelectedRow!, animated: true)
                        let alert = UIAlertController(title: "", message: String.init(format: "Um eine Meldung in dieser Kategorie zu erstellen, melden Sie sich bitte bei %@ an.", self.viewsParentController?.domain?.getName() ?? ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Anmelden", style: .default, handler: { _ in
                            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
                            let vcToPush = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                            vcToPush.selectedDomain = (self.selectedDomain, self.viewsParentController?.domain?.getName() ?? "", self.viewsParentController?.domain?.getRegisterURL() ?? "", self.mapDomainToSystem[self.selectedDomain])
                            self.viewsParentController?.navigationController?.pushViewController(vcToPush, animated: true)
                        }))
                        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
                        self.viewsParentController?.present(alert, animated: true)
                    } else if UserDefaults.standard.integer(forKey: "user.domainID") != 0 {
                        let alert = UIAlertController(title: "", message: String.init(format: "Die Meldung geht an %@. Sie sind bei einem anderen System angemeldet. Möchten Sie die Meldung ohne Nutzerkonto erstellen?", self.viewsParentController?.domain?.getName() ?? ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { _ in
                            self.loadDuplicates(type: type, jghud: jghud)
                        }))
                        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: { _ in
                            self.tableView?.deselectRow(at: self.tableView!.indexPathForSelectedRow!, animated: true)
                        }))
                        self.viewsParentController?.present(alert, animated: true)
                    } else {
                        self.loadDuplicates(type: type, jghud: jghud)
                    }
                }
            }
        } else {
            loadDuplicates(type: type, jghud: jghud)
        }
    }
    
    func loadDuplicates(type: ReportTypeMO, jghud: JGProgressHUD? = nil) {
        let lat = viewsParentController?.report?.lat.doubleValue ?? 0
        let lon = viewsParentController?.report?.long.doubleValue ?? 0
        self.viewsParentController?.system = self.mapDomainToSystem[self.selectedDomain] ?? System.fallback
        
        let hud:JGProgressHUD
        if jghud == nil {
            hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Prüfe auf Duplikate..."
            hud.show(in: self.viewsParentController!.view, animated: true)
        } else {
            hud = jghud!
        }
        
        MMApi.shared.getDuplicates(lat: lat, lon: lon, categoryid: type.id?.intValue ?? 0, domainid: self.selectedDomain, system: self.mapDomainToSystem[self.selectedDomain]) { reports, error in
            if let duplicates = reports, duplicates.count > 0 {
                hud.dismiss(animated: true)
                
                let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
                let vcToPush = storyboard.instantiateViewController(withIdentifier: "DuplicatesViewController") as! DuplicatesViewController
                vcToPush.duplicates = duplicates
                vcToPush.title = "Duplikate"
                vcToPush.system = self.mapDomainToSystem[self.selectedDomain] ?? System.fallback
                self.viewsParentController?.navigationController?.pushViewController(vcToPush, animated: true)
                self.viewsParentController?.goToNextTab()
            } else {
                hud.dismiss(animated: true)
                self.openFuss = true
                self.viewsParentController?.goToNextTab()
            }
        }
    }
    
    @objc func showTypeExplanation(sender: UIButton) {
        self.showTypeExplanation(sender: sender, loadDuplicates: false)
    }
    
    func showTypeExplanation(sender: UIButton, loadDuplicates: Bool) {
        if needsExpandableList(domainid: self.selectedDomain) {
            for category in typesInCategories[self.selectedDomain] ?? [] {
                for rt in category.types {
                    if rt.id?.intValue ?? 0 == sender.tag {
                        if rt.explanation == nil || rt.explanation!.isEmpty {
                            if loadDuplicates {
                                checkDuplicates(type: rt)
                            }
                            return
                        }
                        
                        var name = rt.name
                        if var index = (name ?? "").firstIndex(of: ">") {
                            if String((name ?? "")[index...]).starts(with: " ") {
                                index = (name ?? "").index(index, offsetBy: 2)
                            } else {
                                index = (name ?? "").index(index, offsetBy: 1)
                            }
                            name = String((name ?? "")[index...])
                        }
                        let alert = UIAlertController(title: name, message: "", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            if loadDuplicates {
                                DispatchQueue.main.async {
                                    self.checkDuplicates(type: rt)
                                }
                            }
                        }))
                        
                        var exp = rt.explanation!
                        if let first = rt.explanation?.range(of: "<a href=\""), let second = rt.explanation?.range(of: "\" target=\"_blank\">hier</a>") {
                            let link = rt.explanation?[first.upperBound..<second.lowerBound]
                            alert.addAction(UIAlertAction(title: "Mehr Informationen", style: .default, handler: { (action) in
                                if let url = URL(string: String(link ?? "")), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                }
                            }))
                            exp.replaceSubrange(first.lowerBound..<second.upperBound, with: "hier")
                        }
                        
                        let textColor = self.viewsParentController!.view.isDarkMode() ? "#ffffff" : "#000000"
                        let text = try? NSAttributedString(data: exp.appending("<style>body{font-family: '\(MMFontScheme.shared.smallTextFont?.fontName ?? "")'; font-size:14px;color:\(textColor)}</style>").data(using: .unicode) ?? Data(), options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                        alert.setValue(text, forKey: "attributedMessage")
                        self.viewsParentController?.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } else {
            for rt in self.reportTypes[self.selectedDomain] ?? [] {
                if rt.id?.intValue ?? 0 == sender.tag {
                    if rt.explanation == nil || rt.explanation!.isEmpty {
                        if loadDuplicates {
                            checkDuplicates(type: rt)
                        }
                        return
                    }
                    
                    var name = rt.name
                    if var index = (name ?? "").firstIndex(of: ">") {
                        if String((name ?? "")[index...]).starts(with: " ") {
                            index = (name ?? "").index(index, offsetBy: 2)
                        } else {
                            index = (name ?? "").index(index, offsetBy: 1)
                        }
                        name = String((name ?? "")[index...])
                    }
                    let alert = UIAlertController(title: name, message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                        if loadDuplicates {
                            DispatchQueue.main.async {
                                self.checkDuplicates(type: rt)
                            }
                        }
                    }))
                    
                    var exp = rt.explanation!
                    if let first = rt.explanation?.range(of: "<a href=\""), let second = rt.explanation?.range(of: "\" target=\"_blank\">hier</a>") {
                        let link = rt.explanation?[first.upperBound..<second.lowerBound]
                        alert.addAction(UIAlertAction(title: "Mehr Informationen", style: .default, handler: { (action) in
                            if let url = URL(string: String(link ?? "")), UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }))
                        exp.replaceSubrange(first.lowerBound..<second.upperBound, with: "hier")
                    }
                    
                    
                    let textColor = self.viewsParentController!.view.isDarkMode() ? "#ffffff" : "#000000"
                    let text = try? NSAttributedString(data: exp.appending("<style>body{font-family: '\(MMFontScheme.shared.smallTextFont?.fontName ?? "")';color:\(textColor);font-size:14px;}</style>").data(using: .unicode) ?? Data(), options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                    alert.setValue(text, forKey: "attributedMessage")
                    self.viewsParentController?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: UIPickerViewDelegate, UIPickerViewDataSource

extension ReportTypeViewModel : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mapDomainToSystem.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var values = Array<String>()
        for (id, _) in mapDomainToSystem {
            if self.selectedDomain == id {
                values.insert(self.reportTypes[id]?.first?.domainTitle ?? "Mängelmelder", at: 0)
            } else {
                values.append(self.reportTypes[id]?.first?.domainTitle ?? "Mängelmelder")
            }
        }
        return values[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerView.isHidden = true
        
        var values = Array<String>()
        for (id, _) in mapDomainToSystem {
            if self.selectedDomain == id {
                values.insert(self.reportTypes[id]?.first?.domainTitle ?? "Mängelmelder", at: 0)
            } else {
                values.append(self.reportTypes[id]?.first?.domainTitle ?? "Mängelmelder")
            }
        }
        let selectedValue = values[row]
        for (key, _) in mapDomainToSystem {
            if self.reportTypes[key]?.first?.domainTitle ?? "Mängelmelder" == selectedValue {
                self.selectedDomain = key
            }
        }
        self.buildExpandableArray(domainid: self.selectedDomain)
        self.tableView?.reloadData()
        pickerView.selectRow(0, inComponent: 0, animated: false)
        pickerView.reloadAllComponents()
    }
}

// MARK: UISearchBarDelegate

extension ReportTypeViewModel : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 2 {
            self.searchedTypes = []
            MMApi.shared.searchCategory(searchText: searchText, domainid: self.selectedDomain, system: mapDomainToSystem[self.selectedDomain]) { types, error in
                let filteredTypes = (types ?? []).filter({ type in
                    return self.selectedRubric == nil || self.selectedRubric == type.rubric
                })
                var dict = Dictionary<String, Array<ReportTypeMO>>()
                for t in filteredTypes {
                    let catName:String
                    if t.group == "", let index = (t.name ?? "").firstIndex(of: ">") {
                        catName = String((t.name ?? "")[..<index]).trimmingCharacters(in: .whitespaces)
                    } else if t.group == "", let rubric = t.rubric {
                        catName = rubric
                    } else {
                        catName = t.group ?? ""
                    }
                    if dict.keys.contains(catName) {
                        dict[catName]?.append(t)
                    } else {
                        dict[catName] = [t]
                    }
                }
                
                self.searchedTypes?.removeAll()
                for (key, value) in dict {
                    let sorted = value.sorted { (r1, r2) -> Bool in
                        return (r1.name ?? "").compare(r2.name ?? "") == .orderedAscending
                    }
                    if self.selectedGroup == nil || self.selectedGroup == key {
                        self.searchedTypes?.append((name: key, types: sorted))
                    }
                }
                self.tableView?.reloadData()
            }
        } else if searchText.count == 0 {
            self.searchedTypes = nil
        }
        self.tableView?.reloadData()
    }
    
}
