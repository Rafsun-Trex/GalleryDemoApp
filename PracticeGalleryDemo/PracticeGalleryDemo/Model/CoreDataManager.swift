//
//  CoreDataManager.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 16/8/23.
//

import Foundation
import UIKit
import CoreData


class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // SAVE at anytime
    
    func saveInCoreData(){
//        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        do{
            try self.context.save()
            print("CoreData Updated")
            
        } catch {
            print("Error saving to CoreData")
        }
    }
    
    
    // SAVE imagenames in coredata
    
    func coreDataSave(imageName: String, imagePosition: Int){
        DispatchQueue.main.async {
            
            let imageCD = ImageCD(context: self.context)
            imageCD.imageName = imageName
            imageCD.imagePosition = Int64(truncatingIfNeeded: imagePosition)
            
            print("Image name: \(imageCD.imageName ?? " ") saved in CoreData")
            self.saveInCoreData()

        }
    }

    
    // FETCH imagenames from coredata
    
    func fetchDataCD() -> [ImageCD]{
        var images: [ImageCD] = []
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let request = ImageCD.fetchRequest() as NSFetchRequest<ImageCD>
        do{
            images = try context.fetch(request)
            
        } catch {
            print("Fetch error CoreData")
        }
        
        return images
    }
    
    
    // DELETE from coredata
    
    func deleteImageName(image: ImageCD) {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            context.delete(image)
            print("Deleted from CoreData")
            saveInCoreData()
        }
    
    
}
