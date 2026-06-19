//
//  SetPrivateResponse.swift
//
//  Created by Felix on 02.03.22.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation

class SetPrivateResponse: NSObject {
    
    let success : Bool
    
    private enum Keys: String, SerializationKey {
        case success
    }
    
    init (serialization: Serialization) {
        self.success = serialization.value(forKey: Keys.success) ?? true
    }

}
