//
//  ImageShowVC.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 28/8/23.
//

import UIKit

protocol UpdateMainDelegate: AnyObject{
    func updateItemForCell(indexPath: IndexPath)
}

class PreviewImageVC: UIViewController {
    
    var fetchedImages = [ImageCD]()
    var imageArrayMain = [UIImage]()
    var imageArrayThumb = [UIImage]()
    
    var previousSelected : IndexPath?
    var currentSelected : Int?
    
    var image: UIImage?
    var selectedCellIndex: Int?
    var isThisViewLoaded: Bool = false
    var isTappedPreviewCV: Bool = true
    
    
    weak var delegate:  UpdateMainDelegate?
    
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBOutlet weak var previewCollectionView: UICollectionView!{
        didSet{
            previewCollectionView.register(PreviewCVCell.nib(), forCellWithReuseIdentifier: PreviewCVCell.identifier)
        }
    }
    
    @IBOutlet weak var previewMiniCollectionView: UICollectionView!{
        didSet{
            previewMiniCollectionView.register(PreviewMiniCVCell.nib(), forCellWithReuseIdentifier: PreviewMiniCVCell.identifier)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Navigation title
        self.navigationItem.title = "Preview"
        self.navigationController?.navigationBar.backgroundColor = .white
        
        //fetching coredata imagenames into  new array
        fetchedImages.removeAll()
        fetchedImages = CoreDataManager.shared.fetchDataCD()
        
        
        //file manager
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let folderMain = url.appendingPathComponent("Main")
        let folderThumb = url.appendingPathComponent("Thumb")
        
        if fetchedImages.count > 0 {
            for img in 0...fetchedImages.count - 1 {
                if let nameOfImg = fetchedImages[img].imageName {
                    
                    let imageURLMain = folderMain.appendingPathComponent(nameOfImg).appendingPathExtension("jpg")
                    if let mainImage = UIImage(contentsOfFile: imageURLMain.path){
                        imageArrayMain.append(mainImage)
                    }
                    
                    let imageURLThumb = folderThumb.appendingPathComponent(nameOfImg).appendingPathExtension("jpg")
                    if let thumbImage = UIImage(contentsOfFile: imageURLThumb.path){
                        imageArrayThumb.append(thumbImage)
                    }
                }
            }
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        currentSelected = selectedCellIndex
        guard let crnSlct = currentSelected else {return}
        if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: crnSlct, section: 0)) as? PreviewMiniCVCell{
            cell.setSelectedCellUI(isSelect: true)
            previousSelected = IndexPath(row: crnSlct, section: 0)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !isThisViewLoaded {
            isThisViewLoaded = true
            DispatchQueue.main.async {
                if let idx = self.selectedCellIndex {
                    let indexPath = IndexPath(item: idx, section: 0)
                    
                    // PreviewCollectionView
                    self.previewCollectionView.isPagingEnabled = false
                    self.previewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                    self.previewCollectionView.isPagingEnabled = true
                    
                    self.previewMiniCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                }
                
            }
        }
    }
    
    
    
    @IBAction func btnShareToolBarAction(_ sender: Any) {
        print("Share option will be implemented..")
    }
    
    
    @IBAction func btnDeleteToolBarAction(_ sender: Any) {

        var newIndex = IndexPath()
        let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let testIndexPath = previewCollectionView.indexPathForItem(at: visiblePoint) {
            newIndex = testIndexPath
        }
        
            if self.imageArrayMain.count == 1 {
                self.deleteItemsFromCell(indexPath: newIndex)
                self.delegate?.updateItemForCell(indexPath: newIndex)
                self.navigationController?.popViewController(animated: true)
            }
            else{
                self.deleteItemsFromCell(indexPath: newIndex)
                self.delegate?.updateItemForCell(indexPath: newIndex)
            }
        
        guard let myNewCell = self.previewCollectionView.visibleCells.last else {return}
        if let newCellIndex = self.previewCollectionView.indexPath(for: myNewCell){
            if let cell = self.previewMiniCollectionView.cellForItem(at: newCellIndex) as? PreviewMiniCVCell{
                cell.setSelectedCellUI(isSelect: true)
                currentSelected = newCellIndex.row
                previousSelected = newCellIndex
            }
        }
    }
    
}


extension PreviewImageVC {
    
    // IMAGE DELETE FUNCTION
    func deleteItemsFromCell(indexPath: IndexPath) {
        
        fetchedImages = CoreDataManager.shared.fetchDataCD()
        let fileManager = FileManager.default
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return}
        let folderThumb = url.appendingPathComponent("Thumb")
        let folderMain = url.appendingPathComponent("Main")
        
        
        if let imgName = fetchedImages[indexPath.row].imageName {
            let imageThumbURL = folderThumb.appendingPathComponent(imgName).appendingPathExtension("jpg")
            let imageMainURL = folderMain.appendingPathComponent(imgName).appendingPathExtension("jpg")
            
            let chkMain = DocManager.shared.deleteImageFromDocumentDirectory(fileURL: imageMainURL)
            let chkThumb = DocManager.shared.deleteImageFromDocumentDirectory(fileURL: imageThumbURL)
            
            if(chkMain == 1 && chkThumb == 1) {
                
                
                // DELETE images from image array
                imageArrayMain.remove(at: indexPath.row)
                imageArrayThumb.remove(at: indexPath.row)
                
                let deleteItem = fetchedImages[indexPath.row]
                CoreDataManager.shared.deleteImageName(image: deleteItem)
                fetchedImages.remove(at: indexPath.row)
                
                // DELETE From collectionview
                
                UIView.performWithoutAnimation {
                    self.previewCollectionView.deleteItems(at: [indexPath])
                    self.previewMiniCollectionView.deleteItems(at: [indexPath])
                }
                
                
            }
            
        }
    }
}

extension PreviewImageVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.previewCollectionView {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewCVCell", for: indexPath) as? PreviewCVCell else {
                return UICollectionViewCell()
            }
            cell.previewImageView.image = imageArrayMain[indexPath.row]
            cell.delegate = self
            return cell
        }
        
        else
        {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PreviewMiniCVCell", for: indexPath) as? PreviewMiniCVCell else {
                return UICollectionViewCell()
            }
            cell.setSelectedCellUI(isSelect: false)
            cell.previewMiniImageView.image = imageArrayThumb[indexPath.row]
            return cell
        }
    }
}

extension PreviewImageVC: UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        currentSelected = indexPath.row
        
        if collectionView == previewCollectionView {
            print("Selected PreviewCV : \(indexPath.row)")
            
            
            self.previewMiniCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            
            if let cSelect = currentSelected{
                if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(item: cSelect, section: 0)) as? PreviewMiniCVCell{
                    cell.setSelectedCellUI(isSelect: true)
                }
            }
        }
        
        else{
            print("Selected PreviewMiniCV : \(indexPath.row)")
            
            self.previewMiniCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
            //MARK: PushViewController for NavigationController always gives first element for scrollToItemAt got FIXED with paging
            self.previewCollectionView.isPagingEnabled = false
            self.previewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            self.previewCollectionView.isPagingEnabled = true
            
            if let cSelect = currentSelected{
                if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(item: cSelect, section: 0)) as? PreviewMiniCVCell{
                    cell.setSelectedCellUI(isSelect: true)
                }
            }
        }
        
        if let preSelect = previousSelected{
            if preSelect.row == currentSelected{
                if let cell = self.previewMiniCollectionView.cellForItem(at: preSelect) as? PreviewMiniCVCell{
                    cell.setSelectedCellUI(isSelect: true)
                }
            }
            
            else{
                if let cell = self.previewMiniCollectionView.cellForItem(at: preSelect) as? PreviewMiniCVCell{
                    cell.setSelectedCellUI(isSelect: false)
                }
            }
            
        }
        previousSelected = indexPath
    }
}


extension PreviewImageVC {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == previewCollectionView {
            currentSelected = indexPath.row
            
            self.previewMiniCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            
            if let cSelect = currentSelected{
                if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: cSelect, section: 0)) as? PreviewMiniCVCell{
                    cell.setSelectedCellUI(isSelect: true)
                }
                if let preSelect = previousSelected{
                    if let cell = self.previewMiniCollectionView.cellForItem(at: preSelect) as? PreviewMiniCVCell{
                        cell.setSelectedCellUI(isSelect: false)
                    }
                }
            }
            previousSelected = indexPath
            if currentSelected == previousSelected?.row {
                if let cSelect = currentSelected{
                    if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: cSelect, section: 0)) as? PreviewMiniCVCell{
                        cell.setSelectedCellUI(isSelect: true)
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if scrollView == previewCollectionView {
            
                var myIndex = IndexPath()
                let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
                let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
                if let testIndexPath = previewCollectionView.indexPathForItem(at: visiblePoint) {
                    currentSelected = testIndexPath.row
                    myIndex = testIndexPath
                }
            
                self.previewMiniCollectionView.scrollToItem(at: myIndex, at: .centeredHorizontally, animated: true)
                
                if let cSelect = currentSelected{
                    if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: cSelect, section: 0)) as? PreviewMiniCVCell{
                        cell.setSelectedCellUI(isSelect: true)
                    }
                    if let preSelect = previousSelected{
                        if let cell = self.previewMiniCollectionView.cellForItem(at: preSelect) as? PreviewMiniCVCell{
                            cell.setSelectedCellUI(isSelect: false)
                        }
                    }
                    previousSelected = myIndex
                }
            
            if currentSelected == previousSelected?.row {
                if let cSelect = currentSelected{
                    if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: cSelect, section: 0)) as? PreviewMiniCVCell{
                        cell.setSelectedCellUI(isSelect: true)
                    }
                }
            }
        }
        
        else {
                
                var myIndex = IndexPath()
                let visibleRect = CGRect(origin: previewCollectionView.contentOffset, size: previewCollectionView.bounds.size)
                let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
                if let testIndexPath = previewCollectionView.indexPathForItem(at: visiblePoint) {
                    currentSelected = testIndexPath.row
                    myIndex = testIndexPath
                }

                currentSelected = myIndex.row
                
                if let cSelect = currentSelected{
                    if let cell = self.previewMiniCollectionView.cellForItem(at: IndexPath(row: cSelect, section: 0)) as? PreviewMiniCVCell{
                        cell.setSelectedCellUI(isSelect: true)
                    }
                    previousSelected = myIndex
                }
        }
    }
    
}

extension PreviewImageVC: UICollectionViewDelegateFlowLayout{
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == previewCollectionView {
//            return CGSize(width: collectionView.frame.size.width, height: collectionView.frame.size.height)
            let viewControllerSize = self.view.frame.size
            return viewControllerSize
            
        }
        else {
            return CGSize(width: collectionView.frame.size.width / 9 - 1, height: collectionView.frame.size.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        if collectionView == previewCollectionView {
            return 0
        }
        else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == previewCollectionView {
            return 0
        }
        else {
            return 1
        }
    }
}

extension PreviewImageVC: UpdatePreviewImageVC {
    
    func scrollPreventPIV(isEnabled: Bool){
        previewCollectionView.isScrollEnabled = isEnabled
        previewMiniCollectionView.isScrollEnabled = isEnabled
    }
    
    func panToHide(){
        isTappedPreviewCV = false
        previewMiniCollectionView.isHidden = true
        toolBar.isHidden = true
        previewCollectionView.backgroundColor = .white
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = true
    }
    
    func panBackToOriginal(){
        previewMiniCollectionView.isHidden = false
        toolBar.isHidden = false
        previewCollectionView.backgroundColor = .white
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
    }
    
    func popNav() {
        isTappedPreviewCV = false
        previewMiniCollectionView.isHidden = false
        toolBar.isHidden = false
        previewCollectionView.backgroundColor = .white
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
        //self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
    
//            MARK: To fix the weird jump, need to do contentOffSet, contentInSet work (hint)link:
//            https://stackoverflow.com/questions/2926914/navigation-bar-show-hide/2927038#2927038
    
    func update() {
        if isTappedPreviewCV == true {
            isTappedPreviewCV = false
            previewMiniCollectionView.isHidden = true
            toolBar.isHidden = true
            previewCollectionView.backgroundColor = .black
            view.backgroundColor = .black
            navigationController?.navigationBar.isHidden = true
        }
        else {
            isTappedPreviewCV = true
            previewMiniCollectionView.isHidden = false
            toolBar.isHidden = false
            previewCollectionView.backgroundColor = .white
            view.backgroundColor = .white
            navigationController?.navigationBar.isHidden = false
        }
    }
}

extension PreviewCVCell: UIScrollViewDelegate{
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        print("didScroll")
    }
}
