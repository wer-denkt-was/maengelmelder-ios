//
//  ReportTypeMO.swift
//  Maengelmelder
//
//  Created by Felix on 07.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import Foundation
import CoreData

@objc(ReportTypeMO)
public class ReportTypeMO: NSManagedObject {
    
    @NSManaged public var id : NSNumber?
    @NSManaged public var name : String?
    @NSManaged var marker_id : NSNumber?
    @NSManaged var marker_class : String?
    @NSManaged var has_title : NSNumber?
    @NSManaged var req_photo : String?
    @NSManaged var position : String?
    @NSManaged var rt_description : String?
    @NSManaged var is_private : NSNumber?
    @NSManaged var typeAttributes : NSMutableSet
    @NSManaged var geometry_ids : NSMutableSet
    @NSManaged var explanation : String?
    @NSManaged var group : String?
    @NSManaged var domainTitle : String?
    @NSManaged var domainID : NSNumber?
    @NSManaged var attributeids_message : NSMutableSet?
    @NSManaged var attributeids_update : NSMutableSet?
    @NSManaged var externalUri : String?
    @NSManaged var rubric : String?
    @NSManaged var ordering: NSNumber?
    
    private enum Keys: String, SerializationKey {
        case id
        case name
        case markerid
        case marker_class
        case has_title
        case photo
        case position
        case description
        case is_private = "private"
        case attributes
        case geometry_ids = "geometryids"
        case explanation
        case group
        case title
        case bms
        case attributeids_message
        case attributeids_update
        case external_uri
        case rubric
        case ordering
    }
    
    convenience init (serialization: Serialization) {
        let entity = NSEntityDescription.entity(forEntityName: CoreDataEntityNames.REPORT_TYPE, in: MMCoreDataManager.shared.context)!
        
        self.init(entity: entity, insertInto: MMCoreDataManager.shared.context)
        
        self.id = serialization.value(forKey: Keys.id) ?? -1
        self.group = serialization.value(forKey: Keys.group) ?? ""
        self.name = serialization.value(forKey: Keys.name) ?? ""
        self.marker_id = serialization.value(forKey: Keys.markerid) ?? -1
        self.marker_class = serialization.value(forKey: Keys.marker_class) ?? ""
        self.has_title = serialization.value(forKey: Keys.has_title) ?? -1
        self.req_photo = serialization.value(forKey: Keys.photo) ?? ""
        self.position = serialization.value(forKey: Keys.position) ?? ""
        self.is_private = serialization.value(forKey: Keys.is_private) ?? -1
        self.explanation = serialization.value(forKey: Keys.description) ?? ""
        self.externalUri = serialization.value(forKey: Keys.external_uri)
        self.rubric = serialization.value(forKey: Keys.rubric)
        self.ordering = serialization.value(forKey: Keys.ordering) ?? 0
        
        if let domain = serialization[Keys.bms.rawValue] as? Serialization {
            self.domainTitle = domain.value(forKey: Keys.name)
            self.domainID = domain.value(forKey: Keys.id)
        }
        
        let attributes : [Serialization] = serialization.value(forKey: Keys.attributes) ?? []
        
        if !(attributes.isEmpty) {
            var tempAttrArray: [ReportTypeAttributeMO] = []
            for obj in attributes {
                tempAttrArray.append(ReportTypeAttributeMO (serialization: obj))
            }
        
            if !(tempAttrArray.isEmpty) {
                typeAttributes = NSMutableSet(array: tempAttrArray)
            }
        }
        
        let geo_ids : [NSNumber] = serialization.value(forKey: Keys.geometry_ids) ?? []
        geometry_ids = NSMutableSet(array: geo_ids)
        
        let attributeidsMessage : [NSNumber] = serialization.value(forKey: Keys.attributeids_message) ?? []
        attributeids_message = NSMutableSet(array: attributeidsMessage)
        
        let attributeidsUpdate : [NSNumber] = serialization.value(forKey: Keys.attributeids_update) ?? []
        attributeids_update = NSMutableSet(array: attributeidsUpdate)
        
        if (group == nil || group == ""), let index = (name ?? "").firstIndex(of: ">") {
            group = String((name ?? "")[..<index]).trimmingCharacters(in: .whitespaces)
        }
    }
    
    func clone(context: NSManagedObjectContext) -> ReportTypeMO {
        let clonedEntity = NSEntityDescription.insertNewObject(forEntityName: CoreDataEntityNames.REPORT_TYPE, into: context) as! ReportTypeMO
        
        clonedEntity.id = self.id ?? -1
        clonedEntity.name = self.name ?? ""
        clonedEntity.marker_id = self.marker_id ?? -1
        clonedEntity.marker_class = self.marker_class ?? ""
        clonedEntity.has_title = self.has_title ?? -1
        clonedEntity.req_photo = self.req_photo ?? ""
        clonedEntity.position = self.position ?? ""
        clonedEntity.rt_description = "cloned"
        clonedEntity.is_private = self.is_private ?? -1
        clonedEntity.explanation = self.explanation ?? ""
        clonedEntity.group = self.group
        clonedEntity.domainTitle = self.domainTitle
        clonedEntity.domainID = self.domainID
        clonedEntity.attributeids_message = self.attributeids_message
        clonedEntity.externalUri = self.externalUri
        clonedEntity.rubric = self.rubric
        clonedEntity.ordering = self.ordering
        
        var clonedAttributes : [ReportTypeAttributeMO] = []
        for attribute in self.typeAttributes.allObjects as! [ReportTypeAttributeMO] {
            clonedAttributes.append(attribute.clone(context: context))
        }
        clonedEntity.typeAttributes = NSMutableSet(array: clonedAttributes)
        
        var clonedGeometries : [GeometryMO] = []
        for geometry in self.geometry_ids.allObjects as! [GeometryMO] {
            clonedGeometries.append(geometry.clone(context: context))
        }
        clonedEntity.geometry_ids = NSMutableSet(array: clonedGeometries)
        
        return clonedEntity
    }
    
    func updateReportTypeAttributesAnswers (oldType : ReportTypeMO) {
        if(self.typeAttributes.count > 0){
            for currentTypeAttribute in self.typeAttributes.allObjects as! [ReportTypeAttributeMO] {
                for oldTypeAttribute in oldType.typeAttributes.allObjects as! [ReportTypeAttributeMO] {
                    if(currentTypeAttribute.id == oldTypeAttribute.id){
                        currentTypeAttribute.answer = oldTypeAttribute.answer!
                        break
                    }
                }
            }
        }
    }
    
    func getAttributesFor(update: Bool) -> [ReportTypeAttributeMO] {
        let allAttributes = self.typeAttributes.allObjects as! [ReportTypeAttributeMO]
        let filteredAttributes = allAttributes.filter { (type) -> Bool in
            if update {
                return (self.attributeids_update?.contains(type.id ?? 0) ?? false)
            } else {
                return (self.attributeids_message?.contains(type.id ?? 0) ?? false)
            }
        }
        return filteredAttributes
    }
    
    func returnDisplayableObject() -> ReportTypeDisplayableObject {        
        return ReportTypeDisplayableObject(name: self.name!, id: self.id!, markerId: self.marker_id!, height: 50)
    }
}
