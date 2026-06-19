//
//  ReportDetails.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

public class ReportDetails: NSObject {
    
    let text:String
    let state:String
    let markerID:Int
    let domainID:Int
    let markerColor:String
    let thumbnailUrls:Array<String>
    let pictureUrls:Array<String>
    let messageid:NSNumber
    let typeid:Int
    let lat:NSNumber
    let lon:NSNumber
    let allowComment:Bool
    let details:[Detail]
    
    struct Detail {
        let title: String
        let value: String
        let type: String
    }
    
    public enum Typ {
        case text
        case typ
        case state
        case date
        case address
        case history
    }
    
    private enum Keys: String, SerializationKey {
        case id
        case lat
        case lon
        case allow_comment
        case text
        case message_type
        case name
        case state_german
        case created
        case address
        case history
        case attachments
        case thumbnails
        case sq256
        case url
        case marker_id
        case marker_color
        case domain
        case public_name
        case manual_text
    }
    
    init (serialization: Serialization) {
        self.text = serialization.value(forKey: Keys.text) ?? ""
        self.state = serialization.value(forKey: Keys.state_german) ?? ""
        self.markerID = serialization.value(forKey: Keys.marker_id) ?? 0
        self.markerColor = serialization.value(forKey: Keys.marker_color) ?? "white"
        self.messageid = serialization.value(forKey: Keys.id) ?? 0
        self.lat = serialization.value(forKey: Keys.lat) ?? 0
        self.lon = serialization.value(forKey: Keys.lon) ?? 0
        self.allowComment = serialization.value(forKey: Keys.allow_comment) ?? false
        
        let attachments = serialization.value(forKey: Keys.attachments) ?? []
        var pictures = Array<String>()
        var thumbnails = Array<String>()
        for item in attachments {
            if let pictureSerial = item as? Serialization {
                let pictureURL = pictureSerial.value(forKey: Keys.url) ?? ""
                if !pictureURL.isEmpty {
                    pictures.append(pictureURL)
                }
                let thumbnailsSerial = pictureSerial.value(forKey: Keys.thumbnails) ?? Serialization()
                let thumbnailURL = thumbnailsSerial.value(forKey: Keys.sq256) ?? ""
                if !thumbnailURL.isEmpty {
                    thumbnails.append(thumbnailURL)
                }
            }
        }
        self.pictureUrls = pictures
        self.thumbnailUrls = thumbnails
        
        let messageType = serialization.value(forKey: Keys.message_type) ?? Serialization()
        self.typeid = messageType.value(forKey: Keys.id) ?? 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = dateFormatter.date(from: serialization.value(forKey: Keys.created) ?? "") ?? Date()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let history = serialization.value(forKey: Keys.history) ?? []
        var historyString = ""
        for entry in history {
            if let entrySerial = entry as? Serialization {
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                let date = dateFormatter.date(from: entrySerial.value(forKey: Keys.created) ?? "") ?? Date()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                
                let ownerSerial = entrySerial["owner"] as? Serialization
                let ownerName:String = ownerSerial?.value(forKey: Keys.public_name) ?? ""
                
                historyString.append(contentsOf: dateFormatter.string(from: date))
                historyString.append(contentsOf: " ")
                historyString.append(contentsOf: ownerName)
                historyString.append(contentsOf: "\n")
                if let text:String = entrySerial.value(forKey: Keys.text), !text.isEmpty {
                    historyString.append(contentsOf: text)
                    historyString.append(contentsOf: "\n")
                }
                if let manual:String = entrySerial.value(forKey: Keys.manual_text), !manual.isEmpty {
                    historyString.append(contentsOf: manual)
                    historyString.append(contentsOf: "\n")
                }
                historyString.append(contentsOf: "\n")
            }
        }
        if !historyString.isEmpty {
            historyString = String(historyString.dropLast(2))
        }
        
        var details = Array<Detail>()
        for (key, value) in MMSettings.shared.messageDetailsConfig {
            switch value {
            case .text:
                details.append(Detail(title: key, value: self.text, type: "text"))
            case .address:
                details.append(Detail(title: key, value: serialization.value(forKey: Keys.address) ?? "", type: "address"))
            case .date:
                details.append(Detail(title: key, value: dateFormatter.string(from: date), type: "date"))
            case .history:
                details.append(Detail(title: key, value: historyString, type: "history"))
            case .state:
                details.append(Detail(title: key, value: self.state, type: "state"))
            case .typ:
                details.append(Detail(title: key, value: messageType.value(forKey: Keys.name) ?? "", type: "typ"))
            }
        }
        
        self.details = details
        
        if let domainDict:Serialization = serialization.value(forKey: Keys.domain) {
            self.domainID = domainDict.value(forKey: Keys.id) ?? 32
        } else {
            self.domainID = 32
        }
    }
    
    func getDetailValueString(for index: Int, and darkMode: Bool) -> NSAttributedString {
        let item = self.details[index]
        let textContent = item.value.replacingOccurrences(
            of: "\n",
            with: "<br/>"
        )
        
        if item.type == "history", let textData = textContent.data(using: .utf8), let attributedText = try? NSMutableAttributedString(
            data: textData,
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil) {
            attributedText.addAttributes([.font: MMFontScheme.shared.normalTextFont!, .foregroundColor: MMColorScheme.shared.getColor(isDark: darkMode, type: .tableViewCellText)], range: NSRange(location: 0, length: attributedText.length))
            return attributedText
        } else {
            return NSAttributedString(string: item.value, attributes: [
                NSAttributedString.Key.font: MMFontScheme.shared.normalTextFont!,
                NSAttributedString.Key.foregroundColor: MMColorScheme.shared.getColor(isDark: darkMode, type: .tableViewCellText)
            ])
        }
        
    }

}
