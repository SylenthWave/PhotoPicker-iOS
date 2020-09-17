//
//  PhotoPickerBasicCell.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/6.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: - PhotoPickerBasicCell
class PhotoPickerBasicCell: UICollectionViewCell {
    
    public var assetId: String = ""
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectBox: SelectBox!
    
    lazy var blackMaskView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.backgroundColor = UIColor.black
        view.alpha = 0.35
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public var isShowMask: Bool = false {
        didSet {
            self.blackMaskView.isHidden = !self.isShowMask
            if !self.subviews.contains(self.blackMaskView) {
                self.addSubview(self.blackMaskView)
                NSLayoutConstraint.activate([
                    self.blackMaskView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    self.blackMaskView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                    self.blackMaskView.topAnchor.constraint(equalTo: self.topAnchor),
                    self.blackMaskView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                ])
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.contentMode = .scaleAspectFill
        self.selectBox.resetSelectImagePostion = CGRect(x: 8, y: 8, width: 25, height: 25)
    }
    
    deinit {
        debugPrint("picker cell deinit")
    }

}
