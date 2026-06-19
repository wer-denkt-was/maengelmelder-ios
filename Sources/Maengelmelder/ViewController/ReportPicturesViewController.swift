//
//  ReportPicturesViewController.swift
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import JGProgressHUD

class ReportPicturesViewController: UIViewController {
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var isEmptyCollectionViewLabel: UILabel!
    @IBOutlet weak var expandedImageView: UIImageView!
    @IBOutlet weak var deletePictureButton: UIButton!
    
    fileprivate var hud = JGProgressHUD(style: .dark)
    
    fileprivate var viewModel : ReportPicturesViewModel?
    fileprivate var parentTabController : ReportCreationTabViewController?
    fileprivate var images = Array<UIImage>()
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    fileprivate var selectedImageIndex = -1 {
        didSet {
            self.deletePictureButton.isHidden = selectedImageIndex == -1
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = LocalizedString("HEADING_STEP_2", comment: "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.title = LocalizedString("HEADING_STEP_2", comment: "")
    }
    
    override func viewDidLoad() {
        parentTabController = parent as? ReportCreationTabViewController
        
        viewModel = ReportPicturesViewModel(parentController: parentTabController!)
        
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        
        deletePictureButton.backgroundColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonBg)
        deletePictureButton.tintColor = MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText)
        
        if(parentTabController!.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_MODE || parentTabController!.screenMode == GlobalFlagValues.REPORT_SCREEN_EDIT_IDEA){
            images = viewModel!.getReportImages()
            imageCollectionView.reloadData()
        } else {
            selectedImageIndex = -1
        }
        
        self.deletePictureButton.isHidden = selectedImageIndex == -1
        setLabelsAndBotButtonsBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        setTopNavBarAccessories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].wasTabOpened = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        parentTabController = parent as? ReportCreationTabViewController
        parentTabController!.tabsViewHelper![parentTabController!.selectedIndex].reportDidUpdatedAtTab = true
        updateReportContext()
    }
    
    private func updateReportContext() {
        self.cameraButton.isHidden = images.count == self.viewModel?.maxImages ?? 1
        self.libraryButton.isHidden = images.count == self.viewModel?.maxImages ?? 1
        viewModel!.updateReport(images: images)
    }
    
    private func setTopNavBarAccessories() {
        parent!.navigationItem.title = LocalizedString("HEADING_STEP_2", comment: "")
    }
    
    private func setLabelsAndBotButtonsBar() {
        
        isEmptyCollectionViewLabel.font = MMFontScheme.shared.normalTextFont
        isEmptyCollectionViewLabel.textColor = MMColorScheme.shared.getColor(view: self.view, type: .titleText)
        isEmptyCollectionViewLabel.attributedText = MMSettings.shared.emptyPicturesText
        
        cameraButton.backgroundColor = UIColor.gray
        libraryButton.backgroundColor = UIColor.gray
        
        cameraButton.titleLabel?.font = MMFontScheme.shared.buttonTitleFont!
        libraryButton.titleLabel?.font = MMFontScheme.shared.buttonTitleFont!
        
        cameraButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        libraryButton.setTitleColor(MMColorScheme.shared.getColor(view: self.view, type: .buttonTitleText), for: .normal)
        
        cameraButton.setTitle(LocalizedString("CAMERA_BTN_TITLE", comment: ""), for: .normal)
        libraryButton.setTitle(LocalizedString("LIBRARY_BTN_TITLE", comment: ""), for: .normal)
    }
    
    //MARK :- view button actions
    
    @IBAction func cameraButtonTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self;
            pickerController.sourceType = .camera
            pickerController.allowsEditing = false
            pickerController.modalPresentationStyle = .overCurrentContext
            show(pickerController, sender: false)
        }
    }
    
    @IBAction func deletePictureButtonTapped(_ sender: Any) {
        self.images.remove(at: self.selectedImageIndex)
        if images.isEmpty {
            self.expandedImageView.image = nil
            self.selectedImageIndex = -1
        } else {
            self.expandedImageView.image = self.images[0]
            self.selectedImageIndex = 0
        }
        self.imageCollectionView.reloadData()
        self.updateReportContext()
    }
    
    @IBAction func libraryButtonTapped(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self;
            pickerController.sourceType = .photoLibrary
            pickerController.allowsEditing = false
            pickerController.modalPresentationStyle = .overCurrentContext
            show(pickerController, sender: false)
        }
    }
}

extension ReportPicturesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        hud = JGProgressHUD(style: self.view.isDarkMode() ? .dark : .light)
        hud.vibrancyEnabled = true
        hud.textLabel.text = "Bild wird kopiert..."
        hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        hud.show(in: self.view)
        
        if var image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            DispatchQueue.main.async {
                let width = image.size.width
                let height = image.size.height
                let ratio = 1280 / (width < height ? width : height)
                image = image.resizedImageWith(size: CGSize(width: width * ratio, height: height * ratio))
                
                if (image.jpegData(compressionQuality: 1.0)? .count ?? 0) > 50000000 {
                    self.hud.textLabel.text = "Das Bild konnte nicht hinzugefügt werden, da dieses zu groß ist. Es sind nur Bilder bis zu 50MB erlaubt."
                    self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                    self.hud.dismiss(afterDelay: 5)
                } else {
                    let compressedImage = UIImage(data: image.jpegData(compressionQuality: 1.0) ?? Data())
                    self.images.append(compressedImage ?? image)
                    self.expandedImageView.image = compressedImage ?? image
                    self.imageCollectionView.reloadData()
                    self.updateReportContext()
                    self.hud.dismiss()
                }
            }
        } else {
            self.hud.dismiss()
        }
    }
}

extension ReportPicturesViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionCell
        cell.imageView.image = images[indexPath.row]
        
        if selectedImageIndex == -1 {
            selectedImageIndex = indexPath.row
            
            self.expandedImageView.image = images[indexPath.row]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedImageIndex = indexPath.row
        
        self.expandedImageView.image = images[indexPath.row]
    }
}

extension ReportPicturesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let availableWidth = collectionView.frame.width/3
        let widthPerItem = availableWidth
        
        return CGSize(width: widthPerItem, height: collectionView.frame.height-10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.sectionInsets
    }
}
