//
//  PhotoPreviewViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/5.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

class ParallaxLayoutAttributes: UICollectionViewLayoutAttributes {
    var parallaxValue: CGFloat?
}

extension ParallaxLayoutAttributes {
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! ParallaxLayoutAttributes
        copy.parallaxValue = self.parallaxValue
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        let attributes = object as? ParallaxLayoutAttributes
        if attributes?.parallaxValue != parallaxValue {
            return false
        }
        return super.isEqual(object)
    }
   
}

class ParallaxLayout: UICollectionViewFlowLayout {
    
    var offsetBetweenCells: CGFloat = 44
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override class var layoutAttributesClass: AnyClass {
        return ParallaxLayoutAttributes.self
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return super.layoutAttributesForElements(in: rect)?
            .compactMap { $0.copy() as? ParallaxLayoutAttributes }
            .compactMap(prepareAttributes)
    }
    
    private func prepareAttributes(attributes: ParallaxLayoutAttributes) -> ParallaxLayoutAttributes {
        guard let collectionView = self.collectionView else {return attributes}
        //1. get current attributes
        let minX = attributes.frame.minX
        let offsetX = collectionView.contentOffset.x
        
        let distance = minX - offsetX
        
        let delta = distance / attributes.bounds.width
        if delta >= 1 {
            attributes.transform = .identity
            attributes.parallaxValue = nil
        } else if delta <= -1 {
            attributes.transform = .identity
            attributes.parallaxValue = nil
        } else {
            attributes.transform = CGAffineTransform(translationX: offsetBetweenCells * delta, y: 0)
            attributes.parallaxValue = delta / 2
        }
        return attributes
    }
}

//MARK: - PhotoPreviewViewController
class PhotoPreviewViewController: UIViewController {

    public var didPageItem: ((Int) -> Void)?
    public var shouldPop: ((PhotoPreviewViewController) -> Void)?
    public var delegate: PhotoPreviewViewControllerDelegate?
    public var needHiddenCell: Bool = true
    public var shouldReverse: Bool = false
    public var currentActionCell: UICollectionViewCell? {
        let indexPath = IndexPath(item: self.photoStorge.offsetIndex, section: 0)
        return self.collectionView.cellForItem(at: indexPath)
    }
    private(set) var photoStorge: PhotoStorage
    private(set) var representationView: RepresentationView?
    private var hasOffsetIndex: Bool = false
    private var previousContentOffset: CGPoint = .zero
    private var cacheImage = NSCache<NSString, UIImage>()
    public var photoFetcher = PhotoFetcher()

    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        collectionView.registerCell(PhotoPreviewCell.self)
        collectionView.registerCell(PhotoPreviewVideoCell.self)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor.black
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        return collectionView
    }()
    
    private lazy var collectionViewLayout: ParallaxLayout = {
        let layout = ParallaxLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: self.view.bounds.width, height: self.view.bounds.height)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }()
    
    private lazy var clickTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(hiddenRepresentationView))
        gesture.numberOfTapsRequired = 1
        return gesture
    }()
    
    private var imageFetcher = ImageFetcher()
    
    init(photoStorge: PhotoStorage) {
        self.photoStorge = photoStorge
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("preview deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        self.setupCollectionView()
        self.setupTapGesture()
        self.setupRepresentationView()
        self.setupNavigation()
        try! AVAudioSession.sharedInstance().setCategory(.playback, options: [])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.hasOffsetIndex {
            self.scrollToOffsetIndex()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

//MARK: - Setup
extension PhotoPreviewViewController {
    
    private func setupCollectionView() {
        self.view.addSubview(self.collectionView)
        NSLayoutConstraint.activate([
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    private func setupTapGesture() {
        // click hidden
        self.collectionView.addGestureRecognizer(self.clickTapGesture)
    }
    
    private func setupNavigation() {
        // hidden navbar
        if self.representationView != nil {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    private func setupRepresentationView() {
        self.representationView = self.delegate?.representationView()
        self.representationView?.previewViewController = self
        self.representationView?.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        self.representationView?.photoStorage = self.photoStorge
        self.representationView?.currentCount = self.calculateCurrentCount()
        self.representationView?.didUpdatePhotoStroage(photoStorage: self.photoStorge)
        guard let representationView = self.representationView else { return }
        guard let window = UIApplication.shared.keyWindow else { return }
        window.addSubview(representationView)
        NSLayoutConstraint.activate([
            representationView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            representationView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            representationView.topAnchor.constraint(equalTo: window.topAnchor),
            representationView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
    }
    
}

//MARK: - Private Methods
extension PhotoPreviewViewController {
    
    @objc private func back() {
        
        // cancel all downloading request
        photoFetcher.cancelAllRequest()
        
        self.representationView?.removeFromSuperview()
        guard let shouldPop = self.shouldPop else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        shouldPop(self)
    }
    
    private func scrollToOffsetIndex() {
        let offsetIdx = self.photoStorge.offsetIndex
        let indexPath = IndexPath(item: offsetIdx, section: 0)
        self.collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
        self.previousContentOffset = self.collectionView.contentOffset
    }
    
    @objc private func hiddenRepresentationView() {
        if self.representationView != nil {
            guard let representationView = self.representationView else { return }
            let isHidden = representationView.isHidden
            representationView.isHidden = !isHidden
            self.setNeedsStatusBarAppearanceUpdate()
        } else {
            guard let navbar = self.navigationController?.navigationBar else { return }
            let needHidden = !navbar.isHidden
            self.navigationController?.setNavigationBarHidden(needHidden, animated: false)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return representationView?.isHidden ?? false
    }

    private func calculateCurrentCount() -> Int {
        if !self.shouldReverse {
            return self.photoStorge.offsetIndex + 1
        } else {
            return self.photoStorge.album.collectionResults.count - self.photoStorge.offsetIndex
        }
    }
    
    private func assetAtIndex(index: Int) -> PHAsset {
        var idx = index
        if !self.shouldReverse {
            idx = self.photoStorge.album.collectionResults.count - index - 1
        }
        return self.photoStorge.album.collectionResults[idx]
    }
}

//MARK: - CollectionView Delegate & Datasource
extension PhotoPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let asset = self.assetAtIndex(index: indexPath.row)
        switch asset.mediaType {
        case .image:
            let cell = collectionView.dequeueReuseCell(PhotoPreviewCell.self, forIndexPath: indexPath)
            
            // set up
            cell.assetIdentifier = asset.localIdentifier
            cell.progressView.isHidden = true
            self.clickTapGesture.require(toFail: cell.zoomableImageView.doubleClickTapGesture)

            // fetch normal size image or large size image
            if let image = self.cacheImage.object(forKey: NSString(string: asset.localIdentifier)) {
                if cell.assetIdentifier == asset.localIdentifier {
                    cell.image = image
                }
            } else if let image = self.imageFetcher.fetchedData(for: asset.localIdentifier)  {
                if cell.assetIdentifier == asset.localIdentifier {
                    cell.image = image
                }
            } else {
                self.fetchNormalImageWithAsset(asset, progressHandler: { (progress, error) in
                    cell.progressView.isHidden = progress >= 1
                    cell.progressView.progress = progress >= 1 ? 0 : CGFloat(progress)
                }) { image in
                    if cell.assetIdentifier == asset.localIdentifier {
                        cell.image = image
                    }
                }
            }

            // need hidden cell when transitioning
            if self.photoStorge.offsetIndex == indexPath.row {
                cell.zoomableImageView.isHidden = self.needHiddenCell
            } else {
                cell.zoomableImageView.isHidden = false
            }

            // hidden presentation view
            cell.zoomableImageView.willZoom = { [weak self] in
                guard let self = self else { return }
                
                self.representationView?.alpha = 1.0

                let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
                    self.representationView?.alpha = 0
                }
                animator.addCompletion { _ in
                    self.representationView?.isHidden = true
                    self.setNeedsStatusBarAppearanceUpdate()
                    self.representationView?.alpha = 1.0
                }
                animator.startAnimation()
            }

            // load large image
            weak var weakCell = cell
            cell.zoomableImageView.didZoom = { [weak self] in
                guard let self = self else { return }

                self.fetchLargeImageWithAsset(asset, progressHandler: { (progress, error) in
                    weakCell?.progressView.isHidden = progress >= 1
                    weakCell?.progressView.progress = progress >= 1 ? 0 : CGFloat(progress)
                }) { image in
                    if weakCell?.assetIdentifier == asset.localIdentifier {
                        weakCell?.zoomableImageView.imageView.image = image
                    }
                }
            }
            
            return cell
        case .video:
            let cell = collectionView.dequeueReuseCell(PhotoPreviewVideoCell.self, forIndexPath: indexPath)
            cell.assetIdentifier = asset.localIdentifier
            asset.fetchVideo { avasset, info in
                guard cell.assetIdentifier == asset.localIdentifier else { return }
                guard let avAsset = avasset else { return }
                DispatchQueue.main.async {
                    cell.playerView.setupWithAsset(asset: avAsset)
                }
            }

            cell.playerView.playDidFinish = { [weak self] in
                guard let self = self else { return }
                let wapperView = (self.representationView as! PhotoPreviewRepresentationWapperView)
                wapperView.videoControlView.videoState = .pausing
            }
            
            if self.photoStorge.offsetIndex == indexPath.row {
                cell.playerView.isHidden = self.needHiddenCell
            } else {
                cell.playerView.isHidden = false
            }
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoStorge.album.collectionResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if !self.hasOffsetIndex {
            self.hasOffsetIndex = true
            // the first time show current cell
            guard let wapperView = self.representationView as? PhotoPreviewRepresentationWapperView else { return }
            if let videoCell = cell as? PhotoPreviewVideoCell {
                wapperView.videoControlBackgroundView.isHidden = false
                if let scale = videoCell.playerView.player.currentItem?.asset.duration.timescale {
                    let time = CMTime(seconds: 0.0, preferredTimescale: scale)
                    videoCell.playerView.player.seek(to: time)
                }
                videoCell.playerView.player.play()
                videoCell.playerView.player.isMuted = self.photoStorge.isMuteVideo
            } else {
                wapperView.videoControlBackgroundView.isHidden = true
            }
        }
    }
    
}


//MARK: - Asset fetcher
extension PhotoPreviewViewController {
    
    // use image fetcher to load large image
    func fetchNormalImageWithAsset(_ asset: PHAsset, progressHandler: ((Double, Error?) -> Void)?, completionHandler: @escaping (UIImage?) -> Void) {
        
        func aspectFitSizeForScreenSize(size: CGSize) -> CGSize {
            let screenWidth = UIScreen.main.bounds.width
            let ratioHeight = (screenWidth * size.height) / size.width
            return CGSize(width: screenWidth, height: ratioHeight)
        }
        
        // if asset is long image, then fetch large image
        let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        let aspectSize = aspectFitSizeForScreenSize(size: size)
        let screenSize = UIScreen.main.bounds.size
        if aspectSize.height > screenSize.height {
            self.fetchLargeImageWithAsset(asset, progressHandler: progressHandler, completionHandler: completionHandler)
        } else {
            let targeSize = CGSize(width: screenSize.width * UIScreen.main.scale, height: screenSize.height * UIScreen.main.scale)
            photoFetcher.fetch(asset: asset, targetSize: targeSize, progressHandler: { (progress, error) in
                progressHandler?(progress, error)
            }) { (image, info) in
                completionHandler(image)
            }
        }
    }
    
    // fetch large size image
    func fetchLargeImageWithAsset(_ asset: PHAsset, progressHandler: ((Double, Error?) -> Void)?, completionHandler: @escaping (UIImage?) -> Void) {
        if let image = self.imageFetcher.fetchedData(for: asset.localIdentifier) {
            completionHandler(image)
        } else {
            photoFetcher.fetchData(asset: asset, progressHandler: { (progress, error) in
                progressHandler?(progress, error)
            }) {[weak self] (data, info) in
                guard let self = self else { return }
                guard let imageData = data else { return }
                self.imageFetcher.fetchAsync(asset.localIdentifier, imageData: imageData, completion: { image in
                    completionHandler(image)
                })
            }
        }
    }
}

//MARK: - Prefetching datasource
extension PhotoPreviewViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let asset = self.assetAtIndex(index: indexPath.row)
            if asset.mediaType == .image {
                self.fetchNormalImageWithAsset(asset, progressHandler: nil) {[weak self] image in
                    guard let self = self else { return }
                    guard let image = image else { return }
                    self.cacheImage.setObject(image, forKey: NSString(string: asset.localIdentifier))
                }
            }
        }
    }
}


//MARK: - UIScrollView delegate
extension PhotoPreviewViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        //handle video
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        let offsetIdx = self.photoStorge.offsetIndex
        
        if let indexPath = collectionView.indexPathForItem(at: center), indexPath.row != offsetIdx {
            if let previousVideoCell = collectionView.cellForItem(at: IndexPath(item: offsetIdx, section: 0)) as? PhotoPreviewVideoCell {
                previousVideoCell.playerView.player.pause()
                previousVideoCell.playerView.player.isMuted = true
            }
        }

        let delta: CGFloat
        let leftDirection: Bool
        if self.previousContentOffset.x > scrollView.contentOffset.x {
            delta = self.previousContentOffset.x - scrollView.contentOffset.x
            leftDirection = true
        } else {
            delta = scrollView.contentOffset.x - self.previousContentOffset.x
            leftDirection = false
        }

        // has scrolled half screen
        let index = leftDirection ? self.photoStorge.offsetIndex - 1 : self.photoStorge.offsetIndex + 1
        if index > self.photoStorge.album.collectionResults.count || index < 0 {
            return
        }

        if let currentCell = collectionView.cellForItem(at: IndexPath(item: self.photoStorge.offsetIndex, section: 0)), let nextCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) {
           
            let currentCellIsVideoCell = currentCell is PhotoPreviewVideoCell
            let nextIsVideoCell = nextCell is PhotoPreviewVideoCell

            let wapperView = (self.representationView as! PhotoPreviewRepresentationWapperView)
            var isHidden: Bool = wapperView.videoControlBackgroundView!.isHidden
            if nextIsVideoCell && !currentCellIsVideoCell {
                isHidden = !(delta > UIScreen.main.bounds.width/2)
            }
            
            if currentCellIsVideoCell && !nextIsVideoCell {
                isHidden = !(delta < UIScreen.main.bounds.width/2)
            }
            
            guard wapperView.videoControlBackgroundView!.isHidden != isHidden else { return }
            wapperView.videoControlBackgroundView!.isHidden = isHidden

            wapperView.videoControlView.playButton.transform = isHidden ? CGAffineTransform(scaleX: 1.0, y: 1.0) : CGAffineTransform(scaleX: 0.2, y: 0.2)
            wapperView.videoControlView.volumeButton.transform = isHidden ? CGAffineTransform(scaleX: 1.0, y: 1.0) : CGAffineTransform(scaleX: 0.2, y: 0.2)
            let animator = UIViewPropertyAnimator(duration: 0.8, dampingRatio: 0.4) {
                wapperView.videoControlView.playButton.transform = isHidden ? CGAffineTransform(scaleX: 0.0, y: 0.0) : CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            }
            animator.addAnimations({
                wapperView.videoControlView.volumeButton.transform = isHidden ? CGAffineTransform(scaleX: 0.0, y: 0.0) : CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, delayFactor: 0.08)
            animator.startAnimation()
        }
      
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let center = CGPoint(x: scrollView.contentOffset.x + (scrollView.frame.width / 2), y: (scrollView.frame.height / 2))
        let offsetIdx = self.photoStorge.offsetIndex
        

        // handle video paly state
        if let indexPath = collectionView.indexPathForItem(at: center),
            let currentVideoCell = collectionView.cellForItem(at: indexPath) as? PhotoPreviewVideoCell {
            currentVideoCell.playerView.player.isMuted = self.photoStorge.isMuteVideo

            if indexPath.row != offsetIdx {
                // has enter next video, play video at begin
                if let scale = currentVideoCell.playerView.player.currentItem?.asset.duration.timescale {
                    let time = CMTime(seconds: 0.0, preferredTimescale: scale)
                    currentVideoCell.playerView.player.seek(to: time)
                }
                currentVideoCell.playerView.player.play()
            } else {
                // if offset cell still current cell when scroll did end
                // continue play if video did not paused
                if (self.representationView as! PhotoPreviewRepresentationWapperView).videoControlView.videoState != .pausing {
                    currentVideoCell.playerView.player.play()
                }
            }
        }

        // did scroll to next item
        if let indexPath = collectionView.indexPathForItem(at: center), indexPath.row != offsetIdx {
            self.photoStorge.offsetIndex = indexPath.row
            self.representationView?.currentCount = self.calculateCurrentCount()
            self.didPageItem?(indexPath.row)
            self.representationView?.photoStorage = self.photoStorge
            self.representationView?.didUpdatePhotoStroage(photoStorage: self.photoStorge)
            self.previousContentOffset = scrollView.contentOffset
        }
    }
}

