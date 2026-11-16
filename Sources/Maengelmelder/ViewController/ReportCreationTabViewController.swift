//
//  ReportCreationTabViewController.swift
//  Maengelmelder
//
//  Created by Felix on 28.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation
import JGProgressHUD
import StoreKit

public class ReportCreationTabViewController : UITabBarController {
    
    private var networkInfoButton: UIBarButtonItem?
    
    public var report : ReportMO?
    var indexOfPositionTab = 0
    var indexOfCategoryTab = 2
    var isReportTypeSelected = false
    var tabsViewHelper : [TabViewHelper]?
    public var screenMode : String?
    var originalReportTypes : [ReportTypeMO]?
    var isReportPositionUpdated : Bool = false
    var system : System?
    var domain : Domain?
    lazy fileprivate var uploadUtil : UploadUtility = {[unowned self] in
        return UploadUtility()
    }()
    
    private var inserted = false
    
    var fussSammelCheck:String?
    var fussShouldDelete = true
    
    private var positionVC : ReportPositionViewController?
    var startIndex : Int = 0
    
    var showErrorsInAttributes = false
    var externalData : ExtrernalCreationData?
    
    // Domain of a category forced by a link (force_typeid), loaded at the link position
    private var isLoadingForcedDomain = false
    private var forcedDomainCallbacks : [(Bool) -> Void] = []
    
    private func searchForDomain(id: Int) {
        let lat = self.report?.lat.doubleValue ?? 0
        let lon = self.report?.long.doubleValue ?? 0
        
        MMApi.shared.getDomain(lat: lat, lon: lon, system: self.system) { domain, 	error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            if id == domain?.getID() {
                self.domain = domain
            }
        }
    }
    
    public override func viewDidLoad() {
        MMCoreDataManager.deleteData(entityName: "ReportType", pradicate: NSPredicate(format: "rt_description == %@", "cloned"), moc: MMCoreDataManager.shared.context)
        
        super.viewDidLoad()
        
        self.customizableViewControllers = []
        tabsViewHelper = []
        
        if MMSettings.shared.loadDomainBeforeReports && domain == nil {
            if system == nil {
                system = System.fallback
            }
            self.searchForDomain(id: MMSettings.shared.DEFAULT_DOMAIN_ID)
        }
        
        self.positionVC = self.viewControllers?.first as? ReportPositionViewController
        
        if screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA || screenMode == GlobalFlagValues.REPORT_SCREEN_NEW_IDEA {
            self.viewControllers?.swapAt(0, 1)
            self.viewControllers?.swapAt(0, 2)
            self.indexOfPositionTab = 1
            self.indexOfCategoryTab = 0
        }
        
        if MMSettings.shared.showTypesFirst {
            self.viewControllers?.swapAt(0, 2)
            self.indexOfCategoryTab = 0
            self.indexOfPositionTab = 2
        }
        
        for (_) in viewControllers!.enumerated() {
            tabsViewHelper!.append(TabViewHelper())
        }
        
        tabBar.barTintColor = MMColorScheme.shared.getColor(view: tabBar, type: .barTint)
        tabBar.tintColor = MMColorScheme.shared.getColor(view: tabBar, type: .tint)
        tabBar.backgroundColor = MMColorScheme.shared.getColor(view: tabBar, type: .barTint)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .done, target: self, action: #selector(saveAndClose))
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "next", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
        button.setTitle(LocalizedString("CONTINUE", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
        button.transform = CGAffineTransform(scaleX: -1, y: 1)
        button.titleLabel?.transform = CGAffineTransform(scaleX: -1, y: 1)
        button.imageView?.transform = CGAffineTransform(scaleX: -1, y: -1)
        if #available(iOS 26, *) {
            button.setTitleColor(.label, for: .normal)
            button.tintColor = .label
        } else {
            button.setTitleColor(MMColorScheme.shared.getColor(view: button, type: .titleText), for: .normal)
        }
        button.titleLabel?.font = MMFontScheme.shared.buttonTitleFont ?? MMFontScheme.shared.normalTextFont
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        
        if (screenMode! == GlobalFlagValues.REPORT_SCREEN_NEW_MODE && !inserted) {
            report = NSEntityDescription.insertNewObject(forEntityName: "Report", into: MMCoreDataManager.shared.context) as? ReportMO
            report?.isLocal = 1
            report?.id = NSNumber(value: Date().timeIntervalSince1970)
            report?.lat = NSNumber(value: self.externalData?.getLat() ??  CLLocationManager().location?.coordinate.latitude ?? 0)
            report?.long = NSNumber(value: self.externalData?.getLon() ?? CLLocationManager().location?.coordinate.longitude ?? 0)
            report?.state = GlobalFlagValues.REPORT_CREATED_STATE
            self.navigationItem.backBarButtonItem?.title = ""
            inserted = true
        } else if screenMode! == GlobalFlagValues.REPORT_SCREEN_NEW_IDEA && !inserted {
            report = NSEntityDescription.insertNewObject(forEntityName: "Report", into: MMCoreDataManager.shared.context) as? ReportMO
            report?.isLocal = 1
            report?.id = NSNumber(value: Date().timeIntervalSince1970)
            report?.lat = NSNumber(value: 50.815897)
            report?.long = NSNumber(value: 6.975984)
            report?.state = GlobalFlagValues.REPORT_CREATED_STATE
            self.navigationItem.backBarButtonItem?.title = ""
            inserted = true
        } else {
            isReportTypeSelected = report?.reportType != nil
            if isReportTypeSelected && report?.reportType?.position == "never" && self.viewControllers?.count == 5 {
                self.viewControllers?.remove(at: self.indexOfPositionTab)
            }
        }
        
        self.networkInfoButton = UIBarButtonItem(image: UIImage(systemName: "wifi.exclamationmark"), style: .plain, target: self, action: #selector(self.noNetworkButtonAction(sender:)))
        self.networkInfoButton?.tintColor = .red
        self.networkInfoButton?.tag = 18062
        
        if self.externalData?.shouldForceLocation() ?? false {
            startIndex = 1
        }
        
        if let typeId = self.externalData?.getTypeId() {
            if self.externalData?.shouldForceTypeId() ?? false {
                self.isLoadingForcedDomain = true
            }
            self.fetchCategory(with: typeId) { success in
                if (success ?? false) && (self.externalData?.shouldForceTypeId() ?? false) && self.indexOfCategoryTab >= 0 {
                    self.viewControllers?.remove(at: self.indexOfCategoryTab)
                    if self.indexOfPositionTab > self.indexOfCategoryTab {
                        self.indexOfPositionTab -= 1
                    }
                    self.indexOfCategoryTab = -1
                }
            }
        }
        
        self.selectedIndex = startIndex
    }
    
    @objc func noNetworkButtonAction(sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Aktuell besteht keine Internetverbindung. Das Erstellen von Meldungen ist weiterhin möglich. Das Hochladen ist dann wieder möglich, wenn eine Internetverbindung besteht.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        InternetUtility.shared.delegate = self
        self.onlineStatusChanged(InternetUtility.shared.isOnline())
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveReportContext()
    }
    
    @objc func saveAndClose(uploaded: Bool) {
        // show alert
        let alertSaving = UIAlertController(title: nil, message: LocalizedString("SAVING_REPORT", comment: ""), preferredStyle: .alert)
        alertSaving.addAction(UIAlertAction(title: "Ok", style: .default) {	_ in
            self.navigationController?.popViewController(animated: true)
            if uploaded, MMSettings.shared.showRatingAfterUpload, let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                DispatchQueue.main.async {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        })
        self.present(alertSaving, animated: true)
    }
    
    /**
     Action of the "Weiter" button. A target action passes the sender, not a Bool, so goToNextTab(shouldCheck:)
     must not be used as selector directly (shouldCheck was always false). The position is only checked for a
     category forced by a link (force_typeid), as before for all other reports.
     */
    @objc func continueButtonTapped() {
        goToNextTab(shouldCheck: externalData?.shouldForceTypeId() ?? false)
    }
    
    @objc func goToNextTab(shouldCheck: Bool = true) {
        if selectedIndex == self.indexOfPositionTab {
            
            if shouldCheck {
                let loadingHud = JGProgressHUD(style: .dark)
                loadingHud.textLabel.text = "Position wird geprüft..."
                loadingHud.show(in: self.view)
                
                self.checkCategoryAtPosition { success in
                    loadingHud.dismiss()
                    if !success {
                        var alertMsg = MMSettings.shared.messageInvalidPositionText
                        if alertMsg == "" {
                            alertMsg = LocalizedString(MMSettings.shared.showTypesFirst ? "TYPE_FIRST_CATEGORY_NOT_AVAILABLE" : "CATEGORY_NOT_AVAILABLE", comment: "")
                        }
                        let isTypeForced = self.externalData?.shouldForceTypeId() ?? false
                        if isTypeForced {
                            alertMsg = self.forcedCategoryPositionMessage()
                        }
                        let alert = UIAlertController(title: nil, message: alertMsg, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: { _ in
                            // The category tab is removed for a forced category, stay on the position tab
                            if !isTypeForced {
                                (self.parent as? ReportCreationTabViewController)?.goToTab(2)
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.selectedIndex = self.selectedIndex+1
                    }
                }
            } else {
                if (selectedIndex < viewControllers!.count) {
                    selectedIndex = selectedIndex+1
                }
            }
        } else if(selectedIndex < viewControllers!.count){
            selectedIndex = selectedIndex+1
        }
    }
    
    @objc func goToPrevTab() {
        if selectedIndex > 0 {
            selectedIndex = selectedIndex - 1
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func goToTab(_ index: Int) {
        if index >= 0 && index < viewControllers!.count {
            selectedIndex = index
        }
    }
    
    private func saveReportContext() {
        for (index, element) in tabsViewHelper!.enumerated() {
            if (element.reportDidUpdatedAtTab == false && element.wasTabOpened == true) {
                self.viewControllers![index].viewWillDisappear(false)
            }
        }
        
        MMCoreDataManager.saveContext(entityName: "ReportType", moc: MMCoreDataManager.shared.context)
        MMCoreDataManager.saveContext(entityName: "Report", moc: MMCoreDataManager.shared.context)
    }
    
    /**
     Checks if the message is in the domain associated with the current APPID.
     */	
    func checkCategoryAtPosition(callback: @escaping (Bool) -> Void) {
        
        if MMSettings.shared.showTypesFirst
            || MMSettings.shared.disableCategoryCheckOnPosition
            || report?.reportType?.position == "never"
        {
            callback(true)
            return
        }
        
        if externalData != nil && externalData!.shouldForceTypeId() {
            self.checkForcedCategoryAtPosition(callback: callback)
            return
        }
        
        if system == nil {
            self.fetchSystems(report: report!) { system in
                self.checkCategoryAtPosition(callback: callback)
            }
            return
        }
        	
        let lat = self.report?.lat.doubleValue ?? 0
        let lon = self.report?.long.doubleValue ?? 0
        
        MMApi.shared.getDomain(lat: lat, lon: lon, system: self.system) { domainO, error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            if let domain = domainO {
                // Checks if category exists after picking position. Only works in tandem with onlyShowDefaultDomain
                if (MMSettings.shared.checkIfAnyCategoryExistsOnPosition && MMSettings.shared.onlyShowDefaultDomain) {
                    let hasType = domain.getTypes().contains(where: { type in type.domainID?.intValue == MMSettings.shared.DEFAULT_DOMAIN_ID })
                    callback(hasType)
                    return
                }
                
                if domain.getID() == self.report?.reportType?.domainID?.intValue {
                    for type in domain.getTypes() {
                        if type.id == self.report?.reportType?.id {
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
    
    /**
     Checks if the position is inside the domain of the category forced by a link (force_typeid).
     Uses the system of the category, not the one at the current position.
     */
    private func checkForcedCategoryAtPosition(callback: @escaping (Bool) -> Void) {
        // Position cannot be changed (force_loc) or cannot be checked offline
        if (externalData?.shouldForceLocation() ?? false) || !InternetUtility.shared.isOnline() {
            callback(true)
            return
        }
        
        let lat = self.report?.lat.doubleValue ?? 0
        let lon = self.report?.long.doubleValue ?? 0
        
        // An external system may return its domain for any position, so the system of the category
        // has to be available at the position as well
        MMApi.shared.getSystems(lat: lat, lon: lon) { systems, error in
            guard let categorySystem = self.system,
                  let systemAtPosition = systems?.first(where: { $0.host == categorySystem.host && $0.appid == categorySystem.appid }) else {
                callback(false)
                return
            }
            
            MMApi.shared.getDomain(lat: lat, lon: lon, system: systemAtPosition) { domainO, error in
                MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                if let domain = domainO, domain.getID() == self.report?.reportType?.domainID?.intValue {
                    callback(true)
                    return
                }
                callback(false)
            }
        }
    }
    
    func forcedCategoryPositionMessage() -> String {
        let domainTitle = report?.reportType?.domainTitle ?? report?.domainName ?? ""
        return String(format: "Diese Kategorie ist nur im Gebiet %@ verfügbar. Bitte wählen Sie eine Position innerhalb dieses Gebiets.", domainTitle)
    }
    
    /**
     Calls back once the domain of the forced category is known (true) or could not be loaded (false).
     Loads it again if a previous attempt failed.
     */
    func waitForForcedDomain(_ callback: @escaping (Bool) -> Void) {
        if hasForcedDomain() {
            callback(true)
            return
        }
        forcedDomainCallbacks.append(callback)
        if !isLoadingForcedDomain {
            if let category = report?.reportType {
                isLoadingForcedDomain = true
                fetchForcedDomain(for: category)
            } else {
                finishLoadingForcedDomain()
            }
        }
    }
    
    private func hasForcedDomain() -> Bool {
        guard let domain = self.domain, self.system != nil else { return false }
        return domain.getID() == report?.reportType?.domainID?.intValue
    }
    
    private func fetchForcedDomain(for category: ReportTypeMO) {
        let lat = self.report?.lat.doubleValue ?? 0
        let lon = self.report?.long.doubleValue ?? 0
        
        MMApi.shared.getDomain(lat: lat, lon: lon, system: self.system) { domainO, error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            if let domain = domainO, domain.getID() == category.domainID?.intValue {
                self.domain = domain
                self.report?.domainid = domain.getID() as NSNumber
            }
            self.finishLoadingForcedDomain()
        }
    }
    
    private func finishLoadingForcedDomain() {
        DispatchQueue.main.async {
            self.isLoadingForcedDomain = false
            let success = self.hasForcedDomain()
            let callbacks = self.forcedDomainCallbacks
            self.forcedDomainCallbacks = []
            callbacks.forEach { $0(success) }
        }
    }
    
    private func fetchCategory(with id: Int, callback: @escaping (Bool?) -> Void) {
        if system == nil {
            // Request the category only once the system is known (it may be an external one)
            self.fetchSystems(report: report!) { _ in
                self.fetchCategoryDetails(with: id, callback: callback)
            }
            return
        }
        fetchCategoryDetails(with: id, callback: callback)
    }
    
    private func fetchCategoryDetails(with id: Int, callback: @escaping (Bool?) -> Void) {
        MMApi.shared.getCategoryDetails(id: id, system: self.system) { category, error in
            MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
            if let category = category {
                self.report?.reportType = category
                // Shown before the upload, otherwise it falls back to "Mängelmelder.de"
                self.report?.domainName = category.domainTitle
                if self.externalData?.shouldForceTypeId() ?? false {
                    self.report?.marker_id = category.marker_id ?? 0
                    category.rt_description = "cloned_in_report"
                    // The category tab is removed, so the domain has to be loaded here (at the link position)
                    self.fetchForcedDomain(for: category)
                }
                callback(true)
                return
            }
            if self.externalData?.shouldForceTypeId() ?? false {
                self.finishLoadingForcedDomain()
            }
            callback(false)
            return
        }
    }
    
    private func fetchSystems(report: ReportMO, compleation: @escaping (System?) -> Void) {
        MMApi.shared.getSystems(lat: report.lat.doubleValue, lon: report.long.doubleValue) { systems, error in
            let external = systems?.first(where: { (system) -> Bool in
                return system.external
            })
            self.system = external ?? systems?.first
            compleation(self.system)
        }
    }
    
    func uploadReport(sender: UIViewController){
        // The tab bar allows to skip the position check, so check the position of a forced category again
        if externalData?.shouldForceTypeId() ?? false {
            checkCategoryAtPosition { success in
                if success {
                    self.startUpload(sender: sender)
                } else {
                    let alert = UIAlertController(title: nil, message: self.forcedCategoryPositionMessage(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: { _ in
                        self.goToTab(self.indexOfPositionTab)
                    }))
                    sender.present(alert, animated: true, completion: nil)
                }
            }
            return
        }
        startUpload(sender: sender)
    }
    
    private func startUpload(sender: UIViewController) {
        if domain?.hasTextLimit() ?? false && report?.desc?.count ?? 0 > domain?.getTextLimit() ?? -1 {
            let alert = UIAlertController(title: nil, message: domain?.getTextLimitWarning(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            sender.present(alert, animated: true, completion: nil)
            return
        }
        
        uploadUtil.uploadReport(report: report!, system: system ?? System(appid: MMSettings.shared.APP_ID, host: MMApi.shared.SERVER_URL, name: "", external: false), viewForHud: sender.view, compleation: { (success) in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    self.saveAndClose(uploaded: success)
                })
            }
        })
    }
}

// MARK: Internet Delegate

extension ReportCreationTabViewController : InternetUtilityDelegate {
    
    func onlineStatusChanged(_ isOnline: Bool) {
        if isOnline && self.navigationItem.rightBarButtonItems?.last?.tag == networkInfoButton?.tag {
            self.navigationItem.rightBarButtonItems?.removeLast()
        } else if !isOnline && self.navigationItem.rightBarButtonItems?.last?.tag != networkInfoButton?.tag  {
            self.navigationItem.rightBarButtonItems?.append(networkInfoButton ?? UIBarButtonItem())
        }
    }
    
}
