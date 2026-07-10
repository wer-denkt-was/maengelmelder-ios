//
//  ViewController.swift
//  MM
//
//  Created by Felix on 30.01.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import M13Checkbox
import MapKit
import WebKit
import SideMenu
import MaterialShowcase

class ViewController: UIViewController, MapManagerDelegate {
    
    @IBOutlet weak var bottomBarView: UIView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var createNewReportButton: UIButton!
    @IBOutlet weak var userLocationButton: UIButton!
    @IBOutlet weak var reportsListButton: UIButton!
    @IBOutlet weak var qrCodeButton: UIButton!
    @IBOutlet weak var buttonBar: UIView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!    
    
    @IBOutlet weak var termsView: UIView!
    @IBOutlet weak var sammelCheckButton: UIButton!
    @IBOutlet weak var termsCheckBox: M13Checkbox!
    @IBOutlet weak var privacyCheckbox: M13Checkbox!
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var privacyLabel: UILabel!
    @IBOutlet weak var termsPrivacyWebView: WKWebView!
    @IBOutlet weak var deniedButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var basemapSwitchButton: UIButton!
    
    @IBOutlet weak var calloutView: UIView!
    @IBOutlet weak var calloutTitle: UILabel!
    @IBOutlet weak var calloutSubtitle: UILabel!
    @IBOutlet weak var calloutButton: UIButton!
    
    @IBOutlet weak var ideaContainer: UIView!
    @IBOutlet weak var mangleCard: UIView!
    @IBOutlet weak var ideaCard: UIView!
    
    private let NETWORK_BUTTON_TAG = 1001
    private let LAYER_BUTTON_TAG = 1002
    private let FILTER_BUTTON_TAG = 1003
    
    private var filterButton: UIBarButtonItem?
    private var networkInfoButton: UIBarButtonItem?
    private var menuBarButton: UIBarButtonItem?
    private var titleLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var logoView: UIImageView?
    
    var openUrl : URL?
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var viewModel : ViewModel?
    fileprivate var mapManager : MapManager?
    fileprivate var reportMarkers: [ReportMapMarker]?
    
    fileprivate var selectedGroup: ReportGroup?
    fileprivate var currentDomainID = MMSettings.shared.DEFAULT_DOMAIN_ID
    fileprivate var currentLat:Double = 0
    fileprivate var currentLon:Double = 0
    
    fileprivate var tutorialStep = 0
    fileprivate var maxTutorialSteps = 3
    
    fileprivate var firstLocation = true
    
    fileprivate let offset = UIImage(named: "marker-white-new.png", in: MM.shared.bundle, compatibleWith: nil)!.size.height/2
    
    fileprivate var allGroups = Array<ReportGroup>()
    
    fileprivate var externalData:ExtrernalCreationData?
    
    override func viewWillAppear(_ animated: Bool) {
        termsPrivacyWebView.navigationDelegate = self
        termsPrivacyWebView.isOpaque = false
        
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("newLocation"), object: nil, queue: nil) { (not) in
            if let lat = not.userInfo?["lat"] as? Double, let lon = not.userInfo?["lon"] as? Double, let id = not.userInfo?["id"] as? Int {
                self.mapView.setCenter(CLLocationCoordinate2D(latitude: lat, longitude: lon), animated: true)
                self.selectedGroup = self.mapManager?.selectMapMarker(id: NSNumber(integerLiteral: id))
                if let group = self.selectedGroup, group.getReports().count == 1, let graphic = group.getReports().first {
                    self.calloutTitle.text = graphic.title
                    self.calloutSubtitle.text = graphic.subtitle
                    self.calloutView.isHidden = false
                } else {
                    self.calloutView.isHidden = true
                }
            }
        }	
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowStart"), object: nil, queue: nil) { not in
            self.ideaContainer.isHidden = false
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleManualOfflineMode), name: NSNotification.Name("SetOffline"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateMapWithMarkers(notification:)), name: Notification.Name("reportMarkers"), object: nil)
        
        InternetUtility.shared.delegate = self
        self.onlineStatusChanged(InternetUtility.shared.isOnline())
        self.setTopNavBarAccessories()
        self.setTopNavBarStyle()
        self.setCallout()
        self.setBotBar()
        self.setTermsAndPrivacy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItems = []
        navigationItem.backButtonDisplayMode = .minimal

        MMCoreDataManager.cleanDBofOldReports(moc: MMCoreDataManager.shared.context)
        viewModel = ViewModel(delegate: self)
          
        DispatchQueue.main.async {
            self.mapManager = MapManager(mapView: self.mapView!, screenIdentifier: GlobalFlagValues.REPORT_SCREEN_NEW_MODE)
            self.mapManager?.delegate = self
            self.setUpBaseMapSwitch()
        }
        
        if !CLLocationManager.locationServicesEnabled() || self.locationManager.authorizationStatus == .denied {
            let alert = UIAlertController(title: nil, message: LocalizedString("DENIED_LOCATION", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if self.locationManager.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }
        self.setIdeaOverlay()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let url = self.openUrl, self.viewModel?.isPrivacyAccepted() ?? false  {
            self.externalData = ExtrernalCreationData(with: url)
            self.createNewReportButtonAction(UIButton())
            self.openUrl = nil
            return
        }
        
        if InternetUtility.shared.isOnline() {
            self.getMapRegion { bb in
                self.viewModel?.fetchSystems(bb: bb)
            }
        }
        
        self.mapManager?.checkOfflineMapVersion(vc:self);
    }
    
    private func setUpBaseMapSwitch() {
        // basemap switch button is placed here since it has to wait till map is loaded
        let offlineAndOnlyOneTypeOfMap = !(self.mapManager?.hasBothTypesOfOfflineMapsDownloaded() ?? false) && !InternetUtility.shared.isOnline()
        self.basemapSwitchButton.isHidden = !MMSettings.shared.showMapTypeButtonOnMainMap || offlineAndOnlyOneTypeOfMap
        switch MMSettings.shared.defaultBaseMapType {
            case .streets:
                self.basemapSwitchButton.setImage(UIImage(named: "satellite", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
            case .satellite:
                self.basemapSwitchButton.setImage(UIImage(named: "street", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
        }
    }
    
    func didSelect(view: ReportMapMarkerView?) {
        if let reportGroup = view?.annotation as? ReportGroup {
            if reportGroup.getReports().count == 1 {
                self.selectedGroup = reportGroup
                
                self.calloutTitle.text = reportGroup.getReports().first!.title
                self.calloutSubtitle.text = reportGroup.getReports().first!.subtitle
                self.calloutView.isHidden = false
            } else {
                if reportGroup.isReallySmall() {
                    self.selectedGroup = reportGroup
                    
                    self.calloutTitle.text = String.init(format: "%d Meldungen", reportGroup.getReports().count)
                    self.calloutSubtitle.text = "Tippen Sie, um eine Liste zu öffnen"
                    self.calloutView.isHidden = false
                } else {
                    self.mapView.removeAnnotation(reportGroup)
                    self.mapView.showAnnotations(reportGroup.getReports().map({ (marker) -> ReportGroup in
                        return ReportGroup(with: marker)
                    }), animated: true)
                }
            }
        } else {
            self.selectedGroup = nil
            self.calloutView.isHidden = true
        }
    }
    
    @objc func calloutTapped() {
        if let group = self.selectedGroup, group.getReports().count == 1, let graphic = group.getReports().first {
            if InternetUtility.shared.isOnline() {
                let id = graphic.reportID
                let system = graphic.system
                let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
                let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportDetailController") as! ReportDetailViewController
                vcToPush.reportId = id
                vcToPush.domainId = graphic.domainID
                vcToPush.system = system
                (MMSettings.shared.parentNavigationController ?? self.navigationController)?.pushViewController(vcToPush, animated: true)
            } else {
                self.showNoInternetAlert()
            }
        } else if let group = self.selectedGroup, group.getReports().count > 1 {
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportListController") as? ReportListViewController
            vcToPush?.currentDomainID = self.currentDomainID
            vcToPush?.currentLat = self.currentLat
            vcToPush?.currentLon = self.currentLon
            vcToPush?.selectedGroup = self.selectedGroup?.getReports().count ?? 0 > 1 ? self.selectedGroup : nil
            (MMSettings.shared.parentNavigationController ?? self.navigationController)?.pushViewController(vcToPush!, animated: true)
        }
    }
    
    fileprivate func showNoInternetAlert() {
        let alert = UIAlertController(title: nil, message: LocalizedString("NO_INTERNET", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Top view Customization Functions

    fileprivate func setTopNavBarAccessories() {
        self.menuBarButton = UIBarButtonItem(image: UIImage(named: "hamburger_menu", in: MM.shared.bundle, compatibleWith: nil), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.hamburgerMenuButtonAction(button:)))
        if #available(iOS 26, *) {
            self.menuBarButton?.tintColor = .label
        } else {
            self.menuBarButton?.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        }
        navigationItem.leftBarButtonItem = menuBarButton
        
        if !(navigationItem.rightBarButtonItems ?? []).contains(where: { button in
            return button.tag == FILTER_BUTTON_TAG
        })  && MMSettings.shared.showReportListButton {
            self.filterButton = UIBarButtonItem(image: UIImage(named: "filter_list", in: MM.shared.bundle, compatibleWith: nil), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(self.showFilter))
            self.filterButton?.tag = FILTER_BUTTON_TAG
            navigationItem.rightBarButtonItems?.append(self.filterButton!)
        }
        
        if MMSettings.shared.localMapLayers.count > 0 && !(navigationItem.rightBarButtonItems ?? []).contains(where: { button in
            return button.tag == LAYER_BUTTON_TAG
        }) {
            let rightBarButton = UIBarButtonItem(image: UIImage(named: "ic_layer", in: MM.shared.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(self.showLayerAlert))
            if #available(iOS 26, *) {
                rightBarButton.tintColor = .label
            } else {
                rightBarButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
            }
            rightBarButton.tag = LAYER_BUTTON_TAG
            navigationItem.rightBarButtonItems?.append(rightBarButton)
        }
        
        self.networkInfoButton = UIBarButtonItem(image: UIImage(systemName: "wifi.exclamationmark"), style: .plain, target: self, action: #selector(self.noNetworkButtonAction(sender:)))
        self.networkInfoButton?.tintColor = .red
        self.networkInfoButton?.tag = NETWORK_BUTTON_TAG
    }
    
    @objc fileprivate func showFilter() {
        self.performSegue(withIdentifier: "show_filter", sender: self.filterButton ?? self)
    }
            
    @objc fileprivate func showLayerAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Speichern", style: .default))
        
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 5
        
        var i = 0
        for (name, _) in MMSettings.shared.localMapLayers {
            let label = UILabel()
            label.textColor = MMColorScheme.shared.getColor(view: label, type: .tableViewCellText)
            label.text = name
            label.tag = i
            
            label.sizeToFit()
            
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: "localLayer." + name)
            toggle.setOn(UserDefaults.standard.bool(forKey: "localLayer." + name), animated: true)
            toggle.addTarget(self, action: #selector(self.toggleChanged(sender:)), for: .valueChanged)
            toggle.tag = i
            
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 10
            
            stackView.addArrangedSubview(toggle)
            stackView.addArrangedSubview(label)
            
            mainStackView.addArrangedSubview(stackView)

            i = i + 1
        }
        alert.view.addSubview(mainStackView)
        mainStackView.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 10).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -52).isActive = true
        alert.view.layoutIfNeeded()
        self.present(alert, animated: true)
    }
    
    @objc fileprivate func toggleChanged(sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "localLayer." + MMSettings.shared.localMapLayers[sender.tag].0)
        self.mapManager?.reloadLayers()
    }
    
    fileprivate func setTopNavBarStyle() {
        if #available(iOS 26, *) {
            // On iOS 26+ Liquid Glass manages the bar background — forcing barTintColor/backgroundColor
            // breaks the glass effect. Mark the bar as translucent so UIKit extends the content view
            // to y=0 (behind the nav bar), revealing the map through the glass.
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.tintColor = .label
        } else {
            navigationController?.navigationBar.barTintColor = MMColorScheme.shared.getColor(view: self.view, type: .barTint)
            navigationController?.navigationBar.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
            navigationController?.navigationBar.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .barTint)

            let styleAttrs = [
                NSAttributedString.Key.foregroundColor: MMColorScheme.shared.getColor(view: self.view, type: .titleText),
                NSAttributedString.Key.font: MMFontScheme.shared.titleTextFont!
                ] as [NSAttributedString.Key : Any]

            navigationController?.navigationBar.titleTextAttributes = styleAttrs
        }

        titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        titleLabel?.backgroundColor = .clear
        if #available(iOS 26, *) {
            titleLabel?.textColor = .label
        } else {
            titleLabel?.textColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        }
        titleLabel?.font = MMFontScheme.shared.titleTextFont?.withSize(17)
        titleLabel?.text = MMSettings.shared.APP_TITLE
        titleLabel?.sizeToFit()

        self.subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        self.subtitleLabel?.backgroundColor = .clear
        if #available(iOS 26, *) {
            self.subtitleLabel?.textColor = .label
        } else {
            self.subtitleLabel?.textColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        }
        self.subtitleLabel?.font = MMFontScheme.shared.titleTextFont?.withSize(12)
        self.subtitleLabel?.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(titleLabel?.frame.size.width ?? 0, subtitleLabel?.frame.size.width ?? 0), height: 30))
        titleView.addSubview(titleLabel!)
        titleView.addSubview(subtitleLabel!)
        
        if MMSettings.shared.onlyShowDefaultDomain {
            self.navigationItem.title = MMSettings.shared.APP_TITLE
        } else {
            self.navigationItem.titleView = titleView
        }
    }
    
    private func updateSubtitle(_ with: String) {
        self.subtitleLabel?.text = with
        self.subtitleLabel?.sizeToFit()
        
        let widthDiff = (subtitleLabel?.frame.size.width ?? 0) - (titleLabel?.frame.size.width ?? 0)
        subtitleLabel?.frame.origin.x = -widthDiff / 2
        
    }
    
    fileprivate func setBotBar() {
        self.bottomBarView.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .barTint)
        
        self.sammelCheckButton.isHidden = !MMSettings.shared.isSammelcheckActivated
        self.reportsListButton.isHidden = !MMSettings.shared.showReportListButton
        self.qrCodeButton.isHidden = !MMSettings.shared.isQRCodeActivated
        
        self.qrCodeButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
        self.sammelCheckButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        self.sammelCheckButton.setTitle("Sammelcheck", for: .normal)
        self.sammelCheckButton.addTarget(self, action: #selector(createNewSammelcheckReport), for: .touchUpInside)
        self.buttonBar.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .barTint)
        self.createNewReportButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        self.createNewReportButton.setTitle(LocalizedString("CREATE_REPORT_BTN_TITLE", comment: ""), for: .normal)
        self.userLocationButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
        self.reportsListButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
        
        self.loadingLabel.textColor = MMColorScheme.shared.getColor(view: self.view, type: .normalText)
        self.loadingLabel.text = LocalizedString("LOADING_REPORTS", comment: "")
        self.loadingView.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .secondaryAppTheme)
        self.loadingIndicator.color = MMColorScheme.shared.getColor(view: self.view, type: .normalText)
        self.loadingView.isHidden = true
        
        self.basemapSwitchButton.isHidden = !MMSettings.shared.showMapTypeButtonOnMainMap
        switch MMSettings.shared.defaultBaseMapType {
            case .streets:
                self.basemapSwitchButton.setImage(UIImage(named: "satellite", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
            case .satellite:
                self.basemapSwitchButton.setImage(UIImage(named: "street", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
        }
    }
    
    fileprivate func setCallout() {
        self.calloutView.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .appTheme)
        self.calloutTitle.textColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        self.calloutSubtitle.textColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        self.calloutButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        self.calloutButton.isUserInteractionEnabled = false
        self.calloutView.isUserInteractionEnabled = true
        self.calloutView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(calloutTapped)))
    }
    
    //MARK: notifications observer
    
    @objc func toggleManualOfflineMode() {
        InternetUtility.shared.setManualOfflineMode(!InternetUtility.shared.getManualOfflineMode())
    }
    
    @objc func updateMapWithMarkers (notification : Notification){
        let markers = notification.object as! [ReportMapMarker]
        
        var groups = Array<ReportGroup>()
        for m in markers {
            groups.append(ReportGroup(with: m))
        }
        self.allGroups = Array<ReportGroup>(groups)
        
        self.mapView.removeAnnotations(self.mapView.annotations.filter({ (anno) -> Bool in
                    return anno is ReportGroup
                }) as! [ReportGroup])
        
        groupMarker(marker: groups, threshold: self.offset*2)
                
        self.loadingView.isHidden = true
    }
    
    private func groupMarker(marker: Array<ReportGroup>, threshold: CGFloat) {
        let zoomstop = mapView.camera.altitude <= 150
        
        var groups = Array<ReportGroup>()
        
        for r in marker {
            r.setSmall(zoomstop)
            groups.append(r)
        }
        
        var done = false
        var deadlist = Array<ReportGroup>()
        while !done {
            done = true
            var i = 0
            while i < groups.count {
                let t1 = groups[i]
                if t1.isAlive() {
                    var j = i+1
                    while j < groups.count {
                        let t2 = groups[j]
                        if t2.isAlive() && t1.overlaps(with: t2, threshold: threshold, mapView: mapView) {
                            t1.join(group: t2)
                            t2.setDead()
                            done = false
                            deadlist.append(t2)
                        }
                        j = j + 1
                    }
                }
                i = i + 1
            }
            
            groups = groups.filter({ (group) -> Bool in
                return !deadlist.contains(group)
            })
            deadlist.removeAll()
        }
        
        for g in groups {
            self.mapManager!.addGroupToMap(g)
        }
    }
        
    //MARK: Idea
    func setIdeaOverlay() {
        self.ideaContainer.isHidden = !MMSettings.shared.isIdeaModuleActivated
        if MMSettings.shared.isIdeaModuleActivated {
            self.ideaCard.clipsToBounds = false
            self.ideaCard.layer.shadowColor = UIColor.lightGray.cgColor
            self.ideaCard.layer.shadowOpacity = 1
            self.ideaCard.layer.shadowOffset = CGSize.zero
            self.ideaCard.layer.shadowRadius = 10
            self.ideaCard.layer.shadowPath = UIBezierPath(roundedRect: self.ideaCard.bounds, cornerRadius: 10).cgPath
            self.ideaCard.backgroundColor = .clear
            self.ideaCard.subviews.forEach { view in
                view.backgroundColor = .systemBackground
                view.clipsToBounds = true
                view.layer.cornerRadius = 10
            }
            
            self.mangleCard.clipsToBounds = false
            self.mangleCard.layer.shadowColor = UIColor.lightGray.cgColor
            self.mangleCard.layer.shadowOpacity = 1
            self.mangleCard.layer.shadowOffset = CGSize.zero
            self.mangleCard.layer.shadowRadius = 10
            self.mangleCard.layer.shadowPath = UIBezierPath(roundedRect: self.mangleCard.bounds, cornerRadius: 10).cgPath
            self.mangleCard.backgroundColor = .clear
            self.mangleCard.subviews.forEach { view in
                view.backgroundColor = .systemBackground
                view.clipsToBounds = true
                view.layer.cornerRadius = 10
            }
            
            self.ideaCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showIdea)))
            self.mangleCard.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showMaengel)))
        }
    }
    
    @objc func showIdea() {
        let vcToPush = viewModel!.createNewReport()
        vcToPush.screenMode = GlobalFlagValues.REPORT_SCREEN_NEW_IDEA
        navigationController?.pushViewController(vcToPush, animated: true)
    }
    
    @objc func showMaengel() {
        self.ideaContainer.isHidden = true
        self.checkShowCase()
    }
    
    //MARK: Terms and Privacy
    func setTermsAndPrivacy() {
        self.deniedButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
        self.deniedButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        self.deniedButton.setTitle(LocalizedString("TERMS_DENIED_BUTTON_TITLE", comment: ""), for: .normal)
        self.acceptButton.setTitle(LocalizedString("TERMS_ACCEPT_BUTTON_TITLE", comment: ""), for: .normal)
        self.acceptButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        self.acceptButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
        self.privacyCheckbox.boxType = .square
        self.privacyCheckbox.stateChangeAnimation = .fill
        self.privacyCheckbox.markType = .checkmark
        self.privacyCheckbox.setCheckState((self.viewModel?.isPrivacyAccepted() ?? false) ? .checked : .unchecked, animated: true)
        self.termsCheckBox.stateChangeAnimation = .fill
        self.termsCheckBox.boxType = .square
        self.termsCheckBox.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .secondaryAppTheme)
        self.termsCheckBox.markType = .checkmark
        self.termsCheckBox.setCheckState((self.viewModel?.isTermsAccepted() ?? false) ? .checked : .unchecked, animated: true)
        
        if !(self.viewModel?.isWelcomeAccepted() ?? false) {
            self.deniedButton.setTitle("Beenden", for: .normal)
            self.acceptButton.setTitle("Weiter", for: .normal)
            self.termsView.isHidden = false
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.viewModel?.loadInfoPage(webView: self.termsPrivacyWebView, type: .welcome)
        } else if !(self.viewModel?.isTermsAccepted() ?? false) {
            self.termsView.isHidden = false
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.viewModel?.loadInfoPage(webView: self.termsPrivacyWebView, type: .terms)
        } else if !(self.viewModel?.isPrivacyAccepted() ?? false) {
            self.termsView.isHidden = false
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            self.viewModel?.loadInfoPage(webView: self.termsPrivacyWebView, type: .privacy)
        } else {
            self.termsView.isHidden = true
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            if let location = self.locationManager.location, firstLocation {
                firstLocation = false
                self.mapView.setCamera(MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: 5000, pitch: 0, heading: 0), animated: false)
            }
            if !MMSettings.shared.isIdeaModuleActivated {
                self.checkShowCase()
            }
        }
        if #available(iOS 26, *) {
            self.mapView.isHidden = !self.termsView.isHidden
        }
    }
    
    fileprivate func fetchInitialReports() {
        DispatchQueue.global(qos:.background).async {
            if (InternetUtility.shared.isOnline()) {
                if !self.viewModel!.startInitialFetching() {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: nil, message: LocalizedString("DENIED_LOCATION", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        self.loadingView.isHidden = true
                    }
                }
                
            } else {
                self.loadingView.isHidden = true
                DispatchQueue.main.async {
                    if !InternetUtility.shared.getManualOfflineMode() { self.showNoInternetAlert() }
                }
            }
        }
        
    }
    
    //MARK: ShowCase
    
    func checkShowCase() {
        if !UserDefaults.standard.bool(forKey: "FirstTutorialFinished") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadingView.isHidden = true
                self.showTutorial()
            }
        } else {
            if InternetUtility.shared.isOnline() {
                self.fetchInitialReports()
            }
        }
    }
    
    fileprivate func showTutorial(){
        
        switch tutorialStep {
        
        case 1:
            
            let showcase = TutorialUtility.getTutorialView(target: self.menuBarButton!, width: self.menuBarButton!.width/2, primaryText: LocalizedString("SHOWCASE_MENU_TITLE", comment: ""), secondaryText: LocalizedString("SHOWCASE_MENU_MESSAGE", comment: ""), isDark: self.view.isDarkMode())
            showcase.delegate = self
            showcase.show(completion: {
                
                self.tutorialStep += 1
            })
            
        case 2:
            let alert = UIAlertController(title: nil, message: "Benutzen Sie dieses System niemals, um Notfälle zu melden. Verwenden Sie hierzu die Telefonnummern von Polizei, Feuerwehr und Rettungsdienst.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                self.tutorialStep += 1
                UserDefaults.standard.set(true, forKey: "FirstTutorialFinished")
                // self.loadingView.isHidden = false
                self.fetchInitialReports()
                self.showCaseDidDismiss(showcase: TutorialUtility.getTutorialView(target: self.createNewReportButton, width: 0, primaryText: "", secondaryText: ""), didTapTarget: true)
            }))
            self.present(alert, animated: true)
            
        default:
            
            let showcase = TutorialUtility.getTutorialView(target: self.createNewReportButton, width: self.createNewReportButton.frame.width/2, primaryText: LocalizedString("SHOWCASE_CREATE_TITLE", comment: ""), secondaryText: LocalizedString("SHOWCASE_CREATE_MESSAGE", comment: ""))
            showcase.delegate = self
            showcase.show(completion: {
                
                self.tutorialStep += 1
            })
        }
    }
    
    func showLoginPopUp() {
        let alert = UIAlertController(title: nil, message: "Um eine Meldung erstellen zu können, müssen Sie sich anmelden. Möchten Sie nun die Anmelde-Seite öffnen?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { action in
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            self.navigationController?.pushViewController(vcToPush, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Nein", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //MARK: view buttons listeners
    
    @objc func hamburgerMenuButtonAction(button : UIButton!) {        
        self.performSegue(withIdentifier: "show_menu", sender: self)
    }
    
    @objc func noNetworkButtonAction(sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Aktuell besteht keine Internetverbindung. Das Erstellen von Meldungen ist weiterhin möglich. Das Hochladen ist dann wieder möglich, wenn eine Internetverbindung besteht.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }
    
    @IBAction func createNewReportButtonAction(_ sender: UIButton) {
        if UserDefaults.standard.string(forKey: "token") == nil && MMSettings.shared.isLoginRequired {
            self.showLoginPopUp()
        } else {
            let vcToPush = viewModel!.createNewReport()
            vcToPush.screenMode = GlobalFlagValues.REPORT_SCREEN_NEW_MODE
            vcToPush.externalData = self.externalData
            (MMSettings.shared.parentNavigationController ?? self.navigationController)?.pushViewController(vcToPush, animated: true)
            self.externalData = nil
        }
    }
    
    @objc func createNewSammelcheckReport() {
        if UserDefaults.standard.string(forKey: "token") == nil && MMSettings.shared.isLoginRequired {
            self.showLoginPopUp()
        } else {
            let inputAlert = UIAlertController(title: nil, message: "Bitte gib die Nummer des Sammelchecks ein:", preferredStyle: .alert)
            inputAlert.addTextField { textField in
                textField.placeholder = "Nummer des Sammelchecks"
                textField.text = UserDefaults.standard.string(forKey: "lastFussCheck")
            }        
            inputAlert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
            inputAlert.addAction(UIAlertAction(title: "Weiter", style: .default, handler: { _ in
                let textField = inputAlert.textFields?.first!
                let vcToPush = self.viewModel!.createNewReport()
                vcToPush.screenMode = GlobalFlagValues.REPORT_SCREEN_NEW_MODE
                vcToPush.fussSammelCheck = textField?.text
                UserDefaults.standard.set(textField?.text, forKey: "lastFussCheck")
                self.navigationController?.pushViewController(vcToPush, animated: true)
            }))
            inputAlert.addAction(UIAlertAction(title: "Was ist ein Sammelcheck?", style: .default, handler: { _ in
                let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
                let vcToPush = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
                vcToPush.pageName = .sammelcheck
                self.navigationController?.pushViewController(vcToPush, animated: true)
            }))
            self.present(inputAlert, animated: true, completion: nil)
        }
    }
    
    @IBAction func userLocationButtonAction(_ sender: Any) {
        if let position = self.locationManager.location {
            self.mapView.setCamera(MKMapCamera(lookingAtCenter: position.coordinate, fromDistance: 5000, pitch: 0, heading: 0), animated: true)
        } else {
            let alert = UIAlertController(title: nil, message: "Deine Position konnte nicht bestimmt werden. Bitte überprüfe, ob du der App die verwendung deines Standortes erlaubst.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func openReportListButton(_ sender: Any) {
        if InternetUtility.shared.isOnline() {
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportListController") as? ReportListViewController
            vcToPush?.currentDomainID = self.currentDomainID
            vcToPush?.currentLat = self.currentLat
            vcToPush?.currentLon = self.currentLon
            vcToPush?.selectedGroup = self.selectedGroup?.getReports().count ?? 0 > 1 ? self.selectedGroup : nil
            (MMSettings.shared.parentNavigationController ?? self.navigationController)?.pushViewController(vcToPush!, animated: true)
        } else {
            self.showNoInternetAlert()
        }
    }
    
    @IBAction func acceptTermsButtonAction(_ sender: Any) {
        self.viewModel?.acceptTermsOrPrivacy()
        self.setTermsAndPrivacy()
    }
    
    @IBAction func denieTermsButtonAction(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: LocalizedString("TERMS_ALERT_MESSAGE", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func switchBasemap(_ sender: Any) {
        let finalType = self.mapManager?.changeBaseMap() ?? .streets
        switch finalType {
            case .streets:
                self.basemapSwitchButton.setImage(UIImage(named: "satellite", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
            case .satellite:
                self.basemapSwitchButton.setImage(UIImage(named: "street", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_menu" {
            let destination = segue.destination as? SideMenuNavigationController
            destination?.menuWidth = self.view.bounds.width * 0.8
            
            let menuViewCtrl = destination?.viewControllers.first as? MenuViewController
            menuViewCtrl?.setParams(domainid: self.currentDomainID,
                                    latitude: self.currentLat,
                                    longitude: self.currentLon)
        } else if segue.identifier == "scanner" {
            (segue.destination as? ScannerViewController)?.delegate = self
        }
    }
}

// MARK: Tutorial Delegate

extension ViewController: MaterialShowcaseDelegate {
    
    func showCaseWillDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        
    }
    
    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
       
        if(tutorialStep < maxTutorialSteps){
            showTutorial()
        } else {
            if UserDefaults.standard.string(forKey: "token") == nil && MMSettings.shared.isLoginRequired {
                self.showLoginPopUp()
            }
        }
    }
}

// MARK: WebView Delegate

extension ViewController : WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
            vcToPush.navTitle = MMSettings.shared.APP_TITLE
            vcToPush.url = navigationAction.request.url?.absoluteString
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.navigationController?.pushViewController(vcToPush, animated: true)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }    
}

// MARK: MapView Delegate

extension ViewController : MapViewDelegate {
    
    func updateDomain(title: String, id: Int, lat: Double, lon: Double) {
        self.updateSubtitle(title)
        self.currentDomainID = id
        self.currentLon = lon
        self.currentLat = lat
        
    }
    
    func getMapRegion(completion: @escaping (BoundingBox) -> Void) {
        DispatchQueue.main.async {
            let neP = CGPoint(x: self.mapView.bounds.origin.x + self.mapView.bounds.size.width, y: self.mapView.bounds.origin.y)
            let swP = CGPoint(x: self.mapView.bounds.origin.x, y: self.mapView.bounds.origin.y + self.mapView.bounds.size.height)
            
            let neC = self.mapView.convert(neP, toCoordinateFrom: self.mapView)
            let swC = self.mapView.convert(swP, toCoordinateFrom: self.mapView)
            
            UserDefaults.standard.set(neC.latitude, forKey: "ne_latitude")
            UserDefaults.standard.set(neC.longitude, forKey: "ne_longitude")
            UserDefaults.standard.set(swC.latitude, forKey: "sw_latitude")
            UserDefaults.standard.set(swC.longitude, forKey: "sw_longitude")
            
            completion(BoundingBox(ne: neC, sw: swC, center: self.mapView.centerCoordinate))
        }
    }
    
    func mapFinishedMoving() {
        groupMarker(marker: allGroups, threshold: self.offset*2)
        if InternetUtility.shared.isOnline() {
            self.getMapRegion { (bb) in
                self.loadingView.isHidden = false
                self.viewModel?.fetchSystems(bb: bb)
            }
        } else {
            self.loadingView.isHidden = true
        }
    }
    
    func mapStartMoving() {
        //Nothing to do
    }
}

// MARK: Internet Delegate

extension ViewController : InternetUtilityDelegate {
    
    func onlineStatusChanged(_ isOnline: Bool) {
        let networkButtonIndex = self.navigationItem.rightBarButtonItems?.firstIndex(where: { $0.tag == self.NETWORK_BUTTON_TAG })
        self.mapManager?.reloadLayers()
        if isOnline {
            if networkButtonIndex != nil {
                self.navigationItem.rightBarButtonItems?.remove(at: networkButtonIndex!)
            }
            self.fetchInitialReports()
        } else {
            if networkButtonIndex == nil {
                self.navigationItem.rightBarButtonItems?.append(networkInfoButton ?? UIBarButtonItem())
            }
            self.mapManager?.removeMapMarkers()
        }
        
        self.setUpBaseMapSwitch()
    }
    
}

// MARK: Scanner Delegate

extension ViewController : ScannerViewController.Delegate {
    
    func found(url: URL) {
        self.externalData = ExtrernalCreationData(with: url)
        self.createNewReportButtonAction(UIButton())
    }
}
