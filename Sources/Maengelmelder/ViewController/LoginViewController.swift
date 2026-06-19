//
//  LoginViewController.swift
//  Maengelmelder
//
//  Created by Felix on 05.04.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreLocation
import JGProgressHUD

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginContainerView: UIView!
    @IBOutlet weak var domainButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var forgotPassword: UIButton!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    @IBOutlet weak var profileContainerView: UIView!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameTitleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!    
    @IBOutlet weak var deleteAccountButton: UIButton!
    
    private var isLoggedIn : Bool {
        return UserDefaults.standard.string(forKey: "token") != nil
    }
    
    private var domains = Array<(Int, String, String, System?)>()
    var selectedDomain : (Int, String, String, System?)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.deleteAccountButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        self.deleteAccountButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
        self.deleteAccountButton.setTitle("Konto löschen", for: .normal)
        
        // Do any additional setup after loading the view.
        if isLoggedIn && (selectedDomain == nil || selectedDomain!.0 == UserDefaults.standard.integer(forKey: "user.domainID")) {
            self.navigationItem.title = LocalizedString("PROFILE_TITLE", comment: "")
            self.loginContainerView.isHidden = true
            self.profileContainerView.isHidden = false
            
            if let url = URL(string: UserDefaults.standard.string(forKey: "user.avatarUri") ?? "") {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async {
                        self.avatarView.image = UIImage(data: data)
                    }
                    }.resume()
            }
            
            self.nameTitleLabel.text = " " + LocalizedString("NAME_TITLE", comment: "")
            self.emailTitleLabel.text = " " + LocalizedString("EMAIL_TITLE", comment: "")
            self.nameLabel.text = "  " + (UserDefaults.standard.string(forKey: "user.publicName") ?? "")
            self.emailLabel.text = "  " + (UserDefaults.standard.string(forKey: "loginmail") ?? "")
            
            self.logoutButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
            self.logoutButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
            self.logoutButton.setTitle(LocalizedString("LOGOUT_BTN_TITLE", comment: ""), for: .normal)
        } else {
            self.navigationItem.title = LocalizedString("LOGIN_BTN_TITLE", comment: "")
            
            self.loginContainerView.isHidden = false
            self.profileContainerView.isHidden = true
            
            self.logInButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
            self.logInButton.setTitle(LocalizedString("LOGIN_BTN_TITLE", comment: ""), for: .normal)
            self.logInButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
            
            self.forgotPassword.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
            self.forgotPassword.setTitle(LocalizedString("LOGIN_REGISTER", comment: ""), for: .normal)
            self.forgotPassword.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
            
            self.mailLabel.text = LocalizedString("LOGIN_MAIL", comment: "")
            self.mailTextField.placeholder = LocalizedString("LOGIN_MAIL", comment: "")
            self.mailTextField.delegate = self
            
            if let mail = UserDefaults.standard.string(forKey: "loginmail") {
                self.mailTextField.text = mail
            }
            
            self.passwordLabel.text = LocalizedString("LOGIN_PASS", comment: "")
            self.passwordTextField.placeholder = LocalizedString("LOGIN_PASS", comment: "")
            self.passwordTextField.delegate = self
            
            if isLoggedIn && self.selectedDomain != nil {
                self.warningLabel.isHidden = false
                self.warningLabel.text = String.init(format: "Sie sind aktuell an %@ angemeldet. Mit der neuen Anmeldung auf %@ werden Sie automatisch vom bisherigen System abgemeldet.", UserDefaults.standard.string(forKey: "user.domainName") ?? "", self.selectedDomain!.1)
            } else {
                self.warningLabel.isHidden = true
            }
            
            if MMSettings.shared.onlyShowDefaultDomain || self.selectedDomain != nil {
                self.domainButton.isHidden = true
                self.selectedDomain = (MMSettings.shared.DEFAULT_DOMAIN_ID, MMSettings.shared.APP_NAME, MMSettings.shared.REGISTRATION_PAGE_URL, nil)
                self.domainButton.setTitle(MMSettings.shared.APP_NAME, for: .normal)
            } else {
                self.fetchSystems()
            }
        }
    }
    
    func fetchSystems() {
        let locationManager = CLLocationManager()

        guard locationManager.location != nil else {
            self.selectedDomain = (MMSettings.shared.DEFAULT_DOMAIN_ID, MMSettings.shared.APP_NAME, MMSettings.shared.REGISTRATION_PAGE_URL, nil)
            self.domainButton.setTitle(MMSettings.shared.APP_NAME, for: .normal)
            self.domainButton.isHidden = true
            if !MMSettings.shared.noPositionHintText.isEmpty {
                self.warningLabel.isHidden = false
                self.warningLabel.text = MMSettings.shared.noPositionHintText
            }
            return
        }

        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Prüfe Standortdaten..."
        hud.show(in: self.view)

        let lat = locationManager.location!.coordinate.latitude
        let lon = locationManager.location!.coordinate.longitude

        MMApi.shared.getSystems(lat: lat, lon: lon) { systems, error in
            self.fetchDomains(lat: lat, lon: lon, systems: systems ?? []) {
                hud.dismiss()
                self.selectedDomain = self.domains.first ?? (MMSettings.shared.DEFAULT_DOMAIN_ID, MMSettings.shared.APP_NAME, MMSettings.shared.REGISTRATION_PAGE_URL, nil)
                self.domainButton.setTitle("  " + (self.domains.first?.1 ?? MMSettings.shared.APP_NAME) + "  ", for: .normal)
                self.domainButton.menu = UIMenu(title: "", options: [], children: self.domains.map({ (domain) -> UIMenuElement in
                    return UIAction(title: domain.1) { _ in
                        self.domainButton.setTitle("  " + domain.1 + "  ", for: .normal)
                        self.selectedDomain = domain
                    }
                }))
            }
        }
    }
    
    private func fetchDomains(lat: Double, lon: Double, systems: [System], compleation: @escaping () -> Void) {
        self.domains.removeAll()
        let hasExternal = systems.contains(where: { (system) -> Bool in
            return system.external
        })
        let numberOfCalls = hasExternal ? systems.count-1 : systems.count
        var finishedCalls = 0
        for sys in systems {
            if sys.external || !hasExternal {
                MMApi.shared.getDomain(lat: lat, lon: lon, system: sys, appid: MMSettings.shared.APP_ID == 1 ? nil : MMSettings.shared.APP_ID) { domainO, error in
                    MMCoreDataManager.saveContext(entityName: CoreDataEntityNames.REPORT_TYPE, moc: MMCoreDataManager.shared.context)
                    if let domain = domainO {
                        self.domains.append((domain.getID(), domain.getName(), domain.getRegisterURL(), sys))
                        
                        finishedCalls=finishedCalls+1
                        if(finishedCalls == numberOfCalls) {
                            compleation()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func logInButtonPressed(_ sender: Any) {
        guard let selectedDomain = self.selectedDomain else { return }
        
        if let mail = mailTextField.text, let password = passwordTextField.text {
            
            let userDefaults = UserDefaults.standard
            userDefaults.set(mail, forKey: "loginmail")
            
            if (InternetUtility.shared.isOnline()) {
                MMApi.shared.login(email: mail, password: password, domainid: selectedDomain.0, system: selectedDomain.3) { responseO, error in
                    if let response = responseO, response.success {
                        let defaults = UserDefaults.standard
                        defaults.set(response.id, forKey: "user.id")
                        defaults.set(response.token, forKey: "token")
                        defaults.set(response.avatarUri, forKey: "user.avatarUri")
                        defaults.set(response.publicName, forKey: "user.publicName")
                        defaults.set(response.firstname, forKey: "user.firstname")
                        defaults.set(response.lastname, forKey: "user.lastname")
                        defaults.set(response.email, forKey: "user.email")
                        defaults.set(response.type, forKey: "user.type")
                        defaults.set(selectedDomain.0, forKey: "user.domainID")
                        defaults.set(selectedDomain.1, forKey: "user.domainName")
                        if selectedDomain.3 != nil {
                            do {
                                defaults.set(try JSONEncoder().encode(selectedDomain.3), forKey: "user.system")
                            } catch {
                                // System object cannot be encoded but it should not happen anyway
                            }
                        }
                        
                        if let nvc = self.navigationController {
                            let alertController = UIAlertController(title: nil, message: String.init(format: LocalizedString("LOGIN_SUCCESS_MSG", comment: ""), response.publicName), preferredStyle: .alert)
                            let successAction = UIAlertAction(title: LocalizedString("OK", comment: ""), style: UIAlertAction.Style.default) { _ in
                                nvc.popViewController(animated: true)
                            }
                            
                            alertController.addAction(successAction)
                            self.present(alertController, animated: true, completion: nil)
                            
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        let alert = UIAlertController(title: nil, message: LocalizedString("LOGIN_FAILED_MSG", comment: ""), preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                let alert = UIAlertController(title: nil, message: LocalizedString("NO_INTERNET", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func deleteAccountPressed(_ sender: Any) {
        let inputAlert = UIAlertController(title: nil, message: "Sind Sie sich sicher, dass Sie Ihr Benutzerkonto wirklich löschen möchten? Bitte beachten Sie, dass eine Löschung bis zu 72h Zeit in Anspruch nehmen kann.", preferredStyle: .alert)
        inputAlert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel, handler: nil))
        inputAlert.addAction(UIAlertAction(title: "Ja, Nutzer löschen", style: .destructive, handler: { _ in
            
            MMApi.shared.deleteAccount(userid: UserDefaults.standard.integer(forKey: "user.id"), domainid: UserDefaults.standard.integer(forKey: "user.domainID"), system: nil) { response, error in
                // Logout when request is sent
                if response != nil && response!.success {
                    self.logoutButtonPressed(sender)
                } else {
                    let errorAlert = UIAlertController(title: nil, message: "Leider ist ein Fehler aufgetreten. Bitte probieren Sie es erneut und überprüfen Sie ihre Internetverbindung. Sollte der Fehler weiterhin bestehen, kontaktieren Sie uns bitte per Email.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.present(errorAlert, animated: true, completion: nil)
                    
                }
            }
        }))
        self.present(inputAlert, animated: true, completion: nil)        
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        guard let selectedDomain = self.selectedDomain else { return }
        
        let storyboard = UIStoryboard(name: "MMMain", bundle: MM.shared.bundle)
        let vcToPush = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        vcToPush.navTitle = LocalizedString("LOGIN_REGISTER", comment: "")
        vcToPush.url = selectedDomain.2
        self.navigationController?.pushViewController(vcToPush, animated: true)
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        MMApi.shared.logout { result, error in
            //It does not matter if the server recognized the logout, because a new login will create a new token regardless
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "user.id")
            defaults.removeObject(forKey: "token")
            defaults.removeObject(forKey: "user.avatarUri")
            defaults.removeObject(forKey: "user.publicName")
            defaults.removeObject(forKey: "user.domainID")
            defaults.removeObject(forKey: "user.domainName")
            
            self.viewDidLoad()
        }
    }
}

extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.mailTextField {
            self.passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            self.passwordTextField.resignFirstResponder()
            self.logInButtonPressed(self)
        }
        return false
    }
    
}

