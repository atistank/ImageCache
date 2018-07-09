//
//  ViewController.swift
//  ADImageCatch
//
//  Created by Apple on 5/11/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit
import LinearProgressBar
import CoreTelephony

class DemoViewController: UIViewController {

    @IBOutlet weak var viewButtom: UIView!
    @IBOutlet weak var viewNavigation: UIView!
    @IBOutlet weak var lblTaskResume: UILabel!
    @IBOutlet weak var lblPending: UILabel!
    @IBOutlet weak var lblDownloading: UILabel!
    @IBOutlet weak var vTableview: UITableView!
    
//MARK:- Properties
    var resultApi       = [photoAPI]()
    var imageList       = [UIImage]()
    let session         = URLSession(configuration: .default)
    let STSimageCatche  = HelperFileService()
    var downloadService = DownloadService.share
    var cellObjects     = [String:DownloadCellObject]()
    var fileNameCell    = [String]()
    let networkInfo     = CTTelephonyNetworkInfo()
    
//MARK:- Lifeclyle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        checkNetworking { (status) in
            
            // Limit Download Task
            switch status {
            case .ConnectionTypeWiFi:
                self.downloadService.currentDownloadMaximum = 2
            case .ConnectionType3G:
                self.downloadService.currentDownloadMaximum = 1
            case .ConnectionType4G:
                self.downloadService.currentDownloadMaximum = 2
            case .ConnectionTypeNone:
                self.downloadService.currentDownloadMaximum = 0
            case .ConnectionTypeUnknown:
                self.downloadService.currentDownloadMaximum = 1
            case .ConnectionType2G:
                self.downloadService.currentDownloadMaximum = 1
            }
        }
        fetchJson()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func tapFolder(_ sender: Any) {
        let story = UIStoryboard.init(name: "Main", bundle: nil)
        let vc = story.instantiateViewController(withIdentifier: "FolderViewController") as! FolderViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func setUI() {
        vTableview.delegate                  = self
        vTableview.dataSource                = self
        vTableview.separatorStyle            = .none
        
        // Create folder save image
        let folderOriginalImage              = "ImageCatche"
        let folderResizeImage                = "ImageResize"
        let ImageCatchePath                  = URL.createFolder(folderName: folderOriginalImage)
        let ImageResizePath                  = URL.createFolder(folderName: folderResizeImage)
        downloadService.folderOriginal       = folderOriginalImage
        downloadService.folderResize         = folderResizeImage
        viewNavigation.layer.cornerRadius    = 5
        viewNavigation.clipsToBounds         = false
        viewNavigation.layer.shadowOpacity   = 0.1
        viewNavigation.layer.shadowColor     = UIColor.black.cgColor
        viewNavigation.layer.shadowOffset    = CGSize(width: 0, height: 0)
        viewNavigation.layer.shadowRadius    = 6
        viewButtom.layer.cornerRadius        = 5
        viewButtom.clipsToBounds             = false
        viewButtom.layer.shadowOpacity       = 0.1
        viewButtom.layer.shadowColor         = UIColor.black.cgColor
        viewButtom.layer.shadowOffset        = CGSize(width: 0, height: 0)
        viewButtom.layer.shadowRadius        = 6
        print("Folder ImageCatche Path: \(ImageCatchePath!)")
        print("Folder ImageResize Path: \(ImageResizePath!)")
    }
}

//MARK:- Fetch Data
extension DemoViewController {
    
    func fetchJson(){
        if let result = loadJson(filename: "jSon") {
            for _ in 0...100 {
                 self.resultApi.append(contentsOf: result)
            }
            _ = resultApi.map{
                let url = URL(string: $0.url)
                let cellObject = DownloadCellObject(urlPhoto: url!, identifier: 0, taskName: (url?.lastPathComponent)!, taskStatus: StatusFileDownload.DownloadItemStatusNotStarted, process: 0, taskDetail: "", totalBytes: 0, totalbyteRecives: 0, filePath: "", fileName: "", image: #imageLiteral(resourceName: "ic_default"), first: -0)
                cellObjects[String(describing: cellObject.urlPhoto)] = cellObject
                let fileName = url?.lastPathComponent
                fileNameCell.append(fileName!)
            }
            for _ in 0...resultApi.count-1 {
                self.imageList.append(#imageLiteral(resourceName: "demoImage"))
            }
        }
    }
    
    func loadJson(filename fileName: String) -> [photoAPI]? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data     = try Data(contentsOf: url)
                let decoder  = JSONDecoder()
                let jsonData = try decoder.decode(Array<photoAPI>.self, from: data)
                return jsonData
            } catch {
                print("error:\(error)")
            }
        }
        return nil
    }
    
    
}

//MARK: - Tableview
extension DemoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !resultApi.isEmpty {
            return resultApi.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell                 = tableView.dequeueReusableCell(withIdentifier: "cell") as! ImageTableViewCell
        let url                  = resultApi[indexPath.row].url
        cell.delegate            = self
        cell.lblUrl.text         = resultApi[indexPath.row].url
        cell.lblNetworking.text  = fileNameCell[indexPath.row]
        cell.index               = indexPath
        cell.setModel(row: indexPath.row, model: cellObjects[url]! )
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 122.0
    }
}

//MARK: - Download Parse
extension DemoViewController: TrackCellDelegate {
    
    func downloadTapped(_ index: IndexPath) {
            if resultApi.count > 0 {
                let imageApi = resultApi[index.row]
                let queue    = DispatchQueue.global(qos: .background)
                downloadService.startDownloadFileFromURL(row: index.row, sourceURL: imageApi.url, informationFile: { (downloadFileItem) -> () in
                    self.updateCell(item: downloadFileItem, filePath: downloadFileItem.filePath, index: index)
                }, queue: queue)
            } else {
                print("error \(resultApi.count)")
            }
    }
    
    func resumeTapped( identifier: Int) {
        downloadService.resumeDownload(identifier: identifier)
    }
    
    func pauseTapped( identifier: Int,_ index: IndexPath) {
        downloadService.pauseDownload(identifier: identifier) { (downloadItem) in
            self.updateCell(item: downloadItem, filePath: downloadItem.filePath, index: index)
        }
    }
}

//MARK: - Reload Update UI Cell
extension DemoViewController {
    
    func reload(_ row: Int) {
        vTableview.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
    func updateCell(item:DownloadItem, filePath: String, index: IndexPath) {
        if cellObjects.count == 0 { return }
        let cellObject: DownloadCellObject  = cellObjects[item.sourceURL]!
        cellObject.identifier               = item.identifier
        let status: StatusFileDownload      = item.downloadItemStatus
        lblDownloading.text   = "Downloading: \(downloadService.currentActiveDownloadTasks)"
        lblPending.text       = "Task Pending: \(downloadService.pendingDownloadTasks)"
        lblTaskResume.text    = "Task Resume: \(downloadService.resumeDownloadTasks)"
        
        if let cellImage = vTableview.cellForRow(at: index) {
            let cell = cellImage as! ImageTableViewCell
            
            if status == .DownloadItemStatusCompleted {
                cellObject.taskStatus  = .DownloadItemStatusCompleted
                cellObject.filePath    = filePath
                cellObject.fileName    = item.fileName
                cellObject.image       = item.image
                DispatchQueue.main.async {
                    cell.setModel(row: index.row, model: cellObject)
                }
            } else if status == .DownloadItemStatusPaused {
                cellObject.taskStatus  = .DownloadItemStatusPaused
                DispatchQueue.main.async {
                    cell.setModel(row: index.row, model: cellObject)
                }
            } else if status == .DownloadItemStatusCancelled {
                cellObject.taskStatus  = .DownloadItemStatusCancelled
                DispatchQueue.main.async {
                    cell.setModel(row: index.row, model: cellObject)
                }
            } else if status == .DownloadItemStatusPending {
                cellObject.taskStatus  = .DownloadItemStatusPending
                DispatchQueue.main.async {
                    cell.setModel(row: index.row,model: cellObject)
                }
            } else if status == .DownloadItemStatusTimeOut {
                cellObject.taskStatus  = .DownloadItemStatusTimeOut;
                DispatchQueue.main.async {
                    cell.setModel(row: index.row,model: cellObject)
                }
            } else {
                // status is Started Download
                let progress                 = Float(item.totalbyteRecives) / Float(item.totalBytes)
                let second                   = self.TimeLeft(startDate: item.startDate, byesTransferred: item.totalbyteRecives, totalByteExpectedToWrite: item.totalBytes)
                let formatByteWritten        = ByteCountFormatter.string(fromByteCount: item.totalbyteRecives, countStyle: ByteCountFormatter.CountStyle.file)
                let formartBytesExpected     = ByteCountFormatter.string(fromByteCount: item.totalBytes, countStyle: ByteCountFormatter.CountStyle.file)
                let detailInfor              = String(format: "%.0f%% - %@ / %@ - About: %@", progress * 100, formatByteWritten,formartBytesExpected,self.timeFormartted(totalSecond: Int(second)))
                cellObject.filePath          = filePath
                cellObject.totalbyteRecives  = item.totalbyteRecives
                cellObject.totalBytes        = item.totalBytes
                cellObject.taskDetail        = detailInfor
                cellObject.process           = progress
                cellObject.first             = item.row
                cellObject.taskStatus        = .DownloadItemStatusStarted
                DispatchQueue.main.async {
                    cell.setModel(row: index.row,model: cellObject)
                }
            }
        }
    }
}

//MARK: - Formart Time
extension DemoViewController {
    
    func TimeLeft(startDate: Date, byesTransferred: Int64 , totalByteExpectedToWrite: Int64) -> Float {
        let timeInterval     = CFDateGetTimeIntervalSinceDate(Date() as CFDate, startDate as CFDate)
        let speed            = Float(byesTransferred) / Float(timeInterval)
        let remainingBytes   = totalByteExpectedToWrite - byesTransferred
        let timeLeft         = Float(remainingBytes) / speed
        return timeLeft
    }
    
    func timeFormartted(totalSecond: Int) -> String {
        let seconds  = totalSecond % 60
        let minutes  = ( totalSecond / 60 ) % 60
        let hours    = totalSecond / 3600
        if hours > 0 {
            return String(format: "%02dh:%02dm:%02ds",hours,minutes,seconds)
        } else if minutes > 0 {
            return String(format: "%02dm:%02ds",minutes,seconds)
        } else {
            return String(format: "%02ds",seconds)
        }
    }
}
