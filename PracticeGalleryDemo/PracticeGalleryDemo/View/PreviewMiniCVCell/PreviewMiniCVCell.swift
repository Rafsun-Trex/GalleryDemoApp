//
//  PreviewMiniCVCell.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 31/8/23.
//

import UIKit

class PreviewMiniCVCell: UICollectionViewCell {

    static let identifier = "PreviewMiniCVCell"
    static func nib() -> UINib {
        return UINib(nibName: "PreviewMiniCVCell", bundle: nil)
    }
    
    @IBOutlet weak var previewMiniImageView: UIImageView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    public func setSelectedCellUI(isSelect: Bool) {
        if isSelect {
            DispatchQueue.main.async {
                self.layer.borderColor = UIColor.green.cgColor
                self.layer.borderWidth = 5.0
            }
           
        }else {
            DispatchQueue.main.async {
                self.layer.borderColor = UIColor.clear.cgColor
                self.layer.borderWidth = 0.0
            }
        }
    }
}
