//
//  ReportMapMarkerView.swift
//  MM
//
//  Created by Felix on 17.07.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import MapKit

class ReportMapMarkerView: MKAnnotationView {

    public var canAnimate: Bool = false
    
    init(annotation: ReportGroup?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        self.image = annotation?.getImage(selected: false) ?? UIImage()
        self.centerOffset = CGPoint(x: 0, y: -(image?.size.height ?? 0)/2)
    }
    
    public func animate(toggle: Bool) {
        self.canAnimate = toggle
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.image = (annotation as? ReportGroup)?.getImage(selected: selected) ?? UIImage()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil && self.canAnimate {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        transform = CGAffineTransform(translationX: 0, y: -50)
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut],
            animations: {
                self.transform = .identity
            },
            completion: nil
        )
    }
}
