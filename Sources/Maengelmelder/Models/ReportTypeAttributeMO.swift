//
//  ReportTypeAttributeMO.swift
//  Maengelmelder
//
//  Created by Felix on 07.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import Foundation
import CoreData

@objc(ReportTypeAttributeMO)
public class ReportTypeAttributeMO: NSManagedObject {
    
    @NSManaged var id : NSNumber?
    @NSManaged var name : String?
    @NSManaged var type : String?
    @NSManaged var regex : String?
    @NSManaged var is_public : NSNumber
    @NSManaged var error : String?
    @NSManaged var ordering : NSNumber
    @NSManaged var required_if_value : NSNumber
    @NSManaged var visible_to : String?
    @NSManaged var code : String?
    @NSManaged var required_if_code : NSNumber
    @NSManaged var required_admin : NSNumber
    @NSManaged var visible_if_value : NSNumber
    @NSManaged var group : String?
    @NSManaged var relation_data : String?
    @NSManaged var default_value : String?
    @NSManaged var cached : NSNumber
    @NSManaged var visible_if_code : NSNumber
    @NSManaged var answer : String?
    @NSManaged var values : NSSet
    @NSManaged var help : String?
    @NSManaged var required : NSNumber?
    @NSManaged var multiselect : NSNumber?
    @NSManaged var max_length : NSNumber?
    
    private enum Keys: String, SerializationKey {
        case id
        case name
        case type
        case regex
        case is_public = "public"
        case error
        case ordering
        case required_if_value
        case visible_to
        case code
        case required_if_code
        case required_admin
        case visible_if_value
        case group
        case relation_data
        case default_value
        case cached
        case visible_if_code
        case values
        case text
        case help
        case required
        case multiselect
        case max_length
    }
    
    convenience init (serialization: Serialization) {
        
        let entity = NSEntityDescription.entity(forEntityName: CoreDataEntityNames.REPORT_TYPE_ATTRIBUTES, in: MMCoreDataManager.shared.context)!
        
        self.init(entity: entity, insertInto: MMCoreDataManager.shared.context)
        
        self.id = serialization.value(forKey: Keys.id) ?? -1
        if id == -1 {
            self.id = NumberFormatter().number(from: serialization.value(forKey: Keys.id) ?? "") ?? -1
        }
        self.name = serialization.value(forKey: Keys.name) ?? ""
        self.type = serialization.value(forKey: Keys.type) ?? ""
        self.regex = serialization.value(forKey: Keys.regex) ?? ""
        self.is_public = serialization.value(forKey: Keys.is_public) ?? -1
        self.error = serialization.value(forKey: Keys.error) ?? ""
        self.ordering = serialization.value(forKey: Keys.ordering) ?? -1
        self.required_if_value = serialization.value(forKey: Keys.required_if_value) ?? -1
        self.visible_to = serialization.value(forKey: Keys.visible_to) ?? ""
        self.code = serialization.value(forKey: Keys.code) ?? ""
        self.required_if_code = serialization.value(forKey: Keys.required_if_code) ?? -1
        self.required_admin = serialization.value(forKey: Keys.required_admin) ?? -1
        self.visible_if_value = serialization.value(forKey: Keys.visible_if_value) ?? -1
        self.group = serialization.value(forKey: Keys.group) ?? ""
        self.relation_data = serialization.value(forKey: Keys.relation_data) ?? ""
        self.default_value = serialization.value(forKey: Keys.default_value) ?? ""
        self.cached = serialization.value(forKey: Keys.cached) ?? -1
        self.visible_if_code = serialization.value(forKey: Keys.visible_if_code) ?? -1
        self.answer = ""
        self.help = serialization.value(forKey: Keys.help) ?? self.name ?? ""
        self.required = serialization.value(forKey: Keys.required) ?? 0
        self.multiselect = serialization.value(forKey: Keys.multiselect) ?? 0
        self.max_length = serialization.value(forKey: Keys.max_length) ?? 0
        
        let vals : [Serialization] = serialization.value(forKey: Keys.values) ?? []
        var tempVals : [String] = []
        
        for val in vals {
            let id : String = val.value(forKey: Keys.id) ?? ""
            let text : String = val.value(forKey: Keys.text) ?? ""
            let ordering : String = val.value(forKey: Keys.ordering) ?? "1"
            
            tempVals.append(id + "^" + text + "^" + ordering)
        }
        
        if (tempVals.count > 0) {
            self.values = NSSet(array: tempVals)
        }
        
        if ordering == -1 {
            ordering = id ?? -1
        }
    }
    
    convenience init (name: String, id: NSNumber, typ: String, code: String, sortOrder : NSNumber, answer: String, required: Bool) {
        let entity = NSEntityDescription.entity(forEntityName: CoreDataEntityNames.REPORT_TYPE_ATTRIBUTES, in: MMCoreDataManager.shared.context)!
        
        self.init(entity: entity, insertInto: MMCoreDataManager.shared.context)
        
        self.id = id
        self.name = name
        self.type = typ
        self.code = code
        self.ordering = sortOrder
        self.answer = answer
        self.help = name
        self.required = required ? 1 : 0
    }
    
    func clone(context: NSManagedObjectContext) -> ReportTypeAttributeMO {
        let clonedEntity = NSEntityDescription.insertNewObject(forEntityName: CoreDataEntityNames.REPORT_TYPE_ATTRIBUTES, into: context) as! ReportTypeAttributeMO
        
        clonedEntity.id = self.id
        clonedEntity.name = self.name ?? ""
        clonedEntity.type = self.type ?? ""
        clonedEntity.regex = self.regex ?? ""
        clonedEntity.is_public = self.is_public
        clonedEntity.error = self.error ?? ""
        clonedEntity.ordering = self.ordering
        clonedEntity.required_if_value = self.required_if_value
        clonedEntity.visible_to = self.visible_to ?? ""
        clonedEntity.code = self.code ?? ""
        clonedEntity.required_if_code = self.required_if_code
        clonedEntity.required_admin = self.required_admin
        clonedEntity.visible_if_value = self.visible_if_value
        clonedEntity.group = self.group ?? ""
        clonedEntity.relation_data = self.relation_data ?? ""
        clonedEntity.default_value = self.default_value  ?? ""
        clonedEntity.cached = self.cached
        clonedEntity.visible_if_code = self.visible_if_code
        clonedEntity.answer = self.answer
        clonedEntity.help = self.help
        clonedEntity.required = self.required
        clonedEntity.multiselect = self.multiselect
        clonedEntity.max_length = self.max_length
        
        clonedEntity.values = NSSet(array: self.values.allObjects)
        
        return clonedEntity
    }
    
    func updateAnswer(answer: String){
        self.answer = answer
    }
    
    func returnDisplayableObject() -> ReportAttributesDisplayableObject {        
        var height : CGFloat = 0.0
        
        if (type! == AttributeTypes.text || type! == AttributeTypes.email) {
            let attributedText = NSAttributedString(string: name!, attributes: [.font : MMFontScheme.shared.normalTextFont!])
            let constraintBox = CGSize(width: UIScreen.main.bounds.width-30, height: .greatestFiniteMagnitude)
            let textHeight = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
            height = max(100.0, textHeight + 55)
        }
        else if (type! == AttributeTypes.textarea) {
            let attributedText = NSAttributedString(string: name!, attributes: [.font : MMFontScheme.shared.normalTextFont!])
            let constraintBox = CGSize(width: UIScreen.main.bounds.width-30, height: .greatestFiniteMagnitude)
            let textHeight = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
            height = max(200.0, textHeight + 155)
        }
        else if (type! == AttributeTypes.valuelist) {
            height = 50.0
        }
        else if (type! == AttributeTypes.checkbox) {
            let attributedText = NSAttributedString(string: name!, attributes: [.font : MMFontScheme.shared.smallTextFont!])
            let constraintBox = CGSize(width: UIScreen.main.bounds.width/3*2, height: .greatestFiniteMagnitude)
            let textHeight = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).height
            height = max(50.0, textHeight)
        }
        
        if cached == 1 && (answer == nil || answer!.isEmpty) {
            answer = UserDefaults.standard.string(forKey: "\(id!.intValue)") ?? ""
            
            if code == "email" && MMSettings.shared.formEmail != nil {
                answer = MMSettings.shared.formEmail
            } else if code == "first_name" && MMSettings.shared.formFirstName != nil {
                answer = MMSettings.shared.formFirstName
            } else if code == "last_name" && MMSettings.shared.formLastName != nil {
                answer = MMSettings.shared.formLastName
            }
        }
        
        return ReportAttributesDisplayableObject(name: name!, id: id!, typ: type!, code: code!, height: height, pHolder: help ?? "", sortOrder: ordering, required: self.required == 1, answer: answer ?? "", vals:  Array(values) as! [String], multiselect: self.multiselect == 1, maxLength: self.max_length ?? 0)
    }
}
