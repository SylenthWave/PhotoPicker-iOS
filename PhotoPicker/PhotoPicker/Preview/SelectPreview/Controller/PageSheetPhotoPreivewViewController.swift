//
//  PageSheetPhotoPreivewViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/5/28.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

class PageSheetPhotoPreviewCell: UICollectionViewCell {
    
    var assetIdentifier: String = ""
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var selectBox: SelectBox = {
        let box = SelectBox()
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.imageView)
        self.addSubview(self.selectBox)
        self.setNeedsUpdateConstraints()
    }

    override func updateConstraints() {
        super.updateConstraints()
        NSLayoutConstraint.activate([
            self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.imageView.topAnchor.constraint(equalTo: self.topAnchor),
            self.imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            self.selectBox.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10),
            self.selectBox.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            self.selectBox.widthAnchor.constraint(equalToConstant: 25),
            self.selectBox.heightAnchor.constraint(equalToConstant: 25)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

class PageSheetPageSheetPhotoPreivewNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class PageSheetPhotoPreivewViewController: UIViewController {
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        collectionView.registerCell(PageSheetPhotoPreviewCell.self)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var collectionViewLayout: CenterForceCollectionViewLayout = {
        let layout = CenterForceCollectionViewLayout()
        return layout
    }()
    
    lazy var navbarView: PageSheetNavBarView = {
        let view = UIView.loadNib(PageSheetNavBarView.self)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.close = { [weak self] in
            guard let self = self else { return }
            self.close()
        }
        view.send = { [weak self] in
            guard let self = self else { return }
            self.close()
            NotificationCenter.default.post(name: PhotoPickerViewController.sendNotificationName, object: nil)
        }
        return view
    }()
    
    lazy var alphaView: UIView = {
        let alphaView = UIView()
        alphaView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            alphaView.backgroundColor = .systemBackground
        } else {
            alphaView.backgroundColor = .white
        }
        return alphaView
    }()
    
    lazy var blurView: UIVisualEffectView = {
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
    
    public var photoStorge: PhotoStorage
    public var datasource: [PHAsset] = []
    private var photoFetcher = PhotoFetcher()

    init(photoStorge: PhotoStorage) {
        self.photoStorge = photoStorge
        self.datasource = self.photoStorge.selectedAssets
        super.init(nibName: nil, bundle: nil)
     }

     required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.setupNavBar()
        self.layout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                alphaView.alpha = 1
            } else {
                alphaView.alpha = 0.85
            }
        }
    }
    
    private func setupNavBar() {
        self.resetNavbarView()
        if #available(iOS 13.0, *) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .close, target: self, action: #selector(close))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(podAssetName: "close_button_icon")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(close))
        }
    }
    
    private func resetNavbarView() {
        self.navbarView.titleLabel.text = "已选\(self.photoStorge.selectedAssets.count)张图片"
        self.navbarView.images = self.photoStorge.selectedAssets.map({ asset -> UIImage? in

            var image: UIImage?
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            
            asset.fetchImage(targetSize: CGSize(width: 40, height: 40), options: option, synchronousInBackground: false) { (img, info) in
                image = img
            }
            return image
        })
    }
    

    private func layout() {

        self.view.addSubview(alphaView)
        NSLayoutConstraint.activate([
            alphaView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            alphaView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            alphaView.topAnchor.constraint(equalTo: self.view.topAnchor),
            alphaView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
       
        self.view.addSubview(self.blurView)
        NSLayoutConstraint.activate([
            self.blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.blurView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.view.addSubview(self.navbarView)
        NSLayoutConstraint.activate([
            self.navbarView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.navbarView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.navbarView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.navbarView.heightAnchor.constraint(equalToConstant: 64)
        ])

        self.view.addSubview(self.collectionView)
        self.view.insertSubview(self.collectionView, belowSubview: self.navbarView)
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.navbarView.bottomAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }

    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension PageSheetPhotoPreivewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReuseCell(PageSheetPhotoPreviewCell.self, forIndexPath: indexPath)
        
        let asset = self.datasource[indexPath.row]
        cell.layer.cornerRadius = 9
        cell.clipsToBounds = true
        cell.assetIdentifier = asset.localIdentifier
        
        let size = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        
        weak var weakCell = cell
        weak var weakAsset = asset
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        asset.fetchImage(targetSize: CGSize(width: size.width * scale, height: size.height * scale), options: options) { (image, info) in
            guard weakCell?.assetIdentifier == weakAsset?.localIdentifier else { return }
            cell.imageView.image = image
        }

        if let index = self.photoStorge.selectedAssets.firstIndex(of: asset) {
            cell.selectBox.currentState = .selectedWithCount(count: Int(index + 1), animated: false)
        } else {
            cell.selectBox.currentState = .unselected
        }

        cell.selectBox.changeState = { [weak self] box in
            guard let self = self else { return }
            if box.currentState == .unselected {
                self.photoStorge.addAsset(asset)
            } else {
                self.photoStorge.removeAsset(asset)
            }
            box.currentState = box.currentState == .unselected ? .selectedWithCount(count: self.photoStorge.selectedAssets.count, animated: true) : .unselected
            self.resetNavbarView()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.datasource.count
    }

}

