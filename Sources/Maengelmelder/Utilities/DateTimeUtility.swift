//
//  DateTimeUtility.swift
//  Maengelmelder
//
//  Created by Felix on 06.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation

class DateTimeUtility {
    
    class func getDateString() -> String{
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        
        let today_string = String(year!) + "-" + String(month!) + "-" + String(day!)
        
        return today_string
        
    }
    
    class func getTimeString() -> String{
        
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        let today_string = String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
        
        return today_string
        
    }
}
