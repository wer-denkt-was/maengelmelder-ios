//
//  CommentViewModel.swift
//  MM
//
//  Created by Felix on 18.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit

class CommentViewModel: NSObject {
    
    private var reportDetails : ReportDetails?
    private var system : System?
    private var domainSettings : DomainSettings?
    private var type : ReportTypeMO?
    
    init(system: System, reportDetails: ReportDetails) {
        self.reportDetails = reportDetails
        self.system = system
        
        super.init()
        
        MMApi.shared.getDomainSettings(domainid: reportDetails.domainID, system: system) { settingsO, error in
            if let setting = settingsO {
                self.domainSettings = setting
            }
        }
        
        MMApi.shared.getCategoryDetails(id: reportDetails.typeid, system: system) { reportType, error in
            if let t = reportType {
                self.type = t
            }
        }
    }
    
    func setOldImage(to imageView: UIImageView) {
        if let url = URL(string: self.reportDetails?.pictureUrls.first ?? "") {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            }.resume()
        }
    }
    
    func canUpload(text: String) -> UIAlertController? {
        if let settings = self.domainSettings, settings.bmsTextLimit > -1, text.count > settings.bmsTextLimit {
            let alert = UIAlertController(title: nil, message: settings.bmsLimitWarning, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            return alert
        }
        return nil
    }
    
    func getSettings() -> DomainSettings? {
        return self.domainSettings
    }
    
    func getType() -> ReportTypeMO? {
        return self.type
    }
    
    func uploadUpdate(text: String, attributes: Array<ReportTypeAttributeMO>, solved: Bool, image: UIImage?, completion: @escaping (UploadReportResponse) -> Void) {
        MMApi.shared.updateReport(id: reportDetails?.messageid.intValue ?? 0, text: text, attributes: attributes, solved: solved, image: image, domainid: reportDetails?.domainID ?? 32, system: system) { result, error in
            if let response = result {
                completion(response)
            } else {
                completion(UploadReportResponse(success: false, message: LocalizedString("UPLOAD_FAILED", comment: ""), messageid: self.reportDetails?.messageid.intValue ?? 0))
            }
        }
    }
}
