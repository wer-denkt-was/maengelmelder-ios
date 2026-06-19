//
//  ReportPicturesViewModel.swift
//  Maengelmelder
//
//  Created by Felix on 29.03.18.
//  Copyright © 2024 WDW. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class ReportPicturesViewModel {
    
    fileprivate var viewsParentController: ReportCreationTabViewController?
    
    let maxImages = 3
    
    init(parentController: ReportCreationTabViewController) {
        self.viewsParentController = parentController
    }
    
    func updateReport(images: [UIImage]) {
        
        deleteOldImages()
        
        var imagePathArray : [String] = []
        
        var id = 0
        for image in images {
            if let data = image.jpegData(compressionQuality: 1.00) {
                let filename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(String.init(format: "%d-%d.jpg", self.viewsParentController?.report?.id.intValue ?? 0, id))
                if FileManager.default.createFile(atPath: filename.path, contents: data, attributes: nil) {
                    imagePathArray.append(filename.lastPathComponent)
                    id = id + 1
                }
            }
        }
        
        self.viewsParentController!.report!.attachments = NSMutableOrderedSet(array: imagePathArray)
    }
    
    private func deleteOldImages() {
        let imagesPaths = viewsParentController!.report!.attachments.array as! [String]
        
        for path in imagesPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
    
    func getReportImages() -> [UIImage] {        
        let imagesPaths = viewsParentController!.report!.attachments.array as! [String]
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var images : [UIImage] = []
        for path in imagesPaths {
            images.append(UIImage(contentsOfFile: baseURL.appendingPathComponent(path).path) ?? UIImage())
        }
        
        return images
    }
}
