//
//  MapViewCollectionViewCell.swift
//  MM
//
//  Created by Felix on 25.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import MapKit

class MapViewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var mapview: MKMapView!
    
    var mapManager : MapManager?
    
}
