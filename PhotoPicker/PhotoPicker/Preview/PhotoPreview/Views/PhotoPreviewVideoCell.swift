//
//  PhotoPreviewVideoCell.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/1.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import AVKit

class PhotoPreviewVideoCell: UICollectionViewCell {
    public var assetIdentifier: String = ""

    var playerView: PlayerView = {
        let view = PlayerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.playerView)
        NSLayoutConstraint.activate([
            self.playerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.playerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.playerView.topAnchor.constraint(equalTo: self.topAnchor),
            self.playerView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("video cell deinit!")
    }

}

class PlayerView: UIView {
    
    lazy var playerWapperView: PlayerWapperView = {
        let view = PlayerWapperView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var player: AVPlayer = {
        let player = AVPlayer()
        return player
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    var playDidFinish: (() -> Void)?
    
    override var isHidden: Bool {
        didSet {
            let playerlayer = self.playerWapperView.layer as! AVPlayerLayer
            playerlayer.isHidden = self.isHidden
        }
    }

    private func setup() {
        self.player = AVPlayer()
        self.backgroundColor = UIColor.clear
        self.addSubview(self.playerWapperView)
        NSLayoutConstraint.activate([
            self.playerWapperView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.playerWapperView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.playerWapperView.topAnchor.constraint(equalTo: self.topAnchor),
            self.playerWapperView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        let playerlayer = self.playerWapperView.layer as! AVPlayerLayer
        playerlayer.backgroundColor = UIColor.clear.cgColor
        playerlayer.needsDisplayOnBoundsChange = true
        playerlayer.player = self.player
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            NotificationCenter.default.removeObserver(self)
        }
    }

    public func setupWithAsset(asset: AVAsset) {
        let item = AVPlayerItem(asset: asset)
        self.player.replaceCurrentItem(with: item)
    }
    
    @objc func playerDidFinishPlaying() {
        if let scale = player.currentItem?.asset.duration.timescale {
            let time = CMTime(seconds: 0.0, preferredTimescale: scale)
            player.seek(to: time)
        }
        self.playDidFinish?()
    }
    
    deinit {
        print("video cell deinit!")
    }

}

class PlayerWapperView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
