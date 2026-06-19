//
//  Serialization.swift
//  Maengelmelder
//
//  Created by Felix on 13.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation

typealias Serialization = [String: Any]

protocol SerializationKey {
    var stringValue: String { get }
}

extension RawRepresentable where RawValue == String {
    var stringValue: String {
        return rawValue
    }
}

protocol SerializationValue {}

extension Bool: SerializationValue {}
extension String: SerializationValue {}
extension NSNumber: SerializationValue {}
extension Dictionary: SerializationValue {}
extension Array: SerializationValue {}
extension Int: SerializationValue {}
extension Int64: SerializationValue {}

extension Dictionary where Key == String, Value: Any {
    func value<V: SerializationValue>(forKey key: SerializationKey) -> V? {
        return self[key.stringValue] as? V
    }
}


