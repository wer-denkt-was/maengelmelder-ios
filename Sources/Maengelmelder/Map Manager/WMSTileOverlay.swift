//
//  WMSTileOverlay.swift
//  Maengelmelder
//
//  Created by Jason Christian on 16.09.25.
//  Mithilfe von ChatGPT
//

import MapKit

class WMSTileOverlay: MKTileOverlay {		
    //  baseURL example: https://my.qgisserver.com/mapserver.qgz
    let baseURL: String
    let layers: String
    let srs: String
    let dimension: Int
    let wmsVersion: String
    let imageFormat: String
    let alpha: CGFloat

    init(baseURL: String,
         layers: String,
         srs: String = "EPSG:3857",
         dimensionPx: Int = 256,
         wmsVersion: String = "",
         imageFormat: String = "image/png",
         alpha: CGFloat = 1.0)
    {
        self.baseURL = baseURL
        self.layers = layers
        self.srs = srs
        self.dimension = dimensionPx
        self.wmsVersion = wmsVersion
        self.imageFormat = imageFormat
        self.alpha = alpha
        super.init(urlTemplate: nil)
        self.tileSize = CGSize(width: dimension, height: dimension)
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // Convert tile path to bounding box in EPSG:3857
        let mercatorSize = 20037508.3427892 * 2
        let zoomScale = mercatorSize / pow(2.0, Double(path.z))
        
        let minx = -20037508.3427892 + Double(path.x) * zoomScale
        let maxx = -20037508.3427892 + (Double(path.x) + 1) * zoomScale
        let miny = 20037508.3427892 - (Double(path.y) + 1) * zoomScale
        let maxy = 20037508.3427892 - Double(path.y) * zoomScale
        
        let bbox = "\(minx),\(miny),\(maxx),\(maxy)"
        
        var urlString = baseURL
        urlString += "?SERVICE=WMS"
        urlString += "&REQUEST=GetMap"
        if self.wmsVersion != "" {
            urlString += "&VERSION=\(self.wmsVersion)"
        }
        urlString += "&LAYERS=\(self.layers)"
        urlString += "&SRS=\(self.srs)"
        urlString += "&BBOX=\(bbox)"
        urlString += "&WIDTH=\(self.dimension)"
        urlString += "&HEIGHT=\(self.dimension)"
        urlString += "&FORMAT=\(self.imageFormat)"
        urlString += "&TRANSPARENT=TRUE"
        
        print (urlString)

        return URL(string: urlString)!
    }
}
