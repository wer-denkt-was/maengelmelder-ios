//
//  ReportListViewController.swift
//  MM
//
//  Created by Felix on 28.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class ReportListViewController: UIViewController, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private var viewModel : ReportListViewModel?
    
    var currentDomainID = MMSettings.shared.DEFAULT_DOMAIN_ID
    var currentLat:Double = 0
    var currentLon:Double = 0
    var selectedGroup:ReportGroup?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.viewModel = ReportListViewModel(self, group: selectedGroup)
        self.tableView.dataSource = self.viewModel
        self.tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if selectedGroup != nil {
            self.navigationItem.title = String.init(format: "%d Meldungen", selectedGroup!.getReports().count)
        } else {
            self.navigationItem.title = LocalizedString("REPORT_LIST_PAGE_TITLE", comment: "")
        }
        
        let button1 = UIBarButtonItem(image: UIImage(named: "sort", in: MM.shared.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showSortAlert))
        let button2 = UIBarButtonItem(image: UIImage(named: "filter_list", in: MM.shared.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showFilterView))
        button1.accessibilityLabel = "Sortieren"
        button2.accessibilityLabel = "Filtern"
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(image: UIImage(named: "sort", in: MM.shared.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showSortAlert)),
                                                   UIBarButtonItem(image: UIImage(named: "filter_list", in: MM.shared.bundle, compatibleWith: nil), style: .plain, target: self, action: #selector(showFilterView))]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.present(self.viewModel!.didSelectRowAt(indexPath: indexPath), animated: true, completion: nil)
    }
    
    @objc func showSortAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Nach Name sortieren", style: .default, handler: { (action) in
            self.viewModel?.sort(.Name)
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Nach Kategorie sortieren", style: .default, handler: { (action) in
            self.viewModel?.sort(.Typ)
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "Nach Status sortieren", style: .default, handler: { (action) in
            self.viewModel?.sort(.State)
            self.tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func showFilterView() {
        self.performSegue(withIdentifier: "show_filter", sender: self)
    }

}
