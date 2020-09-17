//
//  PhotoPickerBottomToolbar.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/4/18.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class PhotoPickerBottomToolbar: UIView {
    
    @IBOutlet weak var backgroundView: UIView!
    
    var preview: (() -> Void)?
    var send: (() -> Void)?
    var originalImage: ((PhotoPickerBottomToolbar) -> Void)?
    @IBOutlet weak var originalImageLabel: UILabel!
    
    @IBOutlet weak var previewBtn: UIButton! {
        didSet {
            self.previewBtn.isEnabled = false
        }
    }

    @IBOutlet weak var sendBtn: UIButton! {
        didSet {
            self.sendBtn.isEnabled = false
        }
    }
    
    @IBOutlet weak var originalImageView: UIImageView!

    private lazy var blurView: UIVisualEffectView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemChromeMaterial)
        } else {
            blur = UIBlurEffect(style: .light)
        }
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        self.setupSendButton()
        self.traitCollectionDidChange(nil)
        self.setupBlurView()
        self.originalImageView.image = UIImage(podAssetName: "circle_unselected_gray_image")
    }
    
    private func setupBlurView() {
        self.insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: self.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    private func setupSendButton() {
        self.sendBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    public func changeSendButtonTitle(photoStorage: PhotoStorage) {
        let title = photoStorage.selectedAssets.count > 0 ? "确定(\(photoStorage.selectedAssets.count))" : "确定"
        self.sendBtn.setTitle(title, for: .normal)
    }
    
    @IBAction func tappedSendBtn(_ sender: Any) {
        self.send?()
    }
    
    @IBAction func tappedPreviewBtn(_ sender: Any) {
        self.preview?()
    }
    
    @IBAction func tappedOriginalButton(_ sender: Any) {
        self.originalImage?(self)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 12.0, *) {
            self.originalImageLabel.textColor = self.traitCollection.userInterfaceStyle == .dark ? .white : .gray
            self.previewBtn.setTitleColor(self.traitCollection.userInterfaceStyle == .dark ? .white : .black, for: .normal)
            self.previewBtn.setTitleColor(self.traitCollection.userInterfaceStyle == .dark ? .gray : .gray, for: .disabled)
            
            self.sendBtn.setTitleColor(self.traitCollection.userInterfaceStyle == .dark ? .systemGreen : .systemGreen, for: .normal)
            self.sendBtn.setTitleColor(self.traitCollection.userInterfaceStyle == .dark ? .gray : .gray, for: .disabled)
        }
    }
}
