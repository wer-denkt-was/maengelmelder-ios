//
//  System.swift
//  MM
//
//  Created by Felix on 12.06.19.
//  Copyright © 2024 WDW. All rights reserved.
//

public class System: Codable {
    
    public static let fallback = System(appid: MMSettings.shared.APP_ID, host: MMApi.shared.SERVER_URL, name: MMSettings.shared.APP_NAME, external: false)
    
    public let appid:Int
    public let host:String
    public let name:String
    public let external:Bool
    
    private enum Keys : String, SerializationKey {
        case host
        case appid
        case name
        case external
    }
    
    init(json: Serialization) {
        appid = json.value(forKey: Keys.appid) ?? MMSettings.shared.APP_ID
        host = json.value(forKey: Keys.host) ?? MMApi.shared.SERVER_URL
        external = json.value(forKey: Keys.external) ?? false
        name = json.value(forKey: Keys.name) ?? ""
    }
    
    public init(appid: Int, host: String, name: String, external: Bool) {
        self.appid = appid
        self.host = host
        self.name = name
        self.external = external
    }
    
    init(from string: String) {
        let splited = string.split(separator: "^")
        self.appid = Int(String(splited[0])) ?? MMSettings.shared.APP_ID
        self.host = String(splited[1])
        self.name = String(splited[2])
        self.external = Int(String(splited[3])) == 1
        
    }
    
    func toString() -> String {
        return String.init(format: "%d^%@^%@^%d", appid, host, name, external ? 1 : 0)
    }

}
