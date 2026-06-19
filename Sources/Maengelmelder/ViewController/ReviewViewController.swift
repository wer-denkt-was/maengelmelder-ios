//
//  ReviewViewController.swift
//  MM
//
//  Created by Felix on 08.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import JGProgressHUD

class ReviewViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var sebdLaterButton: UIButton!
    @IBOutlet weak var sendNowButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    
    fileprivate var viewModel : ReviewViewModel?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = LocalizedString("HEADING_STEP_5", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = LocalizedString("HEADING_STEP_5", comment: "")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.viewModel = ReviewViewModel(parentController: self.parent as! ReportCreationTabViewController)
        self.collectionView.dataSource = viewModel
        self.collectionView.delegate = viewModel
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        super.viewWillAppear(animated)
        self.collectionView.reloadData()
        
        self.parent?.navigationItem.title = LocalizedString("HEADING_STEP_5", comment: "")
        
        self.sendNowButton.backgroundColor = MMColorScheme.shared.getColor(view: sendNowButton, type: .buttonBg)
        self.sendNowButton.setTitleColor(MMColorScheme.shared.getColor(view: sendNowButton, type: .buttonTitleText), for: .normal)
        
        self.sebdLaterButton.backgroundColor = MMColorScheme.shared.getColor(view: sebdLaterButton, type: .buttonBg)
        self.sebdLaterButton.setTitleColor(MMColorScheme.shared.getColor(view: sebdLaterButton, type: .buttonTitleText), for: .normal)
        
        if self.parent?.navigationItem.rightBarButtonItems?.count ?? 0 > 0 {
            self.parent?.navigationItem.rightBarButtonItems?.remove(at: 0)
        }
        
        if((self.parent as? ReportCreationTabViewController)?.isReportPositionUpdated ?? false && (self.parent as? ReportCreationTabViewController)?.report?.reportType != nil){
            self.viewModel?.fetchSystems()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let parentTVC = parent as! ReportCreationTabViewController
        if(parentTVC.navigationItem.rightBarButtonItem == nil){
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "next", in: MM.shared.bundle, compatibleWith: nil), for: .normal)
            button.setTitle(LocalizedString("CONTINUE", comment: ""), for: .normal)
            button.addTarget(parentTVC, action: #selector(parentTVC.goToNextTab), for: .touchUpInside)
            button.transform = CGAffineTransform(scaleX: -1, y: 1)
            button.titleLabel?.transform = CGAffineTransform(scaleX: -1, y: 1)
            button.imageView?.transform = CGAffineTransform(scaleX: -1, y: -1)
            button.setTitleColor(MMColorScheme.shared.getColor(view: button, type: .titleText), for: .normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
            parentTVC.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }
    }
    
    @IBAction func sendLater(_ sender: Any) {
        (self.parent as? ReportCreationTabViewController)?.saveAndClose(uploaded: false)
    }
    
    @IBAction func sendNow(_ sender: Any) {
        guard InternetUtility.shared.isOnline() else {
            let alert = UIAlertController(title: nil, message: LocalizedString("NO_INTERNET", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default))
            self.present(alert, animated: true)
            return
        }
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Upload wird vorbereitet..."
        hud.show(in: self.view)
        
        guard checkRequiredFields(report: (self.parent as! ReportCreationTabViewController).report!, hud: hud) else {
            (self.parent as! ReportCreationTabViewController).showErrorsInAttributes = true
            return
        }
        
        (parent as? ReportCreationTabViewController)?.checkCategoryAtPosition(callback: { success in
            hud.dismiss(animated: true)
            if !success {
                var alertMsg = MMSettings.shared.messageInvalidPositionText;
                if alertMsg.isEmpty {
                    alertMsg = LocalizedString(MMSettings.shared.showTypesFirst ? "TYPE_FIRST_CATEGORY_NOT_AVAILABLE" : "CATEGORY_NOT_AVAILABLE", comment: "")
                }
                let alert = UIAlertController(title: nil, message: alertMsg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: { _ in
                    (self.parent as? ReportCreationTabViewController)?.goToTab(2)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.sendDataNow()
            }
        })
    }
    
    private func sendDataNow() {
        let parent = self.parent as! ReportCreationTabViewController
        
        var totalBytes:Int64 = 0
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for image in parent.report?.attachments ?? [] {
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: baseURL.appendingPathComponent(image as? String ?? "error").path)[.size] as? NSNumber {
                totalBytes += fileSize.int64Value
            }
        }
        
        let reportSize = String.init(format: "%d MB", totalBytes/1000000)
        let size = String.init(format: "Ihre Meldung ist %@ groß. Das Hochladen kann je nach Verbindung einige Zeit dauern. Insbesondere mehrere Fotos führen zu einem großen Datenvolumen.", reportSize)
        let domainName = parent.report?.domainName ?? "Mängelmelder.de"
        let message:String
        if MMSettings.shared.onlyShowDefaultDomain {
            message = size
        } else {
            message = String.init(format: "Die Meldung ist bereit zum Hochladen an %@. Sollte dies nicht korrekt sein, prüfen Sie bitte, ob die Position der Meldung korrekt übernommen wurde.%@", domainName, totalBytes > 0 ? ("\n\n"+size) : "")
        }
        
        let boldAttr = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 17)]
        let notBoldAttr = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]
        
        let attrStr = NSMutableAttributedString(string: message, attributes: notBoldAttr)
        let range = NSString(string: message).range(of: domainName)
        attrStr.setAttributes(boldAttr, range: range)
        
        let range2 = NSString(string: message).range(of: reportSize)
        attrStr.setAttributes(boldAttr, range: range2)
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alert.setValue(attrStr, forKey: "attributedMessage")
        alert.addAction(UIAlertAction(title: LocalizedString("UPLOAD_BTN_TITLE", comment: ""), style: .default, handler: { (action) in
            parent.uploadReport(sender: self)
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func checkRequiredFields(report: ReportMO, hud: JGProgressHUD) -> Bool {
        if(report.reportType?.id == nil || report.reportType?.id == -1){
            hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
            hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.dismiss(afterDelay: 5, animated: true)
            return false
        }

        if (report.reportType?.has_title ?? 0) == 1 && (report.title == nil || report.title!.filter({ !$0.isWhitespace }).isEmpty)  {
            hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
            hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.dismiss(afterDelay: 5, animated: true)
            return false
        }
        
        if(report.text == nil || report.text!.filter({ !$0.isWhitespace }).isEmpty) {
            hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
            hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.dismiss(afterDelay: 5, animated: true)
            return false
        }
        
        for attribute in report.reportType!.getAttributesFor(update: false) {
            if attribute.required == 1 {
                if attribute.type == AttributeTypes.checkbox {
                    if attribute.answer != "true" {
                        hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.dismiss(afterDelay: 5, animated: true)
                        return false
                    }
                } else {
                    if attribute.answer == nil || attribute.answer!.filter({ !$0.isWhitespace }).isEmpty {
                        hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.dismiss(afterDelay: 5, animated: true)
                        return false
                    }
                    
                    if attribute.regex != nil && !attribute.regex!.isEmpty {
                        if attribute.answer!.range(of: attribute.regex!, options: .regularExpression) == nil {
                            hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                            hud.detailTextLabel.text = attribute.error
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.dismiss(afterDelay: 5, animated: true)
                            return false
                        }
                    }
                    
                }
            }
        }
        
        if report.reportType?.req_photo == "required" && report.attachments.count == 0 {
            hud.textLabel.text = LocalizedString("UPLOAD_MISSING_FOTO", comment: "")
            hud.detailTextLabel.text = ""
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.dismiss(afterDelay: 5, animated: true)            
            return false
        }
        
        return true
    }
    
}
