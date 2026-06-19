//
//  MMColorScheme.swift
//  MM
//
//  Created by Felix on 06.02.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import Foundation

/**
 ColorScheme for the Maengelmelder-Module.
 */
public class MMColorScheme {
    
    /**
     The diffrent Kinds of colors that are aailable in the ColorScheme.
     */
    public enum Kind {
        case appTheme
        case secondaryAppTheme
        case barTint
        case tint
        case titleText
        case normalText
        case inputText
        case inputBg
        case buttonTitleText
        case buttonBg
        case tableViewHeaderBg
        case tableViewCellText
        case tutorialBg
        case tutorialText
        case menuHeaderBg
    }
    
    /**
     Represents a color in the scheme. Saves two colors: one for normal mode and one for dark mode.
     */
    public struct MMColor {
        let normal:UIColor
        let dark:UIColor
        
        /**
         Creates a new MMColor object.
         
         - parameter normal: The color that is used when the device is in normal mode
         - parameter dark: The color that is used when the device is in dark mode
         */
        public init(normal: UIColor, dark: UIColor) {
            self.normal = normal
            self.dark = dark
        }
    }
    
    /** The shared instance. Use this to access the color scheme. */
    public static let shared = MMColorScheme()
    
    private var appThemeColor:MMColor
    private var secondaryAppThemeColor:MMColor
    
    private var barTintColor:MMColor
    private var tintColor:MMColor
    
    private var titleTextColor:MMColor
    private var normalTextColor:MMColor
    
    private var inputTextColor:MMColor
    private var inputBgColor:MMColor
    
    private var buttonTitleTextColor:MMColor
    private var buttonBgColor:MMColor
    
    private var tableViewHeaderBgColor:MMColor
    private var tableViewCellTextColor:MMColor
    
    private var tutorialBgColor:MMColor
    private var tutorialTextColor:MMColor
    
    private var menuHeaderBgColor:MMColor
    
    private init() {
        let darkBlue : UIColor = UIColor(red: 16/255, green: 55/255, blue: 62/255, alpha: 1.0)
        let cyan : UIColor = UIColor(red: 53/255, green: 141/255, blue: 140/255, alpha: 1.0)

        appThemeColor = MMColor(normal: darkBlue, dark: darkBlue)
        secondaryAppThemeColor = MMColor(normal: cyan, dark: cyan)
        barTintColor = MMColor(normal: darkBlue, dark: darkBlue)
        tintColor = MMColor(normal: .white, dark: .white)
        titleTextColor = MMColor(normal: .white, dark: .white)
        inputTextColor = MMColor(normal: .black, dark: .black)
        normalTextColor = MMColor(normal: .white, dark: .white)
        buttonTitleTextColor = MMColor(normal: .white, dark: .white)
        buttonBgColor = MMColor(normal: darkBlue, dark: darkBlue)
        tableViewCellTextColor = MMColor(normal: .black, dark: .black)
        tutorialBgColor = MMColor(normal: cyan, dark: cyan)
        tutorialTextColor = normalTextColor
        menuHeaderBgColor = MMColor(normal: .white, dark: .white)
        inputBgColor = MMColor(normal: .lightGray, dark: .lightGray)
        tableViewHeaderBgColor = MMColor(normal: .white, dark: .white)
    }
    
    /**
     Set the color of the given type to the given color.
     
     - parameter color: A MMColor that should be set for the specified type.
     - parameter type: The type of views that should get the color.
     */
    public func set(_ color:MMColor, for type: Kind) {
        switch type {
        case .appTheme:
            appThemeColor = color
        case .barTint:
            barTintColor = color
        case .buttonBg:
            buttonBgColor = color
        case .buttonTitleText:
            buttonTitleTextColor = color
        case .inputText:
            inputTextColor = color
        case .inputBg:
            inputBgColor = color
        case .normalText:
            normalTextColor = color
        case .secondaryAppTheme:
            secondaryAppThemeColor = color
        case .tableViewCellText:
            tableViewCellTextColor = color
        case .tableViewHeaderBg:
            tableViewHeaderBgColor = color
        case .tint:
            tintColor = color
        case .titleText:
            titleTextColor = color
        case .tutorialBg:
            tutorialBgColor = color
        case .tutorialText:
            tutorialTextColor = color
        case .menuHeaderBg:
            menuHeaderBgColor = color
        }
    }
    
    /**
     Get the color for the specified view that has the specified type.
     
     - parameter view: The view that should get the color
     - parameter type: the type of view
     
     - returns: A UIColor (dark mdoe is selected internally)
     */
    public func getColor(view: UIView, type:Kind) -> UIColor {
        return self.getColor(isDark: view.isDarkMode(), type: type)
    }
    
    /**
     Get the color for the specified mode and type.
     
     - parameter isDark: dark mode or normal mode
     - parameter type: the type of view
     
     - returns: A UIColor
     */
    public func getColor(isDark: Bool, type:Kind) -> UIColor {
        let color:MMColor
        switch type {
        case .appTheme:
            color = appThemeColor
        case .barTint:
            color = barTintColor
        case .buttonBg:
            color = buttonBgColor
        case .buttonTitleText:
            color = buttonTitleTextColor
        case .inputText:
            color = inputTextColor
        case .inputBg:
            color = inputBgColor
        case .normalText:
            color = normalTextColor
        case .secondaryAppTheme:
            color = secondaryAppThemeColor
        case .tableViewCellText:
            color = tableViewCellTextColor
        case .tableViewHeaderBg:
            color = tableViewHeaderBgColor
        case .tint:
            color = tintColor
        case .titleText:
            color = titleTextColor
        case .tutorialBg:
            color = tutorialBgColor
        case .tutorialText:
            color = tutorialTextColor
        case .menuHeaderBg:
            color = menuHeaderBgColor
        }
        
        if isDark {
            return color.dark
        } else {
            return color.normal
        }
    }
}
