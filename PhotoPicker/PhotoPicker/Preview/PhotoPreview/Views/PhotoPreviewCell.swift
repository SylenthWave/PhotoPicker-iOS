//
//  PhotoPreviewCell.swift
//  Photofetcher
//
//  Created by SylenthWave on 2020/3/6.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class PhotoPreviewCell: UICollectionViewCell {
    
    public var assetIdentifier: String = ""
    public var progressTopConstraint: NSLayoutConstraint!
    public var image: UIImage? {
        didSet {
            self.zoomableImageView.imageView.image = image
            if let image = self.image {
                let size = self.aspectFitSizeForScreenSize(size: image.size)
                let top = UIScreen.main.bounds.height/2 + size.height/2 - 45
                self.progressTopConstraint.constant = top
            }
        }
    }
    private(set) lazy var zoomableImageView: ZoomableImageView = {
        let view = ZoomableImageView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private(set) lazy var progressView: RoundProgressView = {
        let view = RoundProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.zoomableImageView)
        NSLayoutConstraint.activate([
            self.zoomableImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.zoomableImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.zoomableImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.zoomableImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        
        self.zoomableImageView.imageView.addSubview(self.progressView)
        self.progressTopConstraint = self.progressView.topAnchor.constraint(equalTo: self.zoomableImageView.imageView.topAnchor, constant: 0)
        NSLayoutConstraint.activate([
            self.progressView.trailingAnchor.constraint(equalTo: self.zoomableImageView.imageView.trailingAnchor, constant: -15),
            self.progressTopConstraint,
            self.progressView.widthAnchor.constraint(equalToConstant: 30),
            self.progressView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        self.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        debugPrint("preview cell deinit")
    }
    
    func aspectFitSizeForScreenSize(size: CGSize) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let ratioHeight = (screenWidth * size.height) / size.width
        return CGSize(width: screenWidth, height: ratioHeight)
    }
    
}

// Parallax
extension PhotoPreviewCell {

     override func layoutSubviews () {
        super.layoutSubviews()
        let path = UIBezierPath (rect: self.bounds)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        layer.mask = shapeLayer
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        guard let attributes = layoutAttributes as? ParallaxLayoutAttributes else { return }
        
        let value = -((attributes.parallaxValue ?? 0) * 0.3 * bounds.width)
        print(value)
        print(attributes.indexPath.row)

        self.zoomableImageView.transform = CGAffineTransform(translationX: value, y: 0)
    }
}
