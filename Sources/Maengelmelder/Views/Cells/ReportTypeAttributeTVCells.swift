//
//  ReportTypeAttributeTVCells.swift
//  Maengelmelder
//
//  Created by Felix on 05.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

//MARK: Dropdown

class DropDownItemCell: UITableViewCell {
    
    @IBOutlet weak var ddToggler: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    func setStyle() {
        titleLabel.font = MMFontScheme.shared.subTitleTextFont!
        titleLabel.textColor = isDarkMode() ? .white : MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewCellText)
    }
    
    func configureCell(text: String, required: Bool, multiselect: Bool) {
        titleLabel.text = text + (required ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
    }
}

//MARK: TextField

class TextFieldItemCell: UITableViewCell {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var charCount: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var editBackgroundView: UIView!
    
    func setStyle() {
        contentView.backgroundColor = MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewHeaderBg)
        titleLabel.font = MMFontScheme.shared.subTitleTextFont!
        titleLabel.textColor = isDarkMode() ? .white : MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewCellText)
        textField.font = MMFontScheme.shared.normalTextFont!
        textField.textColor = MMColorScheme.shared.getColor(view: titleLabel, type: .inputText)
        charCount.textColor = MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewCellText)
        charCount.font = MMFontScheme.shared.smallTextFont
        editBackgroundView.backgroundColor = MMColorScheme.shared.getColor(view: self, type: .inputBg)
    }
    
    func configureCell(text: String, placeHolder: String, required: Bool, contentType: UITextContentType, keyboardType: UIKeyboardType) {
        titleLabel.text = text + (required ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
        textField.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGray])
        textField.text = ""
        textField.textColor = MMColorScheme.shared.getColor(view: self, type: .inputText)
        textField.autocorrectionType = .yes
        textField.textContentType = contentType
        textField.keyboardType = keyboardType
    }
}

//MARK: Checkbox

class CheckBoxItemCell: UITableViewCell {
    
    @IBOutlet weak var switchBox: UISwitch!
    @IBOutlet weak var titleLabel: UILabel!
    
    func setStyle() {
        titleLabel.font = MMFontScheme.shared.smallTextFont!
        titleLabel.textColor = isDarkMode() ? .white : MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewCellText)
    }
    
    func configureCell (text: String, switchState: Bool) {
        titleLabel.text = text
        switchBox.isOn = switchState
    }
}

//MARK: TextArea

class TextAreaItemCell: UITableViewCell {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var charCount: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var editBackgroundView: UIView!
    
    var placeHolderText: String = ""
    
    func setStyle() {
        contentView.backgroundColor = MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewHeaderBg)
        titleLabel.font = MMFontScheme.shared.subTitleTextFont!
        titleLabel.textColor = isDarkMode() ? .white : MMColorScheme.shared.getColor(view: titleLabel, type: .tableViewCellText)
        textView.font = MMFontScheme.shared.normalTextFont!
        textView.textColor = MMColorScheme.shared.getColor(view: self, type: .inputText)
        charCount.textColor = MMColorScheme.shared.getColor(view: self, type: .inputText)
        charCount.font = MMFontScheme.shared.smallTextFont
        editBackgroundView.backgroundColor = MMColorScheme.shared.getColor(view: self, type: .inputBg)
    }
    
    func configureCell(text: String, placeHolder: String, required: Bool, answer:String) {
        titleLabel.text = text + (required ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
        placeHolderText = placeHolder
        textView.text = answer.isEmpty ? placeHolder : answer
        textView.textColor = answer.isEmpty ? UIColor.darkGray : MMColorScheme.shared.getColor(view: self, type: .inputText)
        textView.autocorrectionType = .yes
    }
}
