//
//  MMSettings.swift
//  MM
//
//  Created by Felix on 02.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit

/**
 Holds all settings for the Maengelmelder module.
 */
public class MMSettings {
    
    /** The shared instance. Use this to access the settings. */
    public static let shared = MMSettings()
    
    //MARK: Required Settings
    /** The App-ID that is used in the communication with the server. */
    public var APP_ID : Int = 1
    /** The default domain-id that is used as default when fetching domains. */
    public var DEFAULT_DOMAIN_ID : Int = 32
    /** The name of the app. Used only internally. Should not conatin spaces. */
    public var APP_NAME : String = "MM"
    /** The title of the app. Is shown in the navigation bar when no other title is present. */
    public var APP_TITLE : String = "Mängelmelder"
    /** The URL to the registration page */
    public var REGISTRATION_PAGE_URL : String = "https://www.xn--mngelmelder-l8a.de/login"
    /** If given, it will override the base URL for api call */
    public var OVERRIDE_API_BASE_URL : String? = nil
    
    //MARK: Modules
    /** Activates the Login-Module */
    public var isLoginModuleActivated : Bool = false
    /** Activiates the Idea-Module */
    public var isIdeaModuleActivated : Bool = false
    /** Activate manual offline mode*/
    public var isManualOfflineModeActivated : Bool = false
    /** When activited a extra button for creating a message is shown (sammelcheck) */
    public var isSammelcheckActivated : Bool = false
    /** When activited a extra button for creating a message via a qr code is shown */
    public var isQRCodeActivated : Bool = false
    /** When activated the rating popup is shown after uploading a message */
    public var showRatingAfterUpload : Bool = false
    /** Show reports from map as list */
    public var showReportListButton : Bool = true
    /** Show menu item for report list in overview menu*/
    public var showReportListButtonInMenu : Bool = false
    /** Defines local map layers. Each local layer musst be one entry (name, (color as hex, urls) in the array. The name is shown in the layer chooser and the urls contain the urls to the geojson files.  */
    public var localMapLayers : Array<(String, LocalLayer)> = []
    /** Defines the list of downloadable offline map data */
    public var offlineMaps : Array<DownloadableMap> = []
    /** Defines the list of map layers loaded in addition to basemap (id, name, tile-URL, transparency(0-1), map Type (XYZ or WMS), layerName for WMS) */
    public var mapLayers : Array<(Int, String, String, Double, String, String)> = []
    /** If nil, uses ios mapkit's satellite map */
    public var satelliteMapLayer: (Int, String, String, Double, String, String)? = nil
    /** The default basemap type */
    public var defaultBaseMapType: MapType = .streets
    /** URL used to check map's offline version */
    public var offlineMapVersionCheckUrl: String = ""
    
    //MARK: Create Report Settings
    /** When activated the position and type steps are switched when creating a message. */
    public var showTypesFirst : Bool = false
    /** Show group names in table as header */
    public var showGroupAsHeader : Bool = true
    /** Show a search bar on type selection */
    public var showSearchBarInTypes : Bool = false
    /** Show a search bar on position selection */
    public var showSearchBarInPosition : Bool = false
    /** Text for when iit is not possible to to create a message due to no categories existing */
    public var emptyCategoriesText : String = "An dieser Stelle ist keine Zuständigkeit hinterlegt, keine Meldung möglich."
    /** Text for locations where it is not possible to create a message. Overrides the default value */
    public var messageInvalidPositionText : String = ""
    /** Require manual update of position in position step */
    public var requireManualPositionUpdate : Bool = false
    /** Text for locations where it is not possible to to create a message*/
    public var emptyPicturesText : NSAttributedString = NSAttributedString(string: "kein Foto hinzugefügt")
    /** Header above the attributes */
    public var headerInAttributes : String? = LocalizedString("TABLE_HEADER_STEP_4", comment: "")
    
    //MARK: Prefill Settings
    /** The mail of the current user, will be used to prefill form fields */
    public var formEmail : String?
    /** The first name of the current user, will be used to prefill form fields */
    public var formFirstName : String?
    /** The last name of the current user, will be used to prefill form fields */
    public var formLastName : String?
    /** Default text for message description */
    public var defaultMessageDescription : String = ""
    
    //MARK: Message Detail Settings
    /** Defines the order and information that is shown on the message details screen */
    public var messageDetailsConfig : [(String, ReportDetails.Typ)] = [("Anfrage", .text), ("Typ", .typ), ("Status", .state), ("Datum", .date), ("Adresse", .address), ("Historie", .history)]
    /** Enables the report finished switch located on the comment view*/
    public var isFinishOnCommentActivated : Bool = true
    /** Enables the pictures on the comment view*/
    public var isPictureOnCommentActivated : Bool = true
    /** Defines the type of subscribtion to a report that is used inside the app. */
    public var subscribeReportTyp : SubscriptionTyp = .API
    /** The URL for subscription via mail */
    public var subscriptionMail : String?
    /** The Button title for subscription via mail */
    public var subscriptionButtonTitle : String?
    
    //MARK: Menu Settings
    /** If activated, the users thumbnail (avatar) is shown in the menu */
    public var showProfileAvatarInMenu : Bool = false
    /** If activated, shows "New Report" Button entry in menu **/
    public var showNewReportInMenu : Bool = false
    /** The info pages that are shown in the menu. The order is the same as in the array. */
    public var menuInfoPages : [InfoPage.Kind] = [.about, .terms, .privacy, .imprint]
    /** The info pages and wehre to load the content from. */
    public var infoPages : [InfoPage] = [InfoPage(type: .about, loadFromHTML: true), InfoPage(type: .terms, loadFromHTML: true), InfoPage(type: .privacy, loadFromHTML: true), InfoPage(type: .imprint, loadFromHTML: true), InfoPage(type: .welcome, loadFromHTML: true)]
    /** if for some reason you need multiple "about us" pages, put them here, Otherwise, empty array */
    public var multipleAboutUsPages : [InfoPage] = []
    /** Infotext to show at the bottom part of the menu, above version number */
    public var infoTextBottomMenu: NSAttributedString? = nil
    /** if given, infotext at bottom menu opens to the given URL when clicked */
    public var linkTextBottomMenu: URL? = nil
    
    //MARK: Other Settings
    /** Sets the maximum number of markers that are shown on the map.*/
    public var maximumMarker : Int = 50
    /** When activated, only the default domain is shown. */
    public var onlyShowDefaultDomain : Bool = false
    /** Hint text shown when no user position is available during login. If empty, no hint is shown. */
    public var noPositionHintText: String = ""
    /** When activated a login is required to send a message (login module needs to be active) */
    public var isLoginRequired : Bool = false
    /** When activated the filter for the blue status is shown */
    public var showBlueStatus : Bool = false
    /** Load domain before reports */
    public var loadDomainBeforeReports : Bool = false
    /** Should show welcome on first start */
    public var showWelcomeOnFirstStart : Bool = true
    /** The parents navigation controller to which the controllers should be pushed */
    public var parentNavigationController : UINavigationController?
    /** Custom storyboard for type selection */
    public var customTypeSelectionStoryboard : UIStoryboard?
    /** Custom view controller for my messages */
    public var customMyMessagesController : UIViewController?
    /** Show MapTypeButton on Main Map */
    public var showMapTypeButtonOnMainMap : Bool = false
    /** Custom Category Config */
    public var customCategoryConfig : CustomCategoryConfig?
    /** Whether to use Basic authentication or not */
    public var useBasicAuthentication: Bool = false
    /** Basic auth username */
    public var basicAuthenticationUsername: String? = nil
    /** Basic auth password */
    public var basicAuthenticationPassword: String? = nil
    /** If enabled, it will check whether the given position has any category after choosing position */
    public var checkIfAnyCategoryExistsOnPosition: Bool = false
    /** If enabled, it will NOT check if the category exists at the choosen position */
    public var disableCategoryCheckOnPosition: Bool = false
    /** Appended to "appv" param */
    public var versionNameSuffix: String  = ""
    /**If true, it will show the app icon on the rightButtonBar of the navigationView. The app icon should be an image asset with the name "mm_app_icon" **/
    public var showAppIconOnWebViewNavigationBar: Bool = false
    /** The method to validate qr codes when scanned via the app */
    public var validateQRCode: (String) -> Bool = { _ in return false }
}
