//
//  PickerStorage.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/4/15.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

protocol PhotoStorageDelegate: class {
    func didUpdateStorage(action: PhotoStorage.Action)
}

class PhotoStorage {
    enum Action: Equatable {
        
        case add(asset: PHAsset)
        case remove(asset: PHAsset)
        
        var asset: PHAsset {
            switch self {
            case .add(let asset): return asset
            case .remove(let asset): return asset
            }
        }
    }
    
    var isMuteVideo: Bool = true
    var isOriginal: Bool = false
    var offsetIndex: Int = 0
    var resultOffset: Int = 0
    var currentAsset: PHAsset?
    public var selectedAssets: [PHAsset] = []
    var album: PhotoAlbum
    weak var delegate: PhotoStorageDelegate?
    
    init(album: PhotoAlbum) {
        self.album = album
    }
    
    deinit {
        debugPrint("storage deinit")
    }
    
    func addAsset(_ asset: PHAsset) {
        self.selectedAssets.append(asset)
        self.delegate?.didUpdateStorage(action: .add(asset: asset))
    }
    
    func removeAsset(_ asset: PHAsset) {
        guard let idx = self.selectedAssets.firstIndex(of: asset) else { return }
        self.selectedAssets.remove(at: idx)
        self.delegate?.didUpdateStorage(action: .remove(asset: asset))
    }
}
