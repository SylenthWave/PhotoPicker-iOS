//
//  PhotoPreviewRepresentationWapperView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/4/14.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import AVKit

//MARK: - Life
class PhotoPreviewRepresentationWapperView: PhotoPreviewRepresentationView {
    
    @IBOutlet weak var selectBox: SelectBox!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendBtn: UIButton! {
        didSet {
            self.sendBtn.setTitleColor(.green, for: .normal)
            self.sendBtn.setTitleColor(.gray, for: .disabled)
            self.sendBtn.isEnabled = false
        }
    }
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var videoControlBackgroundView: UIView!
    
    lazy var videoControlView: VideoControlView = {
        let view = UIView.loadNib(VideoControlView.self)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var photoStorageSelectedAssetsKVOToken: NSKeyValueObservation?
    
    class func make() -> PhotoPreviewRepresentationWapperView {
        let view = UIView.loadNib(PhotoPreviewRepresentationWapperView.self)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let height = UIApplication.shared.statusBarFrame.height + 44
        self.topViewHeightConstraint.constant = height
        self.setupSendButton()
        self.setupTopSelectbox()
        self.setupVideoControl()
    }
    
    deinit {
        debugPrint("representation view deinit")
        self.photoStorageSelectedAssetsKVOToken?.invalidate()
    }
}

//MARK: - Setup
extension PhotoPreviewRepresentationWapperView {
    
    private func setupVideoControl() {
        self.videoControlBackgroundView.addSubview(self.videoControlView)
        NSLayoutConstraint.activate([
            self.videoControlView.leadingAnchor.constraint(equalTo: self.videoControlBackgroundView.leadingAnchor),
            self.videoControlView.trailingAnchor.constraint(equalTo: self.videoControlBackgroundView.trailingAnchor),
            self.videoControlView.topAnchor.constraint(equalTo: self.videoControlBackgroundView.topAnchor),
            self.videoControlView.bottomAnchor.constraint(equalTo: self.videoControlBackgroundView.bottomAnchor)
        ])
        
        self.videoControlView.playButtonTapped = {[weak self] control in
            guard let self = self else { return }
            guard let previewVC = self.previewViewController else { return }
            guard let videoCell = previewVC.currentActionCell as? PhotoPreviewVideoCell else { return }
            switch videoCell.playerView.player.timeControlStatus {
            case .playing:
                videoCell.playerView.player.pause()
                control.videoState = .pausing
            case .paused, .waitingToPlayAtSpecifiedRate:
                videoCell.playerView.player.play()
                control.videoState = .playing
            @unknown default: break
            }
        }
        
        self.videoControlView.volumButtonTapped = {[weak self] control in
            guard let self = self else { return }
            guard let previewVC = self.previewViewController else { return }
            guard let videoCell = previewVC.currentActionCell as? PhotoPreviewVideoCell else { return }

            if videoCell.playerView.player.isMuted {
                self.photoStorage?.isMuteVideo = false
                videoCell.playerView.player.isMuted = false
                control.volumeState = .on
            } else {
                self.photoStorage?.isMuteVideo = true
                videoCell.playerView.player.isMuted = true
                control.volumeState = .off
            }
        }

    }
    
    private func setupTopSelectbox() {
        self.selectBox.changeState = { [weak self] selectBox in
            guard let self = self else { return }
            guard let photoStorage = self.photoStorage else { return }
            guard let asset = self.photoStorage?.currentAsset else { return }
            switch selectBox.currentState {
            case .unselected:
                let count = photoStorage.selectedAssets.count + 1
                selectBox.currentState = .selectedWithCount(count: count, animated: true)
                self.photoStorage?.addAsset(asset)
            default:
                selectBox.currentState = .unselected
                self.photoStorage?.removeAsset(asset)
            }
            if let storage = self.photoStorage {
                self.changeSendButtonTitle(photoStorage: storage)
            }
        }
    }

    private func setupSendButton() {
        self.sendBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        self.sendBtn.setTitle("确定", for: .normal)
        self.sendBtn.addTarget(self, action: #selector(tapppedSend), for: .touchUpInside)
    }
    
    
    private func changeSendButtonTitle(photoStorage: PhotoStorage) {
        let title = photoStorage.selectedAssets.count > 0 ? "确定(\(photoStorage.selectedAssets.count))" : "确定"
        self.sendBtn.setTitle(title, for: .normal)
        self.sendBtn.isEnabled = photoStorage.selectedAssets.count > 0
    }

    private func setupCountLabel(photoStorage: PhotoStorage) {
        let total = photoStorage.album.collectionResults.count
        self.countLabel.text = "\(self.currentCount) / \(total)"
    }

    private func setupSelectBox(photoStorage: PhotoStorage) {
        guard let asset = photoStorage.currentAsset else { return }

        if let idx = photoStorage.selectedAssets.firstIndex(of: asset) {
            self.selectBox.currentState = .selectedWithCount(count: idx + 1, animated: false)
        } else {
            
            let videoCount = photoStorage.selectedAssets.filter { $0.mediaType == .video }.count
            
            if photoStorage.selectedAssets.count > 0 && asset.mediaType == .video {
                self.selectBox.currentState = .disable
                return
            }
            if videoCount > 0 {
                self.selectBox.currentState = .disable
                return
            }
            self.selectBox.currentState = .unselected
        }
    }
    
    private func setupVideo(photoStorage: PhotoStorage) {
        self.videoControlView.videoState = .playing
        if let isMute = self.photoStorage?.isMuteVideo {
            self.videoControlView.volumeState = isMute ? .off : .on
        }
    }
    
    @objc func tapppedSend() {
        self.removeFromSuperview()
        NotificationCenter.default.post(name: PhotoPickerViewController.sendNotificationName, object: nil)
    }

}


//MARK: - PhotoPreviewRepresentationViewDelegate
extension PhotoPreviewRepresentationWapperView: PhotoPreviewRepresentationViewDelegate {
    
    func didUpdatePhotoStroage(photoStorage: PhotoStorage) {
        self.setupCountLabel(photoStorage: photoStorage)
        self.setupSelectBox(photoStorage: photoStorage)
        self.changeSendButtonTitle(photoStorage: photoStorage)
        self.setupVideo(photoStorage: photoStorage)
    }
    
    var backButton: UIButton {
        return self.backBtn
    }
}
