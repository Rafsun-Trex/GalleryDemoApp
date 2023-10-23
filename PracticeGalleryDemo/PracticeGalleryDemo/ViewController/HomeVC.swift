//
//  ViewController.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 16/8/23.
//

import UIKit
import PhotosUI
import QuickLook


class HomeVC: UIViewController {
    
    @IBOutlet weak var photoCollectionView: UICollectionView!{
        didSet{
            photoCollectionView.register(PhotoCVCell.nib(), forCellWithReuseIdentifier: PhotoCVCell.identifier)
        }
    }
    
    var imageArray = [UIImage]()
    var pImage = UIImage()
    var namesOfImages = [ImageCD]()
    var previewIndexQL = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //enable drag interactions
        photoCollectionView.dragInteractionEnabled = true
        
        //fetching coredata imagenames into  new array
        namesOfImages.removeAll()
        namesOfImages = CoreDataManager.shared.fetchDataCD()
        
        //file manager
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let folderThumb = url.appendingPathComponent("Thumb")
        
        if namesOfImages.count > 0 {
            for img in 0...namesOfImages.count - 1 {
                if let nameOfImg = namesOfImages[img].imageName {
                    let imageURL = folderThumb.appendingPathComponent(nameOfImg).appendingPathExtension("jpg")
                    if let thumbImage = UIImage(contentsOfFile: imageURL.path){
                        imageArray.append(thumbImage)
                    }
                }
                else
                {
                    print("Error in nameOfImages Array")
                }
                
            }
            
        }
        
    }
    
    
    
    @IBAction func btnImportImage(_ sender: UIBarButtonItem) {
        showActionSheet()
    }
    
    
    
}


extension HomeVC{
    func showActionSheet(){
        let actionSheet = UIAlertController(title: "Select", message: "Choose an option", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(_) in
            self.getCameraImage()
        }))
        actionSheet.addAction(UIAlertAction(title: "Photos", style: .default, handler: {(_) in
            self.phPickerAction()
        }))
        actionSheet.addAction(UIAlertAction(title: "Files", style: .default, handler: {(_) in
            self.pickFile()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    func phPickerAction() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 15
        config.filter = .images
        let photoPickerVC = PHPickerViewController(configuration: config)
        photoPickerVC.delegate = self
        self.present(photoPickerVC, animated: true)
    }
    
    func getCameraImage(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let imagePickerController = UIImagePickerController()
            imagePickerController.allowsEditing = true
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            imagePickerController.cameraCaptureMode = .photo
            self.present(imagePickerController, animated: true, completion: nil)
        } else {
            print("Source type isn't available")
        }
    }
    
    func pickFile(){
        let documentPickerController = UIDocumentPickerViewController(forOpeningContentTypes: [.png], asCopy: true)
        documentPickerController.delegate = self
        documentPickerController.allowsMultipleSelection = true
        present(documentPickerController, animated: true)
        
    }
    
    
    
}


extension HomeVC: UIDocumentPickerDelegate{
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true)
        let group = DispatchGroup()
        
        group.enter()
        
        for i in 0..<urls.count{
            let url = urls[i]
            guard let image = UIImage(contentsOfFile: url.path)
            else{
                return
            }
            
            self.imageArray.append(DocManager.shared.resizeImage(image: image, targetSize: CGSize(width: 250, height: 250)))
            let filename = UUID().uuidString
            let indexPath = IndexPath(item: self.imageArray.count - 1, section: 0)
            self.photoCollectionView.insertItems(at: [indexPath])
            
            DocManager.shared.saveImageToDocumentDirectory(imageName: filename, image: image)
            CoreDataManager.shared.coreDataSave(imageName: filename,  imagePosition: self.imageArray.count - 1)
            
            if i == urls.count-1 {
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.namesOfImages.removeAll()
            self.namesOfImages = CoreDataManager.shared.fetchDataCD()
            self.photoCollectionView.reloadData()
        }
    }
}

extension HomeVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        else{
            return
        }
        
        //self.imageArray.append(image)
        self.imageArray.append(DocManager.shared.resizeImage(image: image, targetSize: CGSize(width: 250, height: 250)))
        let filename = UUID().uuidString
        let indexPath = IndexPath(item: self.imageArray.count - 1, section: 0)
        self.photoCollectionView.insertItems(at: [indexPath])
        DocManager.shared.saveImageToDocumentDirectory(imageName: filename, image: image)
        CoreDataManager.shared.coreDataSave(imageName: filename,  imagePosition: self.imageArray.count - 1)
        
    }
    
}


extension HomeVC: PHPickerViewControllerDelegate{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        let group = DispatchGroup()
        
        group.enter()
        
        for i in 0..<results.count {
            let result = results[i]
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    let filename = UUID().uuidString
                    let orientedImage = image.fixImageOrientation()
                    DocManager.shared.saveImageToDocumentDirectory(imageName: filename, image: orientedImage)
                    CoreDataManager.shared.coreDataSave(imageName: filename,  imagePosition: self.imageArray.count - 1)
                    self.imageArray.append(DocManager.shared.resizeImage(image: image, targetSize: CGSize(width: 250, height: 250)))
                    
                    DispatchQueue.main.async {
                        // **effective way of reload collectionview - updating individual cell
                        let indexPath = IndexPath(item: self.imageArray.count - 1, section: 0)
                        self.photoCollectionView.insertItems(at: [indexPath])
                        
                    }
                    if i == results.count-1 {
                        group.leave()
                    }
                }
                
            }
        }
        group.notify(queue: .main) {
            self.namesOfImages.removeAll()
            self.namesOfImages = CoreDataManager.shared.fetchDataCD()
            self.photoCollectionView.reloadData()
        }
    }
    
}

extension HomeVC: DeleteItemDelegate{
    
    // IMAGE DELETE FUNCTION
    func deleteItemsFromCell(cell: PhotoCVCell) {
        namesOfImages = CoreDataManager.shared.fetchDataCD()
        if let indexPath = photoCollectionView.indexPath(for: cell){
            let fileManager = FileManager.default
            guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
            let folderThumb = url.appendingPathComponent("Thumb")
            let folderMain = url.appendingPathComponent("Main")
            
            if let imgName = namesOfImages[indexPath.row].imageName {
                let imageThumbURL = folderThumb.appendingPathComponent(imgName).appendingPathExtension("jpg")
                let imageMainURL = folderMain.appendingPathComponent(imgName).appendingPathExtension("jpg")
                
                let chkMain = DocManager.shared.deleteImageFromDocumentDirectory(fileURL: imageMainURL)
                let chkThumb = DocManager.shared.deleteImageFromDocumentDirectory(fileURL: imageThumbURL)
                
                if(chkMain == 1 && chkThumb == 1) {
                    imageArray.remove(at: indexPath.row)
                    let deleteItem = namesOfImages[indexPath.row]
                    CoreDataManager.shared.deleteImageName(image: deleteItem)
                    namesOfImages.remove(at: indexPath.row)
                    
                    // RELOAD collectionview
                    self.photoCollectionView.deleteItems(at: [indexPath])
                }
            }
        }
    }
}

extension HomeVC: UpdateMainDelegate{
    
    // UPDATE HomeVC
    func updateItemForCell(indexPath: IndexPath) {
        
        imageArray.remove(at: indexPath.row)
        photoCollectionView.deleteItems(at: [indexPath])
        namesOfImages.remove(at: indexPath.row)
    }
}

extension HomeVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("ImageArray count \(imageArray.count)")
        return imageArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCVCell", for: indexPath) as? PhotoCVCell else {
            return UICollectionViewCell()
        }
        cell.photoImageView.image = imageArray[indexPath.row]
        
        // Getting INDEX of cell
        cell.indexNumber = indexPath
        cell.delegate = self
        return cell
    }
    
}


extension HomeVC: UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        print("from: \(sourceIndexPath.item) to: \(destinationIndexPath.item)")
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected item: \(indexPath.row)")
        namesOfImages = CoreDataManager.shared.fetchDataCD()
        let storyBoard = UIStoryboard(name: "Main", bundle:nil)
        let imageVC = storyBoard.instantiateViewController(identifier: "ImageShowVC") as! PreviewImageVC
        
        var imageName = ""
        if let jpgImgName = namesOfImages[indexPath.row].imageName {
            imageName = jpgImgName + ".jpg"
            //previewIndexQL = indexPath.row
        }
        
        imageVC.image = DocManager.shared.getImageFromMainDD(name: imageName)
        imageVC.delegate = self
        imageVC.selectedCellIndex = indexPath.row
        
//        let previewController = QLPreviewController()
//        previewController.dataSource = self
//        previewController.delegate = self
//        previewController.currentPreviewItemIndex = indexPath.row
//        self.present(previewController, animated: true, completion: nil)
        
        
        imageVC.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(imageVC, animated: true)

    }
}

//extension HomeVC: QLPreviewControllerDataSource{
//    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
//        return imageArray.count
//    }
//
//    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
//        let fileManager = FileManager.default
//        let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
//        let folderMain = url!.appendingPathComponent("Main")
//        let mainUrl = folderMain.appendingPathComponent(namesOfImages[index].imageName!).appendingPathExtension("jpg")
//        let URL = mainUrl
//        return URL as QLPreviewItem
//    }
//
//}

//extension HomeVC: QLPreviewControllerDelegate{
//    func previewControllerWillDismiss(_ controller: QLPreviewController) {
//        let storyBoard = UIStoryboard(name: "Main", bundle:nil)
//        let imageVC = storyBoard.instantiateViewController(identifier: "ImageShowVC") as! PreviewImageVC
//        imageVC.navigationController?.popViewController(animated: true)
//    }
//}


extension HomeVC: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.size.width/3 - 2, height: collectionView.frame.size.height/5 - 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}

extension HomeVC: UICollectionViewDragDelegate{
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        pImage = imageArray[indexPath.row]
        let item = pImage
        let itemProvider = NSItemProvider.init(object: pImage as NSItemProviderWriting)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        // right place to hide delete btn or other works while dragging
    }
    
}

extension HomeVC: UICollectionViewDropDelegate{
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        let proposal = UICollectionViewDropProposal(operation: UIDropOperation.move, intent: UICollectionViewDropProposal.Intent.insertAtDestinationIndexPath)
        return proposal
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        }
        else {
            let row = collectionView.numberOfItems(inSection: 0)
            destinationIndexPath = IndexPath(item: row - 1, section: 0)
        }
        
        if coordinator.proposal.operation == .move {
            if let item = coordinator.items.first,
               let sourceIndexPath = item.sourceIndexPath
            {
                collectionView.performBatchUpdates({
                    
                    // UPDATE OBJECT ARRAY
                    self.imageArray.remove(at: sourceIndexPath.item)
                    self.imageArray.insert(pImage, at: destinationIndexPath.item)
                    debugPrint("Source : \(sourceIndexPath.item)  Destination : \(destinationIndexPath.item)")
                    
                    
                    // FETCH to avoid crush on performing drag action for first time
                    self.namesOfImages = CoreDataManager.shared.fetchDataCD()
                    let dragImageName = namesOfImages[sourceIndexPath.item].imageName
                    
                    var source = sourceIndexPath.item
                    let destination = destinationIndexPath.item
                    
                    //UPDATE IMAGE POSITION
                    
                    if(destination < source)
                    {
                        while (destination < source ) {
                            self.namesOfImages[source].imageName = self.namesOfImages[source - 1].imageName
                            source = source - 1
                            
                        }
                        self.namesOfImages[source].imageName = dragImageName
                        CoreDataManager.shared.saveInCoreData()
                    }
                    else{
                        while (source < destination ) {
                            self.namesOfImages[source].imageName = self.namesOfImages[source + 1].imageName
                            source = source + 1
                        }
                        self.namesOfImages[source].imageName = dragImageName
                        CoreDataManager.shared.saveInCoreData()
                    }
                    
                    
                    
                    // UPDATE collectionview
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                    
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
        }
    }
}

extension UIImage {
    func fixImageOrientation() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        self.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
