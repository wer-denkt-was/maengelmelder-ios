//
//  ReportTypeTableViewCell.swift
//  Maengelmelder
//
//  Created by Felix on 04.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

class ReportTypeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var reportTypeMarkerImageView: UIImageView!
    @IBOutlet weak var reportTypeNameLabel: UILabel!
    @IBOutlet weak var reportTypeDomainLabel: UILabel!
    @IBOutlet weak var explanationButton: UIButton!
    
    func setStyle () {
        reportTypeNameLabel.font = MMFontScheme.shared.subTitleTextFont
        reportTypeNameLabel.textColor = MMColorScheme.shared.getColor(view: reportTypeNameLabel, type: .tableViewCellText)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.explanationButton.tintColor = selected ? MMColorScheme.shared.getColor(view: self, type: .buttonTitleText) : (isDarkMode() ? .white : MMColorScheme.shared.getColor(view: self, type: .appTheme))
        
        self.backgroundColor = selected ? MMColorScheme.shared.getColor(view: self, type: .secondaryAppTheme) : .clear
        self.reportTypeNameLabel.textColor = selected ? MMColorScheme.shared.getColor(view: self, type: .normalText) : MMColorScheme.shared.getColor(view: self, type: .tableViewCellText)
    }
}
