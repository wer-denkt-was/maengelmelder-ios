//
//  ReportAttributesViewModel.swift
//  Maengelmelder
//
//  Created by Felix on 05.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ReportAttributesViewModel : NSObject {
    
    fileprivate var viewsParentController: ReportCreationTabViewController?
    weak var reportAttributesDS: ReportAttributesTableViewDataSource?
    
    private var fussCheck:String?
    
    var selectedAttribute : ReportAttributesDisplayableObject? = nil
    
    init(parentController: ReportCreationTabViewController, reportAttributesDS: ReportAttributesTableViewDataSource) {
        super.init()
        self.viewsParentController = parentController
        self.reportAttributesDS = reportAttributesDS
        self.fussCheck = parentController.fussSammelCheck
    }
    
    func fetch() {
        DispatchQueue.main.async {
            if self.viewsParentController?.report?.isOffline ?? 0 == 1 {
                self.fetchReportTypeAttributes()
            } else if self.viewsParentController?.domain != nil && self.viewsParentController?.system != nil {
                self.loadSettingsForDomain(with: self.viewsParentController!.domain!.getID(), and: self.viewsParentController!.system!)
             } else {
                self.fetchSystems()
            }
        }
    }
    
    private func fetchSystems() {
        MMApi.shared.getSystems(lat: viewsParentController?.report?.lat.doubleValue ?? 0, lon: viewsParentController?.report?.long.doubleValue ?? 0) { systems, error in
            self.searchForDomain(systems: systems ?? [])
        }
    }
    
    private func searchForDomain(systems: [System]) {
        guard let idToFind = viewsParentController?.report?.reportType?.domainID?.intValue else {
            return
        }
        let lat = viewsParentController?.report?.lat.doubleValue ?? 0
        let lon = viewsParentController?.report?.long.doubleValue ?? 0
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        
        if (MMSettings.shared.onlyShowDefaultDomain) {
            // just fetch the default domain's attributes if app only shows the default domain
            let defaultDomainId = MMSettings.shared.DEFAULT_DOMAIN_ID
            self.loadSettingsForDomain(with: defaultDomainId, and: systems.first!)
        } else {
            for sys in systems {
                if sys.external || !hasExternal {
                    MMApi.shared.getDomain(lat: lat, lon: lon, system: sys) { domain, error in
                        MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                        if idToFind == domain?.getID() {
                            self.viewsParentController?.domain = domain
                            self.viewsParentController?.system = sys
                            self.loadSettingsForDomain(with: idToFind, and: sys)
                        }
                    }
                }
            }
        }
    }
    	
    private func loadSettingsForDomain(with id: Int, and system:System) {
        MMApi.shared.getDomainSettings(domainid: id, system: system) { settingsO, error in
            if let settings = settingsO {
                self.viewsParentController?.domain?.setSettings(settings)
                self.fetchReportTypeAttributes()
            }
        }
    }
    
    func updateAttributeAnswers(attributesAnswers : [Int : String]) {
        for attribute in reportAttributesDS!.modelToDisplay{
            if(attribute.returnDisplayableObject().attId!.intValue == 1111){ //report titel
                self.viewsParentController!.report!.title = attributesAnswers[1111]
                attribute.answer = attributesAnswers[1111]
            } else if(attribute.returnDisplayableObject().attId!.intValue == 2222){// report desc
                self.viewsParentController!.report!.text = attributesAnswers[2222]
                attribute.answer = attributesAnswers[2222]
            } else if (attributesAnswers[attribute.returnDisplayableObject().attId!.intValue] != nil) {
                if attribute.cached == 1 {
                    UserDefaults.standard.set(attributesAnswers[attribute.returnDisplayableObject().attId!.intValue]!, forKey: "\(attribute.returnDisplayableObject().attId!.intValue)")
                }
                attribute.updateAnswer(answer: attributesAnswers[attribute.returnDisplayableObject().attId!.intValue]!)
            }
        }
    }
    
    func fetchReportTypeAttributes () {
        guard self.viewsParentController?.report?.reportType != nil else {
            return
        }
        var typeAttributes = self.viewsParentController!.report!.reportType!.getAttributesFor(update: false)
        
        let reportTitle = self.viewsParentController!.report!.title ?? ""

        let reportDesc = self.viewsParentController?.report?.text ?? MMSettings.shared.defaultMessageDescription
        
        if((self.viewsParentController?.domain?.getAttributesAsDefaultFields() ?? 0) == 0) {
            //dummy attributes for titel and desc for a report
            if (self.viewsParentController!.report!.reportType!.has_title ?? 0) == 1 {
                typeAttributes.append(ReportTypeAttributeMO(name: LocalizedString("TITEL", comment: ""), id: 1111, typ: AttributeTypes.text, code: "titel", sortOrder: -3, answer: reportTitle, required: true))
            }
            
            let descField = ReportTypeAttributeMO(name: LocalizedString("DESCRIPTION", comment: ""), id: 2222, typ: AttributeTypes.textarea, code: "desc", sortOrder: -2, answer: reportDesc, required: true)
            descField.help = "Bitte geben Sie die Beschreibung ein."
            typeAttributes.append(descField)
        }
        
        if let sammelcheck = self.fussCheck {
            typeAttributes.first { att in
                return att.code == "checknumber"
            }?.updateAnswer(answer: sammelcheck)
        }
        typeAttributes.removeAll { att in
            return (att.code == "checknumber" && self.fussCheck == nil) || att.code == "public_complete"
        }
        
        for attribute in viewsParentController?.report?.reportType?.getAttributesFor(update: false) ??  [] {
            if attribute.code == "public_complete" {
                attribute.answer = UserDefaults.standard.string(forKey: "user.type") == "admin" ? "true" : "false"
            }
        }
        
        reportAttributesDS!.modelToDisplay = typeAttributes.sorted{ $0.ordering.intValue < $1.ordering.intValue}
    }
    
    func updateNewAttributesAnsWithOld(oldAnswers : [Int : String]){
        //when a report type is changed this method will copy the answers of old attributes to similar attributes of the new type's attributes(common attributes)
        
        if(oldAnswers[1111] != nil){
            viewsParentController!.report!.title = oldAnswers[1111]
        }
        
        if(oldAnswers[2222] != nil){
            viewsParentController!.report!.text = oldAnswers[2222]
        }
        
        for key in oldAnswers.keys{
            for attribute in viewsParentController!.report!.reportType!.getAttributesFor(update: false) {
                if(key == attribute.returnDisplayableObject().attId!.intValue){
                    attribute.updateAnswer(answer: oldAnswers[key]!)
                }
            }
        }
    }
}

//MARK: UIPickerDelegate
extension ReportAttributesViewModel : UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return selectedAttribute?.getDropdownValues().count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(selectedAttribute!.getDropdownValues()[row].split(separator: "^")[1])
    }
}
