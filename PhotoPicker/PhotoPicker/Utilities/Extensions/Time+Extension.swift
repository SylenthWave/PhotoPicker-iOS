//
//  Time+Extension.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/1.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import AVKit

public extension AVURLAsset {
    
    var videoStroageSize: Double {
        let tracks = self.tracks
        var estimatedSize = 0.0
        for track in tracks {
            let rate = Double(track.estimatedDataRate / 8)
            let seconds = Double(CMTimeGetSeconds(track.timeRange.duration))
            estimatedSize += seconds * rate
        }
        return estimatedSize == 0.0 ? 0.0 : (estimatedSize / 1024 / 1024)
    }
}

public extension TimeInterval {
    
    var videoTime: String? {
        let seconds = Int(self) % 60
        let minutes = (Int(self) / 60) % 60
        let hours = Int(self) / 3600
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours,minutes,seconds)
        } else {
            return String(format: "%d:%02d", minutes,seconds)
        }
    }
    
}


fileprivate class ThisClass {}

extension Bundle {
    static func current() -> Bundle {
        return Bundle(for: ThisClass.self)
    }
}

extension UIImage {
   convenience init?(podAssetName: String) {
    let path = Bundle(for: ThisClass.self).resourcePath!
    let bundle = Bundle(path: path)

    self.init(named: podAssetName,
              in: bundle,
              compatibleWith: nil)
   }
}
