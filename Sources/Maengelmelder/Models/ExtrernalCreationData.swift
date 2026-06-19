//
//  ExtrernalCreationData.swift
//  Maengelmelder
//
//  Created by Felix Leber on 28.11.25.
//

import Foundation

class ExtrernalCreationData {
    
    private var lat: Double? = nil
    private var lon: Double? = nil
    private var forceLoc = false
    private var typeId: Int? = nil
    private var forceTypeId = false
    private var forceAttributes = Dictionary<Int, String>()
    private var selectAttributes = Dictionary<Int, String>()
    
    init(with url: URL) {
        let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true)
        let params = components?.queryItems
        
        for param in params ?? [] {
            if param.name == "lat" {
                lat = Double(param.value ?? "")
            } else if param.name == "lon" {
                lon = Double(param.value ?? "")
            } else if param.name == "force_loc" {
                forceLoc = param.value == "1"
            } else if param.name == "selected_typeid" {
                typeId = Int(param.value ?? "")
            } else if param.name == "force_typeid" {
                typeId = Int(param.value ?? "")
                forceTypeId = true
            } else if param.name.starts(with: "force_attribute") {
                if let id = Int(param.name.replacingOccurrences(of: "force_attribute", with: "")) {
                    forceAttributes[id] = param.value ?? ""
                }
            } else if param.name.starts(with: "selected_attribute") {
                if let id = Int(param.name.replacingOccurrences(of: "selected_attribute", with: "")) {
                    selectAttributes[id] = param.value ?? ""
                }
            }
        }
    }
    
    func getLat() -> Double? {
        return lat
    }
    
    func getLon() -> Double? {
        return lon
    }
    
    func shouldForceLocation() -> Bool {
        return forceLoc
    }
    
    func getTypeId() -> Int? {
        return typeId
    }
    
    func shouldForceTypeId() -> Bool {
        return forceTypeId
    }
    
    func getForcedAttribute(for id: Int) -> String? {
        return forceAttributes[id]
    }
    
    func getSelectedAttribute(for id: Int) -> String? {
        return selectAttributes[id]
    }
    
}
