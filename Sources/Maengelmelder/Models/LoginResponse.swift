//
//  LoginResponse.swift
//  MM
//
//  Created by Felix on 05.04.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

public class LoginResponse: NSObject {
    
    public let success:Bool
    public let token:String
    public let id:NSNumber
    public let publicName:String
    public let firstname:String?
    public let lastname:String?
    public let email:String?
    public let avatarUri:String
    public let type:String
    
    public var isAdmin : Bool {
        return type == "admin"
    }
    
    private enum Keys: String, SerializationKey {
        case success
        case data
        case token
        case user
        case id
        case public_name
        case avatar_uri
        case type
        case email
        case firstname
        case lastname
    }
    
    init (serialization: Serialization) {
        let user = serialization[Keys.user.stringValue] as? Serialization
        self.token = serialization.value(forKey: Keys.token) ?? ""
        self.id = user?.value(forKey: Keys.id) ?? -1
        self.publicName = user?.value(forKey: Keys.public_name) ?? ""
        self.avatarUri = user?.value(forKey: Keys.avatar_uri) ?? ""
        self.success = user != nil
        self.type = user?.value(forKey: Keys.type) ?? "unknown"
        self.email = user?.value(forKey: Keys.email)
        self.firstname = user?.value(forKey: Keys.firstname)
        self.lastname = user?.value(forKey: Keys.lastname)        
    }

}
