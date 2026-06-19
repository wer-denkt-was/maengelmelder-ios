//
//  ReportPositionViewController.swift
//  Maengelmelder
//
//  Created by Felix on 29.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MaterialShowcase
import MapKit
import JGProgressHUD

class ReportPositionViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var updatePositionButton: UIButton!
    @IBOutlet weak var myLocationButton: UIButton!
    @IBOutlet weak var mapTypeButton: UIButton!
    @IBOutlet weak var crosshairView: UIImageView!
    @IBOutlet weak var newMarkerView: UIImageView!
    @IBOutlet weak var newMarkerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var crosshairWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchAdressContainer: UIView!
    @IBOutlet weak var searchAdressContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var searchAdressField: UITextField!
    @IBOutlet weak var searchAdressButton: UIButton!
    
    fileprivate var mapManager : MapManager?
    fileprivate var viewModel : ReportPositionViewModel?
    fileprivate var parentTabController : ReportCreationTabViewController?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = LocalizedString("HEADING_STEP_1", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = LocalizedString("HEADING_STEP_1", comment: "")
    }
    
    override func viewDidLoad() {
        parentTabController = parent as? ReportCreationTabViewController
        
        viewModel = ReportPositionViewModel(parentController: parentTabController!)
        
        self.mapManager = MapManager(mapView: self.mapView!, screenIdentifier: self.parentTabController!.screenMode!)
        self.mapManager?.delegate = self
        
        //If we hava a forced location from a URL, then do not allow to change the position
        self.mapView.isUserInteractionEnabled = !(self.parentTabController?.externalData?.shouldForceLocation() ?? false)
            
        if(self.parentTabController!.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_MODE){
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: viewModel!.getReportPosition(), fromDistance: 5000, pitch: 0, heading: 0), animated: false)
        } else {
            if self.parentTabController?.report?.long == 0 && self.parentTabController?.report?.lat == 0 {
                let coord = CLLocationManager().location?.coordinate
                self.viewModel?.updateReport(lat: NSNumber(value: coord?.latitude ?? 0), long: NSNumber(value: coord?.longitude ?? 0), address: "")
            }
            let distance : CLLocationDistance = (self.parentTabController?.report?.long == 0 && self.parentTabController?.report?.lat == 0) ? 100000000 : 5000
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: viewModel!.getReportPosition(), fromDistance: distance, pitch: 0, heading: 0), animated: false)
            
            parentTabController!.isReportPositionUpdated = true
        }
        
        self.newMarkerView.isHidden = MMSettings.shared.requireManualPositionUpdate
        let report = self.parentTabController?.report
        let overrideMarker = report?.reportType != nil ? "" : "marker-new"
        if MMSettings.shared.requireManualPositionUpdate,
            let marker = self.parentTabController?.report?.markerGraphicForMap(system: self.parentTabController?.system, overrideMarkerImageName: overrideMarker) {
            marker.canAnimate = true
            self.mapManager?.addMarkerToMap(marker: marker)
        }
        
        self.crosshairView.image = UIImage(named: "crosshair", in: MM.shared.bundle, compatibleWith: nil)
        self.crosshairView.tintColor = self.crosshairView.isDarkMode() ? .white : .black
        
        self.searchAdressContainer.isHidden = !MMSettings.shared.showSearchBarInPosition
        self.searchAdressContainerHeight.constant = MMSettings.shared.showSearchBarInPosition ? 35 : 0
        self.searchAdressContainer.backgroundColor = MMColorScheme.shared.getColor(isDark: self.searchAdressContainer.isDarkMode(), type: .barTint)
        self.searchAdressButton.backgroundColor = MMColorScheme.shared.getColor(isDark: self.searchAdressButton.isDarkMode(), type: .buttonBg)
        self.searchAdressButton.setTitleColor(MMColorScheme.shared.getColor(isDark: self.searchAdressButton.isDarkMode(), type: .buttonTitleText), for: .normal)
        self.searchAdressField.returnKeyType = .search
        self.searchAdressField.delegate = self
        
        self.crosshairView.isHidden = !self.mapView.isUserInteractionEnabled
        self.updatePositionButton.isHidden = !self.mapView.isUserInteractionEnabled
        self.searchAdressContainer.isHidden = !self.mapView.isUserInteractionEnabled
        self.myLocationButton.isHidden = !self.mapView.isUserInteractionEnabled
        
        if !InternetUtility.shared.isOnline() {
            self.mapTypeButton.isHidden = !(self.mapManager?.hasBothTypesOfOfflineMapsDownloaded() ?? false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].wasTabOpened = true
        
        if !showTutorial() {
            if CLLocationManager().location == nil && self.parentTabController?.report?.long == 0 && self.parentTabController?.report?.lat == 0 {
                self.mapView.setCamera(MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), fromDistance: 100000000, pitch: 0, heading: 0), animated: false)
                let alert = UIAlertController(title: "Keine Position", message: "Ihre aktuelle Position konnte (bis jetzt) noch nicht bestimmt werden. Bitte wählen Sie die Position der Meldung manuell aus!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTopNavBarAccessories()
        
        self.updatePositionButton.backgroundColor = MMColorScheme.shared.getColor(view: updatePositionButton, type: .buttonBg)
        self.updatePositionButton.setTitleColor(MMColorScheme.shared.getColor(view: updatePositionButton, type: .buttonTitleText), for: .normal)
        
        self.myLocationButton.backgroundColor = MMColorScheme.shared.getColor(view: myLocationButton, type: .buttonBg)
        self.myLocationButton.tintColor = MMColorScheme.shared.getColor(view: myLocationButton, type: .buttonTitleText)
        
        if (self.parentTabController?.report?.reportType) != nil {
            self.newMarkerView.image = CategoryConfig.getMarkerTo(report: (self.parentTabController?.report)!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        parentTabController = parent as? ReportCreationTabViewController
        parentTabController?.tabsViewHelper?[parentTabController!.selectedIndex].reportDidUpdatedAtTab = true
    }
    
    private func showTutorial() -> Bool {
        if !MMSettings.shared.showTypesFirst && !UserDefaults.standard.bool(forKey: "SecondTutorialFinished") {
            let showcase = TutorialUtility.getTutorialView(target: self.parentTabController!.tabBar, width: 80, primaryText: LocalizedString("SHOWCASE_NAVIGATION_TITLE", comment: ""), secondaryText: LocalizedString("SHOWCASE_NAVIGATION_MESSAGE", comment: ""))
        
            showcase.delegate = self
            showcase.show(completion: {
                UserDefaults.standard.set(true, forKey: "SecondTutorialFinished")
            })
            return true
        }
        return false
    }
    
    private func setTopNavBarAccessories() {
        self.updatePositionButton.setTitle(" " + LocalizedString("UPDATE_POS_BTN_TITLE", comment: "") + " ", for: UIControl.State.normal)
        
        parent!.navigationItem.title = LocalizedString("HEADING_STEP_1", comment: "")
    }
    
    public func updateReportContext(checkCategory: Bool, nextStep: Bool, onFinished: ((Bool) -> Void)? = nil) {
        guard self.mapView.isUserInteractionEnabled else {
            if nextStep {
                onFinished?(true)
                self.parentTabController?.goToNextTab(shouldCheck: false)
            }
            return
        }
        
        let location = mapManager!.getMapCenterLocation()
        
        viewModel!.updateReport(lat: NSNumber(value: location.latitude), long: NSNumber(value: location.longitude), address: "")
        
        if InternetUtility.shared.isOnline() && checkCategory {
            
            if MMSettings.shared.checkIfAnyCategoryExistsOnPosition {
                
                let controller = parent as? ReportCreationTabViewController
                
                let loadingHud = JGProgressHUD(style: .dark)
                loadingHud.textLabel.text = "Position wird geprüft..."
                loadingHud.show(in: self.view)
                
                controller?.checkCategoryAtPosition(callback: { success in
                    loadingHud.dismiss()
                    if !success {
                        onFinished?(false)
                        var alertMsg = MMSettings.shared.messageInvalidPositionText
                        if alertMsg == "" {
                            alertMsg = LocalizedString(MMSettings.shared.showTypesFirst ? "TYPE_FIRST_CATEGORY_NOT_AVAILABLE" : "CATEGORY_NOT_AVAILABLE", comment: "")
                        }
                        let alert = UIAlertController(title: nil, message: alertMsg, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: { _ in
                            if (!MMSettings.shared.checkIfAnyCategoryExistsOnPosition) {
                                (self.parent as? ReportCreationTabViewController)?.goToTab(2)
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else if MMSettings.shared.showTypesFirst {
                        onFinished?(true)
                        self.viewModel?.checkDuplicates()
                    } else if nextStep {
                        onFinished?(true)
                        self.parentTabController?.goToNextTab()
                    }
                })
            } else {
                if nextStep {
                    onFinished?(true)
                    self.parentTabController?.goToNextTab(shouldCheck: false)
                }
            }
        } else {
            if nextStep {
                onFinished?(true)
                self.parentTabController?.goToNextTab(shouldCheck: false)
            }
        }
        
    }
    
    //MARK: view button actions
    
    @IBAction func searchAdressButtonAction(_ sender: Any) {
        if InternetUtility.shared.isOnline() {
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Suche nach Adresse..."
            hud.show(in: self.view)
            MMApi.shared.searchAddress(searchText: self.searchAdressField.text ?? "", domainid: self.parentTabController?.domain?.getID(), system: self.parentTabController?.system, completion: { (lat, lon) in
                if lat == nil || lon == nil {
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.indicatorView?.accessibilityElementsHidden = true
                    hud.textLabel.text = "Es konnte keine Adresse gefunden werden, die den Eingaben entspricht. Bitte versuchen Sie es mit anderen Eingaben erneut."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIAccessibility.post(notification: .announcement, argument: hud.textLabel)
                    }
                    hud.dismiss(afterDelay: 5, animated: true)
                } else {
                    hud.dismiss(animated: true)
                    self.mapView.setCenter(CLLocationCoordinate2D(latitude: lat!, longitude: lon!), animated: false)
                    self.updateReportContext(checkCategory: false, nextStep: false)
                }
            })
        } else {
            let alert = UIAlertController(title: nil, message: LocalizedString("NO_INTERNET", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func myLocationButtonAction(_ sender: Any) {
        guard let location = CLLocationManager().location?.coordinate else {
            let alert = UIAlertController(title: nil, message: "Deine Position konnte nicht bestimmt werden. Bitte überprüfe, ob du der App die Verwendung deines Standortes erlaubst.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.mapView.setCenter(location, animated: true)
    }
    
    @IBAction func updatePositionButtonTapped(_ sender: Any) {
        parentTabController!.isReportPositionUpdated = true
        parentTabController!.fussShouldDelete = false
        updateReportContext(checkCategory: true, nextStep: true) { valid in
            if valid && MMSettings.shared.requireManualPositionUpdate {
                self.mapManager?.removeMapMarkers()
                if let marker = self.parentTabController?.report?.markerGraphicForMap(system: self.parentTabController?.system,
                                                                                      overrideMarkerImageName: "marker-new") {
                    marker.canAnimate = true
                    self.mapManager?.addMarkerToMap(marker: marker)
                }
            }
        }
    }

    @IBAction func mapTypButtonTapped(_ sender: Any) {
        let type = self.mapManager?.changeBaseMap() ?? .streets
        
        switch type {
            case .streets:
                self.mapTypeButton.setImage(UIImage(named: "satellite", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
                self.crosshairView.tintColor = self.crosshairView.isDarkMode() ? .white : .black
            case .satellite:
                self.mapTypeButton.setImage(UIImage(named: "street", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
                self.crosshairView.tintColor = .white
        }
    }
}

// MARK: MaterialShowcaseDelegate

extension ReportPositionViewController: MaterialShowcaseDelegate {
    
    func showCaseWillDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        
    }
    
    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        if CLLocationManager().location == nil && self.parentTabController?.report?.long == 0 && self.parentTabController?.report?.lat == 0 {
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 0, longitude: 0), fromDistance: 100000000, pitch: 0, heading: 0), animated: false)
            var alertMsg = MMSettings.shared.messageInvalidPositionText
            if alertMsg == "" {
                alertMsg = "Ihre aktuelle Position konnte (bis jetzt) noch nicht bestimmt werden. Bitte wählen Sie die Position der Meldung manuell aus!"
            }
            let alert = UIAlertController(title: "Keine Position", message: alertMsg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: UITextFieldDelegate

extension ReportPositionViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchAdressField.resignFirstResponder()
        self.searchAdressButtonAction(self.searchAdressButton as Any)
        return true
    }
    
}

//MARK: MapManagerDelegate

extension ReportPositionViewController: MapManagerDelegate {
    func didSelect(view: ReportMapMarkerView?) {
        //Not needed here
    }
    
    func mapStartMoving() {
        if !MMSettings.shared.requireManualPositionUpdate {
            self.crosshairWidthConstraint.constant = 40
            self.newMarkerBottomConstraint.constant = 10
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func mapFinishedMoving() {
        if !MMSettings.shared.requireManualPositionUpdate {
            self.crosshairWidthConstraint.constant = 50
            self.newMarkerBottomConstraint.constant = 0
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            parentTabController?.isReportPositionUpdated = true
            parentTabController?.fussShouldDelete = false
            updateReportContext(checkCategory: false, nextStep: false)
        }
    }
    
    
}
