//
//  PhotoPickerViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/2/10.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

//MARK: - PhotoPickerViewController
public class PhotoPickerViewController: UIViewController {
    
    public typealias CompletionResult = (assets: [PHAsset], isOriginal: Bool)
    
    public var completionHandler: ((CompletionResult) -> Void)?
    public var completionHandlerWithoutDimiss: ((CompletionResult, PhotoPickerViewController) -> Void)?
    public var closeHandler: ((PhotoPickerViewController) -> Void)?
    public var didDismiss: (() -> Void)?
    
    static var sendNotificationName: NSNotification.Name {
        return NSNotification.Name("com.photopicker.send")
    }
    
    private var photoStorage: PhotoStorage?
    private let titleView = PickerNavBarTitleView()
    private var parsedOptionsInfo: PhotoPickerParsedOptionsInfo
    private weak var previewViewController: PhotoPreviewViewController?
    private weak var currentSelectedPhotoPickerCell: PhotoPickerBasicCell?
    private var hasOffset: Bool = false
    private var shouldUpdateFooter: Bool = true
    private var photoFetcher = PhotoFetcher()
    
    private lazy var bottomToolbar: PhotoPickerBottomToolbar = {
        let view = UIView.loadNib(PhotoPickerBottomToolbar.self)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var albumWapperVC: AlbumWapperViewController = {
        let vc = AlbumWapperViewController()
        // whether hidden video
        vc.isHiddenVideo = self.parsedOptionsInfo.isHiddenVideo
        // selected a album and update current picker images
        vc.refreshAlbum = { [weak self] album in
            guard let self = self else { return }
            self.photoStorage?.album = album
            self.titleView.title = album.assetCollection.localizedTitle ?? ""
            self.collectionView.reloadData()
            self.albumWapperVC.dismiss()
            self.shouldScrollToBottom()
            self.titleView.state = .close
            self.shouldUpdateFooter = true
        }
        
        vc.dismissHandler = { [weak self] in
            guard let self = self else { return }
            self.titleView.state = .close
        }
        return vc
    }()
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.collectionViewLayout)
        collectionView.registerSupplementaryView(PhotoPickerFooterView.self, kind: UICollectionView.elementKindSectionFooter)
        collectionView.registerCell(PhotoPickerCollectionViewVideoCell.self)
        collectionView.registerCell(PhotoPickerCollectionViewCell.self)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = .systemBackground
        } else {
            collectionView.backgroundColor  = .white
        }
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        let width = (UIScreen.main.bounds.width - (parsedOptionsInfo.itemMinimumSpacing * CGFloat(self.parsedOptionsInfo.itemCountForRow - 1)) - self.parsedOptionsInfo.collectionViewEdge * 2) / CGFloat(self.parsedOptionsInfo.itemCountForRow)
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumInteritemSpacing = parsedOptionsInfo.itemMinimumSpacing
        layout.minimumLineSpacing = parsedOptionsInfo.itemMinimumSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: self.parsedOptionsInfo.collectionViewEdge, bottom: 0, right: self.parsedOptionsInfo.collectionViewEdge)
        layout.footerReferenceSize = CGSize(width: self.view.bounds.width, height: 50)
        return layout
    }()
    
    convenience init(selectedAssets: [PHAsset] = []) {
        self.init(optionsInfo: [
            .itemMinimumSpacing(3),
            .photoDirection(.down),
            .maximumVideoSelectCount(.count(1)),
            .isHiddenVideo(false)
            ], selectedAssets: selectedAssets)
    }
    
    init(optionsInfo: PhotoPickerOptionsInfo, selectedAssets: [PHAsset] = []) {
        self.parsedOptionsInfo = PhotoPickerParsedOptionsInfo(optionsInfo)
        
        super.init(nibName: nil, bundle: nil)
        PHAssetCollection.fetchAlbums { albums in
            guard let firstAlbum = albums.first else { return }
            self.photoStorage = PhotoStorage(album: firstAlbum)
            
            //hidden videos
            if self.parsedOptionsInfo.isHiddenVideo {
                let fetchOption = PHFetchOptions()
                fetchOption.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                self.photoStorage?.album.fetchResultOption = fetchOption
            }
            self.photoStorage?.selectedAssets = selectedAssets
            self.photoStorage?.delegate = self
            self.titleView.title = self.photoStorage?.album.assetCollection.localizedTitle ?? ""
            self.collectionView.reloadData()
            if let storage = self.photoStorage {
                self.bottomToolbar.changeSendButtonTitle(photoStorage: storage)
            }
            self.shouldScrollToBottom()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("picker deinit")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(close))

        self.setupNavBarTitleView()
        self.setupCollectionView()
        self.setupTransitioningWapperDelegate()
        self.toolbarActions()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(send), name: Self.sendNotificationName, object: nil)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    public func dismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }

    @objc func close() {
        self.dismiss()
        self.didDismiss?()
    }
    
    public func cancelFreeze() {
        self.bottomToolbar.sendBtn.isEnabled = true
        self.bottomToolbar.previewBtn.isEnabled = true
        self.titleView.button.isEnabled = true
    }
    
    public func freeze() {
        self.bottomToolbar.sendBtn.isEnabled = false
        self.bottomToolbar.previewBtn.isEnabled = false
        self.titleView.button.isEnabled = false
    }
    
    @objc func send() {
        guard let photoStorage = self.photoStorage else { return }
        if let completionHandlerWithoutDimiss = self.completionHandlerWithoutDimiss {
            self.freeze()
            completionHandlerWithoutDimiss(CompletionResult(assets: photoStorage.selectedAssets, isOriginal: photoStorage.isOriginal), self)
        } else {
            self.completionHandler?(CompletionResult(assets: photoStorage.selectedAssets, isOriginal: photoStorage.isOriginal))
            self.dismiss()
        }
   
    }
    
}

//MARK: - Actions
extension PhotoPickerViewController {
    
    private func toolbarActions() {
        
        // show preview view controller
        self.bottomToolbar.preview = { [weak self] in
            guard let self = self else { return }
            guard let photoStorage = self.photoStorage else { return }
            let previewVC = PageSheetPhotoPreivewViewController(photoStorge: photoStorage)
            previewVC.modalPresentationStyle = .popover
            previewVC.modalPresentationCapturesStatusBarAppearance = true
            self.present(previewVC, animated: true, completion: nil)
        }
        
        self.bottomToolbar.send = { [weak self] in
            guard let self = self else { return }
            self.send()
        }
        
        self.bottomToolbar.originalImage = { [weak self] toolBar in
            guard let self = self else { return }
            guard let storage = self.photoStorage else { return }
            storage.isOriginal = !storage.isOriginal
            toolBar.originalImageView.image = storage.isOriginal ? UIImage(podAssetName: "circle_selected_image") : UIImage(podAssetName: "circle_unselected_gray_image")
        }
        
    }

}

//MARK: - Setup method
extension PhotoPickerViewController {
    
    private func shouldScrollToBottom() {
        // if photo direction is down, scroll to bottom
        if let storage = self.photoStorage,
            self.parsedOptionsInfo.photoDirection == .down {
            self.collectionView.scrollToItem(
                at: IndexPath(item: storage.album.collectionResults.count - 1, section: 0),
                at: .bottom,
                animated: false
            )
        }
    }
    
    private func setupTransitioningWapperDelegate() {
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return }
        nav.transitionWapper.delegate = self
        nav.transitionWapper.datasoruce = self
        nav.transitionWapper.animatedTransitioning.panGesture.delegate = self
    }
    
    private func setupNavBarTitleView() {
        self.titleView.title = self.photoStorage?.album.assetCollection.localizedTitle ?? ""
        self.titleView.click = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .open:
                self.albumWapperVC.presentedIn(self)
            case .close:
                self.albumWapperVC.dismiss()
            }
        }
        if #available(iOS 11.0, *) {
            self.navigationItem.titleView = titleView
        } else {
            titleView.frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width - 88, height: 44))
            self.navigationItem.titleView = titleView
        }
        let image = UIImage(podAssetName: "picker_close_button_icon")

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: image?.imageAsset?.image(with: self.traitCollection).withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(close))
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.navigationItem.leftBarButtonItem?.image = UIImage(podAssetName: "picker_close_button_icon")?.imageAsset?.image(with: self.traitCollection).withRenderingMode(.alwaysOriginal)
    }
    
    private func setupCollectionView() {
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.bottomToolbar)
        
        var bottomBarHeight: CGFloat = 50
        var safeBottomHeight: CGFloat = 0
        if #available(iOS 11.0, *) {
            safeBottomHeight = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
        }
        
        var contentInset = self.collectionView.contentInset
        contentInset.bottom += safeBottomHeight
        self.collectionView.contentInset = contentInset
        var scrollIndicatorInsets = self.collectionView.scrollIndicatorInsets
        scrollIndicatorInsets.bottom += safeBottomHeight
        self.collectionView.scrollIndicatorInsets = scrollIndicatorInsets
        
        bottomBarHeight += safeBottomHeight
           
        NSLayoutConstraint.activate([
            self.bottomToolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.bottomToolbar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.bottomToolbar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.bottomToolbar.heightAnchor.constraint(equalToConstant: bottomBarHeight)
        ])
        
        NSLayoutConstraint.activate([
            self.collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    private func assetIn(_ results: PHFetchResult<PHAsset>, indexPath: IndexPath) -> PHAsset {
        let index = self.parsedOptionsInfo.photoDirection == .down ? indexPath.row : results.count - indexPath.row - 1
        let asset = results.object(at: index)
        return asset
    }

}

//MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension PhotoPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // SelectBox and mask setup
        func setupSelectState(cell: PhotoPickerBasicCell, asset: PHAsset) {
            cell.isShowMask = false
            // matching selected image/video
            if let idx = self.photoStorage?.selectedAssets.firstIndex(of: asset) {
                cell.selectBox.currentState = .selectedWithCount(count: idx + 1, animated: true)
            } else {
                // the maximum selected count for video
                switch self.parsedOptionsInfo.maximumVideoSelectCount {
                case .infinite:
                    cell.selectBox.currentState = .unselected
                case .count(let count):
                    if count == 1 {
                        if let first = self.photoStorage?.selectedAssets.first {
                            //if has selected image hidden all video cell
                            if first.mediaType == .video || asset.mediaType == .video {
                                cell.selectBox.currentState = .disable
                                cell.isShowMask = true
                            } else {
                                cell.selectBox.currentState = .unselected
                            }
                        } else {
                            cell.selectBox.currentState = .unselected
                        }
                    } else {
                        if let videoCount = self.photoStorage?.selectedAssets.filter({ $0.mediaType == .video }),
                            videoCount.count == count, asset.mediaType == .video {
                            cell.selectBox.currentState = .disable
                            cell.isShowMask = true
                        } else {
                            cell.selectBox.currentState = .unselected
                        }
                    }
                }
            }
            
            // handle select image
            cell.selectBox.changeState = { [weak self] selectBox in
                guard let self = self else { return }
                switch selectBox.currentState {
                case .unselected:

                    // if selected assets exceed the maximum limit count
                    // show alert
                    switch self.parsedOptionsInfo.maximumSelectCount {
                    case .count(let count):
                        if count == self.photoStorage?.selectedAssets.count {
                            let alert = UIAlertController(title: "最多只能选择\(count)张图片哦～", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            return
                        }
                    case .infinite: break
                    }
                    
                    // large video (more then 200M) can't select
                    if asset.mediaType == .video {
                       asset.fetchVideo(options: nil, progressHandler: nil) { (avAsset, info) in
                            guard let avAsset = avAsset as? AVURLAsset else { return }
                            if avAsset.videoStroageSize > 200.0 {
                                let alertVC = UIAlertController(title: "视频大小超过200M,请重新选择", message: nil, preferredStyle: .alert)
                                let cancel = UIAlertAction(title: "知道了", style: .cancel, handler: nil)
                                alertVC.addAction(cancel)
                                self.present(alertVC, animated: true, completion: nil)
                                return
                            } else {
                                self.photoStorage?.addAsset(asset)
                            }
                        }
                    } else {
                        self.photoStorage?.addAsset(asset)
                    }

                default:
                    self.photoStorage?.removeAsset(asset)
                }
            }
        }
        
        // reverse results
        guard let results = self.photoStorage?.album.collectionResults else { return UICollectionViewCell() }
        
        let asset = self.assetIn(results, indexPath: indexPath)

        switch asset.mediaType {
        case .image:
            
            let cell = collectionView.dequeueReuseCell(PhotoPickerCollectionViewCell.self, forIndexPath: indexPath)

            cell.assetId = asset.localIdentifier
            
            // fetch image
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            asset.fetchImage(targetSize: UIScreen.main.bounds.size, options: options) { (image, info) in
                if cell.assetId == asset.localIdentifier {
                    cell.imageView.image = image
                }
            }
            
            setupSelectState(cell: cell, asset: asset)
            return cell
            
        case .video:
            
            let cell = collectionView.dequeueReuseCell(PhotoPickerCollectionViewVideoCell.self, forIndexPath: indexPath)

            cell.assetId = asset.localIdentifier
            
            // fetch image
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            asset.fetchImage(targetSize: UIScreen.main.bounds.size, options: options) { (image, info) in
                if cell.assetId == asset.localIdentifier {
                    cell.imageView.image = image
                }
            }
            cell.timeLabel.text = asset.duration.videoTime
            setupSelectState(cell: cell, asset: asset)
            return cell

        default:
            return UICollectionViewCell()
        }
        
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photoStorage?.album.collectionResults.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let photoStorage = self.photoStorage else { return }
        guard let results = self.photoStorage?.album.collectionResults else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoPickerBasicCell else { return }
        let asset = self.assetIn(results, indexPath: indexPath)

        // video disable
        if cell.isShowMask {
            return
        }

        self.photoStorage?.currentAsset = asset
        
        self.currentSelectedPhotoPickerCell = cell
        self.photoStorage?.offsetIndex = indexPath.row
        
        let previewVC = PhotoPreviewViewController(photoStorge: photoStorage)
        previewVC.delegate = self
        previewVC.shouldReverse = self.parsedOptionsInfo.photoDirection == .down
        previewVC.didPageItem = {[weak self] index in
            guard let self = self else { return }
            
            if let lastCell = self.currentSelectedPhotoPickerCell, lastCell.isHidden {
                lastCell.isHidden = false
            }

            let asset = self.assetIn(results, indexPath: IndexPath(item: index, section: 0))
            self.photoStorage?.currentAsset = asset
            
            let changeIndexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(at: changeIndexPath, at: .centeredVertically, animated: false)
            collectionView.layoutIfNeeded()
            guard let cell = collectionView.cellForItem(at: changeIndexPath) as? PhotoPickerBasicCell else { return }
            cell.isHidden = true
            self.currentSelectedPhotoPickerCell = cell
        }
        previewVC.shouldPop = { vc in
            vc.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(previewVC, animated: true)
        self.previewViewController = previewVC
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReuseSupplementaryView(PhotoPickerFooterView.self, kind: kind, for: indexPath) as? PhotoPickerFooterView else { return UICollectionReusableView() }
        if let collection = self.photoStorage?.album.assetCollection , self.shouldUpdateFooter == true {
            self.shouldUpdateFooter = false
            if self.parsedOptionsInfo.isHiddenVideo {
                footerView.label.text = "\(collection.photosCount)张照片"
            } else {
                footerView.label.text = "\(collection.photosCount)张照片, \(collection.videoCount)个视频"
            }
        }
        return footerView
    }
    
}

//MARK: - PhotoStorage Delegate
extension PhotoPickerViewController: PhotoStorageDelegate {
    
    func didUpdateStorage(action: PhotoStorage.Action) {
        
        func reloadHandler(action: PhotoStorage.Action, storage: PhotoStorage, asset: PHAsset) {
            let assetIndex = storage.album.collectionResults.index(of: asset)
            let index = self.parsedOptionsInfo.photoDirection == .down ? assetIndex : storage.album.collectionResults.count - assetIndex - 1
            let indexPath = IndexPath(row: index, section: 0)
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? PhotoPickerBasicCell else { return }
            
            switch action {
            case .add:
                if let count = self.photoStorage?.selectedAssets.count {
                    cell.selectBox.currentState = .selectedWithCount(count: count, animated: true)
                }
            case .remove:
                cell.selectBox.currentState = .unselected
            }

            var indexPaths = collectionView.indexPathsForVisibleItems
            guard let idx = indexPaths.firstIndex(where: { $0.row == index }) else { return }
            indexPaths.remove(at: idx)
            collectionView.reloadItems(at: indexPaths)
        }
        
        guard let stroage = self.photoStorage else { return }
        
        // handle toolbar preview button enable
        self.bottomToolbar.changeSendButtonTitle(photoStorage: stroage)
        let shouldEnablePreviewButton = stroage.selectedAssets.count > 0
        self.bottomToolbar.previewBtn.isEnabled = shouldEnablePreviewButton
        self.bottomToolbar.sendBtn.isEnabled = shouldEnablePreviewButton
        
        // reload selected cell
        reloadHandler(action: action, storage: stroage, asset: action.asset)
    }
    
    func handleVideoCellDisableState(currentAsset: PHAsset, stroage: PhotoStorage) {
        let videoCells = collectionView.visibleCells.filter { $0 is PhotoPickerCollectionViewVideoCell }
        guard videoCells.count > 0 else { return }
        
        let cells = videoCells as! [PhotoPickerCollectionViewVideoCell]
        for cell in cells {
            cell.isShowMask = !(stroage.selectedAssets.count == 0)
        }
    }
}

//MARK: - PhotoPreviewViewControllerDelegate
extension PhotoPickerViewController: PhotoPreviewViewControllerDelegate {
    func representationView() -> RepresentationView {
        return PhotoPreviewRepresentationWapperView.make()
    }
}

//MARK: - Calculate transtion item frame
extension PhotoPickerViewController {
    
    private var smallImageFrame: CGRect {
        guard let selectedCell = self.currentSelectedPhotoPickerCell else { return .zero }
        let covertFrame = selectedCell.convert(selectedCell.imageView.frame, to: self.view)
        return covertFrame
    }
    
    private var largeImageFrame: CGRect {
        guard let previewVC = self.previewViewController else { return .zero }
        
        // if has been detail, use ZoomableImageView calculate large image frame
        if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell {
            switch cell.zoomableImageView.zoomState {
            case .full:
                let origin: CGPoint = CGPoint(x: -cell.zoomableImageView.scrollView.contentOffset.x, y: -cell.zoomableImageView.scrollView.contentOffset.y)
                return CGRect(origin: origin, size: cell.zoomableImageView.scrollView.contentSize)
            case .zomming, .original:
                let size = cell.zoomableImageView.imageView.aspectFitImageSize(size: cell.zoomableImageView.scrollView.contentSize)
                return CGRect(origin: CGPoint(x: -cell.zoomableImageView.scrollView.contentOffset.x, y: UIScreen.main.bounds.height/2 - size.height/2), size: size)
            }
        }
        
        if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
            let layer = (cell.playerView.playerWapperView.layer as! AVPlayerLayer)
            return layer.videoRect
        }
        
        // if has not been detail, use small cell calculate the large image frame
        guard let selectedCell = self.currentSelectedPhotoPickerCell else { return .zero }
        let size = selectedCell.imageView.imageViewAspectFitSizeForScreenSize
        var y = UIScreen.main.bounds.height/2 - size.height/2
        if y < 0 { y = 0 }
        return CGRect(origin: CGPoint(x: 0, y: y), size: size)

    }
    
}

//MARK: - ImagePopoverTransitioningWapperDatasource
extension PhotoPickerViewController: ImagePopoverTransitioningWapperDatasource {
    func image(fetcher: @escaping (UIView) -> Void) {
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return }
        switch nav.transitionWapper.animatedTransitioning.operation {
        case .push:
            guard let asset = self.photoStorage?.currentAsset else { return }
            guard let cell = self.currentSelectedPhotoPickerCell else { return }
            let cacheImage = cell.imageView.image
            
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            let screenSize = UIScreen.main.bounds.size
            let targeSize = CGSize(width: screenSize.width * UIScreen.main.scale, height: screenSize.height * UIScreen.main.scale)
            
            asset.fetchImage(targetSize: targeSize, options: option, synchronousInBackground: false) { (image, info) in
                if image == nil {
                    let view = UIImageView(image: cacheImage)
                    fetcher(view)
                } else {
                    let view = UIImageView(image: image)
                    fetcher(view)
                }
            }

        case .pop, .interactive:
            guard let previewVC = self.previewViewController else { return }
            
            // image
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell {
                let imageView = UIImageView(image: cell.zoomableImageView.imageView.image)
                fetcher(imageView)
            }
            
            // video
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
                let playerView = PlayerWapperView(frame: self.largeImageFrame)
                (playerView.layer as! AVPlayerLayer).player = cell.playerView.player
                fetcher(playerView)
            }
        }
    }
    
    func imageOriginalFrame() -> CGRect {
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return .zero }
        switch nav.transitionWapper.animatedTransitioning.operation {
        case .push:
            return self.smallImageFrame
        case .pop, .interactive:
            return self.largeImageFrame
        }
    }
    
    func imageFinalFrame() -> CGRect {
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return .zero }
        switch nav.transitionWapper.animatedTransitioning.operation {
        case .push:
            return self.largeImageFrame
        case .pop, .interactive:
            return self.smallImageFrame
        }
    }
    
    func simulanteousScrollView() -> UIScrollView? {
        guard let previewVC = self.previewViewController else { return nil }
        guard let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell else { return nil }
        return cell.zoomableImageView.scrollView
    }
    
    func addAdditionalAnimaton(transitionWapper: ImagePopoverTransitioningWapper) -> (() -> Void)? {
        guard let representationView = self.previewViewController?.representationView else { return nil }
        switch transitionWapper.animatedTransitioning.operation {
        case .push:
            representationView.alpha = 0
            return {
                representationView.alpha = 1
            }
        case .pop, .interactive:
            representationView.alpha = 1
            return {
                representationView.alpha = 0
            }
        }
    }
  
}

//MARK: - ImagePopoverTransitioningWapperDelegate
extension PhotoPickerViewController: ImagePopoverTransitioningWapperDelegate {
    
    func transitionWillStart(transition: ImagePopoverTransitioningWapper) {
        guard let cell = self.currentSelectedPhotoPickerCell else { return }
        cell.isHidden = true
        
        switch transition.animatedTransitioning.operation {
        case .interactive, .pop:
            guard let previewVC = self.previewViewController else { return }
            // image
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell {
                cell.zoomableImageView.isHidden = true
            }
            //video
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    cell.playerView.isHidden = true
                }
            }
        case .push: break
        }
    }
    
    func transitionWillEnd(transition: ImagePopoverTransitioningWapper, isComplete: Bool) {
        guard let cell = self.currentSelectedPhotoPickerCell else { return }
        cell.isHidden = !isComplete
        
        if !isComplete {
            switch transition.animatedTransitioning.operation {
            case .interactive, .pop:
                guard let previewVC = self.previewViewController else { return }
                
                //image
                if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell {
                    cell.zoomableImageView.isHidden = false
                }
                
                //video
                if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
                    if let player = transition.imageView.layer as? AVPlayerLayer {
                        player.player = nil
                    }
                    //!!!transition flash
                    cell.playerView.isHidden = false
                }
                
            case .push: break
            }
        }
        
    }

    func transitioningDidCompletion(transitioning: ImagePopoverTransitioningWapper) {
        switch transitioning.animatedTransitioning.operation {
        case .push:
            guard let previewVC = self.previewViewController else { return }
            previewVC.needHiddenCell = false
            
            // image
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell {
                cell.zoomableImageView.isHidden = false
            }
            
            // video
            if let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
                cell.playerView.isHidden = false
            }
        case .pop, .interactive:
            guard let previewVC = self.previewViewController else { return }
            
            // pause and mute player
            if let cell = self.previewViewController?.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewVideoCell {
                cell.playerView.player.isMuted = true
                cell.playerView.player.pause()
            }
            
            // if download image from icloud, cancel all request
            previewVC.photoFetcher.cancelAllRequest()
            
            self.previewViewController?.representationView?.removeFromSuperview()
            self.previewViewController = nil
            self.currentSelectedPhotoPickerCell = nil
            self.photoStorage?.currentAsset = nil
        }
    }

}

//MARK: - Gesture delegate
extension PhotoPickerViewController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else { return false }
        guard otherGestureRecognizer is UIPanGestureRecognizer else  { return false }
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return false }
        nav.transitionWapper.shouldSimultaneousHandleGesture = false
        
        guard let previewVC = self.previewViewController else { return false }
        guard let cell = previewVC.collectionView.cellForItem(at: IndexPath(item: previewVC.photoStorge.offsetIndex, section: 0)) as? PhotoPreviewCell else { return false }
        
        if cell.zoomableImageView.zoomState == .full || cell.zoomableImageView.scrollView.contentSize.height > cell.zoomableImageView.scrollView.bounds.height {
            if scrollView.contentOffset.y <= 0 {
                nav.transitionWapper.shouldSimultaneousHandleGesture = true
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController as? PhotoPickerTransitionNavigationController else { return false }
        if nav.transitionWapper.animatedTransitioning.panGesture == gestureRecognizer {
            if gestureRecognizer.numberOfTouches > 0 {
                let point = nav.transitionWapper.animatedTransitioning.panGesture.velocity(in: self.view)
                let shouldBegin = fabsf(Float(point.y)) > fabsf(Float(point.x))
                return shouldBegin
            } else {
                return false
            }
        }
        return false
    }
}
