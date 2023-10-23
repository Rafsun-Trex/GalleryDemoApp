//
//  DocManager.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 16/8/23.
//

import Foundation
import UIKit


class DocManager {
    
    static let shared = DocManager()
    
    // SAVE image to DocumentDirectory
    
    func saveImageToDocumentDirectory(imageName: String, image: UIImage){
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let folderMain = url.appendingPathComponent("Main")
        let folderThumb = url.appendingPathComponent("Thumb")
        
        if !fileManager.fileExists(atPath: folderMain.path) && !fileManager.fileExists(atPath: folderThumb.path){
            do {
                try fileManager.createDirectory(at: folderMain, withIntermediateDirectories: true)
                try fileManager.createDirectory(at: folderThumb, withIntermediateDirectories: true)
            }
            catch {
                print(error)
            }
            
        }
        
        let mainUrl = folderMain.appendingPathComponent(imageName).appendingPathExtension("jpg")
        let thumbUrl = folderThumb.appendingPathComponent(imageName).appendingPathExtension("jpg")
        
        if let mainData = image.jpegData(compressionQuality: 1.0) {
            do{
                try mainData.write(to: mainUrl)
                print("Saved in Main DD")
            } catch {
                print("Error saving in Main DD")
            }
        }
        
        let thumbImage = resizeImage(image: image, targetSize: CGSize(width: 250, height: 250))
        if let thumbData = thumbImage.jpegData(compressionQuality: 1.0) {
            do{
                try thumbData.write(to: thumbUrl)
                print("Saved in Thumb DD")
            } catch {
                print("Error saving in Thumb DD")
            }
        }
    }

    func getImageFromMainDD(name: String) -> UIImage {
        var image: UIImage!
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderMain = url.appendingPathComponent("Main")
        let imageURL = folderMain.appendingPathComponent(name)
        if fileManager.fileExists(atPath: imageURL.path) {
            image = UIImage(contentsOfFile: imageURL.path)!
        } else {
            print("Not found at \(imageURL.path)")
        }
        return image
    }

    
    // DELETE image from Document directory
    
    func deleteImageFromDocumentDirectory(fileURL: URL) -> Int{
        var flag = 0
        let fileManager = FileManager.default
        do{
            try fileManager.removeItem(at: fileURL)
            flag = 1
            print("Image has been deleted from DocDirectory")
        } catch {
            print(error)
        }
        return flag
    }
    
    
    
    //MARK: Image Size Change
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(origin: .zero, size: newSize)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
}


