//
//  ReportTypeViewHelper.swift
//  Maengelmelder
//
//  Created by Felix on 04.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

class ReportTypeViewHelper {
    
    var typeName : String?
    var typeId: NSNumber
    var typeMarker: String?
    var type : String?
    var rowHeight : CGFloat
    var state: Bool
    var placeholder: String
    var order : NSNumber
    var selectedValue : String
    var vals : [String]
    var color : String
    var compleationPercentage : Float
    var picture : UIImage?
    
    
    init(id: NSNumber, selectedVal: String) {
        typeName = ""
        typeId  = id
        type = ""
        typeMarker = ""
        rowHeight = 0
        state = false
        placeholder = ""
        order = 0
        selectedValue = selectedVal
        vals = []
        color = ""
        compleationPercentage = 0
    }
    
    init(name: String, id: NSNumber, markerId: NSNumber, height: CGFloat) {
        typeName = name
        typeId  = id
        type = ""
        typeMarker = String(format: "marker-white-%@@2x.png", markerId.stringValue)
        rowHeight = height
        state = false
        placeholder = ""
        order = 0
        selectedValue = ""
        vals = []
        color = ""
        compleationPercentage = 0
    }
    
    init(name: String, id: NSNumber, typ: String, height: CGFloat, pHolder: String, sortOrder : NSNumber) {
        typeName = name
        typeId  = id
        typeMarker = ""
        type = typ
        rowHeight = height
        state = false
        placeholder = pHolder
        order = sortOrder
        selectedValue = ""
        vals = []
        color = ""
        compleationPercentage = 0
    }
    
    init(name: String, id: NSNumber, typ: String, height: CGFloat, markerId: NSNumber, colour : String) {
        typeName = name
        typeId  = id
        
        if(markerId == NSNumber(value:-1)){
            typeMarker = "marker.png"
        } else {
            typeMarker = String(format: "marker-@%-%@@2x.png", colour, markerId.stringValue)
        }
        
        type = typ
        rowHeight = height
        state = false
        placeholder = ""
        order = 0
        selectedValue = ""
        vals = []
        color = colour
        compleationPercentage = 0
    }
    
    init(name: String, id: NSNumber, typ: String, height: CGFloat, markerId: NSNumber, colour : String, percentage: Float, pictureData : Data?) {
        
        typeName = name
        typeId  = id
        
        if(markerId == NSNumber(value:-1)){
            typeMarker = "marker.png"
        } else {
            typeMarker = String(format: "marker-%@-%@@2x.png", colour, markerId.stringValue)
        }
        
        type = typ
        rowHeight = height
        state = false
        placeholder = ""
        order = 0
        selectedValue = ""
        vals = []
        color = colour
        compleationPercentage = percentage
        
        if(pictureData != nil) {            
            picture = UIImage(data: pictureData!)
        }
        
    }
}
