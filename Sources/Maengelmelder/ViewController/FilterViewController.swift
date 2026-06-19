//
//  FilterViewController.swift
//  MM
//
//  Created by Felix on 10.04.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController {

    @IBOutlet weak var stateTitle: UILabel!
    @IBOutlet weak var inProcessSwitch: UISwitch!
    @IBOutlet weak var inProcessLabel: UILabel!
    @IBOutlet weak var green2Switch: UISwitch!
    @IBOutlet weak var green2Label: UILabel!
    @IBOutlet weak var redSwitch: UISwitch!
    @IBOutlet weak var redLabel: UILabel!
    @IBOutlet weak var blueLabel: UILabel!
    @IBOutlet weak var blueSwitch: UISwitch!
    @IBOutlet weak var greenSwitch: UISwitch!
    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var favLabel: UILabel!
    @IBOutlet weak var favSwitch: UISwitch!

    @IBOutlet weak var blueHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var blueBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var blueTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var searchTitle: UITextField!
    @IBOutlet weak var searchType: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = LocalizedString("FILTER_AFTER", comment: "")
        self.stateTitle.text = LocalizedString("STATE", comment: "")
        self.inProcessLabel.text = LocalizedString("IN_PROGRESS", comment: "")
        self.green2Label.text = LocalizedString("FINISHED_INCOMPLETE", comment: "")
        self.redLabel.text = LocalizedString("INCOMPLETE", comment: "")
        self.greenLabel.text = LocalizedString("FINISHED", comment: "")
        self.favLabel.text = LocalizedString("FAV_FILTER", comment: "")
        self.blueLabel.text = "Weitergabe an Dritte"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButton))
        
        self.searchTitle.placeholder = LocalizedString("SEARCH_TITLE_DESC", comment: "")
        self.searchTitle.textColor = self.view.isDarkMode() ? .white : .black
        
        self.searchType.placeholder = LocalizedString("HEADING_STEP_3", comment: "")
        self.searchType.textColor = self.view.isDarkMode() ? .white : .black
        
        if !MMSettings.shared.showBlueStatus {
            self.blueHeightConstraint.constant = 0
            self.blueBottomConstraint.constant = 0
            self.blueSwitch.isHidden = true
        }
        
    }
    
    @objc func doneButton() {
        var dict = ["states" : [inProcessSwitch.isOn, green2Switch.isOn, redSwitch.isOn, greenSwitch.isOn, blueSwitch.isOn], "only_fav":favSwitch.isOn] as [String : Any]
        if let search = self.searchTitle.text, !search.isEmpty {
            dict["search_title"] = search
        }
        if let search = self.searchType.text, !search.isEmpty {
            dict["search_type"] = search
        }
        NotificationCenter.default.post(name: NSNotification.Name("filter_settings"), object: nil, userInfo: dict)
        self.navigationController?.popViewController(animated: true)
        UserDefaults.standard.set(dict, forKey: "user_filter")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let dict = UserDefaults.standard.dictionary(forKey: "user_filter") {
            self.favSwitch.isOn = dict["only_fav"] as? Bool ?? false
            if let states = dict["states"] as? [Bool] {
                self.inProcessSwitch.isOn = states[0]
                self.green2Switch.isOn = states[1]
                self.redSwitch.isOn = states[2]
                self.greenSwitch.isOn = states[3]
                if states.count > 4 { self.blueSwitch.isOn = states[4] }
            }
            if let search = dict["search_title"] as? String {
                self.searchTitle.text = search
            }
            if let search = dict["search_type"] as? String {
                self.searchType.text = search
            }
        }
    }
}
