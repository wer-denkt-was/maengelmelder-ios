//
//  MMApi.swift
//  Maengelmelder
//
//  Created by Felix on 20.02.24.
//

import Foundation
import Alamofire
import UIKit

/**
 Class for making requests to the API.
 */
public class MMApi {
    
    /** The URL to the API */
    public var SERVER_URL = MMSettings.shared.OVERRIDE_API_BASE_URL ?? "https://api.werdenktwas.de/"
    //var SERVER_URL : String = ""
    
    /** Is a basic auth required for the api (if true it uses the provided username and passwort) */
    public var useBasicAuth = MMSettings.shared.useBasicAuthentication
    
    /** The username to use when basic auth is enabled */
    public var basicAuthUser = MMSettings.shared.basicAuthenticationUsername ?? ""
    /** The password to use when basic auth is enabled */
    public var basicAuthPass = MMSettings.shared.basicAuthenticationPassword ?? ""
    
    /// The shared instance for the API.
    public static let shared = MMApi()
    
    /**
     Returns the existing systems at the given location.
     - parameter lat: Latitude as Double
     - parameter lon: Longitude as Double
     - parameter completion: Called after the request to the API. Returns an array of Systems or an error as String.
     */
    public func getSystems(lat: Double, lon: Double, completion: @escaping (_ systems: [System]?, _ error: String?) -> Void) {
        
        var parameters = getDefaultParams(useToken: MMSettings.shared.onlyShowDefaultDomain)
        parameters["lat"] = String.init(format: "%f", lat)
        parameters["lon"] = String.init(format: "%f", lon)
        
        AF.request(MMApi.shared.SERVER_URL + "api/v1" + String(format: ApiMethodPaths.PATH_SYSTEM_LOCATION, MMSettings.shared.APP_ID), method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            // print ("getSystems", "URL: \(response.request?.url)");
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var systems = Array<System>()
                        if let data = json?["data"] as? Dictionary<	String, Any>, let array = data["systems"] as? Array<Any> {
                            for object in array {
                                if let seri = object as? Serialization {
                                    systems.append(System(json: seri))
                                }
                            }
                        }
                        completion(systems, nil)
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Returns the details of the given domain.
     - parameter lat: Latitude as Double
     - parameter lon: Longitude as Double
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter appid: The appid of the current app (or nil to use the appid of the system)
     - parameter completion: Called after the request to the API. Returns the Domain or an error as String.
     */
    public func getDomain(lat: Double, lon: Double, system: System?, appid: Int? = nil, completion: @escaping (_ domain: Domain?, _ error: String?) -> Void) {
        
        let appIdForApi = appid ?? system?.appid ?? MMSettings.shared.APP_ID
        var parameters = getDefaultParams(useToken: true)
        parameters["lat"] = String.init(format: "%f", lat)
        parameters["lon"] = String.init(format: "%f", lon)
        
        self.getSingleObject(url: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_GET_DOMAIN, appIdForApi), parameters: parameters) { result, error in
            if let data = result {
                completion(Domain(serialization: data), nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Returns the settings of the given domain.
     - parameter id: The ID of the domain
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the DomainSettings or an error as String.
     */
    public func getDomainSettings(domainid: Int, system: System?, completion: @escaping (_ settings: DomainSettings?, _ error: String?) -> Void) {
        self.getSingleObject(url: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_DOMAIN_SETTINGS, domainid), parameters: getDefaultParams(useToken: shouldUseToken(domainid: domainid))) { result, error in
            if let data = result {
                completion(DomainSettings(serialization: data), nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Returns the details of a specific message.
     - parameter id: The ID of the message as Int
     - parameter domainid: The ID of the domain of the message
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the ReportDetails or an error as String.
     */
    public func getMessageDetail(id: Int, domainid: Int, system: System?, completion: @escaping (_ details: ReportDetails?, _ error: String?) -> Void) {
        self.getSingleObject(url: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_MESSAGE_DETAIL, domainid, id), parameters: getDefaultParams(useToken: shouldUseToken(domainid: domainid))) { result, error in
            if let data = result {
                completion(ReportDetails(serialization: data), nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Adds the given mail to the subscription list of the given message.
     - parameter id: The ID of the message for which the user wants notifications vai mail
     - parameter mail: The mail adress of the user.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns a bool indicating success or an error as String.
     */
    public func addSubscription(id: Int, mail: String, domainid: Int, system: System?, completion: @escaping (_ result: Bool, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_SUBSCRIBE, domainid, id)) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams(useToken: shouldUseToken(domainid: domainid)) {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        let parameters = ["email": mail] as [String : String]
        
        AF.request(urlComponents.url!, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        if let result = json?["success"] as? Bool {
                            completion(result, nil)
                        } else {
                            completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                    } catch {
                        completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
        
    }
    
    /**
     Returns the details of the given category.
     - parameter id: The id of the category
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the Category or an error as String.
     */
    public func getCategoryDetails(id: Int, system: System?, completion: @escaping (_ reportType: ReportTypeMO?, _ error: String?) -> Void) {
        self.getSingleObject(url: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_GET_CATEGORY, system?.appid ?? 1, id), parameters: getDefaultParams(useToken: false)) { result, error in
            if let data = result {
                completion(ReportTypeMO(serialization: data), nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    /**
     Performs a logout for the current user.
     - parameter completion: Called after the request to the API. Returns the Response or an error as String.
     */
    public func logout(completion: @escaping (_ result: BasicResponse?, _ error: String?) -> Void) {
        AF.request(MMApi.shared.SERVER_URL + "api/v1" + ApiMethodPaths.PATH_LOGOUT, method: .get, parameters: getDefaultParams(), headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            completion(BasicResponse(success: json["success"] as? Bool ?? false, message: json["message"] as? String ?? ""), nil)
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Returns possible duplicates at the given location for the given category.
     - parameter lat: Latitude as Double
     - parameter lon: Longitude as Double
     - parameter categoryid: The ID of the category
     - parameter domainid: The ID of the domain
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns an array of messages or an error as String.
     */
    public func getDuplicates(lat: Double, lon: Double, categoryid: Int, domainid: Int, system: System?, completion: @escaping (_ reports: Array<ReportDetails>?, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_DUPLICATES, domainid)) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams(useToken: shouldUseToken(domainid: domainid)) {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems?.append(URLQueryItem(name: "fieldset", value: "mmv2"))
        
        let parameters = ["typeid": categoryid, "lat":lat, "lon":lon] as [String : Any]
        AF.request(urlComponents.url!, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var reports = Array<ReportDetails>()
                        if let data = json?["data"] as? Dictionary<String, Any>, let array = data["duplicates"] as? Array<Any> {
                            for object in array {
                                if let seri = object as? Serialization {
                                    reports.append(ReportDetails(serialization: seri))
                                }
                            }
                        }
                        completion(reports, nil)
                        
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
        
    }
    
    /**
     Login with email and password.
     - parameter email: The email if the user.
     - parameter password: The password if the user.
     - parameter domainid: Th ID of the domain the user wants to login to. If no domainid is provided, the default domain from MMSettings will be used.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the response or an error as String.
     */
    public func login(email: String, password: String, domainid: Int = MMSettings.shared.DEFAULT_DOMAIN_ID, system: System?, completion: @escaping (_ response: LoginResponse?, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + ApiMethodPaths.PATH_LOGIN) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams() {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        let parameters = ["email": email, "password":password, "domainid":domainid] as [String : Any]
        AF.request(urlComponents.url!, method: .post, parameters: parameters, headers: getHeaders()).responseData { response in
            URLSession.shared.reset {
                DispatchQueue.main.async {
                    switch response.result {
                        case .success(let data):
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                                if let data = json?["data"] as? Dictionary<String, Any> {
                                    completion(LoginResponse(serialization: data), nil)
                                } else {
                                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                                }
                                
                            } catch {
                                completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                }                
            }
        }
    }
    
    /**
     Deletes the account of the given user.
     - parameter userid: The ID of the user.
     - parameter domainid: The ID of the domain.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the response or an error as String.
     */
    public func deleteAccount(userid: Int, domainid: Int, system: System?, completion: @escaping (_ response: BasicResponse?, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_DELETE_ACCOUNT, domainid, userid)) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams() {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        let parameters = ["confirm": 1] as [String : Any]
        AF.request(urlComponents.url!, method: .put, parameters: parameters, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            completion(BasicResponse(success: json["success"] as? Bool ?? false, message: json["message"] as? String ?? ""), nil)
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Returns all messages for the given paramters.
     - parameter checkNumber: The Sammelcheck-Number for which the messages should be returned.
     - parameter owner: The Owner-ID for which the messages should be returned.
     - parameter page: The page that should be returned.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the messages as an array or an error as String.
     */
    public func getMessagesForList(checkNumber: String?, owner: String?, page: Int, system: System?, completion: @escaping (_ reports: Array<ReportMO>?, _ error: String?) -> Void) {
        var parameters = getDefaultParams(useToken: MMSettings.shared.onlyShowDefaultDomain)
        parameters["rows"] = "20"
        parameters["page"] = String(page)
        parameters["fieldset"] = "mmv2_map"
        
        if let owner = owner {
            parameters["ownerid"] = owner
        } else {
            parameters["visible_map"] = "1"
        }
        
        if let sammel = checkNumber {
            parameters["attribute1770"] = sammel
        }
        
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + (MMSettings.shared.onlyShowDefaultDomain ? String.init(format: ApiMethodPaths.PATH_NEAREST_MESAGES_DOMAIN, MMSettings.shared.DEFAULT_DOMAIN_ID) : String.init(format: ApiMethodPaths.PATH_NEAREST_MESAGES, system?.appid ?? MMSettings.shared.APP_ID)), method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var reports = Array<ReportMO>()
                        if let data = json?["data"] as? Array<Any> {
                            for object in data {
                                if let seri = object as? Serialization {
                                    reports.append(ReportMO(serialization: seri))
                                }
                            }
                        }
                        completion(reports, nil)
                        
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Returns all messages for the given boundingbox.
     - parameter boundingBox: The BoundingBox for which the messages should be returned.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter filter: The current filters, empty if there are none.
     - parameter completion: Called after the request to the API. Returns the messages as an array or an error as String.
     */
    public func getNearestMessages(boundingBox: BoundingBox, filter: Dictionary<String, Any> = [:], system: System?, completion: @escaping (_ reports: Array<ReportMO>?, _ error: String?) -> Void) {
        var parameters = getDefaultParams(useToken: MMSettings.shared.onlyShowDefaultDomain)
        parameters["top"] = String.init(format: "%f", boundingBox.ne.latitude)
        parameters["left"] = String.init(format: "%f", boundingBox.sw.longitude)
        parameters["bottom"] = String.init(format: "%f", boundingBox.sw.latitude)
        parameters["right"] = String.init(format: "%f", boundingBox.ne.longitude)
        parameters["visible_map"] = "1"
        parameters["fieldset"] = "mmv2_map"
        
        if let search_title = filter["search_title"] as? String, !search_title.isEmpty {
            parameters["text"] = search_title
        }
        
        if let searchTypes = filter["states"] as? Array<Bool> {
            var states = ""
            for i in 0..<searchTypes.count {
                if searchTypes[i] {
                    if i == 0 {
                        states += "in Bearbeitung,"
                    } else if i == 1 {
                        states += "Ungelöst Abgeschlossen,"
                    } else if i == 2 {
                        states += "Ungeprüft,"
                    } else if i == 3 {
                        states += "Gelöst,"
                    } else if i == 4 {
                        states += "Weitergabe an Dritte,"
                    }
                }
            }
            
            if states.isEmpty {
                completion([], nil)
            } else {
                states.removeLast()
                parameters["state"] = states
            }
        }
        
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + (MMSettings.shared.onlyShowDefaultDomain ? String.init(format: ApiMethodPaths.PATH_NEAREST_MESAGES_DOMAIN, MMSettings.shared.DEFAULT_DOMAIN_ID) : String.init(format: ApiMethodPaths.PATH_NEAREST_MESAGES, system?.appid ?? MMSettings.shared.APP_ID)), method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var reports = Array<ReportMO>()
                        if let data = json?["data"] as? Array<Any> {
                            for object in data {
                                if let seri = object as? Serialization {
                                    reports.append(ReportMO(serialization: seri))
                                }
                            }
                        }
                        
                        completion(reports, nil)
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Search for an location via a given search text.
     - parameter searchText: A String representing the search text+
     - parameter domainid: The ID of the domain.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the found Coordinates or nil.
     */
    public func searchAddress(searchText: String, domainid:Int?, system: System?, completion: @escaping (Double?, Double?) -> Void) {
        var parameters = getDefaultParams(useToken: shouldUseToken(domainid: domainid ?? 0))
        parameters["q"] = searchText
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String.init(format: ApiMethodPaths.PATH_SEARCH_ADDRESS, domainid == nil ? "" : String(domainid!)), method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        let data = json?["data"] as? Dictionary<String, Any>
                        let results = data?["results"] as? Array<Dictionary<String, Any>>
                        let geometry = results?.first?["geometry"] as? Dictionary<String, Any>
                        let location = geometry?["location"] as? Dictionary<String, Any>
                        completion(location?["lat"] as? Double, location?["lng"] as? Double)
                    } catch {
                        completion(nil, nil)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, nil)
            }
        }
    }
    
    /**
     Searches the categories of the given domain (and system) for the keyword.
     - parameter searchText: A String representing the search text+
     - parameter domainid: The ID of the domain.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the found ReportTypes or an error as String.
     */
    public func searchCategory(searchText: String, domainid:Int, system: System?, completion: @escaping (_ types: Array<ReportTypeMO>?, _ error: String?) -> Void) {
        var parameters = getDefaultParams(useToken: shouldUseToken(domainid: domainid))
        parameters["q"] = searchText
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_SEARCH_CATEGORY, domainid), method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var reports = Array<ReportTypeMO>()
                        if let data = json?["data"] as? Array<Any> {
                            for object in data {
                                if let seri = object as? Serialization {
                                    reports.append(ReportTypeMO(serialization: seri))
                                }
                            }
                        }
                        completion(reports, nil)
                        
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
            }
        }
    }
    
    /**
     Creates a picture bundle for messages with multiple pictures.
     - parameter domainid: The ID of the domain.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the PictureBundle or an error as String.
     */
    public func createBundle(domainid: Int, system: System?, completion: @escaping (_ bundle: PictureBundle?, _ error: String?) -> Void) {
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_CREATE_BUNDLE, domainid), method: .post, parameters: getDefaultParams(useToken: shouldUseToken(domainid: domainid)), encoder: URLEncodedFormParameterEncoder(destination: .queryString), headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        if let data = json?["data"] as? Dictionary<String, Any> {
                            completion(PictureBundle(json: data), nil)
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Uploads a picture to the given bundle.
     - parameter domainid: The ID of the domain.
     - parameter token: The token of the picture bundle.
     - parameter image: The image that should be uploaded.
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the PictureBundle or an error as String.
     */
    public func uploadFileToBundle(domainid: Int, token: String, image: UIImage, system: System?, completion: @escaping (_ bundle: PictureBundle?, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_FILE_TO_BUDLE, domainid, token)) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams(useToken: shouldUseToken(domainid: domainid)) {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(image.jpegData(compressionQuality: 1.0) ?? Data(), withName: "picture", fileName: "pic.jpg", mimeType: "image/jpeg")
        }, to: urlComponents.url!, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        if let data = json?["data"] as? Dictionary<String, Any> {
                            completion(PictureBundle(json: data), nil)
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
        
    }
    
    /**
     Updates a Message with a comment, attributes and a picture (all are optional)
     - parameter id: The ID of the message
     - parameter text: The text the user has entered as a comment
     - parameter attributes: The attributes that are needed for an update
     - parameter solved: Indicates if the message is solved
     - parameter image: The new image for the message
     - parameter domainid: The domainID of the message
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the UpdateResponse or an error as String.
     */
    public func updateReport(id: Int, text: String, attributes: Array<ReportTypeAttributeMO>, solved: Bool, image: UIImage?, domainid: Int, system: System?, completion: @escaping (_ result: UploadReportResponse?, _ error: String?) -> Void) {
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_UPDATE, domainid)) ?? URLComponents()
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams(useToken: shouldUseToken(domainid: domainid)) {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }
        
        AF.upload(multipartFormData: { multipartFormData in		
            if image != nil { multipartFormData.append(image!.jpegData(compressionQuality: 1.0) ?? Data(), withName: "picture", fileName: "pic.jpg", mimeType: "image/jpeg") }
            
            var data: String = ""
            if UserDefaults.standard.string(forKey: "token") == nil {
                data = "{\"messageid\":\(id), \"text\":\"\(text)\", \"solved\":\(solved ? 1 : 0),  \"phone\": \"\(UIDevice.current.identifierForVendor?.uuidString ?? "NO_ID")\", \"attribute_values\" : \(self.attributesToJSON(attributes))}"
            } else {
                data = "{\"messageid\":\(id), \"text\":\"\(text)\", \"solved\":\(solved ? 1 : 0),  \"attribute_values\" : \(self.attributesToJSON(attributes))}"
            }
            data = data.replacingOccurrences(of: "\n", with: "\\n")
            multipartFormData.append(data.data(using: .utf8) ?? Data(), withName: "data")
            
        }, to: urlComponents.url!, headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            if json["success"] as? Bool ?? true {
                                completion(UploadReportResponse(success: true, message: "UPDATE_SUCCESS", messageid: id), nil)
                            } else if let message = json["message"] as? String {
                                if message.contains("ERR2") {
                                    completion(UploadReportResponse(success: false, message: "MESSAGE_NOT_EXISTENT", messageid: json["messageid"] as? Int ?? 0), nil)
                                } else if message.contains("ERR1") {
                                    completion(UploadReportResponse(success: false, message: "MISSING_TEXT", messageid: json["messageid"] as? Int ?? 0), nil)
                                } else if message.contains("ERR5") {
                                    completion(UploadReportResponse(success: false, message: "NOT_ALLOWED", messageid: json["messageid"] as? Int ?? 0), nil)
                                } else {
                                    completion(UploadReportResponse(success: false, message: "UNKOWN_ERROR", messageid: json["messageid"] as? Int ?? 0), nil)
                                }
                            }
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Uploads a new Message to the Server.
     - parameter report: The message that should be uploaded
     - parameter bundle: Optional: The picture bundle for the pictures
     - parameter isCurrentUserResponsible: Bool that indicated if the current user should be made responsible for the message
     - parameter system: The system to which the message should be uploaded
     - parameter updateProgress: This function is called while uploading and contains the current progress (0-1)
     - parameter completion: This is called after the API call. Contains the Response or an error as String.
     */
    public func uploadReport(_ report: ReportMO, bundle: PictureBundle?, isCurrentUserResponsible: Bool, system: System?, updateProgress: @escaping (_ progress: Double) -> Void, completion: @escaping (_ result: UploadReportResponse?, _ error: String?) -> Void) {
        
        // Use report type's domainid instead of the report's
        // This is to avoid areas with overlapping domains
        var urlComponents = URLComponents(string: (system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String(format: ApiMethodPaths.PATH_UPLOAD_REPORTS, report.reportType?.domainID?.intValue ?? 32)) ?? URLComponents()
        
        urlComponents.queryItems = []
        for (key, value) in getDefaultParams(useToken: shouldUseToken(domainid: report.domainid?.intValue ?? 32)) {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
        }

        AF.upload(multipartFormData: { multipartFormData in
            let uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "x") + MMSettings.shared.versionNameSuffix
            let position = report.reportType?.position == "never" ? "" : "\"lat\" : \(report.lat.decimalValue), \"lon\" : \(report.long.decimalValue),"
            var data : String
            if bundle != nil {
                if isCurrentUserResponsible {
                    let userid = UserDefaults.standard.string(forKey: "user.id") ?? ""
                    data = "{\"title\" : \"\((report.title ?? "Kein Titel").replacingOccurrences(of: "\"", with: "\\\""))\", \"bundle_token\" : \"\(bundle!.token)\", \"via\" : \"iOS\", \"expected_filenames\" : \(bundle!.expectedFilenames), \"phone\" : \"\(uuid)\", \"appv\": \"\(appVersion)\", \"description\" : \"\((report.text ?? "Kein Beschreibung").replacingOccurrences(of: "\"", with: "\\\""))\", \"typeid\":\(report.reportType!.id ?? 0), \(position) \"responsibleid\": \"\(userid)\", \"attribute_values\" : \(report.attributesJSON(update: false))}"
                } else {
                    data = "{\"title\" : \"\((report.title ?? "Kein Titel").replacingOccurrences(of: "\"", with: "\\\""))\", \"bundle_token\" : \"\(bundle!.token)\", \"via\" : \"iOS\", \"expected_filenames\" : \(bundle!.expectedFilenames), \"phone\" : \"\(uuid)\", \"description\" : \"\((report.text ?? "Kein Beschreibung").replacingOccurrences(of: "\"", with: "\\\""))\", \"typeid\":\(report.reportType!.id ?? 0), \(position) \"attribute_values\" : \(report.attributesJSON(update: false))}"
                }
            } else {
                if isCurrentUserResponsible {
                    let userid = UserDefaults.standard.string(forKey: "user.id") ?? ""
                    data = "{\"title\" : \"\((report.title ?? "Kein Titel").replacingOccurrences(of: "\"", with: "\\\""))\", \"via\" : \"iOS\", \"phone\" : \"\(uuid)\", \"appv\": \"\(appVersion)\", \"appv\": \"\(appVersion)\", \"description\" : \"\((report.text ?? "Kein Beschreibung").replacingOccurrences(of: "\"", with: "\\\""))\", \"typeid\":\(report.reportType!.id ?? 0), \(position) \"responsibleid\": \"\(userid)\", \"attribute_values\" : \(report.attributesJSON(update: false))}"
                } else {
                    data = "{\"title\" : \"\((report.title ?? "Kein Titel").replacingOccurrences(of: "\"", with: "\\\""))\", \"via\" : \"iOS\", \"phone\" : \"\(uuid)\", \"appv\": \"\(appVersion)\", \"description\" : \"\((report.text ?? "Kein Beschreibung").replacingOccurrences(of: "\"", with: "\\\""))\", \"typeid\":\(report.reportType!.id ?? 0), \(position) \"attribute_values\" : \(report.attributesJSON(update: false))}"
                }
            }
            
            data = data.replacingOccurrences(of: "\n", with: "\\n")
            multipartFormData.append(data.data(using: .utf8) ?? Data(), withName: "data")
            
            if bundle == nil && report.attachments.count > 0 {
                let imagesPaths = report.attachments.array as! [String]
                let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let img_1st = UIImage(contentsOfFile: baseURL.appendingPathComponent(imagesPaths.first!).path) ?? UIImage()
                let img_1st_data = img_1st.jpegData(compressionQuality: 1.0) ?? Data()
                multipartFormData.append(img_1st_data, withName: "picture", fileName: "pic.jpg", mimeType: "image/jpeg")
            }
            
        }, to: urlComponents.url!, headers: getHeaders()).uploadProgress(closure: { progress in
            var progress = progress.fractionCompleted
            if progress > 1 {
                progress = 0.99
            }
            updateProgress(progress)
        }).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            if let message = json["message"] as? String {
                                completion(UploadReportResponse(success: false, message: message, messageid: 0), nil)
                            } else {
                                if let data = json["data"] as? Dictionary<String, Any>, let links = data["links"] as? Dictionary<String, Any>, let selfJson = links["self"] as? Dictionary<String, Any>, let href = selfJson["href"] as? String, let indexOfSlash = href.range(of: "/", options: .backwards), let id = Int(href.suffix(from: href.index(after: indexOfSlash.lowerBound))) {
                                    completion(UploadReportResponse(success: true, message: "SUCCESS", messageid: id), nil)
                                } else {
                                    completion(UploadReportResponse(success: true, message: "SUCCESS", messageid: 0), nil)
                                }
                            }
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Returns the categories of the given domain.
     - parameter domainid: The id of the domain that should be queried
     - parameter system: The system of the domain (if nil the default values will be used)
     - parameter completion: Called after the request to the API. Returns the Domain or an error as String.
     */
    public func getCategories(domainID: Int, system: System?, completion: @escaping (_ types: Array<ReportTypeMO>?, _ error: String?) -> Void) {
        AF.request((system?.host ?? MMApi.shared.SERVER_URL) + "api/v1" + String.init(format: ApiMethodPaths.PATH_CATEGORIES, domainID), method: .get, parameters: getDefaultParams(useToken: shouldUseToken(domainid: domainID)), headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        var reports = Array<ReportTypeMO>()
                        if let data = json?["data"] as? Array<Any> {
                            for object in data {
                                if let seri = object as? Serialization {
                                    reports.append(ReportTypeMO(serialization: seri))
                                }
                            }
                        }
                        completion(reports, nil)
                        
                    } catch {
                        completion([], LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    /**
     Set the message to private.
     - parameter messageID: The ID of the message that should be made private
     - parameter domainID: The ID of the domain of the mesage
     - parameter system: The system of the domain
     - parameter completion: Called after the request to the API. Returns a bool indicating success and an error as String.
     */
    public func setMessagePrivate(messageID: Int, domainID: Int, system: System, completion: @escaping (_ success: Bool, _ error: String?) -> Void) {
        AF.request(system.host + "api/v1" + String.init(format: ApiMethodPaths.PATH_PRIVATE, domainID, messageID), method: .get, parameters: getDefaultParams(useToken: shouldUseToken(domainid: domainID)), headers: getHeaders()).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            if json["success"] as? Bool ?? false {
                                completion(true, nil)
                            } else {
                                completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                            }
                        } else {
                            completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(false, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    public func getOfflineMapVersion(completion: @escaping (_ result: Int?, _ error: String?) -> Void) {
        AF.request(MMSettings.shared.offlineMapVersionCheckUrl, method: .get, headers: getHeaders(noCache: true)).responseData { response in
            switch response.result {
                case .success(let data):
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any> {
                            let version = json["version"] as! Int?
                            completion(version, "")
                        }
                    } catch {
                        // Error parsing json. Just ignore the result then
                    }
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    private func getSingleObject(url: String, parameters: Dictionary<String, String>, completion: @escaping (_ result: Dictionary<String, Any>?, _ error: String?) -> Void) {
        AF.request(url, method: .get, parameters: parameters, headers: getHeaders()).responseData { response in
            // print("getSingleObject", "request url: \(response.request?.url)")
            // print("getSingleObject", "response: \(response)")
            switch response.result {
                case .success(let data):
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? Dictionary<String, Any>
                        if let data = json?["data"] as? Dictionary<String, Any> {
                            completion(data, nil)
                        } else {
                            completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                        }
                        
                    } catch {
                        completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    completion(nil, LocalizedString("UNKOWN_ERROR", comment: ""))
                }
        }
    }
    
    private func shouldUseToken(domainid: Int) -> Bool {
        return UserDefaults.standard.integer(forKey: "user.domainID") == domainid
    }
    
    private func getDefaultParams(useToken: Bool = true) -> [String: String] {
        var parameters = Dictionary<String, String>()
        parameters["appv"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "x"
        parameters["appv"]! += MMSettings.shared.versionNameSuffix
        parameters["pf"] = "ios"
        parameters["app"] = Bundle.main.bundleIdentifier
        
        if useToken, let token = UserDefaults.standard.string(forKey: "token") {
            parameters["authorization"] = token
        } else {
            parameters["phone"] = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }
        if let apikey = UserDefaults.standard.string(forKey: "apikey") {
            parameters["apikey"] = apikey
        }
        
        return parameters
    }
    
    private func getHeaders(noCache: Bool = false) -> HTTPHeaders {
        var headers = HTTPHeaders()
        if useBasicAuth {
            headers.add(HTTPHeader.authorization(username: basicAuthUser, password: basicAuthPass))
        }
        if noCache {
            headers.add(HTTPHeader.self(name: "Cache-Control", value: "no-cache"))
        }
        return headers
    }
    
    private func attributesToJSON(_ attributes: Array<ReportTypeAttributeMO>) -> String {
        if attributes.count == 0 {
            return "{}"
        }
        
        var dict = "{"
        for attribute in attributes {
            if attribute.type == AttributeTypes.valuelist {
                dict.append("\"\(attribute.id!.intValue)\" : [\"\(attribute.answer?.split(separator: "^").first ?? "")\"]")
            } else {
                dict.append("\"\(attribute.id!.intValue)\" : [\"\(attribute.answer ?? "")\"]")
            }
            dict.append(", ")
        }
        dict = String(dict.dropLast())
        dict = String(dict.dropLast())
        dict.append("}")
        return dict
    }
    
}

