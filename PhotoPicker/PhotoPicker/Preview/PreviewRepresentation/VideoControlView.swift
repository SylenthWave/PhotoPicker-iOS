//
//  VideoControlView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/3.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class VideoControlView: UIView {
    
    enum VideoState {
        case playing
        case pausing
    }
    
    enum VolumeState {
        case on
        case off
    }

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    
    var videoState: VideoState = .playing {
        didSet {
            switch self.videoState {
            case .playing:
                self.playButton.setImage(UIImage(podAssetName: "video_pause_icon"), for: .normal)
            case .pausing:
                self.playButton.setImage(UIImage(podAssetName: "video_play_icon"), for: .normal)
            }
        }
    }
    
    var volumeState: VolumeState = .off {
        didSet {
            switch self.volumeState {
            case .on:
                self.volumeButton.setImage(UIImage(podAssetName: "video_sound_on_icon"), for: .normal)
            case .off:
                self.volumeButton.setImage(UIImage(podAssetName: "video_sound_off_icon"), for: .normal)
            }
        }
    }
    
    var playButtonTapped: ((VideoControlView) -> Void)?
    var volumButtonTapped: ((VideoControlView) -> Void)?
    
    @IBAction func tappedPlayButton(_ sender: Any) {
        self.playButtonTapped?(self)
    }
    
    @IBAction func tappedVolumeButton(_ sender: Any) {
        self.volumButtonTapped?(self)
    }
}
