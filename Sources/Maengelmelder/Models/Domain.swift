//
//  Domain.swift
//  MM
//
//  Created by Felix on 18.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData

public class Domain {
    
    private let isDefault:Bool
    private let domainID:Int
    private let name:String
    private var textLimit:Int?
    private var textLimitWarning:String?
    private var attributesAsDefaultFields: Int?
    private let linkWeb:String?
    private var types:[ReportTypeMO]
    
    private enum Keys: String, SerializationKey {
        case is_default
        case id
        case primary_domain
        case links
        case web
        case href
        case name
        case types
        case settings
        case bmsTextLimit
        case bmsLimitWarning
        case attributesAsDefaultFields
    }
    
    init (serialization: Serialization) {        
        isDefault = serialization.value(forKey: Keys.is_default) ?? false
        
        let primaryDomain = serialization[Keys.primary_domain.rawValue] as? Serialization
        domainID = primaryDomain?.value(forKey: Keys.id) ?? MMSettings.shared.DEFAULT_DOMAIN_ID
        name = primaryDomain?.value(forKey: Keys.name) ?? MMSettings.shared.APP_NAME
        
        let settings = primaryDomain?[Keys.settings.rawValue] as? Serialization
        textLimit = Int(settings?[Keys.bmsTextLimit.rawValue] as? String ?? "")
        textLimitWarning = settings?.value(forKey: Keys.bmsLimitWarning)
        attributesAsDefaultFields = settings?.value(forKey: Keys.attributesAsDefaultFields)
        
        types = Array<ReportTypeMO>()
        let typeArray = serialization.value(forKey: Keys.types) ?? []
        for t in typeArray {
            let type = ReportTypeMO(serialization: t as! Serialization)
            let alreadyInserted = types.contains { t in
                return t.id == type.id && t.domainID == type.domainID
            }
            if (!alreadyInserted) {
                // Avoid doubled types
                types.append(type)
            }
        }
        
        let links = primaryDomain?[Keys.links.rawValue] as? Serialization
        let webLinks = links?[Keys.web.rawValue] as? Serialization
        linkWeb = webLinks?.value(forKey: Keys.href)
    }
    
    init(isDefault: Bool, domainID: Int, domainName: String, types: [ReportTypeMO]) {
        self.isDefault = isDefault
        self.domainID = domainID
        self.name = domainName
        self.types = types
        self.linkWeb = MMSettings.shared.REGISTRATION_PAGE_URL
    }
    
    func getID() -> Int {
        return domainID
    }
    
    func getTypes() -> [ReportTypeMO] {
        return types
    }
    
    func getName() -> String {
        return name
    }
    
    func hasTextLimit() -> Bool {
        return textLimit != nil && textLimit! > -1 && textLimitWarning != nil && !textLimitWarning!.isEmpty
    }
    
    func getTextLimit() -> Int {
        return textLimit ?? -1
    }
    
    func getTextLimitWarning() -> String {
        return textLimitWarning ?? ""
    }
    
    func getAttributesAsDefaultFields() -> Int {
        return attributesAsDefaultFields ?? 0
    }
    
    func hasAttributesAsDefaultFields() -> Bool {
        return (attributesAsDefaultFields ?? 0) == 1
    }
    
    func getRegisterURL() -> String {
        return self.linkWeb?.replacingOccurrences(of: "bms", with: "login") ?? MMSettings.shared.REGISTRATION_PAGE_URL
    }
    
    func setSettings(_ settings: DomainSettings) {
        self.textLimitWarning = settings.bmsLimitWarning
        self.textLimit = settings.bmsTextLimit
        self.attributesAsDefaultFields = settings.attributesAsDefaultFields
    }
    
}
