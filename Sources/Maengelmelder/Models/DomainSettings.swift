//
//  DomainSettings.swift
//  MM
//
//  Created by Felix on 21.10.20.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

public class DomainSettings {
    
    let bmsTextLimit:Int
    let bmsLimitWarning:String
    let attributesAsDefaultFields: Int
    let isCurrentUserResponsible: Bool
    let anonQuestions: Bool
    
    init (serialization: Serialization) {
        self.anonQuestions = (serialization["anon_questions"] as? Int ?? 1) == 1
        if let settingsJSON = serialization["settings"] as? Serialization {
            self.bmsLimitWarning = settingsJSON["bmsLimitWarning"] as? String ?? ""
            self.bmsTextLimit = settingsJSON["bmsTextLimit"] as? Int ?? Int(settingsJSON["bmsTextLimit"] as? String ?? "-1") ?? -1
            self.attributesAsDefaultFields = settingsJSON["attributes_as_default_fields"] as? Int ?? Int(settingsJSON["attributes_as_default_fields"] as? String ?? "0") ?? 0
            if let responsibleJSON = settingsJSON["responsible"] as? Serialization {
                let defaultResponsible = responsibleJSON["default_responsible"] as? String ?? ""
                let show = (responsibleJSON["show"] as? Int ?? 0) == 1
                self.isCurrentUserResponsible = show && defaultResponsible == "current_user"
            } else {
                self.isCurrentUserResponsible = false
            }
        } else {
            self.bmsLimitWarning = ""
            self.bmsTextLimit = -1
            self.attributesAsDefaultFields = 0
            self.isCurrentUserResponsible = false
        }        
    }
    
    init(limit: Int, warning: String, attributesAsDefaultFields: Int) {
        self.bmsLimitWarning = warning
        self.bmsTextLimit = limit
        self.attributesAsDefaultFields = attributesAsDefaultFields
        self.isCurrentUserResponsible = false
        self.anonQuestions = true
    }

}
