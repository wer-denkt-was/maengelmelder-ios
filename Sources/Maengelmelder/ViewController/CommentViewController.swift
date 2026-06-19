//
//  CommentViewController.swift
//  MM
//
//  Created by Felix on 18.02.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import JGProgressHUD

class CommentViewController: UIViewController {

    @IBOutlet weak var oldImageLabel: UILabel!
    @IBOutlet weak var newImageLabel: UILabel!
    @IBOutlet weak var oldImageView: UIImageView!
    @IBOutlet weak var newImageView: UIImageView!
    @IBOutlet weak var reportFinishedSwitch: UISwitch!
    @IBOutlet weak var reportFinishedLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentTextField: UITextView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var attributesStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pickerContainerView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var constraintToSuperviewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintToFotoviewTop: NSLayoutConstraint!
    
    var viewModel : CommentViewModel?
    
    private var image : UIImage?
    private var attributeTextViews = Array<UITextField>()
    private var dropDownViews = Array<UILabel>()
    
    private var lastKeyboardHeight : CGFloat = 0
    private var selectedAttribute : ReportTypeAttributeMO?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = LocalizedString("COMMENT_TITLE", comment: "00")
        
        commentLabel.text = LocalizedString("COMMENT_PLACEHOLDER", comment: "")
        commentLabel.font = MMFontScheme.shared.subTitleTextFont?.withSize(UIFont.preferredFont(forTextStyle: .callout).pointSize)
        oldImageLabel.text = LocalizedString("OLD_IMAGE_LABEL", comment: "")
        newImageLabel.text = LocalizedString("NEW_IMAGE_LABEL", comment: "")
        reportFinishedLabel.text = LocalizedString("SWITCH_TEXT", comment: "")
        sendButton.setTitle(LocalizedString("SEND_COMMENT_BUTTON", comment: ""), for: .normal)
        commentTextField.text = LocalizedString("COMMENT_PLACEHOLDER", comment: "")
        commentTextField.textColor = .lightGray
        
        sendButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
        sendButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        sendButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(uploadCommentAndImage)))
        
        viewModel?.setOldImage(to: oldImageView)
        
        commentTextField.delegate = self
        
        reportFinishedLabel.isHidden = !MMSettings.shared.isFinishOnCommentActivated
        reportFinishedSwitch.isHidden = !MMSettings.shared.isFinishOnCommentActivated
        oldImageView.isHidden = !MMSettings.shared.isPictureOnCommentActivated
        oldImageLabel.isHidden = !MMSettings.shared.isPictureOnCommentActivated
        newImageView.isHidden = !MMSettings.shared.isPictureOnCommentActivated
        newImageLabel.isHidden = !MMSettings.shared.isPictureOnCommentActivated
        constraintToFotoviewTop.isActive = MMSettings.shared.isPictureOnCommentActivated
        constraintToSuperviewTop.isActive = !MMSettings.shared.isPictureOnCommentActivated
        
        if !MMSettings.shared.isFinishOnCommentActivated && !MMSettings.shared.isPictureOnCommentActivated {
            commentTextField.becomeFirstResponder()
        }
        
        newImageView.isUserInteractionEnabled = true
        newImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addImageAction)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(not:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(not:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        checkForAttributes()
    }
    
    @objc func keyboardWillShow(not: Notification) {
        if let keyboardFrame = not.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue, self.scrollView.adjustedContentInset.bottom < 100 {
            lastKeyboardHeight = keyboardFrame.cgRectValue.height
            let customInsets = UIEdgeInsets(top: 0, left: self.scrollView.adjustedContentInset.left, bottom: self.scrollView.adjustedContentInset.bottom + lastKeyboardHeight, right: self.scrollView.adjustedContentInset.right)
            self.scrollView.contentInset = customInsets
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
    }
    
    @objc func keyboardWillHide(not: Notification) {
        self.navigationItem.rightBarButtonItem = nil
        let customInsets = UIEdgeInsets(top: self.scrollView.adjustedContentInset.top, left: self.scrollView.adjustedContentInset.left, bottom: self.scrollView.adjustedContentInset.bottom - lastKeyboardHeight, right: self.scrollView.adjustedContentInset.right)
        self.scrollView.contentInset = customInsets
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        self.pickerContainerView.isHidden = true
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func savePickerAction(_ sender: Any) {
        self.pickerContainerView.isHidden = true
        self.selectedAttribute?.answer = self.dropdownValues[self.pickerView.selectedRow(inComponent: 0)]
        for label in self.dropDownViews {
            if label.tag == self.selectedAttribute?.id?.intValue {
                label.text = String(self.selectedAttribute?.answer?.split(separator: "^")[1] ?? "")
            }
        }
        self.selectedAttribute = nil
    }
    
    @objc func addImageAction() {
        let alert = UIAlertController(title: nil, message: LocalizedString("CHOOSE_SOURCE_IMAGE", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: LocalizedString("CAMERA_BTN_TITLE", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .camera
                pickerController.allowsEditing = false
                pickerController.modalPresentationStyle = .overCurrentContext
                self.present(pickerController, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: LocalizedString("LIBRARY_BTN_TITLE", comment: ""), style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .photoLibrary
                pickerController.modalPresentationStyle = .overCurrentContext
                pickerController.allowsEditing = false
                self.present(pickerController, animated: true, completion: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func checkForAttributes() {
        guard self.attributesStackView.bounds.height < 10 else {
            return
        }
        
        if self.viewModel?.getType() != nil {
            updateAttributes()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkForAttributes()
            }
        }
    }
    
    func updateAttributes() {
        self.attributesStackView.spacing = 10
        var attributes = self.viewModel?.getType()?.getAttributesFor(update: true) ?? []
        attributes.sort { (a1, a2) -> Bool in
            return a1.ordering.intValue < a2.ordering.intValue
        }
        for attribute in attributes {
            if attribute.type == AttributeTypes.text || attribute.type == AttributeTypes.textarea || attribute.type == AttributeTypes.email {
                let subStack = UIStackView()
                subStack.alignment = .fill
                subStack.distribution = .fillProportionally
                subStack.axis = .vertical
                
                let label = UILabel()
                label.font = MMFontScheme.shared.subTitleTextFont?.withSize(UIFont.preferredFont(forTextStyle: .callout).pointSize)
                label.text = (attribute.name ?? "") + ((attribute.required == 1) ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
                subStack.addArrangedSubview(label)
                
                let inputView = UITextField()
                inputView.tag = attribute.id?.intValue ?? 0
                inputView.placeholder = (attribute.name ?? "") + ((attribute.required == 1) ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
                inputView.font = MMFontScheme.shared.normalTextFont
                inputView.keyboardType = attribute.type == AttributeTypes.email ? .emailAddress : .default
                self.attributeTextViews.append(inputView)
                subStack.addArrangedSubview(inputView)
                
                self.attributesStackView.addArrangedSubview(subStack)
            } else if attribute.type == AttributeTypes.checkbox {
                let subStack = UIStackView()
                subStack.alignment = .fill
                subStack.distribution = .fillProportionally
                subStack.axis = .horizontal
                
                let check = UISwitch()
                check.tag = attribute.id?.intValue ?? 0
                check.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
                subStack.addArrangedSubview(check)
                
                let label = UILabel()
                label.font = MMFontScheme.shared.normalTextFont
                label.text = (attribute.name ?? "") + ((attribute.required == 1) ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
                subStack.addArrangedSubview(label)
                
                self.attributesStackView.addArrangedSubview(subStack)
            } else if attribute.type == AttributeTypes.valuelist {
                let subStack = UIStackView()
                subStack.alignment = .fill
                subStack.distribution = .fillProportionally
                subStack.axis = .horizontal
                
                let label = UILabel()
                label.font = MMFontScheme.shared.normalTextFont
                label.text = (attribute.name ?? "") + ((attribute.required == 1) ? (" " + LocalizedString("REQUIRED", comment: "")) : "")
                label.tag = attribute.id?.intValue ?? 0
                subStack.addArrangedSubview(label)
                self.dropDownViews.append(label)
                
                let image = UIImageView(image: UIImage(named: "dropdown", in: MM.shared.bundle, compatibleWith: nil))
                image.tintColor = UIColor(named: "tint_color_dark") ?? .blue
                image.widthAnchor.constraint(equalToConstant: 40).isActive = true
                image.heightAnchor.constraint(equalToConstant: 40).isActive = true
                subStack.addArrangedSubview(image)
                
                subStack.tag = attribute.id?.intValue ?? 0
                subStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDropDown(_:))))
                
                self.attributesStackView.addArrangedSubview(subStack)
            }
        }
    }
    
    @objc func showDropDown(_ gestureRecofnizer: UIGestureRecognizer) {
        for attribute in self.viewModel?.getType()?.getAttributesFor(update: true) ?? [] {
            if attribute.id?.intValue == gestureRecofnizer.view?.tag {
                self.selectedAttribute = attribute
                self.pickerView.reloadAllComponents()
                self.pickerContainerView.isHidden = false
            }
        }
    }
    
    @objc func switchChanged(_ sView: UISwitch) {
        for attribute in self.viewModel?.getType()?.getAttributesFor(update: true) ?? [] {
            if attribute.id?.intValue == sView.tag {
                attribute.answer = sView.isOn ? "true" : "false"
            }
        }
    }
    
    @objc func uploadCommentAndImage() {
        if let alert = self.viewModel?.canUpload(text: self.commentTextField.text ?? "") {
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let hud = JGProgressHUD(style: self.view.isDarkMode() ? .light : .dark)
        hud.textLabel.text = "Kommentar wird gesendet..."
        hud.show(in: self.view, animated: true)
        
        let attributes = self.viewModel?.getType()?.getAttributesFor(update: true) ?? []
        for attribute in attributes {
            if attribute.type == AttributeTypes.text || attribute.type == AttributeTypes.textarea || attribute.type == AttributeTypes.email {
                for view in self.attributeTextViews {
                    if view.tag == attribute.id?.intValue ?? 0 {
                        attribute.answer = view.text
                    }
                }
            }
            
            if attribute.required == 1 {
                if attribute.type == AttributeTypes.checkbox {
                    if attribute.answer != "true" {
                        hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.dismiss(afterDelay: 5, animated: true)
                        return
                    }
                } else {
                    if attribute.answer == nil || attribute.answer!.filter({ !$0.isWhitespace }).isEmpty {
                        hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                        hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                        hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        hud.dismiss(afterDelay: 5, animated: true)
                        return
                    }
                    
                    if attribute.regex != nil && !attribute.regex!.isEmpty {
                        if attribute.answer!.range(of: attribute.regex!, options: .regularExpression) == nil {
                            hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                            hud.detailTextLabel.text = attribute.error ?? "required field is missing"
                            hud.indicatorView = JGProgressHUDErrorIndicatorView()
                            hud.dismiss(afterDelay: 5, animated: true)
                            return
                        }
                    }
                }
            }
        }
        
        self.viewModel?.uploadUpdate(text: self.commentTextField.text ?? "", attributes: attributes, solved: reportFinishedSwitch.isOn, image: image, completion: { (response) in
            if response.success {
                let message = "Vielen Dank für Ihren Hinweis. Der öffentliche Kommentar wird an den aktuell Zuständigen der Meldung geschickt. Erst nach einer manuellen Prüfung ist er öffentlich im System sichtbar."
                hud.textLabel.text = LocalizedString("IS_UPLOAD_SUCCESS", comment: "")
                hud.detailTextLabel.text = message
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss(afterDelay: 7, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                let message = LocalizedString(response.message, comment: "")
                UIView.animate(withDuration: 0.1) {
                    hud.textLabel.text = LocalizedString("IS_ERROR", comment: "")
                    hud.detailTextLabel.text = message
                    hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    hud.dismiss(afterDelay: 5, animated: true)
                }
            }
        })
    }    
}

extension CommentViewController : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = self.view.isDarkMode() ? .white : .black
            textView.font = MMFontScheme.shared.normalTextFont
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let limit = self.viewModel?.getSettings()?.bmsTextLimit, let warning = self.viewModel?.getSettings()?.bmsLimitWarning, limit > 0 {
            if textView.text.count + text.count > limit {
                let alert = UIAlertController(title: nil, message: warning, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return false
            } else {
                self.countLabel?.text = "\(textView.text.count + text.count) / \(limit)"
            }
        } else {
            self.countLabel.text = ""
        }
        return  true
    }
    
}

extension CommentViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        if image != nil {
            self.newImageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
}

extension CommentViewController : UIPickerViewDataSource, UIPickerViewDelegate {
    
    private var dropdownValues:[String] {
        return self.selectedAttribute?.returnDisplayableObject().getDropdownValues() ?? []
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dropdownValues.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(dropdownValues[row].split(separator: "^")[1])
    }
    
}
