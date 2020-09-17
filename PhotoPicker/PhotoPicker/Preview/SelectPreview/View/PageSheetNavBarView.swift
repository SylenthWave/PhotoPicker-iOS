//
//  PageSheetNavBarView.swift
//  Photofetcher
//
//  Created by SylenthWave on 2020/5/28.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: - Life
class PageSheetNavBarView: UIView {
    
    public var close: (() -> Void)?
    public var send: (() -> Void)?
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    public var images: [UIImage?] = [] {
        willSet {
            self.imageStackView.images = newValue
        }
    }
    
    private lazy var blurView: UIVisualEffectView = {
        let blur: UIBlurEffect
        if #available(iOS 13.0, *) {
            blur = UIBlurEffect(style: .systemThickMaterial)
        } else {
            blur = UIBlurEffect(style: .light)
        }
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    @IBOutlet weak var imageBox: UIView!
    
    private lazy var imageStackView: ImageStackView = {
        let view = ImageStackView(frame: .zero, images: [])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        self.setupBlurView()
        self.setupImageView()
        self.handleTraitCollectionChange()
    }
    
    @IBAction func close(_ sender: Any) {
        self.close?()
    }
    
    @IBAction func send(_ sender: Any) {
        self.send?()
    }
    
    private func setupImageView() {
        imageBox.addSubview(imageStackView)
        NSLayoutConstraint.activate([
            imageStackView.widthAnchor.constraint(equalTo: imageView.widthAnchor),
            imageStackView.heightAnchor.constraint(equalTo: imageView.heightAnchor),
            imageStackView.centerYAnchor.constraint(equalTo: imageBox.centerYAnchor),
            imageStackView.centerXAnchor.constraint(equalTo: imageBox.centerXAnchor)
        ])
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

}

// MARK: - Dark Mode
extension PageSheetNavBarView {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.handleTraitCollectionChange()
    }
    
    func handleTraitCollectionChange() {
        if #available(iOS 12.0, *) {
            switch self.traitCollection.userInterfaceStyle {
            case .dark:
                self.lineView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
            default:
                self.lineView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
            }
        }
    }
}
