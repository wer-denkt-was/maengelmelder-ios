//
//  Constants.swift
//  Maengelmelder
//
//  Created by Felix on 19.02.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation

public struct CoreDataEntityNames {
    public static let REPORT_TYPE = "ReportType"
    public static let REPORT = "Report"
    static let REPORT_TYPE_ATTRIBUTES = "ReportTypeAttribute"
    static let GEOMETRY = "Geometry"
    static let REPORT_USER = "ReportUser"
    static let REPORT_COMMENT = "ReportComment"
}

struct AttributeTypes {
    
    static let textarea = "textarea"
    static let text = "text"
    static let valuelist = "valuelist"
    static let checkbox = "checkbox"
    static let email = "email"
}

public struct GlobalFlagValues {
    public static let REPORT_SCREEN_EDIT_MODE : String = "EDIT"
    static let REPORT_SCREEN_NEW_MODE : String = "NEW"
    static let REPORT_SCREEN_NEW_IDEA = "IDEA NEW"
    static let REPORT_SCREEN_EDIT_IDEA = "IDEA EDIT"
    public static let REPORT_CREATED_STATE : String = "created"
    static let REPORT_UPLOADED_STATE : String = "uploaded"
}

struct GlobalArrays {
    static let MODE_IDEA_CATEGORIES = [2263, 2266, 2269, 2272, 2275, 2278, 2279, 2282, 2284, 2287, 2288, 2290, 2291, 3516]
}

struct ApiMethodPaths {
    
    static let PATH_ATTRIBUTES = "/attribute"
    static let PATH_CATEGORIES = "/domain/%d/category"
    static let PATH_UPLOAD_REPORTS = "/domain/%d/message"
    static let PATH_CHECK_LOGIN = "/check_login"
    static let PATH_LOGIN = "/login"
    static let PATH_LOGOUT = "/logout"
    static let PATH_UPDATE = "/domain/%d/update"
    static let PATH_NEAREST_MESAGES = "/bmsapp/%d/message"
    static let PATH_NEAREST_MESAGES_DOMAIN = "/domain/%d/message"
    static let PATH_GET_DOMAIN = "/bmsapp/%d/domain"
    static let PATH_SYSTEM_LOCATION = "/bmsapp/%d/system/by_location"
    static let PATH_MESSAGE_DETAIL = "/domain/%d/message/%d"
    static let PATH_SUBSCRIBE = "/domain/%d/message/%d/subscribe"
    static let PATH_DUPLICATES = "/domain/%d/bms/duplicates"
    static let PATH_CREATE_BUNDLE = "/domain/%d/bundle"
    static let PATH_FILE_TO_BUDLE = "/domain/%d/bundle/%@/file"
    static let PATH_DOMAIN_SETTINGS = "/domain/%d/bms"
    static let PATH_GET_CATEGORY = "/bmsapp/%d/category/%d"
    static let PATH_PRIVATE = "/domain/%d/message/%d/set_private"
    static let PATH_DELETE_ACCOUNT = "/domain/%d/user/%d/delete"
    static let PATH_SEARCH_CATEGORY = "/domain/%d/category/keyword_search"
    static let PATH_SEARCH_ADDRESS = "/domain/%@/search_address"
}

public enum SubscriptionTyp {
    case API
    case EMail
}

public enum MapType {
    case streets
    case satellite
}
