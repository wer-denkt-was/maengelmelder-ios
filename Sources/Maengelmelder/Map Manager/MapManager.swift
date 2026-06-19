//
//  MapManager.swift
//  Maengelmelder
//
//  Created by Felix on 20.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

protocol MapManagerDelegate {
    func didSelect(view: ReportMapMarkerView?)
    func mapFinishedMoving()
    func mapStartMoving()
}

class MapManager : NSObject, MKMapViewDelegate {
    
    private static var PREFIX_KEY_OFFLINEMAPVERSION = "offlinemapversion."
    
    fileprivate var mapView: MKMapView!
    fileprivate var screenId : String?
    fileprivate var locationManager: CLLocationManager?
    fileprivate let tpks : [String] = []
    fileprivate var mapType = MMSettings.shared.defaultBaseMapType
    
    fileprivate var modifingMap = false
    
    private var satelliteMapOverlay : MKOverlay? = nil
    
    var delegate:MapManagerDelegate?
    
    init(mapView : MKMapView, screenIdentifier: String) {
        super.init()
        locationManager = CLLocationManager()
        self.mapView = mapView
        self.screenId = screenIdentifier
        setUpMap()
    }

    private func setUpMap() {
        self.mapView.delegate = self
        self.mapView.showsUserLocation = true
        self.mapView.showsCompass = true
        self.mapView.accessibilityElementsHidden = true
        
        let canLoadOfflineLayer = !InternetUtility.shared.isOnline() && MMSettings.shared.offlineMaps.count > 0
        if (canLoadOfflineLayer) {
            self.loadOfflineLayers()
        } else {
            if let lastMapType = UserDefaults.standard.string(forKey: "mapManager.mapType") {
                self.mapType = lastMapType == "streets" ? .streets : .satellite
            }
            self.setupOnlineMap()
            self.loadLocalLayers()
            self.refreshOnlineBasemap(self.mapType)
        }
    }
    
    private func setupOnlineMap() {
        self.mapView.mapType = .standard
        
        if let location = self.locationManager?.location, screenId == GlobalFlagValues.REPORT_SCREEN_NEW_MODE {
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: 5000, pitch: 0, heading: 0), animated: false)
        }
        
        if let satelliteLayer = MMSettings.shared.satelliteMapLayer {
            self.satelliteMapOverlay = createOverlay(layer: satelliteLayer)
        }
    }
    
    private func loadLocalLayers() {
        for (name, localLayer) in MMSettings.shared.localMapLayers {
            if UserDefaults.standard.bool(forKey: "localLayer." + name) {
                self.mapView.addOverlays(localLayer.getOverlays(), level: .aboveLabels)
            }
        }
        
        if InternetUtility.shared.isOnline() {
            for layer in MMSettings.shared.mapLayers {
                let overlay = createOverlay(layer: layer)
                self.mapView.addOverlay(overlay, level: .aboveLabels)
            }
        }
    }
    
    public func hasBothTypesOfOfflineMapsDownloaded() -> Bool {
        let downloadedMaps = MMSettings.shared.offlineMaps.filter({ $0.isDownloaded })
        let streetsMapsCount = downloadedMaps.filter({ $0.type == "streets" }).count
        let satelliteMapsCount = downloadedMaps.filter({ $0.type == "satellite" }).count
        return streetsMapsCount > 0 && satelliteMapsCount > 0
    }
    
    private func loadOfflineLayers() {
        // Load the correct map layers
        let mapType = UserDefaults.standard.string(forKey: "mapManager.mapType") ?? "streets" // Either street or satellite
        
        // get the downloaded maps
        var downloadedMapFiles = MMSettings.shared.offlineMaps.filter({ map in
            return map.isDownloaded && mapType == map.type
        })
        if downloadedMapFiles.isEmpty {
            // If there is no map file of the given type, just get every downloaded map file
            downloadedMapFiles = MMSettings.shared.offlineMaps.filter({ map in
                return map.isDownloaded
            })
        }
        
        for map in downloadedMapFiles {
            self.mapView.addOverlays(LocalLayer(urlString: map.localURL.absoluteString, color: nil).getOverlays(), level: .aboveLabels)
        }
    }
    
    private func createOverlay(layer: (Int, String, String, Double, String, String)) -> MKOverlay {
        var overlay: MKOverlay!
        let mapType = layer.4
        if mapType == "wms" {
            let wmsOverlay = WMSTileOverlay(baseURL: layer.2, layers: layer.5, alpha: layer.3)
            overlay = wmsOverlay
        } else {
            // By default it's xyz map
            let xyzOverlay = URLTileOverlay(urlTemplate: layer.2)
            xyzOverlay.tileSize = CGSize(width: 256, height: 256)
            xyzOverlay.alpha = layer.3
            overlay = xyzOverlay
        }
        return overlay
    }
        
    func reloadLayers() {
        self.mapView.removeOverlays(self.mapView.overlays)
        self.loadLocalLayers()
    }
    
    func changeBaseMap() -> MapType  {
        self.mapType = self.mapType == .streets ? .satellite : .streets
        
        let canLoadOfflineLayer = !InternetUtility.shared.isOnline() && MMSettings.shared.offlineMaps.count > 0
        if (canLoadOfflineLayer) {
            self.mapView.removeOverlays(self.mapView.overlays)
            self.loadOfflineLayers()
        } else {
            self.reloadLayers()
            self.refreshOnlineBasemap(self.mapType)
        }
        
        // Store it
        let newType = self.mapType == .streets ? "streets" : "satellite"
        UserDefaults.standard.set(newType, forKey: "mapManager.mapType")
        
        return self.mapType
    }
    
    func refreshOnlineBasemap(_ type: MapType) {
        if type == .streets {
            // Remove the satellite overlay if exists
            if satelliteMapOverlay != nil {
                self.mapView.removeOverlay(satelliteMapOverlay!)
            }
            self.mapView.mapType = .standard
        } else {
            // Add the satellite overlay if exists
            if satelliteMapOverlay != nil {
                self.mapView.addOverlay(satelliteMapOverlay!, level: .aboveRoads)
            } else {
                self.mapView.mapType = .satellite
            }
        }
    }
    
    public func getMapCenterLocation () -> CLLocationCoordinate2D {
        return self.mapView?.centerCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    public func checkOfflineMapVersion(vc: UIViewController) {
        let downloadedMaps = MMSettings.shared.offlineMaps.filter({ $0.isDownloaded })
        let versionCheckUrl = MMSettings.shared.offlineMapVersionCheckUrl
        // Try checking offline map version
        if versionCheckUrl != "" {
            
            MMApi.shared.getOfflineMapVersion() { (version, error) in
                if let v = version {
                    
                    // Check the outdated maps
                    let outdatedMaps = downloadedMaps.map { map in
                        return MapManager.isMapFileOutdated(map: map, currentVersion: v)
                    }
                    
                    // If there is at least one outdated map, trigger the alert
                    if outdatedMaps.contains(true) && outdatedMaps.count > 0 {
                        DispatchQueue.main.async {
                            let alert = UIAlertController(title: "Neue Offline-Karten verfügbar", message: "Es sind aktualisierte Offline-Karten verfügbar. Sie können Ihre heruntergeladenen Kartendateien unter \"Offline-Modus verwalten\" aktualisieren.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Verstanden", style: .default, handler: nil))
                            vc.present(alert, animated: true)
                        }
                    }
                    
                    // Update the whole version
                    UserDefaults.standard.set(v, forKey: "mapManager.offlineMapVersion")
                }
            }
        }
    }
    
    public static func isMapFileOutdated(map: DownloadableMap, currentVersion: Int) -> Bool {
        if !map.isDownloaded {
            return false
        }
        let mapVersion = UserDefaults.standard.integer(forKey: MapManager.PREFIX_KEY_OFFLINEMAPVERSION + map.name)
        return mapVersion < currentVersion
    }
    
    public static func setMapFileUpdated(map: DownloadableMap, currentVersion: Int) {
        if map.isDownloaded {
            UserDefaults.standard.set(currentVersion, forKey: MapManager.PREFIX_KEY_OFFLINEMAPVERSION + map.name)
        }
    }
    
    //MARK: Map Drawings
    
    public func addMarkerToMap(marker: ReportMapMarker) {
        if !self.mapView.annotations.contains(where: { (m) -> Bool in
            return (m as? ReportMapMarker)?.reportID == marker.reportID
        }) {
            self.mapView.addAnnotation(marker)
        }
    }
    
    public func addGroupToMap(_ group: ReportGroup) {
        self.mapView.addAnnotation(group)
    }
    
    public func selectMapMarker(id: NSNumber) -> ReportGroup? {
        return nil
    }
    
    public func removeMapMarkers(){
        self.mapView.removeAnnotations(self.mapView.annotations)
    }
    
    //MARK: Map Delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is ReportGroup {
            return ReportMapMarkerView(annotation: annotation as? ReportGroup, reuseIdentifier: "marker")
        }
        	
        if annotation is ReportMapMarker {
            let view = ReportMapMarkerView(annotation: ReportGroup(with: annotation as! ReportMapMarker), reuseIdentifier: "marker")
            view.canAnimate = (annotation as! ReportMapMarker).canAnimate
            return view
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        delegate?.didSelect(view: view as? ReportMapMarkerView)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        delegate?.didSelect(view: nil)
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        delegate?.mapStartMoving()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.camera.altitude < 150 && !modifingMap {
            modifingMap = true
            mapView.camera.altitude = 150
            modifingMap = false
        }
        delegate?.mapFinishedMoving()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            switch overlay {
                case let overlay as MKMultiPolygon:
                    return createMultiPolygonRenderer(for: overlay)
                case let overlay as MKMultiPolyline:
                    return createMultiPolylineRenderer(for: overlay)
                case let overlay as MBTilesOverlay:
                    return MKTileOverlayRenderer(tileOverlay: overlay)
                case let overlay as URLTileOverlay:
                    let renderer = MKTileOverlayRenderer(tileOverlay: overlay)
                    renderer.alpha = (overlay as URLTileOverlay).alpha
                    return renderer
                case let overlay as WMSTileOverlay:
                    let renderer = MKTileOverlayRenderer(tileOverlay: overlay)
                    renderer.alpha = (overlay as WMSTileOverlay).alpha
                    return renderer
                default:
                    return MKOverlayRenderer(overlay: overlay)
                }
        }
        
        private func createMultiPolygonRenderer(for multiPolygon: MKMultiPolygon) -> MKMultiPolygonRenderer {
            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.fromHex(hexString: multiPolygon.title ?? "#000000")
            renderer.fillColor = UIColor.fromHex(hexString: multiPolygon.title ?? "#000000")
            renderer.alpha = 0.5
            
            return renderer
        }
        
        private func createMultiPolylineRenderer(for multiPolyline: MKMultiPolyline) -> MKMultiPolylineRenderer {
            let renderer = MKMultiPolylineRenderer(multiPolyline: multiPolyline)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor.fromHex(hexString: multiPolyline.title ?? "#000000")
            renderer.fillColor = UIColor.fromHex(hexString: multiPolyline.title ?? "#000000")
            renderer.alpha = 0.5
            
            return renderer
        }
}
