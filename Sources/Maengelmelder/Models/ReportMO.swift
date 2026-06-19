//
//  ReportMO.swift
//  Maengelmelder
//
//  Created by Felix on 07.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

@objc(ReportMO)
public class ReportMO: NSManagedObject {
    
    @NSManaged public var lat : NSNumber
    @NSManaged public var long : NSNumber
    @NSManaged public var state_german : String?
    @NSManaged public var attachments : NSMutableOrderedSet
    @NSManaged public var state : String?
    @NSManaged public var id : NSNumber
    @NSManaged public var address : String?
    @NSManaged public var number : String?
    @NSManaged public var marker_id : NSNumber
    @NSManaged public var marker_color : String?
    @NSManaged public var text : String?
    @NSManaged public var title : String?
    @NSManaged public var desc : String?
    @NSManaged public var created : String?
    @NSManaged public var reportType : ReportTypeMO?
    @NSManaged var responsible : ReportUserMO
    @NSManaged public var history : NSSet
    @NSManaged public var attribute_values : NSSet
    @NSManaged public var isLocal : NSNumber
    @NSManaged public var isOffline : NSNumber
    @NSManaged public var pictureURL : String?
    @NSManaged public var typeName : String?
    @NSManaged public var lastSeen : Date?
    @NSManaged public var domainid : NSNumber?
    @NSManaged public var domainName : String?
    @NSManaged public var isPrivate : NSNumber?
    
    private enum Keys: String, SerializationKey {
        case id
        case lat
        case lon
        case long
        case marker_color
        case marker_id
        case attachments
        case address
        case number
        case state
        case state_german
        case text
        case title
        case created
        case reportType = "message_type"
        case responsible
        case history
        case attribute_values
        case public_name
        case typeid
        case color
        case markerid
        case messageid
        case type
        case domain
        case name
        case thumbnail_sq64
        case isPrivate = "private"
    }
    
    convenience init (serialization: Serialization) {
        
        let entity = NSEntityDescription.entity(forEntityName: "Report", in: MMCoreDataManager.shared.context)!
        
        self.init(entity: entity, insertInto: MMCoreDataManager.shared.context)
        
        self.id = serialization.value(forKey: Keys.id) ?? serialization.value(forKey: Keys.messageid) ?? -1
        self.lat = serialization.value(forKey: Keys.lat) ?? 0
        self.long = serialization.value(forKey: Keys.lon) ?? serialization.value(forKey: Keys.long) ?? 0
        self.marker_color = serialization.value(forKey: Keys.marker_color) ?? serialization.value(forKey: Keys.color) ?? ""
        self.pictureURL = serialization.value(forKey: Keys.thumbnail_sq64)
        self.isPrivate = serialization.value(forKey: Keys.isPrivate) ?? 0
        
        self.marker_id = serialization.value(forKey: Keys.marker_id) ?? -1
        if marker_id == -1 {
            let idasstring : String? = serialization.value(forKey: Keys.markerid)
            if idasstring != nil {
                self.marker_id = NSNumber(value: Int(idasstring!) ?? -1)
            }
        }
        
        self.address = serialization.value(forKey: Keys.address) ?? ""
        self.number = serialization.value(forKey: Keys.number) ?? ""
        self.state = serialization.value(forKey: Keys.state) ?? ""
        self.state_german = serialization.value(forKey: Keys.state_german) ?? ""
        self.text = serialization.value(forKey: Keys.text) ?? ""
        self.title = serialization.value(forKey: Keys.title) ?? ""
        self.desc = serialization.value(forKey: Keys.text) ?? ""
        self.created = serialization.value(forKey: Keys.created) ?? ""
        
        let rt : Serialization? = serialization.value(forKey: Keys.reportType)
        let idToFetch : NSNumber = rt?.value(forKey: Keys.id) ?? serialization.value(forKey: Keys.typeid) ?? 0
        
        let pradicate = NSPredicate(format: "id = %@", idToFetch.stringValue)
        
        let results = MMCoreDataManager.fetchData(entityName: CoreDataEntityNames.REPORT_TYPE, pradicate: pradicate, moc: MMCoreDataManager.shared.context) as! [ReportTypeMO]
        if (results.count >= 1) {
            self.reportType = results.first!.clone(context: MMCoreDataManager.shared.context)
            self.reportType!.rt_description = "cloned_in_report"
        }
        
        let user : Serialization? = serialization.value(forKey: Keys.responsible)
        if user != nil {
            let uid : NSNumber = user!.value(forKey: Keys.id)!
            let uname : String = user!.value(forKey: Keys.public_name)!
            self.responsible = ReportUserMO(name: uname, uid: uid)
        }
        
        let commentHistoryArray : [Serialization] = serialization.value(forKey: Keys.history) ?? []
        if (commentHistoryArray.count > 0) {
            
            var tempHistoryArray: [ReportCommentMO] = []
            
            for comment in commentHistoryArray {
                let cid : NSNumber = comment.value(forKey: Keys.id)!
                let ctext : String = comment.value(forKey: Keys.text)!
                
                tempHistoryArray.append(ReportCommentMO(ctext: ctext, cid: cid))
            }
            
            if (tempHistoryArray.count > 0) {
                
                self.history = NSSet(array: tempHistoryArray)
            }
        }
        
        self.typeName = serialization.value(forKey: Keys.type)
        
        if (typeName ?? "").isEmpty {
            let typeSeri = (serialization.value(forKey: Keys.reportType) ?? [:]) as Serialization
            self.typeName = typeSeri.value(forKey: Keys.name)
        }
        
        isLocal = 0
        isOffline = 0
        let domainSeri = (serialization.value(forKey: Keys.domain) ?? [:]) as Serialization
        domainid = domainSeri.value(forKey: Keys.id)
        domainName = domainSeri.value(forKey: Keys.title)
        lastSeen = Date()        
    }
    
    public func markerGraphicForMap(system: System?, overrideMarkerImageName: String = "") -> ReportMapMarker {
        return ReportMapMarker(report: self, system: system ?? System.fallback, overrideMarkerImageName: overrideMarkerImageName)
    }
    
    func attributesJSON(update: Bool) -> String {
        if reportType!.getAttributesFor(update: update).count == 0 {
            return "{}"
        }
        
        var dict = "{"
        for attribute in reportType!.getAttributesFor(update: update) {
            if attribute.type == AttributeTypes.valuelist {
                if attribute.multiselect == 1 {
                    var text = "["
                    let options = (attribute.answer ?? "").components(separatedBy: ";")
                    for opt in options {
                        text.append("\"")
                        text.append(opt.components(separatedBy: "^")[0])
                        text.append("\",")
                    }
                    _ = text.removeLast()
                    text.append("]")
                    dict.append("\"\(attribute.id!.intValue)\" : " + text)
                } else {
                    dict.append("\"\(attribute.id!.intValue)\" : [\"\(attribute.answer?.split(separator: "^").first ?? "")\"]")
                }
                
            } else {
                dict.append("\"\(attribute.id!.intValue)\" : [\"\(attribute.answer ?? "")\"]")
            }
            dict.append(", ")
        }
        dict = String(dict.dropLast())
        dict = String(dict.dropLast())
        dict.append("}")
        return dict
    }
}
