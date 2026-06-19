//
//  GenericDataSource.swift
//  Maengelmelder
//
//  Created by Felix on 18.10.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation

typealias CompletionHandler = (() -> Void)

class GenericDataSource<Model> : NSObject {
    
    var modelToDisplay : [Model]{
        didSet {
            self.notify()
        }
    }
    
    fileprivate var observers = [String: CompletionHandler]()
    
    override init() {
        modelToDisplay = []
    }
    
    func addObserver(_ observer: NSObject, completionHandler: @escaping CompletionHandler){
        observers[observer.description] = completionHandler
    }
    
    public func addAndNotify(observer: NSObject, completionHandler: @escaping CompletionHandler) {
        self.addObserver(observer, completionHandler: completionHandler)
        self.notify()
    }
    
    func notify() {        
        observers.forEach({ $0.value() })
    }
    
    deinit {
        observers.removeAll()
    }
}
