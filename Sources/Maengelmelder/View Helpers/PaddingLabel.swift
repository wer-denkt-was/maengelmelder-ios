//
//  PaddingLabel.swift
//  MM
//
//  Created by Felix on 08.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class PaddingLabel: UILabel {

    override func draw(_ rect: CGRect) {
        let insets = UIEdgeInsets(top: 5, left: 10, bottom: 5 , right: 10)
        super.drawText(in: rect.inset(by: insets))
    }

}
