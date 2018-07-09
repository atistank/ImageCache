//
//  DownloadService.swift
//  ADImageCatch
//
//  Created by Apple on 5/16/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import Foundation
import UIKit
class DownloadService: NSObject {
   
// MARK: - Properties
    private var session: URLSession!
    static  let share = DownloadService()
    private let list                               = ListDownloading.share
    private var imageApdater                       = HelperFileService()
    private var arrNextItems                       = [DownloadItem]()
    private var arrPauseItems                      = [DownloadItem]()
    private var fileExistsForURL                   = [String:String]()
    public  var currentActiveDownloadTasks         = 0
    public  var pendingDownloadTasks               = 0
    public  var resumeDownloadTasks                = 0
    public  var currentDownloadMaximum             = 1
    private var removeItemQueue                    = DispatchQueue(label: "removeItemQueue")
    private var createDirectoryQueue               = DispatchQueue(label: "createDirectoryQueue")
    public var folderOriginal                      = "ImageCatche"
    public var folderResize                        = "ImageResize"
    public var backgroupUpdateTask: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        session = URLSession(configuration: .background(withIdentifier: "ahihi"), delegate: self, delegateQueue: OperationQueue.main)
    }
    
    func beginDownloadBackgroup() {
        backgroupUpdateTask = UIApplication.shared.beginBackgroundTask(withName: "download Image", expirationHandler: {
            self.endDownloadBackgroup()
        })
    }
    
    func endDownloadBackgroup() {
        UIApplication.shared.endBackgroundTask(backgroupUpdateTask)
        backgroupUpdateTask =  UIBackgroundTaskIdentifier.invalid
    }
    
// MARK: - Start Download File
    func startDownloadFileFromURL(row: Int, sourceURL: String, informationFile: ((DownloadItem) -> ())?,  queue: DispatchQueue) {
        
        if sourceURL == fileExistsForURL[sourceURL] {
            print("File Exits")
        } else if completeDownload(sourceURL: sourceURL) == false {
            
            print("File is Downloading.....")
        } else {
            
            print("Start Download File")
            beginDownloadBackgroup()
            queue.async {
                print("run run run ~~~~")
                let urlRequest = URLRequest(url: URL(string: sourceURL)!)
                let downloadTask: URLSessionDownloadTask  = self.session.downloadTask(with: urlRequest)
                let downloadFileItem = DownloadItem(downloadTask: downloadTask, callbackQueue: queue, infoFileDownloadBlock: informationFile!)
                downloadFileItem.startDate            = Date()
                downloadFileItem.fileName             = URL(string: sourceURL)!.lastPathComponent
                downloadFileItem.downloadItemStatus   = .DownloadItemStatusPending
                downloadFileItem.sourceURL            = sourceURL
                downloadFileItem.identifier           = downloadFileItem.downloadTask.taskIdentifier
                downloadFileItem.row                  = row
                
                // Check maximum task download
                if self.currentActiveDownloadTasks >= self.currentDownloadMaximum {
                    self.pendingDownloadTasks += 1
                    self.arrNextItems.append(DownloadItem(downloadTask: downloadTask, callbackQueue: queue, infoFileDownloadBlock: informationFile!))
                } else {
                    self.currentActiveDownloadTasks += 1;
                    downloadFileItem.downloadTask.resume()
                }
                self.list.addNewDownload(object: downloadFileItem)
                print("Prerare End download")
                self.endDownloadBackgroup()
                print("End download")
                // callback to update UI
                if downloadFileItem.infoFileDownloadBlock != nil {
                    DispatchQueue.main.async {
                        downloadFileItem.infoFileDownloadBlock!(downloadFileItem)
                    }
                }
            }
        }
    }

// MARK: - Pause Download
func pauseDownload(identifier: Int,  informationFile: ((DownloadItem) -> ())?) {
    
        let downloadItems = list.getAllList()
        let downloadFileItem = downloadItems.filter { $0.identifier == identifier }[0]
        switch downloadFileItem.downloadItemStatus {
        case .DownloadItemStatusPending:
              pendingDownloadTasks -= 1
        case .DownloadItemStatusStarted:
              currentActiveDownloadTasks -= 1
            downloadFileItem.downloadTask.suspend()
        default:
            print("default downloadFileItem status")
        }
        downloadFileItem.downloadItemStatus = .DownloadItemStatusPaused
        resumeDownloadTasks += 1
        if downloadFileItem.infoFileDownloadBlock != nil {
            DispatchQueue.main.async {
                downloadFileItem.infoFileDownloadBlock!(downloadFileItem)
            }
        }
        if pendingDownloadTasks > 0 && currentActiveDownloadTasks < currentDownloadMaximum {
            if arrNextItems.count > 0 {
                if downloadFileItem.downloadItemStatus == .DownloadItemStatusPending {
                    arrNextItems[0] = downloadFileItem
                    return
                }
                arrNextItems[0].downloadTask.resume()
                arrNextItems.remove(at: 0)
                currentActiveDownloadTasks += 1
                pendingDownloadTasks -= 1
            }
        }
    }
    
    // MARK: - Resume Download
    func resumeDownload(identifier: Int) {
        
        let DownloadItem = list.getAllList()
        let downloadFileItem = DownloadItem.filter { $0.identifier == identifier }[0]
        if resumeDownloadTasks > 0 {
            if currentActiveDownloadTasks >= currentDownloadMaximum {
                if downloadFileItem.downloadItemStatus == .DownloadItemStatusNotStarted {
                    currentActiveDownloadTasks -= 1
                    arrPauseItems[0] = downloadFileItem
                    return
                }
                if !arrPauseItems.isEmpty {
                    arrPauseItems[0].downloadItemStatus = .DownloadItemStatusPaused
                    arrPauseItems[0].downloadTask.suspend()
                    resumeDownloadTasks += 1
                    DispatchQueue.main.async {
                        self.arrPauseItems[0].infoFileDownloadBlock!(self.arrPauseItems[0])
                    }
                }
            }
            
            // resume task
            downloadFileItem.downloadItemStatus = .DownloadItemStatusStarted
            downloadFileItem.downloadTask.resume()
            currentActiveDownloadTasks += 1
            resumeDownloadTasks -= 1
        }
    }
}

// MARK: - Helper function
extension DownloadService {
    
    // get Path of url
    func cachesDirectoryUrlPath() -> URL {
        let paths             = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let cachesDirectory   = paths[0]
        let urlPath           =  URL(fileURLWithPath: cachesDirectory)
        return urlPath
    }
    
    // Check Condition
    func completeDownload(sourceURL: String) -> Bool {
        var check = true
        let resultlist = list.getAllList()
        if  resultlist.contains(where: {$0.sourceURL == sourceURL}) {
            check = false
        }
        return check
    }
    
    func getDownloadSize(url: URL, completion: @escaping (Int64, Error?) -> Void) {
        let timeoutInterval = 5.0
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let contentLength = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            completion(contentLength, error)
        }.resume()
    }
}

// MARK: - Download Session Delegate
extension DownloadService: URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("urlSessionDidFinishEvents")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        print("downloading")
        // Downloading
        let identifier            = downloadTask.taskIdentifier
        let downloadItems         = list.getAllList()
        let downloadingItemFirst  = downloadItems.filter { $0.identifier == identifier }[0]
        
        if downloadingItemFirst.downloadItemStatus == .DownloadItemStatusPending { downloadingItemFirst.downloadItemStatus = .DownloadItemStatusStarted }
        downloadingItemFirst.byteRecives           = bytesWritten
        downloadingItemFirst.totalBytes            = totalBytesExpectedToWrite
        downloadingItemFirst.totalbyteRecives      = totalBytesWritten
        if downloadingItemFirst.infoFileDownloadBlock != nil {
            DispatchQueue.main.async {
                downloadingItemFirst.infoFileDownloadBlock!(downloadingItemFirst)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("didFinishDownloadingTo")
        //Download finished
        let identifier            = downloadTask.taskIdentifier
        let downloadItems         = list.getAllList()
        let test = downloadItems.filter {
            $0.identifier == identifier
        }
        let downloadingItemFirst = test[0]
        var localFilePath: URL
        
        if downloadingItemFirst.directoryName != "" {
            localFilePath = self.cachesDirectoryUrlPath().appendingPathComponent(downloadingItemFirst.directoryName).appendingPathComponent(downloadingItemFirst.fileName)
        } else {
            localFilePath = self.cachesDirectoryUrlPath().appendingPathComponent(folderOriginal).appendingPathComponent(downloadingItemFirst.fileName)
        }
        downloadingItemFirst.filePath = String(describing: localFilePath)
        
        // Movie image to folder "ImageCatche" after download
        removeItemQueue.sync {
            let fileManager = FileManager.default
            try? fileManager.moveItem(at: location, to: localFilePath)
        }
        
        // Image orientation
        let image = imageApdater.getImageFromFolder(named: downloadingItemFirst.fileName, folderName: folderOriginal, defaultImage: #imageLiteral(resourceName: "ic_default"))
        downloadingItemFirst.image = image

        // Image Resize
        let imageResized = image.resizeImage(targetSize: CGSize.init(width: 150, height: 100))
        _ = imageApdater.saveImageToFolder(image: imageResized, folderName: folderResize, fileType: "", fileName: downloadingItemFirst.fileName)
        downloadingItemFirst.image = imageApdater.checkExistFile(folderResize, downloadingItemFirst.fileName) ? imageResized : image
        
        if downloadingItemFirst.infoFileDownloadBlock != nil {
            downloadingItemFirst.downloadItemStatus = .DownloadItemStatusCompleted
            currentActiveDownloadTasks -= 1
            DispatchQueue.main.async {
                downloadingItemFirst.infoFileDownloadBlock!(downloadingItemFirst)
                self.list.removeObject(object: downloadingItemFirst)
            }
        }
        
        // Start download item in pending list
        if pendingDownloadTasks > 0 && currentActiveDownloadTasks < currentDownloadMaximum {
            if arrNextItems.count > 0 {
                if downloadingItemFirst.downloadItemStatus == .DownloadItemStatusPending {
                    arrNextItems[0] = downloadingItemFirst
                    return
                }
                arrNextItems[0].downloadTask.resume()
                arrNextItems.remove(at: 0)
                currentActiveDownloadTasks += 1
                pendingDownloadTasks -= 1
            }
        }
    }
}
