//
//  CustomTypeViewController.swift
//  Maengelmelder
//
//  Created by Felix on 17.12.24.
//

import UIKit

public protocol CustomTypeDelegate {
    func setCategory(_ id: Int)
    func tabBarPressed(_ index: Int)
    func saveButton()
}

open class CustomTypeViewController: UIViewController {
    public var delegate:CustomTypeDelegate?
}
