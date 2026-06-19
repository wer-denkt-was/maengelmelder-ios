//
//  CategoryConfig.swift
//
//  Created by Felix on 11.05.21.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

public protocol CustomCategoryConfig {
    func getIconTo(id: Int) -> UIImage?
    func getBaseImageTo(id: Int) -> UIImage?
}

public class CategoryConfig {
    
    public class func getMarkerTo(report: ReportMO, selected: Bool = false) -> UIImage {
        return getMarkerTo(report: report.markerGraphicForMap(system: nil), selected: selected)
    }
    
    public class func getMarkerTo(report: ReportMapMarker, selected: Bool = false) -> UIImage {
        guard let baseImage = MMSettings.shared.customCategoryConfig?.getBaseImageTo(id: report.typeID.intValue), let icon = MMSettings.shared.customCategoryConfig?.getIconTo(id: report.typeID.intValue) else {
            if selected {
                return self.getMarkerImage(name: report.imageName.appending("-selected"))
            } else {
                return self.getMarkerImage(name: report.imageName)
            }
        }
        
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContext(size)
        baseImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        icon.draw(in: CGRect(x: 12, y: 10, width: size.width-25, height: size.height-25), blendMode: .normal, alpha: 1)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? UIImage()
    }
    
    private class func getMarkerImage(name: String) -> UIImage {
        // Look for the image in application's asset first
        if let image = UIImage(named: name) {
            return image
        }
        // If not available, look inside the module's
        return UIImage(named: name, in: MM.shared.bundle, compatibleWith: nil) ?? UIImage()
    }
}
