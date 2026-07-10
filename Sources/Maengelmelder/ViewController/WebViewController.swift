//
//  WebViewController.swift
//  MM
//
//  Created by Felix on 31.12.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!		
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var overrideInfoPage : InfoPage?
    var pageName : InfoPage.Kind?
    var navTitle: String?
    var url: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.navigationDelegate = self		
        self.webView.isOpaque = false
        
        let pageType = overrideInfoPage?.type ?? self.pageName
        
        if let pt = pageType {
            navigationItem.title = overrideInfoPage?.title ?? LocalizedString(pt.rawValue + "_PAGE_TITEL", comment: "")
            if let page = overrideInfoPage ?? GenericUtility.getInfoPage(for: pt) {
                if page.loadFromHTML {
                    var resourceName = page.bundleIdentifier ?? pt.rawValue.lowercased()
                    resourceName +=  ("_" + MMSettings.shared.APP_NAME.lowercased())
                    let file = Bundle.main.path(forResource: resourceName, ofType: "html") ?? ""
                    let textColor = self.view.isDarkMode() ? "#FFFFFF" : "#000000"
                    let content = try? String(contentsOfFile: file, encoding: .utf8).appending("<style>body{color: \(textColor)}</style>")
                    self.webView.loadHTMLString(content ?? "ERROR", baseURL: URL(fileURLWithPath: file))
                } else {
                    let url = URL(string: page.url ?? "")
                    let request = URLRequest(url: url!)
                    webView.load(request)
                }
            }
        } else if let url = URL(string: url ?? "") {
            title = navTitle ?? ""
            webView.load(URLRequest(url: url))
        }
        
        if MMSettings.shared.showAppIconOnWebViewNavigationBar {
            if let image = UIImage(named: "mm_app_icon")?.withRenderingMode(.alwaysOriginal) {
                self.navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(image: image, style: .done, target: self, action: nil)
                ]
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator.stopAnimating()
    }

}
