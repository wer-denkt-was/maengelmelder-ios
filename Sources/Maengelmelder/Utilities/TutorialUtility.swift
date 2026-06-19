//
//  TutorialUtility.swift
//  MM
//
//  Created by Felix on 20.03.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import MaterialShowcase

struct TutorialUtility {
    
    static func getTutorialView(target: UIView, width: CGFloat, primaryText: String, secondaryText: String) -> MaterialShowcase {        
        let showcase = MaterialShowcase()
        showcase.setTargetView(view: target)
        
        showcase.backgroundPromptColor = MMColorScheme.shared.getColor(view: target, type: .tutorialBg)
        showcase.backgroundPromptColorAlpha = 1
        showcase.backgroundViewType = .full
        
        showcase.targetHolderRadius = width > 80 ? width : 80
        showcase.targetHolderColor = UIColor.clear
        
        showcase.aniComeInDuration = 0.3
        showcase.aniRippleColor = MMColorScheme.shared.getColor(view: target, type: .tint)
        showcase.aniRippleAlpha = 0.4
        
        showcase.primaryText = primaryText
        showcase.primaryTextFont = MMFontScheme.shared.titleTextFont
        showcase.primaryTextColor = MMColorScheme.shared.getColor(view: target, type: .tutorialText)
        showcase.secondaryText = secondaryText
        showcase.secondaryTextFont = MMFontScheme.shared.smallTextFont
        showcase.secondaryTextColor = MMColorScheme.shared.getColor(view: target, type: .tutorialText)
        
        return showcase
    }
    
    static func getTutorialView(target: UIBarButtonItem, width: CGFloat, primaryText: String, secondaryText: String, isDark: Bool) -> MaterialShowcase {
        let showcase = MaterialShowcase()
        showcase.setTargetView(barButtonItem: target)
        
        showcase.backgroundPromptColor = MMColorScheme.shared.getColor(isDark: isDark, type: .tutorialBg)
        showcase.backgroundPromptColorAlpha = 1
        showcase.backgroundViewType = .full
        
        showcase.targetHolderRadius = width > 80 ? width : 80
        showcase.targetHolderColor = UIColor.clear
        
        showcase.aniComeInDuration = 0.3
        showcase.aniRippleColor = MMColorScheme.shared.getColor(isDark: isDark, type: .tint)
        showcase.aniRippleAlpha = 0.4
        
        showcase.primaryText = primaryText
        showcase.primaryTextFont = MMFontScheme.shared.titleTextFont
        showcase.primaryTextColor = MMColorScheme.shared.getColor(isDark: isDark, type: .tutorialText)
        showcase.secondaryText = secondaryText
        showcase.secondaryTextFont = MMFontScheme.shared.smallTextFont
        showcase.secondaryTextColor = MMColorScheme.shared.getColor(isDark: isDark, type: .tutorialText)
        
        return showcase
    }
    
    static func getTutorialView(target: UITabBar, width: CGFloat, primaryText: String, secondaryText: String) -> MaterialShowcase {
        let showcase = MaterialShowcase()
        showcase.setTargetView(tabBar: target, itemIndex: (target.items?.count ?? 0)/2)
        
        showcase.backgroundPromptColor = MMColorScheme.shared.getColor(view: target, type: .tutorialBg)
        showcase.backgroundPromptColorAlpha = 1
        showcase.backgroundViewType = .full
        
        showcase.targetHolderRadius = width > 80 ? width : 80
        showcase.targetHolderColor = UIColor.clear
        
        showcase.aniComeInDuration = 0.3
        showcase.aniRippleColor = MMColorScheme.shared.getColor(view: target, type: .tint)
        showcase.aniRippleAlpha = 0.4
        
        showcase.primaryText = primaryText
        showcase.primaryTextFont = MMFontScheme.shared.titleTextFont
        showcase.primaryTextColor = MMColorScheme.shared.getColor(view: target, type: .tutorialText)
        showcase.secondaryText = secondaryText
        showcase.secondaryTextFont = MMFontScheme.shared.smallTextFont
        showcase.secondaryTextColor = MMColorScheme.shared.getColor(view: target, type: .tutorialText)
        
        return showcase
    }
}
