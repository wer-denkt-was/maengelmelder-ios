//
//  ReportTypeViewController.swift
//  Maengelmelder
//
//  Created by Felix on 04.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import JGProgressHUD
import MaterialShowcase

class ReportTypeViewController : UIViewController {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var spinnerView: UIView!
    @IBOutlet weak var spinnerLabel: UILabel!
    @IBOutlet weak var spinnerDropdown: UIImageView!
    @IBOutlet weak var spinnerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var spinnerDropdownWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportTypesTableView: UITableView!
    @IBOutlet weak var rubricTableView: UITableView!
    @IBOutlet weak var rubricContainerView: UIView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var rubricInfoContainer: UIView!
    @IBOutlet weak var rubricInfoLabel: UILabel!
    @IBOutlet weak var rubricInfoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var rubricDivider: UIView!
    @IBOutlet weak var rubricButton: UIButton!
    
    fileprivate var viewModel : ReportTypeViewModel?
    fileprivate var rubricModel : RubricTableViewModel?
    fileprivate var parentTabController : ReportCreationTabViewController?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = LocalizedString("HEADING_STEP_3", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = LocalizedString("HEADING_STEP_3", comment: "")
    }
    
    
    @objc func rubricButtonPressed() {
        self.viewModel?.rubricsButtonPressed()
        showRubrics()
    }
    
    private func showRubrics() {
        if self.viewModel?.hasRubric(domainid: self.viewModel?.getSelectedDomainID() ?? -1) ?? false {
            if self.rubricModel == nil {
                self.rubricModel = RubricTableViewModel(viewModel: self.viewModel!, containerView: self.rubricContainerView, rubricInfoLabel: self.rubricInfoLabel)
                self.rubricTableView.dataSource = self.rubricModel!
                self.rubricTableView.delegate = self.rubricModel!
                self.rubricTableView.reloadData()
            }
            
            self.rubricContainerView.isHidden = !(self.viewModel?.shouldShowRubricsTable() ?? false)
            self.rubricDivider.isHidden = false
            self.rubricInfoContainer.isHidden = !(self.viewModel?.shouldShowRubricsInfo() ?? false)
            self.rubricInfoHeightConstraint.constant = (self.viewModel?.shouldShowRubricsInfo() ?? false) ? 65 : 0
        } else {
            self.rubricInfoHeightConstraint.constant = 0
            self.rubricDivider.isHidden = true
            self.rubricInfoContainer.isHidden = true
            self.rubricContainerView.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        parentTabController = parent as? ReportCreationTabViewController
        viewModel = ReportTypeViewModel(parentController: parentTabController!, rubricInfoContainer: self.rubricInfoContainer, rubricInfoLabel: self.rubricInfoLabel, rubricButton: self.rubricButton, rubricHeightConstraint: rubricInfoHeightConstraint)
        
        reportTypesTableView.dataSource = self.viewModel
        reportTypesTableView.delegate = self.viewModel
        
        self.searchBar.isHidden = !MMSettings.shared.showSearchBarInTypes
        self.searchBarHeightConstraint.constant = MMSettings.shared.showSearchBarInTypes ? 56 : 0
        self.searchBar.delegate = self
        self.searchBar.placeholder = "Suche nach Kategorien (ab 3 Zeichen)"
        	
        self.rubricButton.addTarget(self, action: #selector(rubricButtonPressed), for: .touchUpInside)
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self.viewModel
        
        self.spinnerLabel.font = MMFontScheme.shared.titleTextFont
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let storyboard = MMSettings.shared.customTypeSelectionStoryboard {
            if self.viewModel?.openFuss ?? false, let vc = storyboard.instantiateInitialViewController() as? CustomTypeViewController {
                vc.delegate = self
                self.parentTabController?.fussShouldDelete = true
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                self.viewModel?.openFuss = true
            }
            return
        }
        
        if showTutorial() {
            return
        }
        
        setTopNavBarAccessories()
        
        if((parent as? ReportCreationTabViewController)!.isReportPositionUpdated == true || self.viewModel?.needsReload() ?? false){
        
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Kategorien werden geladen..."
            hud.show(in: self.view)
            
            viewModel!.fetchSystems {
                if self.viewModel!.hasMultipleDomains() {
                    let showcase = TutorialUtility.getTutorialView(target: self.spinnerView, width: 150, primaryText: "An dieser Position gibt es mehrere Zuständige.", secondaryText: "Hier kannst du auswählen, an wenn die Meldung geschickt werden soll.")
                    showcase.show(completion: nil)
                    self.spinnerView.isHidden = false
                    self.spinnerHeightConstraint.constant = 40
                    self.spinnerLabel.text = self.viewModel?.getSelectedDomainName()
                    self.spinnerView.isUserInteractionEnabled = true
                    self.spinnerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showPicker)))
                } else {
                    self.spinnerHeightConstraint.constant = 0
                    self.spinnerView.isHidden = true
                }
                
                self.showRubrics()
                
                self.reportTypesTableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    hud.dismiss(animated: true)
                    if let oldIndexPath = self.viewModel?.oldTypeIndexPath, oldIndexPath.section < self.viewModel!.numberOfSections(in: self.reportTypesTableView), oldIndexPath.row < self.viewModel!.tableView(self.reportTypesTableView, numberOfRowsInSection: oldIndexPath.section) {
                        self.reportTypesTableView.selectRow(at: self.viewModel?.oldTypeIndexPath, animated: true, scrollPosition: .middle)
                    }
                    	
                    (self.parent as? ReportCreationTabViewController)!.isReportPositionUpdated = false
                    if self.viewModel?.isEmpty() ?? false {
                        let alert = UIAlertController(title: nil, message: MMSettings.shared.emptyCategoriesText, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                })
                if self.viewModel?.offline ?? false {
                    let alert = UIAlertController(title: nil, message: "Keine Verbindung zum Internet. Die Offline-Kategorien werden angezeigt.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                self.pickerView.reloadAllComponents()
                
                self.pickerView.selectRow(0, inComponent: 0, animated: false)
            }
        }
    }
    
    private func showTutorial() -> Bool {
        if MMSettings.shared.showTypesFirst && !UserDefaults.standard.bool(forKey: "SecondTutorialFinished") {
            let showcase = TutorialUtility.getTutorialView(target: self.parentTabController!.tabBar, width: 80, primaryText: LocalizedString("SHOWCASE_NAVIGATION_TITLE", comment: ""), secondaryText: LocalizedString("SHOWCASE_NAVIGATION_MESSAGE", comment: ""))
        
            showcase.delegate = self
            showcase.show(completion: {
                UserDefaults.standard.set(true, forKey: "SecondTutorialFinished")
            })
            return true
        }
        return false
    }
    
    @objc func showPicker() {
        self.pickerView.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].wasTabOpened = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        parentTabController = parent as? ReportCreationTabViewController
        
        parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].reportDidUpdatedAtTab = true
        updateReportContext(self.reportTypesTableView.indexPathForSelectedRow)        
    }
    
    private func setTopNavBarAccessories() {        
        parent!.navigationItem.title = LocalizedString("HEADING_STEP_3", comment: "")
    }
    
    private func updateReportContext(_ indexPath: IndexPath?) {
        viewModel!.updateReportType(indexPath)
    }
}

// MARK: UIPickerViewDelegate

extension ReportTypeViewController : UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.viewModel?.pickerView(pickerView, didSelectRow: row, inComponent: component)
        self.spinnerLabel.text = self.viewModel?.getSelectedDomainName()
        self.showRubrics()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.viewModel?.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    
}

// MARK: UISearchBarDelegate

extension ReportTypeViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel?.searchBar(searchBar, textDidChange: searchText)
        self.showRubrics()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}

// MARK: MaterialShowcaseDelegate

extension ReportTypeViewController: MaterialShowcaseDelegate {
    
    func showCaseWillDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        
    }
    
    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
        viewWillAppear(false)
    }
}

//MARK: CustomTypeDelegate

extension ReportTypeViewController : CustomTypeDelegate {
    
    func setCategory(_ id: Int) {
        self.viewModel?.openFuss = false
        self.viewModel?.updateReportType(id)
        self.navigationController?.popViewController(animated: true)
    }
    
    func tabBarPressed(_ index: Int) {
        self.navigationController?.popViewController(animated: true)
        self.parentTabController?.goToTab(index)
    }
    
    func saveButton() {
        self.viewModel?.openFuss = false
    }
    
}
