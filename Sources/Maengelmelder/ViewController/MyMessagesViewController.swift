//
//  MyMessagesViewController.swift
//  MM
//
//  Created by Felix on 13.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import JGProgressHUD
import StoreKit

class MyMessagesViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ideaSegmentControl: UISegmentedControl!
    @IBOutlet weak var tableViewTopSpace: NSLayoutConstraint!
    @IBOutlet weak var ideaToolbar: UIToolbar!
    @IBOutlet weak var loadingView: UIView!
    
    private var viewModel : MyMessagesViewModel?
    
    private var networkInfoButton: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        viewModel = MyMessagesViewModel()
        tableView.dataSource = viewModel
        tableView.delegate = self
        
        self.navigationItem.title = LocalizedString("MY_MESSAGES_TITLE", comment: "")
        
        self.networkInfoButton = UIBarButtonItem(image: UIImage(systemName: "wifi.exclamationmark"), style: .plain, target: self, action: #selector(self.noNetworkButtonAction(sender:)))
        self.networkInfoButton?.tintColor = .red
        
        if MMSettings.shared.isIdeaModuleActivated {
            self.ideaToolbar.barTintColor = MMColorScheme.shared.getColor(view: self.ideaToolbar, type: .barTint)
            self.ideaSegmentControl.backgroundColor = MMColorScheme.shared.getColor(isDark: self.view.isDarkMode(), type: .secondaryAppTheme)
            self.ideaSegmentControl.setTitleTextAttributes([.foregroundColor : MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)], for: .normal)
            self.ideaSegmentControl.setTitleTextAttributes([.foregroundColor : MMColorScheme.shared.getColor(view: self.view, type: .tableViewCellText)], for: .selected)
        } else {
            self.ideaToolbar.isHidden = true
            tableViewTopSpace.isActive = true
        }
    }
    
    @IBAction func ideaSegmentChanged(_ sender: Any) {
        self.viewModel?.setIdea(self.ideaSegmentControl.selectedSegmentIndex == 1)
        tableView.reloadData()
    }
    
    @objc func noNetworkButtonAction(sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Aktuell besteht keine Internetverbindung. Das Erstellen von Meldungen ist weiterhin möglich. Das Hochladen ist dann wieder möglich, wenn eine Internetverbindung besteht.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        InternetUtility.shared.delegate = self
        self.navigationItem.rightBarButtonItem = InternetUtility.shared.isOnline() ? nil : networkInfoButton
        self.viewModel?.reload(loadingView: self.loadingView)
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        
        if (indexPath.section == 0) {
            actionSheet.addAction(UIAlertAction(title: LocalizedString("UPLOAD_BTN_TITLE", comment: ""), style: .default, handler: {action in
                
                guard InternetUtility.shared.isOnline() else {
                    let alert = UIAlertController(title: nil, message: LocalizedString("NO_INTERNET", comment: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default))
                    self.present(alert, animated: true)
                    return
                }
                
                let hud = JGProgressHUD(style: .dark)
                hud.textLabel.text = "Upload wird vorbereitet..."
                hud.show(in: self.view)
                self.viewModel?.checkCategoryAtPosition(indexPath: indexPath, system: nil, callback: { success in
                    hud.dismiss(animated: true)
                    if success {
                        self.continueUpload(indexPath: indexPath)
                    } else {
                        var alertMsg = MMSettings.shared.messageInvalidPositionText;
                        if alertMsg.isEmpty {
                            alertMsg = LocalizedString(MMSettings.shared.showTypesFirst ? "TYPE_FIRST_CATEGORY_NOT_AVAILABLE" : "CATEGORY_NOT_AVAILABLE", comment: "")
                        }
                        let alert = UIAlertController(title: nil, message: alertMsg, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: { _ in
                            self.navigationController?.pushViewController(self.viewModel!.editReport(indexPath: indexPath, tab: 2), animated: true)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                })
            }))
            
            actionSheet.addAction(UIAlertAction(title: LocalizedString("EDIT_BTN_TITLE", comment: ""), style: .default, handler: { action in
                self.navigationController?.pushViewController(self.viewModel!.editReport(indexPath: indexPath), animated: true)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(title: LocalizedString("REPORT_LIST_SHOW_DETAILS", comment: ""), style: .default, handler: { action in
                self.viewModel?.showDetails(indexPath: indexPath, compleation: { (vc) in
                    if vc is UIAlertController {
                        self.present(vc, animated: true, completion: nil)
                    } else {
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                })
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: indexPath.section == 0 ? LocalizedString("DELETE_BTN_TITLE", comment: "") : "Ausblenden", style: .destructive, handler: { action in
            self.viewModel?.deleteReport(indexPath: indexPath)
            self.tableView.reloadData()
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func continueUpload(indexPath: IndexPath) {
        let domainName = self.viewModel!.getDomainName(indexPath)
        let string = String.init(format: "Ihre Meldung wird an\n%@\ngesendet.\nSollte das nicht zutreffend sein, prüfen Sie bitte Ihre angegebene Position.", domainName)
        
        let boldAttr = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)]
        let notBoldAttr = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        
        let attrStr = NSMutableAttributedString(string: string, attributes: notBoldAttr)
        let range = NSString(string: string).range(of: domainName)
        attrStr.setAttributes(boldAttr, range: range)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(attrStr, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: LocalizedString("UPLOAD_BTN_TITLE", comment: ""), style: .default, handler: { (action) in
            self.viewModel!.uploadReportToserver(indexPath: indexPath, viewForHud: self.view, compleation: {[unowned self] success in
                self.viewModel?.reload(loadingView: self.loadingView)
                self.tableView.reloadData()
                if success, MMSettings.shared.showRatingAfterUpload, let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    DispatchQueue.main.async {
                        SKStoreReviewController.requestReview(in: scene)
                    }
                }
            })
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: Internet Delegate

extension MyMessagesViewController : InternetUtilityDelegate {
    
    func onlineStatusChanged(_ isOnline: Bool) {
        self.navigationItem.rightBarButtonItem = isOnline ? nil : networkInfoButton
    }
    
}
