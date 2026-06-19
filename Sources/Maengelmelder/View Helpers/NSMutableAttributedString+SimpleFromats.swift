//
//  NSMutableAttributedString+SimpleFromats.swift
//  MM
//
//  Created by Felix on 02.01.23.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {
    
    var normalFont : UIFont {
        return MMFontScheme.shared.normalTextFont ?? .preferredFont(forTextStyle: .body)
    }
    
    public func bold(_ value:String, fontSize:CGFloat? = nil) -> NSMutableAttributedString {
        let attributes:[NSAttributedString.Key : Any] = [
            .font : (MMFontScheme.shared.titleTextFont ?? .preferredFont(forTextStyle: .title1)).withSize(fontSize ?? normalFont.pointSize)
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    public func normal(_ value:String) -> NSMutableAttributedString {
        let attributes:[NSAttributedString.Key : Any] = [
            .font : normalFont,
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
    
    public func small(_ value:String) -> NSMutableAttributedString {
        let attributes:[NSAttributedString.Key : Any] = [
            .font : MMFontScheme.shared.smallTextFont ?? .preferredFont(forTextStyle: .footnote),
        ]
        
        self.append(NSAttributedString(string: value, attributes:attributes))
        return self
    }
}
