//
//  ReportMapMarker.swift
//  MM
//
//  Created by Felix on 16.07.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import MapKit

public class ReportMapMarker: NSObject, MKAnnotation {
    
    public dynamic var coordinate: CLLocationCoordinate2D
    public var title: String?
    public var subtitle: String?
    
    public let reportID:NSNumber
    public let domainID:NSNumber
    public let typeID:NSNumber
    public let imageName:String
    public let pictureURL:String?
    public let isPrivate:Bool
    public var canAnimate: Bool = false
    
    public let system: System
    
    init(report: ReportMO, system: System, overrideMarkerImageName: String = "") {
        coordinate = CLLocationCoordinate2D(latitude: report.lat.doubleValue, longitude: report.long.doubleValue)
        
        if report.text == nil || report.text!.isEmpty {
            if report.reportType == nil {
                title = report.state_german
                subtitle = ""
            } else {
                title = report.reportType!.name
                subtitle = report.state_german
            }
        } else {
            title = report.text
            subtitle = report.state_german
        }
        
        reportID = report.id
        domainID = report.domainid ?? 32
        typeID = report.reportType?.id ?? -1
        pictureURL = report.pictureURL
        isPrivate = (report.isPrivate ?? 0) == 1
        
        var imageName = overrideMarkerImageName
        if imageName == "" {
            imageName = String(format:"marker-%@-%d", report.marker_color ?? "white", report.marker_id.intValue)
            if UIImage(named: imageName, in: MM.shared.bundle, compatibleWith: nil) == nil {
                imageName = String(format: "marker-%@-0", report.marker_color ?? "white")
                if UIImage(named: imageName, in: MM.shared.bundle, compatibleWith: nil) == nil {
                    imageName = "marker-white-0"
                }
            }
        }
        self.imageName = imageName
        self.system = system
    }
    
    init(reportDetails: ReportDetails, system: System, overrideMarkerImageName: String = "") {
        coordinate = CLLocationCoordinate2D(latitude: reportDetails.lat.doubleValue, longitude: reportDetails.lon.doubleValue)
        title = reportDetails.text
        subtitle = reportDetails.state
        reportID = reportDetails.messageid
        domainID = NSNumber(value: reportDetails.domainID)
        imageName = overrideMarkerImageName != "" ? overrideMarkerImageName : String(format:"marker-%@-%d", reportDetails.markerColor, reportDetails.markerID)
        typeID = NSNumber(value: reportDetails.typeid)
        pictureURL = nil
        isPrivate = false
        self.system = system
    }
    
    init(coordinate: CLLocationCoordinate2D, overrideMarkerImageName: String = "") {
        self.coordinate = coordinate
        
        self.system = System.fallback
        self.reportID = -1
        self.domainID = -1
        self.typeID = -1
        self.pictureURL = nil
        self.isPrivate = false
        
        imageName = overrideMarkerImageName != "" ? overrideMarkerImageName : "marker-white-0"
    }
}
