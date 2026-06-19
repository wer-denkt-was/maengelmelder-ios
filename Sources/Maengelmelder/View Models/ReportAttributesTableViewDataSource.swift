//
//  ReportTypeAttributeTableViewDataSource.swift
//  MM
//
//  Created by Felix on 18.10.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

class ReportAttributesTableViewDataSource : GenericDataSource<ReportTypeAttributeMO>, UITableViewDataSource {
    
    var delegateHandler : ReportAdditionalAttributesViewController?
    
    private var countLabel:UILabel?
    private var fussCheck:String?
    
    private var charCountLables = Dictionary<Int, UILabel>()
    
    init(delegateVC : ReportAdditionalAttributesViewController, fussCheck:String?) {
        delegateHandler = delegateVC
        self.fussCheck = fussCheck
    }
    
    func getMaxLenght(for id: Int) -> Int {
        return modelToDisplay.first { att in
            return att.id?.intValue ?? 0 == id
        }?.max_length?.intValue ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelToDisplay.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return MMSettings.shared.headerInAttributes
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attributeDO = modelToDisplay[indexPath.row].returnDisplayableObject()
        let externalAnswer = self.delegateHandler?.parentTabController?.externalData?.getForcedAttribute(for: attributeDO.attId?.intValue ?? -1) ?? self.delegateHandler?.parentTabController?.externalData?.getSelectedAttribute(for: attributeDO.attId?.intValue ?? -1)
        let forceExternal = self.delegateHandler?.parentTabController?.externalData?.getForcedAttribute(for: attributeDO.attId?.intValue ?? -1) != nil
        if externalAnswer != nil {
            attributeDO.attAnswer = externalAnswer
        }
        
        if (attributeDO.attType! == AttributeTypes.valuelist) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownCell", for: indexPath) as! DropDownItemCell
            cell.titleLabel.tag = attributeDO.attId!.intValue
            cell.setStyle()
            
            if(attributeDO.attAnswer! == "") {
                cell.configureCell(text: attributeDO.attName!, required: attributeDO.required, multiselect: attributeDO.multiselect)
            } else {
                cell.textLabel!.textColor = UIColor.lightGray
                if attributeDO.multiselect {
                    let options = attributeDO.attAnswer!.components(separatedBy: ";")
                    var text = ""
                    for opt in options {
                        let values = opt.components(separatedBy: "^")
                        text.append(values[1])
                        text.append(", ")
                    }
                    text.removeLast(2)
                    cell.configureCell(text: text, required: attributeDO.required, multiselect: attributeDO.multiselect)
                } else {
                    let values = attributeDO.attAnswer!.components(separatedBy: "^")
                    if(values.count > 1) {
                        cell.configureCell(text: attributeDO.attAnswer!.components(separatedBy: "^")[1], required: attributeDO.required, multiselect: attributeDO.multiselect)
                    } else {
                        for val in attributeDO.getDropdownValues() {
                            if(val.lowercased().range(of: attributeDO.attAnswer!.lowercased()) != nil) {
                                attributeDO.attAnswer = val
                                cell.configureCell(text: attributeDO.attAnswer!.components(separatedBy: "^")[1], required: attributeDO.required, multiselect: attributeDO.multiselect)
                            }
                        }
                    }
                }
            }
            return cell
        } else if (attributeDO.attType! == AttributeTypes.textarea) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextAreaCell", for: indexPath) as! TextAreaItemCell
            cell.textView.tag = attributeDO.attId!.intValue
            cell.setStyle()
            cell.textView.delegate = self
            cell.textView.returnKeyType = .default
            
            cell.configureCell(text: attributeDO.attName!, placeHolder: attributeDO.placeholder!, required: attributeDO.required, answer: attributeDO.attAnswer ?? "")
            
            if delegateHandler?.showError ?? false && attributeDO.required && (attributeDO.attAnswer ?? "").filter({!$0.isWhitespace}).isEmpty {
                cell.errorLabel.text = (attributeDO.attName ?? "") + " darf nicht leer sein!"
            } else {
                cell.errorLabel.text = ""
            }
            
            self.countLabel = cell.charCount            
            return cell
        }
        else if attributeDO.attType! == AttributeTypes.text || attributeDO.attType! == AttributeTypes.email {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFeildCell", for: indexPath) as! TextFieldItemCell
            cell.textField.tag = attributeDO.attId!.intValue
            cell.textField.addTarget(delegateHandler, action: #selector(delegateHandler!.textFieldDidChange(_:)), for: .editingChanged)
            cell.setStyle()
            cell.textField.delegate = self
            
            self.charCountLables[attributeDO.attId?.intValue ?? 0] = cell.charCount
            cell.charCount.isHidden = (attributeDO.maxLength?.intValue ?? 0) == 0
            cell.charCount.text = String.init(format: "0/%d", attributeDO.maxLength?.intValue ?? 0)
            
            if attributeDO.attType! == AttributeTypes.text {
                cell.configureCell(text: attributeDO.attName!, placeHolder: attributeDO.placeholder!, required: attributeDO.required, contentType: UITextContentType.name, keyboardType: UIKeyboardType.alphabet)
            } else {
                cell.configureCell(text: attributeDO.attName!, placeHolder: attributeDO.placeholder!, required: attributeDO.required, contentType: .emailAddress, keyboardType: .emailAddress)
            }
            
            if(attributeDO.attAnswer != "") {
                cell.textField.text = attributeDO.attAnswer!
            } else {
                if(attributeDO.attCode == "date") {
                    cell.textField.text = DateTimeUtility.getDateString()
                    attributeDO.attAnswer = cell.textField.text!
                } else if(attributeDO.attCode == "time") {
                    cell.textField.text = DateTimeUtility.getTimeString()
                    attributeDO.attAnswer = cell.textField.text!
                } else if(attributeDO.attCode == "checknumber") {
                    cell.textField.text = self.fussCheck
                    attributeDO.attAnswer = cell.textField.text!
                }
            }
            
            if(attributeDO.attCode == "date" || attributeDO.attCode == "time" || forceExternal) {
                cell.textField.isEnabled = false
            } else {
                cell.textField.isEnabled = true
            }
            
            
            if delegateHandler?.showError ?? false && attributeDO.required && (attributeDO.attAnswer ?? "").filter({!$0.isWhitespace}).isEmpty {
                cell.errorLabel.text = (attributeDO.attName ?? "") + " darf nicht leer sein!"
            } else {
                cell.errorLabel.text = ""
            }
            
            return cell
            
        } else if (attributeDO.attType == AttributeTypes.checkbox) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CheckBoxCell", for: indexPath) as! CheckBoxItemCell
            cell.switchBox.tag = attributeDO.attId!.intValue
            cell.switchBox.addTarget(delegateHandler!, action: #selector(delegateHandler!.switchChanged(uiSwitch:)), for: .valueChanged)
            cell.setStyle()
            
            if(attributeDO.attAnswer! == "" || attributeDO.attAnswer! == "false"){
                cell.configureCell(text: attributeDO.attName!, switchState: false)
            } else {
                cell.configureCell(text: attributeDO.attName!, switchState: true)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextFeildCell", for: indexPath) as! TextFieldItemCell
            cell.textField.tag = attributeDO.attId!.intValue
            cell.textField.addTarget(delegateHandler, action: #selector(delegateHandler!.textFieldDidChange(_:)), for: .editingChanged)
            cell.setStyle()
            cell.textField.delegate = self
            
            cell.configureCell(text: attributeDO.attName!, placeHolder: attributeDO.placeholder!, required: attributeDO.required, contentType: UITextContentType.name, keyboardType: UIKeyboardType.alphabet)
            
            self.charCountLables[attributeDO.attId?.intValue ?? 0] = cell.charCount
            cell.charCount.isHidden = (attributeDO.maxLength?.intValue ?? 0) == 0
            cell.charCount.text = String.init(format: "0/%d", attributeDO.maxLength?.intValue ?? 0)
            
            if(attributeDO.attAnswer != "") {
                cell.textField.text = attributeDO.attAnswer
            }
            
            if delegateHandler?.showError ?? false && attributeDO.required && (attributeDO.attAnswer ?? "").filter({!$0.isWhitespace}).isEmpty {
                cell.errorLabel.text = (attributeDO.attName ?? "") + " darf nicht leer sein!"
            } else {
                cell.errorLabel.text = ""
            }
            
            return cell
        }
    }
}

extension ReportAttributesTableViewDataSource : UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        delegateHandler?.textViewDidChange(textView)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (delegateHandler?.parent as? ReportCreationTabViewController)?.domain?.hasTextLimit() ?? false, let limit = (delegateHandler?.parent as? ReportCreationTabViewController)?.domain?.getTextLimit(), let warning = (delegateHandler?.parent as? ReportCreationTabViewController)?.domain?.getTextLimitWarning() {
            if textView.text.count + text.count > limit {
                let alert = UIAlertController(title: nil, message: warning, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.delegateHandler?.present(alert, animated: true, completion: nil)
                return false
            } else {
                self.countLabel?.text = "\(textView.text.count + text.count)/\(limit)"
            }
        }
        return delegateHandler?.textView(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegateHandler?.textViewDidBeginEditing(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        delegateHandler?.textViewDidEndEditing(textView)
    }
    
}

extension ReportAttributesTableViewDataSource : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegateHandler!.textFieldShouldReturn(textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = getMaxLenght(for: textField.tag)
        if  maxLength == 0 {
            return true
        }
        
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        if newString.count <= maxLength {
            self.charCountLables[textField.tag]?.text = "\(newString.count)/\(maxLength)"
            return true
        } else {
            return false
        }
    }
    
}
