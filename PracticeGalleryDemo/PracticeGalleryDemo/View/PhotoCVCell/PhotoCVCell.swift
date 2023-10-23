//
//  PhotoCVCell.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 16/8/23.
//

import UIKit

protocol DeleteItemDelegate {
    func deleteItemsFromCell(cell: PhotoCVCell)
}

class PhotoCVCell: UICollectionViewCell {

    static let identifier = "PhotoCVCell"
    var delegate: DeleteItemDelegate?
    var indexNumber = IndexPath()
    
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var btnDeleteImage: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    static func nib() -> UINib {
        return UINib(nibName: "PhotoCVCell", bundle: nil)
    }

    @IBAction func btnDeleteAction(_ sender: Any) {
        
        self.delegate?.deleteItemsFromCell(cell: self)
    }
    
}
