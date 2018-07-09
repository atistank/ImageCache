//
//  STSImageCatcheAdapter.swift
//  ADImageCatch
//
//  Created by Apple on 5/14/18.
//  Copyright © 2018 Apple. All rights reserved.
//
import UIKit
import Foundation

class HelperFileService: NSObject {
    
    private var imageCacheTaskID = [String:UIImage]()
    private var imageDefault:UIImage = #imageLiteral(resourceName: "demoImage")
    private var imageCacheURL = [String:UIImage]()
    private var imagePath = [String:String]()
    
    override init() {
        super.init()
    }
    
    func createFolderImageCatche() {
       _ = URL.createFolder(folderName: "ImageCatche")
       _ = URL.createFolder(folderName: "Thumbnail")
    }

// MARK: - Save & get image from device
    
    // Save Image by folder name
    func saveImageToFolder1(image: UIImage, folderName: String, fileType: String) -> String{
        let imageData   = NSData(data: image.pngData()!)
        let fileName    = NSUUID().uuidString + fileType
        if let filePath = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: folderName) {
            _ = imageData.write(toFile: filePath, atomically: true)
            return fileName
        }
        return ""
    }
    
    // Save Image by folder name
    func saveImageToFolder(image: UIImage, folderName: String, fileType: String, fileName: String) -> String{
        let imageData  = NSData(data: image.pngData()!)
        let paths      = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)
        let docs       = paths[0] as NSString
        let fileName   = fileName + fileType
        let fullPath   =  docs.appendingPathComponent("\(folderName)/\(fileName)")
        _ = imageData.write(toFile: fullPath as String, atomically: true)
        return fullPath
    }
    
    // Save Image to default file path
    func saveImage(image: UIImage, fileType: String) -> String{
        let imageData = NSData(data: image.pngData()!)
        let paths     = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,  FileManager.SearchPathDomainMask.userDomainMask, true)
        let docs      = paths[0] as NSString
        let uuid      = NSUUID().uuidString + fileType
        let fullPath  = docs.appendingPathComponent(uuid)
        _ = imageData.write(toFile: fullPath, atomically: true)
        return uuid
    }
    
    // Get Image from default file path
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    // Get Image from folder file path
    func getImageFromFolder(named: String,folderName: String, defaultImage: UIImage) -> UIImage {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            let folderPath = dir.appendingPathComponent(folderName)
            return UIImage(contentsOfFile: URL(fileURLWithPath: folderPath.absoluteString).appendingPathComponent(named).path)!
        }
        return defaultImage
    }

    // Get name all images from folder
    func loadImagesFromAlbum(folderName:String) -> [String]{
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask    = FileManager.SearchPathDomainMask.userDomainMask
        let paths               = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        var theItems = [String]()
        if let dirPath          = paths.first
        {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(folderName)
            
            do {
                theItems = try FileManager.default.contentsOfDirectory(atPath: imageURL.path)
                
                return theItems
            } catch let error as NSError {
                print(error.localizedDescription)
                return theItems
            }
        }
        return theItems
    }
    
    // Check File Exist
    func checkExistFile(_ folder: String,_ fileName: String) -> Bool {
        let documentsURL        = try! FileManager().url(for: .documentDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true)
        let fooURL              = documentsURL.appendingPathComponent(folder).appendingPathComponent(fileName)
        let fileExists          = FileManager().fileExists(atPath: fooURL.path)
        return fileExists
    }
}

extension URL {
    
    // Create folder
    static func createFolder(folderName: String) -> URL? {
        let fileManager          = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let filePath         = documentDirectory.appendingPathComponent(folderName)
            if !fileManager.fileExists(atPath: filePath.path) {
                do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                    
                    return nil
                }
            }
            return filePath
        } else {
            return nil
        }
    }
    
    // Create folder by Path
    static func createFolderWithPath(_ folderName: String,_ Path: URL?) -> URL? {
        guard let Path = Path else {
            return nil
        }
        let fileManager          = FileManager.default
        let filePath             = Path.appendingPathComponent(folderName)
        if !fileManager.fileExists(atPath: filePath.path) {
            do {
                    try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                    print(error.localizedDescription)
                    
                    return nil
            }
        }
        return filePath
    }
    
    // Create folder Loop
    func createFolderLoop(_ folderName: String) -> URL? {
        let fileManager          = FileManager.default
        let filePath         = self.appendingPathComponent(folderName)
        if !fileManager.fileExists(atPath: filePath.path) {
            do {
                try fileManager.createDirectory(atPath: filePath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
                
                return nil
            }
        }
        return filePath
    }
}

extension UIImage {
    
    // Resize Image
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // Check Size Image
    func checkSizeImage(_ name: String, fileType: String) {
        if fileType == ".png" {
            let uploadData = self.pngData()
            let array = [UInt8](uploadData!)
            let fileSizeWithUnit = ByteCountFormatter.string(fromByteCount: Int64(array.count), countStyle: .file)
            print("File \(name) size: \(fileSizeWithUnit)")
        } else {
         
        }
    }
}
