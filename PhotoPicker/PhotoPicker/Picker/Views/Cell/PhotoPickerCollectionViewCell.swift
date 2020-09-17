//
//  PhotoPickerCollectionViewCell.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/2/13.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class PhotoPickerCollectionViewCell: PhotoPickerBasicCell {
    
    var num: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectBox.resetSelectImagePostion = CGRect(x: 8, y: 8, width: 25, height: 25)
    }
}
