//
//  PreviewCVCell.swift
//  PracticeGalleryDemo
//
//  Created by Mehedi Hasan on 29/8/23.
//

import UIKit

protocol UpdatePreviewImageVC: AnyObject{
    func update()
    func popNav()
    func panToHide()
    func panBackToOriginal()
    func scrollPreventPIV(isEnabled: Bool)
}

class PreviewCVCell: UICollectionViewCell {
    
    static let identifier = "PreviewCVCell"
    
    @IBOutlet weak var previewImageScrollView: UIScrollView!
    @IBOutlet weak var previewImageView: UIImageView!
    
    let doubleTap = UITapGestureRecognizer()
    let oneTap = UITapGestureRecognizer()
    let panDown = UIPanGestureRecognizer()
    
    weak var delegate: UpdatePreviewImageVC?
    
    static func nib() -> UINib {
        return UINib(nibName: "PreviewCVCell", bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        previewImageScrollView.delegate = self
        previewImageScrollView.minimumZoomScale = 1.0
        previewImageScrollView.maximumZoomScale = 10.0
        
        previewImageScrollView.addGestureRecognizer(oneTap)
        oneTap.addTarget(self, action: #selector(oneTapGestureAction))
        oneTap.numberOfTapsRequired = 1
        
        oneTap.require(toFail: doubleTap)
        
        previewImageScrollView.addGestureRecognizer(doubleTap)
        doubleTap.addTarget(self, action: #selector(doubleTapGestureAction))
        doubleTap.numberOfTapsRequired = 2
        
        panDown.delegate = self
        previewImageScrollView.addGestureRecognizer(panDown)
        panDown.addTarget(self, action: #selector(handleDismiss))
    }
    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return previewImageView
    }

    
    var viewTranslation = CGPoint(x: 0, y: 0)
    @objc func handleDismiss(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            viewTranslation = sender.translation(in: previewImageScrollView)
            if viewTranslation.y > 30 {
                self.delegate?.scrollPreventPIV(isEnabled: false)
                self.panDown.isEnabled = true
                self.delegate?.panToHide()
            }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.previewImageScrollView.transform = CGAffineTransform(translationX: self.viewTranslation.x, y: self.viewTranslation.y)
            })
            
        case .ended:
            if viewTranslation.y < 200 {
                self.delegate?.scrollPreventPIV(isEnabled: true)
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.delegate?.panBackToOriginal()
                    self.previewImageScrollView.transform = .identity
                    self.panDown.isEnabled = false
                })
            } else {
                self.panDown.isEnabled = true
                self.delegate?.popNav()
            }
            self.panDown.isEnabled = true
            
        default:
            break
        }
    }

    
    @objc func doubleTapGestureAction(){
        
        if previewImageScrollView.zoomScale == 1.0 {
            UIView.animate(withDuration: 0.5) {
                self.previewImageScrollView.zoomScale = 2.0
            }
        }
        else {
            UIView.animate(withDuration: 0.5) {
                self.previewImageScrollView.zoomScale = 1.0
            }
        }
        
    }
    
    @objc func oneTapGestureAction(){
        
        self.delegate?.update()
    }
}

extension PreviewCVCell: UIGestureRecognizerDelegate {

    // ENABLE multiple gesture recognizer
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    
}


