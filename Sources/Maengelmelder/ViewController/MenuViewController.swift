//
//  MenuViewController.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import SideMenu

class MenuViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var headerImageVeiw : UIImageView!
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    @IBOutlet weak var tableVView : UITableView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var infoTextLabel: UILabel!
    @IBOutlet weak var fussHeaderView: UIView!
    
    fileprivate var viewModel: MenuViewModel?
    
    public var params: (Int, Double, Double)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fussHeaderView.isHidden = true
        
        versionLabel.font = MMFontScheme.shared.smallTextFont
        versionLabel.textColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
        versionLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        
        if let infoText = MMSettings.shared.infoTextBottomMenu {
            infoTextLabel.isHidden = false
            infoTextLabel.attributedText = infoText
            infoTextLabel.textColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
            
            // Clickable
            let tap = UITapGestureRecognizer(target: self, action: #selector(MenuViewController.onInfoTextClicked))
            infoTextLabel.isUserInteractionEnabled = true
            infoTextLabel.addGestureRecognizer(tap)
        } else {
            infoTextLabel.isHidden = true
        }
        
        viewModel = MenuViewModel(tableView: tableVView, vc: self)
        tableVView.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .secondaryAppTheme)
        tableVView.dataSource = viewModel
        tableVView.delegate = self
        
        let image = UIImage(named: "mm_menu_banner", in: Bundle.main, compatibleWith: nil) ?? UIImage(named: "mm_menu_banner", in: MM.shared.bundle, compatibleWith: nil)
        headerHeight.constant = image?.size.height ?? 150
        
        self.view.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .menuHeaderBg)
        self.headerImageVeiw.image = image
    }
    
    public func setParams(domainid: Int, latitude: Double, longitude: Double) {
        self.viewModel?.params = (domainid, latitude, longitude)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vcToPush = self.viewModel?.selectRowAction(indexPath: indexPath) {
            if vcToPush is UIAlertController {
                self.present(vcToPush, animated: true, completion: nil)
            } else {
                self.navigationController?.pushViewController(vcToPush, animated: true)
            }
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: self.viewModel?.selectRowNotfication(indexPath: indexPath) ?? ""), object: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func onInfoTextClicked(sender: UITapGestureRecognizer) {
        if let url = MMSettings.shared.linkTextBottomMenu, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
}
