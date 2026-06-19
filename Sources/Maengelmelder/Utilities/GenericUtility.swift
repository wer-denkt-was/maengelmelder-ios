//
//  GenericUtility.swift
//  Maengelmelder
//
//  Created by Felix on 31.10.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

/**
 Returns the translation for the specific key (fallback is german).
 
 - parameter key: The key of the required translation
 - parameter comment: The comment of the key
 
 - returns: The translation of the string, german as fallback or the key if no translation exists in german
*/
public func LocalizedString(_ key: String, comment: String) -> String {
    guard let fallbackBundlePath = MM.shared.bundle.path(forResource: "de", ofType: "lproj") else { return key }
    guard let fallbackBundle = Bundle(path: fallbackBundlePath) else { return key }
    let fallbackString = fallbackBundle.localizedString(forKey: key, value: comment, table: nil)
    return MM.shared.bundle.localizedString(forKey: key, value: fallbackString, table: nil)
}

class GenericUtility {
    
    /**
     Returns the completion percentage of the given message.
     
     - parameter report: The message object
     
     - returns: The completion percentage as Float (0-1)
     */
    class func getReportCompletionPercentage(report: ReportMO) -> Float {
        var counter = 1
        if report.reportType != nil {
            counter += 1
        }
        if report.title != nil {
            counter += 1
        }
        if report.desc != nil {
            counter += 1
        }
        if report.attachments.count > 0 {
            counter += 1
        }
        return Float(counter)/Float(5)
    }
    
    class func getInfoPage(for type: InfoPage.Kind) -> InfoPage? {
        return MMSettings.shared.infoPages.first { page in
            return page.type == type
        }
    }
    
    class func applyFilters(filters: Dictionary<String, Any>, reports: Array<ReportMO>) -> Array<ReportMO> {
        guard !filters.isEmpty else { return reports }
        
        var filterdReports = Array<ReportMO>()
        
        let selectedStates = filters["states"] as? [Bool] ?? [true, true, true, true, true]
        let onlyFav = filters["only_fav"] as? Bool ?? false
        let searchTitle = filters["search_title"] as? String ?? ""
        let searchType = filters["search_type"] as? String ?? ""
        
        for report in reports {
            if (onlyFav && report.isLocal == 2) || !onlyFav {
                if searchTitle.isEmpty || (report.text?.contains(searchTitle) ?? false) {
                    if searchType.isEmpty || ((report.typeName ?? "").contains(searchType)) {
                        switch report.marker_color {
                            case "yellow": if selectedStates[0] { filterdReports.append(report) }
                            case "green2": if selectedStates[1] { filterdReports.append(report) }
                            case "red": if selectedStates[2] { filterdReports.append(report) }
                            case "green": if selectedStates[3] { filterdReports.append(report) }
                            case "blue": if selectedStates.count > 4 && selectedStates[4] { filterdReports.append(report) }
                            default: filterdReports.append(report)
                        }
                    }
                }
            }
        }
        return filterdReports
    }
}

extension UIView {
    /**
     Returns true, if the view is in dark mode. Otherwise returns false.
     */
    public func isDarkMode() -> Bool {
        if #available(iOS 12.0, *) {
            return self.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }
}

extension UIImage {
    
    /**
     Resizes the image with the new size.
     */
    func resizedImageWith(size newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return image.withRenderingMode(renderingMode)
    }
    
    /**
     Returns the image with a new blended color.
     */
    public func withColor(_ color: UIColor) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
            color.setFill()

            let context = UIGraphicsGetCurrentContext()
            context?.translateBy(x: 0, y: self.size.height)
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.setBlendMode(CGBlendMode.normal)

            let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
            context?.clip(to: rect, mask: self.cgImage!)
            context?.fill(rect)

            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage ?? UIImage()
        }
    
}
