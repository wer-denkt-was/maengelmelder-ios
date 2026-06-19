//
//  UploadUtility.swift
//  MM
//
//  Created by Felix on 30.11.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import JGProgressHUD

public class UploadUtility: NSObject {
    
    private var hud : JGProgressHUD
    
    private var totalBytes : Int64 = 0
    private var sendBytes : Int64 = 0
    private var domainSettings: DomainSettings?
    
    public override init() {
        hud = JGProgressHUD(style: .dark)
        super.init()
    }
    
    private func uploadReportWithDomainSettings(report : ReportMO, system: System, viewForHud: UIView, compleation: @escaping (Bool) -> Void) {
        hud = JGProgressHUD(style: viewForHud.isDarkMode() ? .light : .dark)
        hud.vibrancyEnabled = true
        hud.textLabel.text = LocalizedString("IS_UPLOADING_BTN_TITLE", comment: "")
        self.hud.detailTextLabel.text = String.init(format: "%@ %.0f%%", LocalizedString("IS_UPLOADING_BTN_TITLE", comment: ""), 1)
        hud.indicatorView = JGProgressHUDPieIndicatorView()
        hud.show(in: viewForHud)
        
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for image in report.attachments {
            if let fileSize = try? FileManager.default.attributesOfItem(atPath: baseURL.appendingPathComponent(image as? String ?? "error").path)[.size] as? NSNumber {
                self.totalBytes += fileSize.int64Value
            }
        }
    
        if (InternetUtility.shared.isOnline()) {
            let uploadable = report
            
            if(report.reportType?.id == nil || report.reportType?.id == -1){
                UIView.animate(withDuration: 0.1) {
                    self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                    self.hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
                    self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    self.hud.dismiss(afterDelay: 5, animated: true)
                }
                compleation(false)
                return
            }
            if(domainSettings == nil || domainSettings?.attributesAsDefaultFields == 0) {
                if (report.reportType?.has_title ?? 0) == 1 && (report.title == nil || report.title!.filter({ !$0.isWhitespace }).isEmpty)  {
                    UIView.animate(withDuration: 0.1) {
                        self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        self.hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        self.hud.dismiss(afterDelay: 5, animated: true)
                    }
                    compleation(false)
                }
                
                if(report.text == nil || report.text!.filter({ !$0.isWhitespace }).isEmpty) {
                    UIView.animate(withDuration: 0.1) {
                        self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        self.hud.detailTextLabel.text = LocalizedString("MESSAGE_INCOMPLETE", comment: "")
                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        self.hud.dismiss(afterDelay: 5, animated: true)
                    }
                    compleation(false)
                    return
                }
            }
            
            for attribute in report.reportType!.getAttributesFor(update: false) {
                if attribute.required == 1 {
                    if attribute.type == AttributeTypes.checkbox {
                        if attribute.answer != "true" {
                            UIView.animate(withDuration: 0.1) {
                                self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                                self.hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                self.hud.dismiss(afterDelay: 5, animated: true)
                            }
                            compleation(false)
                            return
                        }
                    } else {
                        if attribute.answer == nil || attribute.answer!.filter({ !$0.isWhitespace }).isEmpty {
                            UIView.animate(withDuration: 0.1) {
                                self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                                self.hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                self.hud.dismiss(afterDelay: 5, animated: true)
                            }
                            compleation(false)
                            return
                        }
                        
                        if attribute.regex != nil && !attribute.regex!.isEmpty {
                            if attribute.answer!.range(of: attribute.regex!, options: .regularExpression) == nil {
                                UIView.animate(withDuration: 0.1) {
                                    self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                                    self.hud.detailTextLabel.text = attribute.error
                                    self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                    self.hud.dismiss(afterDelay: 5, animated: true)
                                }
                                compleation(false)
                                return
                            }
                        }
                        
                    }
                }
            }
            
            if report.reportType?.req_photo == "required" && report.attachments.count == 0 {
                UIView.animate(withDuration: 0.1) {
                    self.hud.textLabel.text = LocalizedString("UPLOAD_MISSING_FOTO", comment: "")
                    self.hud.detailTextLabel.text = ""
                    self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    self.hud.dismiss(afterDelay: 5, animated: true)
                }
                compleation(false)
                return
            }
            
            UIApplication.shared.isIdleTimerDisabled = true
            if report.attachments.count == 0 {
                MMApi.shared.uploadReport(uploadable, bundle: nil, isCurrentUserResponsible: self.domainSettings?.isCurrentUserResponsible ?? false, system: system, updateProgress: { progress in
                    DispatchQueue.main.async {
                        self.hud.progress = Float(progress)
                        self.hud.detailTextLabel.text = String.init(format: "%@ %.0f%%", LocalizedString("IS_UPLOADING_BTN_TITLE", comment: ""), (progress*100))
                    }
                }) { result, error in
                    guard let response = result else {
                        UIView.animate(withDuration: 0.1) {
                            self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                            self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                            self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            self.hud.dismiss(afterDelay: 5, animated: true)
                        }
                        compleation(false)
                        UIApplication.shared.isIdleTimerDisabled = false
                        return
                    }
                    
                    if response.success {
                        uploadable.id = NSNumber(value: response.messageid)
                        uploadable.state = GlobalFlagValues.REPORT_UPLOADED_STATE
                        
                        
                        let imagesPaths = report.attachments.array as! [String]
                        
                        for path in imagesPaths {
                            try? FileManager.default.removeItem(atPath: path)
                        }
                        
                        report.attachments.removeAllObjects()
                        MMCoreDataManager.saveContext(entityName: "Report", moc: MMCoreDataManager.shared.context)
                        
                        UIView.animate(withDuration: 0.1) {
                            self.hud.textLabel.text = LocalizedString("IS_UPLOAD_SUCCESS", comment: "")
                            self.hud.detailTextLabel.text = LocalizedString("UPLOAD_SUCCESSFUL", comment: "")
                            self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                            self.hud.dismiss(afterDelay: 3, animated: true)
                        }
                        
                        compleation(true)
                        UIApplication.shared.isIdleTimerDisabled = false
                    } else {
                        UIView.animate(withDuration: 0.1) {
                            self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                            self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                            self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            self.hud.dismiss(afterDelay: 5, animated: true)
                        }
                        compleation(false)
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
                }
            } else {
                MMApi.shared.createBundle(domainid: uploadable.reportType?.domainID?.intValue ?? 32, system: system) { bundle, error in
                    guard let response = bundle else {
                        UIView.animate(withDuration: 0.1) {
                            self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                            self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                            self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            self.hud.dismiss(afterDelay: 5, animated: true)
                        }
                        compleation(false)
                        UIApplication.shared.isIdleTimerDisabled = false
                        return
                    }
                    
                    self.uploadAdditionalPictures(report: report, bundle: response, system: system, pictureIndex: 0, compleation: { (success, bundle) in
                        if success {
                            MMApi.shared.uploadReport(uploadable, bundle: bundle, isCurrentUserResponsible: self.domainSettings?.isCurrentUserResponsible ?? false, system: system, updateProgress: { progress in
                                DispatchQueue.main.async {
                                    self.hud.progress = Float(progress)
                                    self.hud.detailTextLabel.text = String.init(format: "%@ %.0f%%", LocalizedString("IS_UPLOADING_BTN_TITLE", comment: ""), (progress*100))
                                }
                            }) { result, error in
                                guard let response = result else {
                                    UIView.animate(withDuration: 0.1) {
                                        self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                                        self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                        self.hud.dismiss(afterDelay: 5, animated: true)
                                    }
                                    compleation(false)
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    return
                                }
                                
                                if response.success {
                                    
                                    uploadable.id = NSNumber(value: response.messageid)
                                    uploadable.state = GlobalFlagValues.REPORT_UPLOADED_STATE
                                    
                                    let imagesPaths = report.attachments.array as! [String]
                                    
                                    for path in imagesPaths {
                                        try? FileManager.default.removeItem(atPath: path)
                                    }
                                    
                                    report.attachments.removeAllObjects()
                                    MMCoreDataManager.saveContext(entityName: "Report", moc: MMCoreDataManager.shared.context)
                                    
                                    UIView.animate(withDuration: 0.1) {
                                        self.hud.textLabel.text = LocalizedString("IS_UPLOAD_SUCCESS", comment: "")
                                        self.hud.detailTextLabel.text = LocalizedString("UPLOAD_SUCCESSFUL", comment: "")
                                        self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                                        self.hud.dismiss(afterDelay: 3, animated: true)
                                    }
                                    
                                    compleation(true)
                                    UIApplication.shared.isIdleTimerDisabled = false
                                } else {
                                    UIView.animate(withDuration: 0.1) {
                                        self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                                        self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                                        self.hud.dismiss(afterDelay: 5, animated: true)
                                    }
                                    compleation(false)
                                    UIApplication.shared.isIdleTimerDisabled = false
                                    return
                                }
                            }
                        }
                    })
                }
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                self.hud.detailTextLabel.text = LocalizedString("UPLOAD_FAILED", comment: "")
                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                self.hud.dismiss(afterDelay: 5, animated: true)
            }
            compleation(false)
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    fileprivate func uploadAdditionalPictures(report: ReportMO, bundle: PictureBundle, system: System, pictureIndex: Int, compleation: @escaping (Bool, PictureBundle) -> Void) {
        
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        if (InternetUtility.shared.isOnline()) {
            
            let uploadable = UIImage(contentsOfFile: baseURL.appendingPathComponent(report.attachments[pictureIndex] as? String ?? "error").path)
            
            MMApi.shared.uploadFileToBundle(domainid: report.reportType?.domainID?.intValue ?? 32, token: bundle.token, image: uploadable ?? UIImage(), system: system) { bundleO, error in
                guard let response = bundleO else {
                    UIView.animate(withDuration: 0.1) {
                        self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        self.hud.detailTextLabel.text = LocalizedString("GENERIC_UPLOAD_FALURE", comment: "")
                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        self.hud.dismiss(afterDelay: 5, animated: true)
                    }
                    compleation(false, bundle)
                    UIApplication.shared.isIdleTimerDisabled = false
                    return
                }
                
                if report.attachments.count > pictureIndex+1 {
                    if let fileSize = try? FileManager.default.attributesOfItem(atPath: baseURL.appendingPathComponent(report.attachments[0] as? String ?? "error").path)[.size] as? NSNumber {
                        self.sendBytes += fileSize.int64Value
                    }
                    self.uploadAdditionalPictures(report: report, bundle: response, system: system, pictureIndex: pictureIndex+1, compleation: compleation)
                } else {
                    compleation(true, response)
                }
                
                var progress = Float(self.sendBytes)/Float(self.totalBytes)
                if progress > 1 {
                    progress = 0.99
                }
                
                DispatchQueue.main.async {
                    self.hud.progress = progress
                    self.hud.detailTextLabel.text = String.init(format: "%@ %.0f%%", LocalizedString("IS_UPLOADING_BTN_TITLE", comment: ""), (progress*100))
                }
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                self.hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                self.hud.detailTextLabel.text = LocalizedString("UPLOAD_FAILED", comment: "")
                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                self.hud.dismiss(afterDelay: 5, animated: true)
            }
            compleation(false, bundle)
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    public func uploadReport(report : ReportMO, system: System, viewForHud: UIView, compleation: @escaping (Bool) -> Void) {
        if(domainSettings == nil) {
            if let idToFind = report.domainid?.intValue {
                loadSettingsForDomainAndCallUpload(with: idToFind, and: system,report: report, viewForHud: viewForHud, compleation: compleation)
            } else {
                uploadReportWithDomainSettings(report: report, system: system, viewForHud: viewForHud, compleation: compleation)
            }
        } else {
            uploadReportWithDomainSettings(report: report, system: system, viewForHud: viewForHud, compleation: compleation)
        }
    }
    
    private func loadSettingsForDomainAndCallUpload(with id: Int, and system:System,report : ReportMO, viewForHud: UIView, compleation: @escaping (Bool) -> Void) {
        MMApi.shared.getDomainSettings(domainid: id, system: system) { settingsO, error in
            if let settings = settingsO {
                self.domainSettings = settings
            }
            self.uploadReportWithDomainSettings(report: report, system: system, viewForHud: viewForHud, compleation: compleation)
        }
    }
}
