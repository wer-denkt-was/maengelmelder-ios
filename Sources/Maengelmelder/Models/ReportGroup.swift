//
//  ReportGroup.swift
//  MM
//
//  Created by Felix on 06.04.20.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ReportGroup: NSObject, MKAnnotation {
    
    private var reports = Array<ReportMapMarker>()
    private var minCoords = CLLocationCoordinate2D(latitude: Double.leastNormalMagnitude, longitude: Double.leastNormalMagnitude)
    private var maxCoords = CLLocationCoordinate2D(latitude: Double.greatestFiniteMagnitude, longitude: Double.greatestFiniteMagnitude)
    private var dead = false
    private var small = false
    
    ///The center coordinate of the group
    var coordinate: CLLocationCoordinate2D {
        var center = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        for report in reports {
            center.latitude += report.coordinate.latitude
            center.longitude += report.coordinate.longitude
        }
        
        center.latitude /= Double(reports.count)
        center.longitude /= Double(reports.count)
        
        return center
    }
    
    init(with report: ReportMapMarker) {
        reports.append(report)
        minCoords = CLLocationCoordinate2D(latitude: report.coordinate.latitude, longitude: report.coordinate.longitude)
        maxCoords = CLLocationCoordinate2D(latitude: report.coordinate.latitude, longitude: report.coordinate.longitude)
    }
    
    /**
     - returns: The list of reports that are part of this group
     */
    func getReports() -> Array<ReportMapMarker> {
        return self.reports
    }
    
    func isAlive() -> Bool {
        return !dead
    }
    
    func setDead() {
        self.dead = true
    }
    
    func setSmall(_ value: Bool) {
        self.small = value
    }
    
    func join(group: ReportGroup) {
        for report in group.getReports() {
            self.reports.append(report)
            self.minCoords.latitude = min(minCoords.latitude, report.coordinate.latitude)
            self.minCoords.longitude = min(minCoords.longitude, report.coordinate.longitude)
            self.maxCoords.latitude = max(maxCoords.latitude, report.coordinate.latitude)
            self.maxCoords.longitude = max(maxCoords.longitude, report.coordinate.longitude)
        }
    }
    
    func overlaps(with group:ReportGroup, threshold: CGFloat, mapView:MKMapView) -> Bool {
        let myP = mapView.convert(self.coordinate, toPointTo: mapView)
        let yourP = mapView.convert(group.coordinate, toPointTo: mapView)
        
        let dist = (myP.x - yourP.x) * (myP.x - yourP.x) + (myP.y - yourP.y) * (myP.y - yourP.y)
        return dist <= threshold * threshold
    }
    
    func isReallySmall() -> Bool {
        if self.small {
            return true
        }
        
        var maxC = CLLocationCoordinate2D(latitude: -200, longitude: -200)
        var minC = CLLocationCoordinate2D(latitude: 200, longitude: 200)
        for report in self.reports {
            maxC.latitude = max(maxC.latitude, report.coordinate.latitude)
            maxC.longitude = max(maxC.longitude, report.coordinate.longitude)
            minC.latitude = min(minC.latitude, report.coordinate.latitude)
            minC.longitude = min(minC.longitude, report.coordinate.longitude)
        }
        
        let dist = CLLocation(latitude: maxC.latitude, longitude: maxC.longitude).distance(from: CLLocation(latitude: minC.latitude, longitude: minC.longitude))
        return dist < 25
    }
    
    
    func getImage(selected: Bool) -> UIImage? {
        if reports.count == 1 {
            let report = reports.first!
            return CategoryConfig.getMarkerTo(report: report, selected: selected)
        } else {            
            let threeOrMore = reports.count > 2
            
            var images = Array<UIImage>()
            for r in reports {
                images.append(CategoryConfig.getMarkerTo(report: r))
            }
            
            while images.count < 3 {
                images.append(images.last!)
            }
            
            let width = images[1].size.width
            let height = images[1].size.height
            let xOffset = width / 4
            let yOffset = xOffset / 2
            let bitWidth = (width + (threeOrMore ? xOffset*2 : xOffset))
            let bitHeight = (height + yOffset)
            UIGraphicsBeginImageContextWithOptions(CGSize(width: bitWidth, height: bitHeight), false, 0)
            images[0].draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            if threeOrMore {
                images[1].draw(in: CGRect(x: xOffset*2, y: 0, width: width, height: height))
            }
            images[2].draw(in: CGRect(x: xOffset, y: yOffset, width: width, height: height))
            
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
    }
    
    func getBounds() -> MKMapRect {
        let p1 = MKMapPoint(minCoords)
        let p2 = MKMapPoint(maxCoords)
        return MKMapRect(x: p1.x, y: p1.y, width: fabs(p1.x-p2.x), height: fabs(p1.y-p2.y))
    }
    
    static func == (lhs: ReportGroup, rhs: ReportGroup) -> Bool {
        return lhs === rhs
    }

}
