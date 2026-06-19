//
//  ReportTypeDisplayableObject.swift
//  Maengelmelder
//
//  Created by Felix on 18.10.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

class ReportTypeDisplayableObject {
    
    var typeName : String?
    var typeId: NSNumber?
    var rowHeight : CGFloat?
    var typeMarker: String?
    
    init(name: String, id: NSNumber, markerId: NSNumber, height: CGFloat) {
        typeName = name
        typeId  = id
        typeMarker = String(format: "marker-white-%@@2x.png", markerId.stringValue)
        rowHeight = height
    }
}

class ReportAttributesDisplayableObject {
    
    var attName : String?
    var attId: NSNumber?
    var attType : String?
    var attCode : String?
    var attAnswer : String?
    private var attValues : [String]?
    var rowHeight : CGFloat?
    var placeholder: String?
    var order : NSNumber
    var required : Bool
    var multiselect : Bool
    var maxLength : NSNumber?
    
    init(name: String, id: NSNumber, typ: String, code: String, height: CGFloat, pHolder: String, sortOrder : NSNumber, required: Bool, answer : String, vals : [String], multiselect: Bool, maxLength: NSNumber) {
        attName = name
        attId  = id
        attType = typ
        attCode = code
        rowHeight = height
        placeholder = pHolder
        order = sortOrder
        attAnswer = answer
        attValues = vals
        self.required = required
        self.multiselect = multiselect
        self.maxLength = maxLength
    }
    
    func getDropdownValues() -> Array<String> {
        return (attValues ?? []).sorted { s1, s2 in
            let s1Split = s1.components(separatedBy: "^")
            let s2Split = s2.components(separatedBy: "^")
            if(s1Split.count > 1 && s2Split.count > 1 && (Int(s1Split[2]) ?? 1) !=  (Int(s1Split[2]) ?? 1)) {
                return (Int(s1Split[2]) ?? 1) < (Int(s2Split[2]) ?? 1)
            } else {
                return (Int(s1Split[0]) ?? 0) < (Int(s2Split[0]) ?? 0)
            }
        }
    }
}
