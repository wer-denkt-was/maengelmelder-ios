//
//  ReportDetailViewModel.swift
//  MM
//
//  Created by Felix on 22.01.19.
//  Copyright © 2024 WDW. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit
import FSPagerView
import AlamofireImage

class ReportDetailViewModel: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, FSPagerViewDataSource, FSPagerViewDelegate {
    
    fileprivate var report : ReportDetails?
    fileprivate var isIdea = false
    fileprivate var pagerView : FSPagerView?
    fileprivate var pagerContainer : UIView?
    fileprivate var collectionView: UICollectionView?
    
    fileprivate var system : System?
    
    private var images = Array<UIImage>()
    private var imageDownloader = ImageDownloader()
    
    init(_ reportId: NSNumber, domainID: NSNumber, system: System, pagerView: FSPagerView, pagerContainer: UIView, compleation: ((UIAlertController?) -> Void)? = { alert in }, _ onResolve: @escaping () -> Void = { }) {
        super.init()
        
        self.system = system
        
        self.pagerView = pagerView
        self.pagerContainer = pagerContainer
        self.pagerContainer?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideImage)))
        
        MMApi.shared.getMessageDetail(id: reportId.intValue, domainid: domainID.intValue, system: system) { details, error in
            if details?.markerID == 0 && details?.markerColor == "white" {
                let alert = UIAlertController(title: nil, message: "Diese Meldung ist noch nicht freigegeben worden und kann deshalb nicht angesehen werden. Sobald die Meldung freigegeben wurde, können Sie diese hier einsehen.", preferredStyle: .alert)
                compleation?(alert)
            }
            
            self.report = details
            self.isIdea = GlobalArrays.MODE_IDEA_CATEGORIES.contains(details?.typeid ?? 0)
            self.collectionView?.reloadData()
            self.pagerView?.reloadData()
            
            let urls = self.report?.pictureUrls ?? []
            let requests = urls.map { (url) -> URLRequest in
                return URLRequest(url: URL(string: url)!)
            }
            self.imageDownloader.download(requests, completion: { (response) in
                if case .success(let image) = response.result {
                    self.images.append(image)
                    self.pagerView?.reloadData()
                }
            })
            
            onResolve()
        }
    }
    
    func isCommentAllowed() -> Bool {
        return report?.allowComment ?? false
    }
    
    func subscribe(_ mail: String, completion: @escaping (Bool) -> Void) {
        MMApi.shared.addSubscription(id: report?.messageid.intValue ?? 0, mail: mail, domainid: report?.domainID ?? 32, system: system) { result, error in
            completion(result)
        }
    }
    
    func getCommentViewModel() -> CommentViewModel {
        return CommentViewModel(system: system ?? System(appid: MMSettings.shared.APP_ID, host: MMApi.shared.SERVER_URL, name: "", external: false), reportDetails: report!)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.collectionView = collectionView
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = (self.report?.pictureUrls.isEmpty ?? true) ? 1 : 2
        if isIdea {
            count = count - 1
        }
        return count + (report?.details.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if ((indexPath.row == 0 && isIdea) || (indexPath.row == 1 && !isIdea)) && !(self.report?.pictureUrls.isEmpty ?? false) {
            let pcell = collectionView.dequeueReusableCell(withReuseIdentifier: "photo_cell", for: indexPath) as! ImageCollectionCell
            if let url = URL(string: self.report?.thumbnailUrls.first ?? self.report?.pictureUrls.first ?? "") {
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async {
                        pcell.imageView.image = UIImage(data: data)
                        pcell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showView)))
                        
                        if self.report?.pictureUrls.count ?? 0 > 1 {
                            pcell.moreLabel.text = String(format: "+%d", (self.report?.pictureUrls.count ?? 2)-1)
                        }
                    }
                }.resume()
            }
            return pcell
        } else if indexPath.row == 0 && !isIdea {
            let mcell = collectionView.dequeueReusableCell(withReuseIdentifier: "map_cell", for: indexPath) as! MapViewCollectionViewCell
            mcell.mapManager = MapManager(mapView: mcell.mapview, screenIdentifier: "")
            mcell.mapview.isUserInteractionEnabled = false
            mcell.mapview.setCamera(MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: report?.lat.doubleValue ?? 0, longitude: report?.lon.doubleValue ?? 0), fromDistance: 1000, pitch: 0, heading: 0), animated: false)
            mcell.mapview.removeAnnotations(mcell.mapview.annotations)
            if report != nil {
                mcell.mapManager?.addGroupToMap(ReportGroup(with: ReportMapMarker(reportDetails: report!, system: system!)))
            }
            return mcell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "card_cell", for: indexPath) as! CardViewCell
            cell.isUserInteractionEnabled = true
            cell.updateCard()
            var offset = (self.report?.pictureUrls.isEmpty ?? true) ? 1 : 2
            if self.isIdea {
                offset -= 1
            }
            
            let item = report?.details[(indexPath.row-offset)]
            cell.titleLabel.text = item?.title
            DispatchQueue.main.async {
                cell.textLabel.attributedText = self.report?.getDetailValueString(for: indexPath.row-offset, and: cell.isDarkMode())
            }
        
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width-20
        if indexPath.row <= 1 && !(self.report?.pictureUrls.isEmpty ?? false) && !isIdea {
            return CGSize(width: (width-20)/2, height: (width-20)/2)
        } else if indexPath.row == 0 {
            return CGSize(width: width, height: (width-20)/2)
        } else {
            var offset = (self.report?.pictureUrls.isEmpty ?? true) ? 1 : 2
            if self.isIdea {
                offset -= 1
            }
            let index = (indexPath.row-offset)
            let first = NSAttributedString(string: report?.details[index].title ?? "", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title3)])
            let second = report?.getDetailValueString(for: index, and: collectionView.isDarkMode()) ?? NSAttributedString()
            let size = first.boundingRect(with: CGSize(width: width-10, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
            let size2 = second.boundingRect(with: CGSize(width: width-10, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
            return CGSize(width: width, height: size.height + size2.height + 30)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 10, bottom: 0, right: 10)
    }
    
    @objc private func showView() {
        pagerContainer?.isHidden = false
    }
    
    @objc public func hideImage() {
        self.pagerContainer?.isHidden = true
    }
    
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return self.images.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.image = self.images[index]
        return cell
    }
}
