//
//  PictureBundle.swift
//  MM
//
//  Created by Felix on 31.08.20.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

public class PictureBundle {
    
    let token:String
    let filenames:Array<String>
    
    var expectedFilenames : String {
        var json = "["
        for filename in filenames {
            json.append("\"")
            json.append(filename)
            json.append("\", ")
        }
        json = String(json.dropLast())
        json = String(json.dropLast())
        json.append("]")
        return json
    }
    
    private enum Keys : String, SerializationKey {
        case token
        case files
        case filename
    }
    
    init(json: Serialization) {
        self.token = json.value(forKey: Keys.token) ?? ""
        
        var filenames = Array<String>()
        let files:Array<Serialization> = json.value(forKey: Keys.files) ?? []
        for file in files {
            filenames.append(file.value(forKey: Keys.filename) ?? "")
        }
        self.filenames = filenames
    }
}
