//
//  PhotoPickerCollectionViewVideoCell.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/1.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class PhotoPickerCollectionViewVideoCell: PhotoPickerBasicCell {
    
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectBox.resetSelectImagePostion = CGRect(x: 8, y: 8, width: 25, height: 25)
    }

}
