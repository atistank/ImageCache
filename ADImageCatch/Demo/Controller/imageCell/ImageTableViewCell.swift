//
//  ImageTableViewCell.swift
//  ADImageCatch
//
//  Created by Apple on 5/11/18.
//  Copyright © 2018 Apple. All rights reserved.
//

import UIKit

protocol TrackCellDelegate {
    func downloadTapped(_ index: IndexPath)
    func pauseTapped( identifier: Int, _ index: IndexPath)
    func resumeTapped( identifier: Int)
}

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var ivCheckResume: UIImageView!
    @IBOutlet weak var lblTimeLeft: UILabel!
    @IBOutlet weak var lblNetworking: UILabel!
    @IBOutlet weak var lblDownloadProgress: UILabel!
    @IBOutlet weak var vProgress: UIProgressView!
    @IBOutlet weak var lblUrl: UILabel!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var lblImageType: UILabel!
    @IBOutlet weak var btnDownload: UIButton!
    
    var index: IndexPath = IndexPath()
    var statusButton: StatusButtonDownload = .DownloadButtonStatusDownload
    var model: DownloadCellObjectProtocol?
    var delegate : TrackCellDelegate?
    var imageApater = HelperFileService()
    var taskIdentifier: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    
    @IBAction func downloadAction(_ sender: Any) {
        switch statusButton {
        case .DownloadButtonStatusDownload:
             delegate?.downloadTapped(index)
        case .DownloadButtonStatusPause:
            delegate?.pauseTapped( identifier: taskIdentifier, index)
        case .DownloadButtonStatusPlay:
            delegate?.resumeTapped( identifier: taskIdentifier)
        }
    }
    
    func shouldUpdateCellWithModel(row: Int, object: DownloadCellObjectProtocol) {
        let cellObject : DownloadCellObject = object as! DownloadCellObject
        ivImage.image                   = cellObject.image
        lblDownloadProgress.alpha       = 0
        taskIdentifier                  = cellObject.identifier
        
        if cellObject.taskStatus == .DownloadItemStatusNotStarted {
            btnDownload.setImage(#imageLiteral(resourceName: "ic_playDownload"), for: UIControl.State.normal)
            btnDownload.isHidden        = false
            vProgress.alpha             = 0
            ivCheckResume.alpha         = 0
            lblImageType.text           = "State: Ready"
            statusButton                = .DownloadButtonStatusDownload
            btnDownload.isHidden        = false
            
        } else if cellObject.taskStatus == .DownloadItemStatusCompleted {
            btnDownload.isHidden        = true
            lblImageType.text           = "State: Download Completed"
            vProgress.alpha             = 1
            ivCheckResume.alpha         = 0
            lblDownloadProgress.alpha   = 0
            statusButton                = .DownloadButtonStatusDownload
            vProgress.alpha             = cellObject.first == row ? 1 : 0
            
        } else if cellObject.taskStatus == .DownloadItemStatusPending {
            btnDownload.setImage(#imageLiteral(resourceName: "ic_pending"), for: UIControl.State.normal)
            lblImageType.text           = "State: File Pending..."
            vProgress.alpha             = 0
            lblDownloadProgress.alpha   = 0
            ivCheckResume.alpha         = 0
            btnDownload.isHidden        = true
            statusButton                = .DownloadButtonStatusPause
            
        } else if cellObject.taskStatus == .DownloadItemStatusPaused {
            btnDownload.setImage(#imageLiteral(resourceName: "ic_playDownload"), for: UIControl.State.normal)
            btnDownload.isHidden        = false
            lblImageType.text           = "State: Paused"
            ivCheckResume.alpha         = 1
            lblDownloadProgress.alpha   = 1
            vProgress.alpha             = 1
            statusButton                = .DownloadButtonStatusPlay
            btnDownload.isHidden        = cellObject.first == row ? false : true
            lblDownloadProgress.alpha   = cellObject.first == row ? 1 : 0
            ivCheckResume.alpha         = cellObject.first == row ? 1 : 0
            vProgress.alpha             = cellObject.first == row ? 1 : 0
            
        } else if cellObject.taskStatus == .DownloadItemStatusStarted {
            btnDownload.setImage(#imageLiteral(resourceName: "ic_pause"), for: UIControl.State.normal)
            btnDownload.isHidden        = false
            lblImageType.text           = "State: Start Download"
            lblDownloadProgress.alpha   = 1
            vProgress.alpha             = 1
            ivCheckResume.alpha         = 1
            statusButton                = .DownloadButtonStatusPause
            print("row: ",row)
            btnDownload.isHidden        = cellObject.first == row ? false : true
            lblTimeLeft.alpha           = cellObject.first == row ? 1 : 0
            lblDownloadProgress.alpha   = cellObject.first == row ? 1 : 0
            ivCheckResume.alpha         = cellObject.first == row ? 1 : 0
            vProgress.alpha             = cellObject.first == row ? 1 : 0
            
        } else {
            print("nguoc lai: \(cellObject.taskStatus)")
        }
        lblUrl.text                     = String(describing: cellObject.urlPhoto)
        lblTimeLeft.text                = cellObject.taskDetail
    }

    func setModel(row:Int, model: DownloadCellObjectProtocol) {
        self.model = model
        self.model?.identifier = model.identifier
        updateProgress(progress: model.process)
        shouldUpdateCellWithModel(row: row, object: model)
        
    }
    
    func updateProgress(progress: CFloat) {
        self.vProgress.progress = progress
    }
    
}
