//
//  ReviewViewModel.swift
//  MM
//
//  Created by Felix on 11.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import JGProgressHUD

class ReviewViewModel: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    fileprivate let viewsParentController : ReportCreationTabViewController
    fileprivate var isIdea = false
    
    var showMap : Bool {
        return !isIdea && (viewsParentController.report?.reportType?.position ?? "") != "never"
    }
    
    fileprivate var attributes = Array<ReportTypeAttributeMO>()
    
    init(parentController: ReportCreationTabViewController) {
        self.viewsParentController = parentController
        super.init()
        
        self.isIdea = parentController.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA || parentController.screenMode == GlobalFlagValues.REPORT_SCREEN_NEW_IDEA
        
        self.attributes = viewsParentController.report?.reportType?.getAttributesFor(update: false) ?? []
        self.attributes.sort(by: { (att1, att2) -> Bool in
            return att1.ordering.compare(att2.ordering) == .orderedAscending
        })
        
        if viewsParentController.system == nil || viewsParentController.domain == nil {
            fetchSystems()
        }
    }
    
    func fetchSystems() {
        MMApi.shared.getSystems(lat: viewsParentController.report?.lat.doubleValue ?? 0, lon: viewsParentController.report?.long.doubleValue ?? 0) { systems, error in
            self.searchForDomain(systems: systems ?? [])
        }
    }
    
    private func searchForDomain(systems: [System]) {
        guard let idToFind = viewsParentController.report?.domainid?.intValue else {
            return
        }
        let lat = viewsParentController.report?.lat.doubleValue ?? 0
        let lon = viewsParentController.report?.long.doubleValue ?? 0
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        for sys in systems {
            if sys.external || !hasExternal {
                MMApi.shared.getDomain(lat: lat, lon: lon, system: sys) { domain, error in
                    MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MM.shared.managedObjectContext)
                    if idToFind == domain?.getID() {
                        self.viewsParentController.domain = domain
                        self.viewsParentController.system = sys
                        
                        self.loadSettingsForDomain(with: idToFind, and: sys)
                    }
                }
            }
        }
    }
    
    private func loadSettingsForDomain(with id: Int, and system:System) {
        MMApi.shared.getDomainSettings(domainid: id, system: system) { settingsO, error in
            if let settings = settingsO {
                self.viewsParentController.domain?.setSettings(settings)
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        if !showMap {
            count = ((viewsParentController.report?.reportType?.has_title ?? 0 == 1) ? 4 : 3) + attributes.count
        } else {
            count = ((viewsParentController.report?.reportType?.has_title ?? 0 == 1) ? 5 : 4) +
                attributes.count
        }
        if((viewsParentController.domain?.getAttributesAsDefaultFields() ?? 0) == 1) {
            count-=1;
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo_cell", for: indexPath) as! ImageCollectionCell
            cell.backgroundColor = .lightGray
            if let imagePath = viewsParentController.report?.attachments.array.first as? String {
                let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                cell.backgroundColor = .clear
                cell.imageView.contentMode = .scaleToFill
                cell.imageView.image = UIImage(contentsOfFile: baseURL.appendingPathComponent(imagePath).path)
            } else {
                cell.backgroundColor = .lightGray
                cell.imageView.contentMode = .center
                cell.imageView.image = UIImage(named: "add_photo", in: MM.shared.bundle, compatibleWith: nil)
            }
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer(_:))
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToPictures)))
            
            cell.accessibilityLabel = "Fotos ändern"
            cell.isAccessibilityElement = true
            cell.accessibilityTraits = .button
            return cell
        } else if indexPath.row == 1 && showMap {
            let report = viewsParentController.report
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "map_cell", for: indexPath) as! MapViewCollectionViewCell
            cell.mapview.isUserInteractionEnabled = false
            cell.mapManager = MapManager(mapView: cell.mapview, screenIdentifier: "")
            cell.mapview.removeAnnotations(cell.mapview.annotations)
            cell.mapview.setCamera(MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: report?.lat.doubleValue ?? 0, longitude: report?.long.doubleValue ?? 0), fromDistance: 500, pitch: 0, heading: 0), animated: false)
            cell.mapManager?.addGroupToMap(ReportGroup(with: report!.markerGraphicForMap(system: viewsParentController.system)))
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer(_:))
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToMap)))
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = "Standort ändern"
            cell.accessibilityTraits = .button
            return cell
        } else if (indexPath.row == 1 && !showMap) || (indexPath.row == 2 && showMap) {
            let report = viewsParentController.report
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category_cell", for: indexPath) as! ReviewCategoryCollectionViewCell
            cell.headerLabel.text = LocalizedString("HEADING_STEP_3", comment: "")
            cell.editAccessor.image = UIImage(named: "ic_edit", in: MM.shared.bundle, compatibleWith: nil)
            cell.editAccessor.tintColor = .lightGray
            if report?.reportType?.name != nil && !report!.reportType!.name!.isEmpty {
                
                let markerImage = CategoryConfig.getMarkerTo(report: report!)
                cell.markerImageView.image = markerImage
                
            } else {
                cell.markerImageView.image = nil
            }
            cell.nameLabel.text = viewsParentController.report?.reportType?.name ?? ""
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer(_:))
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToTypes)))
            cell.accessibilityLabel = "Kategorie ändern"
            cell.accessibilityTraits = .button
            cell.isAccessibilityElement = true
            return cell
        } else if ((indexPath.row == 3 && showMap) || (indexPath.row == 2 && !showMap)) && ((viewsParentController.report?.reportType?.has_title ?? 0) == 1) && ((viewsParentController.domain?.getAttributesAsDefaultFields() ?? 0) == 0) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "title_cell", for: indexPath) as! ReviewCategoryCollectionViewCell
            cell.headerLabel.text = LocalizedString("TITEL", comment: "")
            cell.editAccessor.image = UIImage(named: "ic_edit", in: MM.shared.bundle, compatibleWith: nil)
            cell.editAccessor.tintColor = .lightGray
            cell.nameLabel.text = viewsParentController.report?.title ?? ""
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer(_:))
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToAttributes)))
            cell.accessibilityLabel = "Titel ändern"
            cell.accessibilityTraits = .button
            cell.isAccessibilityElement = true
            return cell
        } else if (((indexPath.row == 3 && showMap) || (indexPath.row == 2 && !showMap || (indexPath.row == 4 && ((viewsParentController.report?.reportType?.has_title ?? 0) == 1)))) && (viewsParentController.domain?.getAttributesAsDefaultFields() ?? 0) == 0) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "title_cell", for: indexPath) as! ReviewCategoryCollectionViewCell
            cell.headerLabel.text = LocalizedString("DESCRIPTION", comment: "")
            cell.editAccessor.image = UIImage(named: "ic_edit", in: MM.shared.bundle, compatibleWith: nil)
            cell.editAccessor.tintColor = .lightGray
            cell.nameLabel.text = viewsParentController.report?.text ?? ""
            cell.gestureRecognizers?.forEach(cell.removeGestureRecognizer(_:))
            cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToAttributes)))
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = "Beschreibung ändern"
            cell.accessibilityTraits = .button
            return cell
        } else {
            var offset = ((viewsParentController.report?.reportType?.has_title ?? 0) == 1) ? 5 : 4
            if((viewsParentController.domain?.getAttributesAsDefaultFields() ?? 0) == 1) {
                offset = 3
            }
            if !showMap {
                offset = offset - 1
            }
            let attribute = self.attributes[indexPath.row-offset]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "title_cell", for: indexPath) as! ReviewCategoryCollectionViewCell
            cell.headerLabel.text = attribute.name
            cell.editAccessor.image = nil
            if attribute.multiselect == 1 && attribute.answer != nil && attribute.answer! != "" {
                let options = attribute.answer!.components(separatedBy: ";")
                var text = ""
                for opt in options {
                    text.append(opt.components(separatedBy: "^")[1])
                    text.append(", ")
                }
                text.removeLast(2)
                cell.nameLabel.text = text
                
            } else if attribute.answer?.contains("^") ?? false {
                cell.nameLabel.text = String(attribute.answer?.split(separator: "^")[1] ?? "")
            } else {
                cell.nameLabel.text = (attribute.answer ?? "") == "" ? "-" : attribute.answer
            }
            return cell
        }
    }
    
    @objc private func goToAttributes() {
        self.viewsParentController.selectedIndex = !showMap ? 2 : 3
    }
    
    @objc private func goToTypes() {
        if MMSettings.shared.showTypesFirst {
            self.viewsParentController.selectedIndex = 0
        } else {
            self.viewsParentController.selectedIndex = !showMap ? 1 : 2
        }
    }
    
    @objc private func goToPictures() {
        self.viewsParentController.selectedIndex = !showMap ? 0 : 1
    }
    
    @objc private func goToMap() {
        if MMSettings.shared.showTypesFirst {
            self.viewsParentController.selectedIndex = 2
        } else {
            self.viewsParentController.selectedIndex = 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width-20
        if indexPath.row == 0 && !showMap {
            return CGSize(width: width, height: width/2)
        }
        if indexPath.row <= 1 && showMap {
            return CGSize(width: (width-20)/2, height: (width-20)/2)
        } else if indexPath.row <= 3 {
            return CGSize(width: width, height: 75)
        } else if indexPath.row == 4{
            let text = viewsParentController.report?.text ?? ""
            let size = text.boundingRect(with: CGSize(width: width, height: 0), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:MMFontScheme.shared.normalTextFont!], context: nil)
            return CGSize(width: width, height: 35 + size.height)
        } else {
            return CGSize(width: width, height: 75)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
    }

}
