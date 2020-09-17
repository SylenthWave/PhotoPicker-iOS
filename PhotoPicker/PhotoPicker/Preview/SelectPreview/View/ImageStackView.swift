//
//  ImageStackView.swift
//  PhotoPicker
//
//  Created by sylenthwave on 2020/5/28.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class ImageStackView: UIView {
    
    public var images: [UIImage?] {
        didSet {
            self.resetImageStack(images: images)
        }
    }
    private var imageViews: [UIImageView] = []
    
    init(frame: CGRect, images: [UIImage?]) {
        self.images = images
        super.init(frame: frame)
        self.resetImageStack(images: images)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetImageStack(images: [UIImage?]) {
        imageViews.forEach { $0.removeFromSuperview() }
        self.alpha = images.count == 0 ? 0 : 1
        if images.count == 0 { return }

        if images.count == 1, let image = images.first {
            // count = 1
            let imageView = UIImageView(frame: .zero)
            imageView.image = image
            self.setupImageView(imageView: imageView)
            self.imageViews.append(imageView)
            self.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 44),
                imageView.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            // count > 1
            let factor = 3
            let twoImages = images[0...1]
            for (index, image) in twoImages.reversed().enumerated() {
                
                let imageView = UIImageView(frame: .zero)
                imageView.image = image
                self.setupImageView(imageView: imageView)
                self.addSubview(imageView)
                self.imageViews.append(imageView)
                
                let offsetY = CGFloat((twoImages.count - (index + 1)) * factor)
                
                NSLayoutConstraint.activate([
                    imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -offsetY),
                    imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 44 - offsetY * 2),
                    imageView.heightAnchor.constraint(equalToConstant: 44)
                ])
            }
            
        }
        
    }
    
    private func setupImageView(imageView: UIImageView) {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
    }

}
