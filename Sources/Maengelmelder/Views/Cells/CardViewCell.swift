//
//  CardViewCell.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class CardViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    
    func updateCard() {
        self.contentView.layer.masksToBounds = true
        self.contentView.backgroundColor = .systemBackground
        self.contentView.layer.cornerRadius = 5
        
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        self.layer.backgroundColor = UIColor.clear.cgColor
    }
}
