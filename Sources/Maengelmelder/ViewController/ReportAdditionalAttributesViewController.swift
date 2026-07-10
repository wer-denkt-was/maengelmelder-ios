//
//  ReportAdditionalAttributesViewController.swift
//  Maengelmelder
//
//  Created by Felix on 04.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import JGProgressHUD

class ReportAdditionalAttributesViewController : UIViewController {
    
    @IBOutlet weak var attributesTableView: UITableView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var multiPickerView: UIMultiPicker!
    
    var parentTabController : ReportCreationTabViewController?
    fileprivate var viewModel : ReportAttributesViewModel?
    fileprivate var loadingSPinner : JGProgressHUD?
    
    var reportAttributesDS : ReportAttributesTableViewDataSource?
    var attributeAnswerDict : [Int : String] = [:]
    
    let headerFontSize : CGFloat = 13
    
    var showError : Bool {
        return self.parentTabController?.showErrorsInAttributes ?? false
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = LocalizedString("HEADING_STEP_4", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = LocalizedString("HEADING_STEP_4", comment: "")
    }
    
    override func viewDidLoad() {
        parentTabController = parent as? ReportCreationTabViewController
        
        reportAttributesDS = ReportAttributesTableViewDataSource(delegateVC: self, fussCheck: parentTabController?.fussSammelCheck)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
        viewModel = ReportAttributesViewModel(parentController: parentTabController!, reportAttributesDS: reportAttributesDS!)
        
        attributesTableView.dataSource = reportAttributesDS
        attributesTableView.delegate = self
        self.reportAttributesDS?.addAndNotify(observer: self, completionHandler: {
            if(self.attributeAnswerDict.isEmpty){
                for attribute in self.reportAttributesDS!.modelToDisplay {
                    let id = attribute.returnDisplayableObject().attId!.intValue
                    self.attributeAnswerDict[attribute.returnDisplayableObject().attId!.intValue] = self.parentTabController?.externalData?.getForcedAttribute(for: id) ?? self.parentTabController?.externalData?.getSelectedAttribute(for: id) ?? attribute.returnDisplayableObject().attAnswer!
                }
            }
            self.attributesTableView.reloadData()
            self.loadingSPinner?.dismiss()
        })
        
        attributesTableView.keyboardDismissMode = .interactive
        attributesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        pickerView.dataSource = viewModel
        pickerView.delegate = viewModel
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setTopNavBarAccessories()
        
        if self.reportAttributesDS!.modelToDisplay.count == 0 {
            loadingSPinner = JGProgressHUD(style: .dark)
            loadingSPinner?.textLabel.text = "Antwortmöglichkeiten werden geladen..."
            loadingSPinner?.show(in: self.view)
            self.viewModel?.fetch()
        } else {
            self.viewModel?.fetchReportTypeAttributes()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (parentTabController!.report!.reportType == nil){// if report type is not selected
            loadingSPinner?.dismiss(animated: false)
            let alert = UIAlertController(title: nil, message: LocalizedString("REPORT_TYPE_NOT_SET", comment: ""), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: UIAlertAction.Style.default, handler: { action in
                if self.parentTabController?.screenMode == GlobalFlagValues.REPORT_SCREEN_NEW_IDEA || self.parentTabController?.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA {
                    self.parentTabController!.selectedIndex = 0
                } else {
                    self.parentTabController!.selectedIndex = 2
                }
                }))
            self.present(alert, animated: true, completion: nil)
        } else {
            //if first time report type is selected and will work also	 for edit mode
            parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].wasTabOpened = true
            self.reportAttributesDS?.addAndNotify(observer: self, completionHandler: {
                
                if(self.attributeAnswerDict.isEmpty){
                    for attribute in self.reportAttributesDS!.modelToDisplay {
                        let id = attribute.returnDisplayableObject().attId!.intValue
                        self.attributeAnswerDict[id] = self.parentTabController?.externalData?.getForcedAttribute(for: id) ?? self.parentTabController?.externalData?.getSelectedAttribute(for: id) ?? attribute.returnDisplayableObject().attAnswer!
                    }
                }
                self.attributesTableView.reloadData()
                self.loadingSPinner?.dismiss()
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        parentTabController = parent as? ReportCreationTabViewController
        
        if(parentTabController!.report!.reportType != nil) {
            parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].reportDidUpdatedAtTab = true
            updateReportContext()
        }
    }
    
    private func setTopNavBarAccessories() {            
        parentTabController!.navigationItem.title = LocalizedString("HEADING_STEP_4", comment: "")
    }
    
    private func updateReportContext() {
        viewModel!.updateAttributeAnswers(attributesAnswers: attributeAnswerDict)
    }
    
    //MARK: keyboard obervers
    
    @objc func keyboardWillShow(sender: NSNotification) {
        if let endFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            self.attributesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: endFrame.size.height, right: 0)
        }
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        self.attributesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    //MARK: view button actions
    
    @objc func uploadButtonTapped(button : UIButton!) {
        updateReportContext()
        parentTabController!.uploadReport(sender: self)
    }
    
    //MARK: UISwitch Methods
    
    @objc func switchChanged(uiSwitch: UISwitch) {
        
        if(uiSwitch.isOn){
            attributeAnswerDict[uiSwitch.tag] = "true"
        } else {
            attributeAnswerDict[uiSwitch.tag] = "false"
        }
        
        updateReportContext()
    }
    
    //MARK: Picker Methods
    
    @IBAction func cancelPicker(_ sender: Any) {
        self.pickerContainerView.isHidden = true
    }
    
    @IBAction func savePicker(_ sender: Any) {
        self.pickerContainerView.isHidden = true
        if viewModel?.selectedAttribute?.multiselect ?? false {
            var answers = ""
            for i in self.multiPickerView.selectedIndexes {
                answers.append(viewModel?.selectedAttribute?.getDropdownValues()[i] ?? "")
                answers.append(";")
            }
            if answers.count > 0 {
                _ = answers.removeLast()
            }
            attributeAnswerDict[viewModel?.selectedAttribute?.attId?.intValue ?? 0] = answers
        } else {
            attributeAnswerDict[viewModel?.selectedAttribute?.attId?.intValue ?? 0] = viewModel?.selectedAttribute?.getDropdownValues()[self.pickerView.selectedRow(inComponent: 0)]
        }
        
        attributesTableView.reloadData()
        updateReportContext()
    }
    
    private func setupPicker (indexPath: IndexPath) {
        self.view.endEditing(true)
        
        viewModel?.selectedAttribute = reportAttributesDS!.modelToDisplay[indexPath.row].returnDisplayableObject()
        if viewModel?.selectedAttribute?.multiselect ?? false {
            pickerView.isHidden = true
            multiPickerView.isHidden = false
            var tokenizedValues: [String] = []
            for val in viewModel?.selectedAttribute?.getDropdownValues() ?? [] {
                let splitedVals = val.components(separatedBy: "^")
                tokenizedValues.append(splitedVals[1])
            }
            multiPickerView.options = tokenizedValues
        } else {
            pickerView.isHidden = false
            multiPickerView.isHidden = true
            pickerView.reloadAllComponents()
        }
        pickerContainerView.isHidden = false
        attributesTableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setDDAttributeSelectedValue (selectedValue : String) {
        for attribute in reportAttributesDS!.modelToDisplay {
            for val in attribute.returnDisplayableObject().getDropdownValues() {
                if(val.range(of: selectedValue) != nil) {
                    attributeAnswerDict[attribute.returnDisplayableObject().attId!.intValue] = val
                    break
                }
            }
        }
    }
    
    private func addTabelviewInsets () {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 250, right: 0)
        self.attributesTableView.contentInset = insets
    }

    private func removeTabelviewInsets () {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.attributesTableView.contentInset = insets
    }
}

extension  ReportAdditionalAttributesViewController : UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        attributeAnswerDict[textField.tag] = textField.text!
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateReportContext()
        textField.resignFirstResponder()
        return true
    }
}

extension ReportAdditionalAttributesViewController : UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        attributeAnswerDict[textView.tag] = textView.text!
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.darkGray {
            textView.text = ""
            textView.textColor = MMColorScheme.shared.getColor(view: textView, type: .inputText)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            for attribute in reportAttributesDS!.modelToDisplay{
                if(NSNumber(value: textView.tag) == attribute.returnDisplayableObject().attId!){
                    textView.text = attribute.returnDisplayableObject().placeholder!
                    textView.textColor = UIColor.darkGray
                }
            }
        }
        updateReportContext()
    }
}

extension ReportAdditionalAttributesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let typeAttDO = reportAttributesDS!.modelToDisplay[indexPath.row].returnDisplayableObject()
        return typeAttDO.rowHeight!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if (cell!.reuseIdentifier == "DropDownCell") {
            setupPicker(indexPath: indexPath)
        } else if (cell!.reuseIdentifier == "TextAreaCell" || cell!.reuseIdentifier == "TextFeildCell") {            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let text = reportAttributesDS?.tableView(tableView, titleForHeaderInSection: section) ?? ""
        let size = text.boundingRect(with: CGSize(width: tableView.bounds.width-20, height: 0), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : MMFontScheme.shared.titleTextFont!.withSize(headerFontSize)], context: nil)
        return size.height+20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        headerView.textLabel?.isHidden = true
        let label = PaddingLabel()
        label.numberOfLines = 0
        label.font = MMFontScheme.shared.titleTextFont?.withSize(headerFontSize)
        label.text = reportAttributesDS?.tableView(tableView, titleForHeaderInSection: section)
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        headerView.contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: headerView.contentView.trailingAnchor),
            label.topAnchor.constraint(equalTo: headerView.contentView.topAnchor),
            label.bottomAnchor.constraint(equalTo: headerView.contentView.bottomAnchor)
        ])
        return headerView
    }
}
