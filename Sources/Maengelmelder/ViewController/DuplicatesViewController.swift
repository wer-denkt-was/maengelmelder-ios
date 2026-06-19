//
//  DuplicatesViewController.swift
//  MM
//
//  Created by Felix on 26.07.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData

class DuplicatesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var duplicates = Array<ReportDetails>()
    var system: System = System.fallback
    
    override func viewDidLoad() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Trotzdem weiter", style: .plain, target: self, action: #selector(continueCreation))
    }
    
    @objc func continueCreation() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return duplicates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let duplicate = self.duplicates[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell") as! ReportTableViewCell
        cell.idLabel.text = String.init(format: LocalizedString("MESSAGE_DETAIL_PAGE_TITLE", comment: ""), duplicate.messageid.intValue)
        cell.titleLabel.text = duplicate.text
        cell.subtitleLabel.text = duplicate.state
        cell.markerView.image = UIImage(named: String(format:"marker-%@-%d.png", duplicate.markerColor, duplicate.markerID), in: MM.shared.bundle, compatibleWith: nil) ?? UIImage()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let duplicate = self.duplicates[indexPath.row]
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportDetailController") as! ReportDetailViewController
        vcToPush.reportId = duplicate.messageid
        vcToPush.domainId = NSNumber(value: duplicate.domainID)
        vcToPush.system = system
        self.navigationController?.pushViewController(vcToPush, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Mögliche Duplikate"
    }

}
