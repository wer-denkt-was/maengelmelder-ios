//
//  UploadReportResponse.swift
//  Maengelmelder
//
//  Created by Felix on 06.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//
import Foundation

public class UploadReportResponse: NSObject {
    
    let success : Bool
    let message : String
    let messageid : Int
    
    init(success: Bool, message: String, messageid: Int) {
        self.success = success
        self.message = message
        self.messageid = messageid
    }

}
