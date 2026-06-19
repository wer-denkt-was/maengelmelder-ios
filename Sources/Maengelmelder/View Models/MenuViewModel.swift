//
//  MenuViewModel.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class MenuViewModel: NSObject, UITableViewDataSource {
    
    private let OFFLINE_CELL = 856
    
    private struct Row {
        let cell:UITableViewCell
        let vc:UIViewController?
    }
    
    private var sections = Array<Array<Row>>()
    
    private var isLoginActive : Bool {
        return MMSettings.shared.isLoginModuleActivated
    }
    
    private var isIdeaActive : Bool {
        return MMSettings.shared.isIdeaModuleActivated
    }
    
    private var isOfflineActive : Bool {
        return MMSettings.shared.offlineMaps.count > 0 || MMSettings.shared.isManualOfflineModeActivated
    }
    
    private var isNewReportActive : Bool {
        return MMSettings.shared.showNewReportInMenu
    }
    
    private var tableView:UITableView
    private var parentViewController:UIViewController? = nil
    
    public var params: (Int, Double, Double) = (MMSettings.shared.DEFAULT_DOMAIN_ID, 0, 0)
    
    init(tableView: UITableView, vc: UIViewController? = nil) {
        self.tableView = tableView
        self.parentViewController = vc
        super.init()
        
        if isLoginActive {
            let cellName = UserDefaults.standard.string(forKey: "token") == nil ? "login_cell" : "profile_cell"
            sections.append([getRowForLogin(cell: (tableView.dequeueReusableCell(withIdentifier: cellName))!)])
        }
        
        if isIdeaActive {
            sections.append([self.getIdeaStartRow()])
        }
        
        if isOfflineActive {
            var offlineSection = Array<Row>()
            if MMSettings.shared.isManualOfflineModeActivated {
                offlineSection.append(self.getOfflineModeRow())
            }
            if MMSettings.shared.offlineMaps.count > 0 {
                offlineSection.append(self.getOfflineSettingsRow())
            }
            sections.append(offlineSection)
        }
        
        var myReportsSection = Array<Row>()
        if MMSettings.shared.showNewReportInMenu {
            myReportsSection.append(self.getNewReportRow())
        }
        if MMSettings.shared.showReportListButtonInMenu {
            myReportsSection.append(self.getReportListRow())
        }
        myReportsSection.append(self.getMyMessagesRow())
        sections.append(myReportsSection)
        
        var infoPages = Array<Row>()
        for i in 0..<MMSettings.shared.menuInfoPages.count {
            let menuInfoPage = MMSettings.shared.menuInfoPages[i]
            if menuInfoPage == .about_us && !MMSettings.shared.multipleAboutUsPages.isEmpty {
                // Build collapsible "about us" page links
                infoPages.append(self.getRowForMultipleAboutUsPages(position: i))
            } else if menuInfoPage == .resettutorial {
                // Reset tutorialbutton
                infoPages.append(self.getResetTutorialMenuItem())
            } else {
                // Do it as normal
                infoPages.append(self.getRowForInfoPages(position: i))
            }
        }
        sections.append(infoPages)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section][indexPath.row].cell
    }
    
    func selectRowAction(indexPath: IndexPath) -> UIViewController? {
        return sections[indexPath.section][indexPath.row].vc
    }
    
    func selectRowNotfication(indexPath: IndexPath) -> String? {
        if selectRowAction(indexPath: indexPath) != nil {
            return nil
        }
        
        if sections[indexPath.section][indexPath.row].cell.tag == OFFLINE_CELL {
            return "SetOffline"
        } else {
            return "ShowStart"
        }
    }
    
    private func getVCForMyMessageList() -> UIViewController {
        if let vcToPush = MMSettings.shared.customMyMessagesController {
            return vcToPush
        } else {
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vcToPush = storyboard.instantiateViewController(withIdentifier: "MyMessagesViewController")
            return vcToPush
        }
    }
    
    private func getVCForReportList() -> UIViewController {
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vcToPush = storyboard.instantiateViewController(withIdentifier: "ReportListController") as? ReportListViewController
        vcToPush?.currentDomainID = self.params.0
        vcToPush?.currentLat = self.params.1
        vcToPush?.currentLon = self.params.2
        return vcToPush!
    }
    
    private func getVCForNewMessage() -> UIViewController {
        if UserDefaults.standard.string(forKey: "token") == nil && MMSettings.shared.isLoginRequired {
            let alert = UIAlertController(title: nil, message: "Um eine Meldung erstellen zu können, müssen Sie sich anmelden.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            return alert
        } else {
            let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
            let vc = storyboard.instantiateViewController(withIdentifier: "ReportCreationTabViewController") as! ReportCreationTabViewController
            vc.screenMode = GlobalFlagValues.REPORT_SCREEN_NEW_MODE
            return vc
        }
    }
    
    private func getRowForLogin(cell: UITableViewCell) -> Row {
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.accessibilityTraits = .button
        
        if cell is ProfileTableViewCell {
            if !MMSettings.shared.showProfileAvatarInMenu {
                (cell as! ProfileTableViewCell).avatarView.isHidden = true
                (cell as! ProfileTableViewCell).withImageConstraint.isActive = false
                (cell as! ProfileTableViewCell).withoutImageConstraint.isActive = true
            } else {
                (cell as! ProfileTableViewCell).withImageConstraint.isActive = true
                (cell as! ProfileTableViewCell).withoutImageConstraint.isActive = false
                if let url = URL(string: UserDefaults.standard.string(forKey: "user.avatarUri") ?? "") {
                    URLSession.shared.dataTask(with: url) { (data, response, error) in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            (cell as! ProfileTableViewCell).avatarView.image = UIImage(data: data)
                        }
                    }.resume()
                }
            }
            (cell as! ProfileTableViewCell).titleLabel.text = UserDefaults.standard.string(forKey: "user.publicName") ?? ""
            (cell as! ProfileTableViewCell).titleLabel.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
            (cell as! ProfileTableViewCell).logOutButton.setTitle(LocalizedString("LOGOUT_BTN_TITLE", comment: ""), for: .normal)
            (cell as! ProfileTableViewCell).logOutButton.setTitleColor(MMColorScheme.shared.getColor(view: cell, type: .normalText), for: .normal)
            (cell as! ProfileTableViewCell).logOutButton.addTarget(self, action: #selector(logOut), for: .touchUpInside)
        } else {
            cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .buttonTitleText)
            cell.textLabel?.text = LocalizedString("LOGIN_BTN_TITLE", comment: "")
        }
        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vcToPush = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        
        return Row(cell: cell, vc: vcToPush)
    }
    
    private func getMyMessagesRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = LocalizedString("MY_MESSAGES_TITLE", comment: "")        
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        return Row(cell: cell, vc: getVCForMyMessageList())
    }
            
    private func getNewReportRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = "Neue Meldung"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        return Row(cell: cell, vc: getVCForNewMessage())
    }
    
    private func getReportListRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = "Alle Meldungen"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        return Row(cell: cell, vc: getVCForReportList())
    }
    
    private func getOfflineSettingsRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = "Offline-Daten verwalten"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vc = storyboard.instantiateViewController(withIdentifier: "OfflineSettingsViewController") as! OfflineSettingsViewController
        return Row(cell: cell, vc: vc)
    }
    
    private func getOfflineModeRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.tag = OFFLINE_CELL
        cell.textLabel?.text = "Offline-Modus \(InternetUtility.shared.getManualOfflineMode() ? "deaktivieren" : "aktivieren")"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        return Row(cell: cell, vc: nil)
    }
    
    private func getIdeaStartRow() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = "Start"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        return Row(cell: cell, vc: nil)
    }
    
    private func getRowForMultipleAboutUsPages(position: Int) -> Row {
        let cell = UITableViewCell()
        let title = LocalizedString(String.init(format: "%@_PAGE_TITEL", MMSettings.shared.menuInfoPages[position].rawValue), comment: "")
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.text = LocalizedString(String.init(format: "%@_PAGE_TITEL", MMSettings.shared.menuInfoPages[position].rawValue), comment: "")
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        cell.accessibilityTraits = .button
        
        // Show dialog with different options for "about us"
        let optionsAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        optionsAlert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        for i in 0..<MMSettings.shared.multipleAboutUsPages.count {
            let aboutUsInfo = MMSettings.shared.multipleAboutUsPages[i]
            optionsAlert.addAction(UIAlertAction(title: aboutUsInfo.title ?? title, style: .default, handler: { _ in
                let vc = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
                vc.overrideInfoPage = aboutUsInfo
                self.parentViewController?.navigationController?.pushViewController(vc, animated: true)
            }))
        }
        
        let row = Row(cell: cell, vc: optionsAlert)
        return row
    }
    
    private func getResetTutorialMenuItem() -> Row {
        let cell = UITableViewCell()
        cell.accessibilityTraits = .button
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = "Tutorials beim Start neu starten"
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        
        let alert = UIAlertController(title: "Tutorials beim Start neu starten", message: "Wollen Sie die Tutorials beim Start der App neu starten?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ja", style: .default, handler: { (_) in
            UserDefaults.standard.removeObject(forKey: "FirstTutorialFinished")
            UserDefaults.standard.removeObject(forKey: "SecondTutorialFinished")
            alert.dismiss(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Nein", style: .cancel, handler: nil))
        
        return Row(cell: cell, vc: alert)
    }
    
    private func getRowForInfoPages(position: Int) -> Row {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.textLabel?.text = LocalizedString(String.init(format: "%@_PAGE_TITEL", MMSettings.shared.menuInfoPages[position].rawValue), comment: "") 
        cell.textLabel?.textColor = MMColorScheme.shared.getColor(view: cell, type: .normalText)
        cell.accessibilityTraits = .button
        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vcToPush = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        vcToPush.pageName = MMSettings.shared.menuInfoPages[position]
        
        return Row(cell: cell, vc: vcToPush)
    }
    
    @objc func logOut() {
        MMApi.shared.logout { result, error in
            //It does not matter if the server recognized the logout, because a new login will create a new token regardless
            
            UserDefaults.standard.removeObject(forKey: "user.id")
            UserDefaults.standard.removeObject(forKey: "token")
            UserDefaults.standard.removeObject(forKey: "user.avatarUri")
            UserDefaults.standard.removeObject(forKey: "user.publicName")
            UserDefaults.standard.removeObject(forKey: "user.domainID")
            UserDefaults.standard.removeObject(forKey: "user.domainName")

            DispatchQueue.main.async {
                self.sections[0] = [self.getRowForLogin(cell: (self.tableView.dequeueReusableCell(withIdentifier: "login_cell"))!)]
                self.tableView.reloadSections([0], with: .automatic)
            }
        }
    }
}
