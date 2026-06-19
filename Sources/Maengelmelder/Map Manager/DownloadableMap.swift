//
//  DownloadableMap.swift
//  Maengelmelder
//
//  Created by Felix Leber on 22.04.25.
//

import Foundation
import UIKit
import Alamofire

/**
 Class for downloading and showing offline map data. This can be geometries and / or map tiles.
 */
public class DownloadableMap {
    
    private let FILE_TYPE_GEOJSON = ".geojson"
    private let FILE_TYPE_MBTILES = ".mbtiles"
    
    public static let MAPTYPE_STREET = "streets"
    public static let MAPTYPE_SATELLITE = "satellite"
    
    let name: String
    var size: Int = 0
    let url: URL
    let fileType: String
    let type: String
    
    var fileName : String {
        return url.lastPathComponent
    }
    
    var localURL : URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
    }
    
    var isDownloaded : Bool {
        return FileManager.default.fileExists(atPath: localURL.path)
    }

    private var downloadTask: URLSessionDownloadTask?
    private var progressObservation: NSKeyValueObservation?

    public init(name: String, url: URL, fileType: String, mapType: String) {
        self.name = name
        self.url = url
        self.fileType = fileType
        self.type = mapType
    }

    func deleteLocalFile() {
        do {
            try FileManager.default.removeItem(at: localURL)
        } catch {
            //IGNORED
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        progressObservation = nil
    }

    func download(progress: @escaping (Double) -> Void, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self = self, let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            do {
                if FileManager.default.fileExists(atPath: self.localURL.path) {
                    try FileManager.default.removeItem(at: self.localURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: self.localURL)
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
            self.progressObservation = nil
        }

        progressObservation = task.progress.observe(\.fractionCompleted, options: .new) { taskProgress, _ in
            DispatchQueue.main.async {
                progress(taskProgress.fractionCompleted)
            }
        }

        downloadTask = task
        task.resume()
    }
    
    func fetchFileSize(completion: @escaping () -> Void) {
        guard size == 0 else {
            completion()
            return
        }
        
        if isDownloaded {
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            self.size = Int((attributes?[.size] as? Int64 ?? 0) / (1024 * 1024))
            completion()
        } else {
            AF.request(url, method: .head).response { response in
                if let httpResponse = response.response,
                   let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
                   let size = Int64(contentLength) {
                    self.size = Int(size / (1024 * 1024))
                    completion()
                }
            }
        }
    }
}
