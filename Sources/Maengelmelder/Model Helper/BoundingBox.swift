//
//  BoundingBox.swift
//  Maengelmelder
//
//  Created by Felix on 22.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreLocation

public class BoundingBox {
    let ne:CLLocationCoordinate2D
    let sw:CLLocationCoordinate2D
    let center:CLLocationCoordinate2D
    
    public init(ne: CLLocationCoordinate2D, sw: CLLocationCoordinate2D, center: CLLocationCoordinate2D) {
        self.ne = ne
        self.sw = sw
        self.center = center
    }
    
    public init(ne: CLLocationCoordinate2D, sw: CLLocationCoordinate2D) {
        self.ne = ne
        self.sw = sw
        self.center = CLLocationCoordinate2D(latitude: ne.latitude - sw.latitude, longitude: ne.longitude - sw.longitude)
    }
    
    public func containsReport(_ report: ReportMO) -> Bool {
        return report.lat.doubleValue >= sw.latitude && report.lat.doubleValue <= ne.latitude && report.long.doubleValue >= sw.longitude && report.long.doubleValue <= ne.longitude
    }
}
