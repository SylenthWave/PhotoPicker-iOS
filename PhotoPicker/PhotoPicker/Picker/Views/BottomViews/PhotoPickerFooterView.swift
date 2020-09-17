//
//  PhotoPickerFooterView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/5/16.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class PhotoPickerFooterView: UICollectionReusableView {

    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.setupLabelColor()
    }
    
    func setupLabelColor() {
        if #available(iOS 12.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            self.label.textColor = isDarkMode ? .white : .black
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.setupLabelColor()
    }
}
