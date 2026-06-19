//
//  LocalLayer.swift
//  Maengelmelder
//
//  Created by Felix on 20.03.24.
//

import MapKit

/**
 Class for loading map overlays from local files. Currently supported file types:
  - geojson
  - mbtiles
 */
public class LocalLayer {
    
    private let FILE_TYPE_GEOJSON = ".geojson"
    private let FILE_TYPE_MBTILES = ".mbtiles"
    
    private var overlays = Array<MKOverlay>()
    private var color = "#000000"
    
    /**
     Creates a local layer for the map. If the file type is .geojson, the color is used to draw the geometries on the map. Otherwise the color is not needed.
     */
    public init(urlString: String, color: String?) {
        guard urlString.hasSuffix(FILE_TYPE_GEOJSON) || urlString.hasSuffix(FILE_TYPE_MBTILES) else { return }
        self.color = color ?? "#000000"
        if let url = URL(string: urlString) {
            if urlString.hasSuffix(FILE_TYPE_MBTILES) {
                let mbTilesOverlay = MBTilesOverlay(filePath: urlString)
                mbTilesOverlay.canReplaceMapContent = true
                overlays.append(mbTilesOverlay)
                return
            } else {
                do {
                    let geoData = try Data(contentsOf: url)
                    
                    // Use the `MKGeoJSONDevoder` to convert the JSON data into MapKit objects
                    let decoder = MKGeoJSONDecoder()
                    let jsonObjects = try decoder.decode(geoData)
                    
                    parse(jsonObjects)
                } catch {
                    print("Error decoding GeoJSON: \(error).")
                }
            }
        }
    }
    
    func getOverlays() -> [MKOverlay] {
        return self.overlays
    }
    
    private func parse(_ jsonObjects: [MKGeoJSONObject]) {
        for object in jsonObjects {
            if let feature = object as? MKGeoJSONFeature {
                for geometry in feature.geometry {
                    if let multiPolygon = geometry as? MKMultiPolygon {
                        multiPolygon.title = color
                        overlays.append(multiPolygon)
                    } else if let multiPolyline = geometry as? MKMultiPolyline {
                        multiPolyline.title = color
                        overlays.append(multiPolyline)
                    }
                }
            }
        }
    }
}
