//
//  BasicResponse.swift
//  Maengelmelder
//
//  Created by Felix Leber on 28.10.25.
//

import Foundation

public class BasicResponse: NSObject {
    
    let success : Bool
    let message : String
    
    init(success: Bool, message: String) {
        self.success = success
        self.message = message
    }

}
