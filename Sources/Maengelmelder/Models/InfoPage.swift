//
//  File.swift
//  
//
//  Created by Felix on 30.07.24.
//

import Foundation

public class InfoPage {
    
    public enum Kind : String {
        case about = "ABOUT"
        case imprint = "IMPRINT"
        case privacy = "PRIVACY"
        case terms = "TERMS"
        case welcome = "WELCOME"
        case faq = "FAQ"
        case barriere = "BARRIERE"
        case sammelcheck = "SAMMELCHECK"
        case about_us = "ABOUT_US"
        case more = "MORE"
        case usage = "USAGE_HELP"
        case resettutorial = "RESET_TUTORIAL"
    }
    
    public let title: String?
    public let type : InfoPage.Kind
    public let loadFromHTML : Bool
    public let bundleIdentifier : String?
    public let url : String?
    
    public init(type: InfoPage.Kind, loadFromHTML: Bool, url: String? = nil, title: String? = nil, bundleIdentifier: String? = nil) {
        self.type = type
        self.loadFromHTML = loadFromHTML
        self.url = url
        self.bundleIdentifier = bundleIdentifier
        self.title = title
    }
}
