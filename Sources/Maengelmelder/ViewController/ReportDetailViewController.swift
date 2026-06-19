//
//  ReportDetailViewController.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import FSPagerView

public class ReportDetailViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var imagePagerContainer: UIView!
    @IBOutlet weak var imagePagerView: FSPagerView! {
        didSet {
            self.imagePagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
            self.imagePagerView.itemSize = FSPagerView.automaticSize
        }
    }
    
    public var reportId : NSNumber?
    public var domainId : NSNumber?
    public var system : System?
    
    fileprivate var viewModel : ReportDetailViewModel?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.viewModel = ReportDetailViewModel(reportId ?? 0, domainID: domainId ?? 32, system: system ?? System(appid: MMSettings.shared.APP_ID, host: MMApi.shared.SERVER_URL, name: "", external: false), pagerView: imagePagerView, pagerContainer: imagePagerContainer, compleation: { alert in
            alert!.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert!, animated: true, completion: nil)
        }) {
            let commentAllowed = self.viewModel?.isCommentAllowed() ?? false
            self.commentButton.isHidden = !commentAllowed
        }
        
        self.imagePagerView.dataSource = self.viewModel
        self.imagePagerView.delegate = self.viewModel
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.dataSource = self.viewModel
        self.collectionView.delegate = self.viewModel
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        self.collectionView.reloadData()
        
        self.commentButton.backgroundColor = MMColorScheme.shared.getColor(view: commentButton, type: .buttonBg)
        self.commentButton.setTitleColor(MMColorScheme.shared.getColor(view: commentButton, type: .buttonTitleText), for: .normal)
        self.commentButton.setTitle(LocalizedString("COMMENT_BUTTON_TITLE", comment: ""), for: .normal)
        self.commentButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(commentButtonAction)))
        
        self.subscribeButton.backgroundColor = MMColorScheme.shared.getColor(view: commentButton, type: .buttonBg)
        self.subscribeButton.setTitleColor(MMColorScheme.shared.getColor(view: commentButton, type: .buttonTitleText), for: .normal)
        
        if MMSettings.shared.subscribeReportTyp == .API {
            self.subscribeButton.setTitle(LocalizedString("SUBSCRIBE_BUTTON_TITLE", comment: ""), for: .normal)
            self.subscribeButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(subscribeButtonAction)))
        } else {
            self.subscribeButton.setTitle(MMSettings.shared.subscriptionButtonTitle, for: .normal)
            self.subscribeButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(subscribeViaMail)))
        }
        
        
        self.navigationItem.title = String.init(format: LocalizedString("MESSAGE_DETAIL_PAGE_TITLE", comment: ""), self.reportId?.intValue ?? 0)
    }
    
    @objc func subscribeViaMail() {
        if let url = URL(string: String(format: MMSettings.shared.subscriptionMail ?? "", reportId?.intValue ?? 0)),  UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func subscribeButtonAction() {
        let alert = UIAlertController(title: nil, message: "Bitte gib deine E-Mail-Adresse ein, mit der du die Meldung abonnieren möchtest. Du wirst dann über jegliche Änderungen an der Meldung per Mail informiert!", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "E-Mail"
            textField.keyboardType = .emailAddress
        }
        if MMSettings.shared.isLoginModuleActivated, let userMail = UserDefaults.standard.string(forKey: "user.email") {
            alert.textFields?.first?.text = userMail
        }
        alert.addAction(UIAlertAction(title: LocalizedString("SUBSCRIBE_BUTTON_TITLE", comment: ""), style: .default, handler: { (action) in
            let mail = alert.textFields?.first?.text ?? ""
            if mail.contains("@") && mail.contains(".") && !mail.contains(" ") {
                self.viewModel?.subscribe(mail, completion: { (success) in
                    let alert = UIAlertController(title: nil, message: success ? "Die Meldung wurde erfolgreich abonniert!" : "Die Meldung kann im Moment nicht abonniert werden!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                })
            } else {
                let alert = UIAlertController(title: nil, message: "Die eingegebene E-Mail-Adresse ist keine korrekte Adresse. Bitte versuchen Sie es erneut.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: LocalizedString("OK", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("CANCEL_BTN_TITLE", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func commentButtonAction() {
        self.performSegue(withIdentifier: "show_comment", sender: self)
    }
    
    @IBAction func closePager(_ sender: Any) {
        self.viewModel?.hideImage()
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_comment" {
            let vc = segue.destination as! CommentViewController
            vc.viewModel = self.viewModel?.getCommentViewModel()
        }
    }
}
