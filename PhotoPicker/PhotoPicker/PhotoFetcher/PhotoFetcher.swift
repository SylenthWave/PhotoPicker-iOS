//
//  PhotoFetcher.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/7/11.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

//MARK: - PhotoFetcher
public final class PhotoFetcher {
    
    public var cachedImages: [UIImage] {
        return Array(cache.values)
    }
    
    private var downloadingAsset: [PHAsset : PHImageRequestID] = [:]
    private var cache: [String : UIImage] = [:]

    public init() { }
    
    public func fetch (
        asset: PHAsset,
        targetSize: CGSize = PHImageManagerMaximumSize,
        options: PHImageRequestOptions? = nil,
        contentMode: PHImageContentMode = .default,
        synchronousInBackground: Bool = false,
        progressHandler: @escaping (Double, Error?) -> Void,
        completionHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void)  {
       
        func synchronousOptions() -> PHImageRequestOptions {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = false
            options.isSynchronous = true
            return options
        }

        asset.fetchImage(targetSize: targetSize, options: options ?? synchronousOptions(), synchronousInBackground: synchronousInBackground, contentMode: contentMode) { (image, info) in
            
            completionHandler(image, info)
            
            if image == nil || info?[PHImageResultIsInCloudKey] != nil {
                
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                asset.fetchImage(targetSize: targetSize, options: options) {[weak self] (image, info) in
                    guard let self = self else { return }
                    self.cache[asset.localIdentifier] = image
                    completionHandler(image, info)
                }
                
                if self.downloadingAsset[asset] == nil {
                    self.fetchIcloudImage(asset: asset, targetSize: targetSize, contentMode: contentMode, progressHandler: progressHandler, completionHandler: {[weak self] (image, info) in
                        guard let self = self else { return }
                        self.cache[asset.localIdentifier] = image
                        completionHandler(image, info)
                    })
                }
            }
        }
    }
    
    public func fetchData (
        asset: PHAsset,
        progressHandler: @escaping (Double, Error?) -> Void,
        completionHandler: @escaping (Data?, [AnyHashable : Any]?) -> Void)  {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.resizeMode = .exact
        options.isSynchronous = true
        
        if self.downloadingAsset[asset] == nil {
            self.fetchIcloudImageData(asset: asset, progressHandler: progressHandler, completionHandler: completionHandler)
        }
    }
    
    public func cancelAllRequest() {
        guard downloadingAsset.keys.count > 0 else { return }
        for requestID in downloadingAsset.values {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        debugPrint("cancel all icloud download task!")
    }
    
    public func cancelAsset(_ asset: PHAsset) {
        guard let requestID = downloadingAsset[asset] else { return }
        PHImageManager.default().cancelImageRequest(requestID)
    }
    
    private func fetchIcloudImage(
        asset: PHAsset,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default,
        progressHandler: @escaping (Double, Error?) -> Void,
        completionHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        asset.fetchImage(targetSize: targetSize, options: options, contentMode: contentMode, progressHandler: { (progess, error, stop, info) in
            
            if let requestID = info?[PHImageResultRequestIDKey] as? Int32, self.downloadingAsset[asset] == nil {
                
                self.downloadingAsset[asset] = requestID
            }
            
            if progess >= 1.0, self.downloadingAsset[asset] != nil {
                debugPrint("download image completion)")
                self.downloadingAsset.removeValue(forKey: asset)
            }
            
            debugPrint("downloading image from icloud progress = \(progess)")
            progressHandler(progess, error)
            
        }) { (image, info) in
            completionHandler(image, info)
        }
    }
    
    private func fetchIcloudImageData(
        asset: PHAsset,
        progressHandler: @escaping (Double, Error?) -> Void,
        completionHandler: @escaping (Data?, [AnyHashable : Any]?) -> Void) {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        
        asset.fetchImageData(options: options, progressHandler: { (progess, error, stop, info) in
            
            if let requestID = info?[PHImageResultRequestIDKey] as? Int32, self.downloadingAsset[asset] == nil {
                
                self.downloadingAsset[asset] = requestID
            }
            
            if progess >= 1.0, self.downloadingAsset[asset] != nil {
                debugPrint("download image completion")
                self.downloadingAsset.removeValue(forKey: asset)
            }
            
            debugPrint("downloading image from icloud progress = \(progess)")
            progressHandler(progess, error)
            
        }) { (data, info) in
            completionHandler(data, info)
        }
    }
    
    private func cacheImage(_ key: String, image: UIImage) {
        
        
    }
}

extension PhotoFetcher {
    
    func fetchImages(assets: [PHAsset], targetSize: CGSize, progressHandler: ((Double) -> Void)?, completionHandler: @escaping ([UIImage]) -> Void) {
        let unitCount = 10
        var images: [UIImage] = []
        let group = DispatchGroup()
        let progress = Progress(totalUnitCount: Int64(assets.count * unitCount))
        
        for asset in assets {
            //1 enter group
            group.enter()
            
            //2 create sub progress
            let subProgress = Progress(totalUnitCount: Int64(unitCount), parent: progress, pendingUnitCount: Int64(unitCount))
            
            //fetch image
            let option = PHImageRequestOptions()
            option.isNetworkAccessAllowed = true
            option.isSynchronous = true
           
            self.fetchIcloudImage(asset: asset, targetSize: targetSize, progressHandler: { (progressValue, error) in
                subProgress.completedUnitCount = Int64(progressValue * Double(unitCount))
                if error != nil {
                    subProgress.cancel()
                }
                progressHandler?(progress.fractionCompleted)
                debugPrint("fetch image progress \(progress.fractionCompleted)")
            }) { (image, info) in
                if let img = image {
                    images.append(img)
                }
                group.leave()
            }
        }
        
        // call back
        group.notify(queue: .main) {
            completionHandler(images)
        }
    }
    
}

//MARK: - PHAsset
extension PHAsset {
    
    func fetchImage(targetSize: CGSize,
                    options: PHImageRequestOptions? = nil,
                    synchronousInBackground: Bool = true,
                    contentMode: PHImageContentMode = .default,
                    progressHandler: PHAssetImageProgressHandler? = nil,
                    completionHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        
        if progressHandler != nil {
            options?.progressHandler = { progress, error, stop, info in
                DispatchQueue.main.async {
                    progressHandler?(progress, error, stop, info)
                }
            }
        }
        
        if options?.isSynchronous == true && synchronousInBackground {
            DispatchQueue(label: "com.photopicker.downloader").async {
                PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) in
                    DispatchQueue.main.async {
                        completionHandler(image, info)
                    }
                }
            }
        } else {
            PHImageManager.default().requestImage(for: self, targetSize: targetSize, contentMode: contentMode, options: options) { (image, info) in
                completionHandler(image, info)
            }
        }
    }

    func fetchImageData(options: PHImageRequestOptions?,
                        progressHandler: PHAssetImageProgressHandler?,
                        completionHandler: @escaping ((Data?, [AnyHashable : Any]?) -> Void)) {

        if progressHandler != nil {
            options?.progressHandler = { progress, error, stop, info in
                DispatchQueue.main.async {
                    progressHandler?(progress, error, stop, info)
                }
            }
        }
        
        if options?.isSynchronous == true {
            DispatchQueue(label: "com.photopicker.downloader").async {
                PHImageManager.default().requestImageData(for: self, options: options) { (data, str, orientiation, info) in
                    DispatchQueue.main.async {
                        completionHandler(data, info)
                    }
                }
            }
        } else {
            PHImageManager.default().requestImageData(for: self, options: options) { (data, str, orientiation, info) in
                completionHandler(data, info)
            }
        }
    }
    
    func fetchVideo(options: PHVideoRequestOptions? = nil,
                    progressHandler: PHAssetImageProgressHandler? =  nil,
                    completionHandler: @escaping ((AVAsset?, [AnyHashable : Any]?) -> Void)) {
        
        if options != nil {
            options?.progressHandler =  { progress, error, stop, info in
                DispatchQueue.main.async {
                    progressHandler?(progress, error, stop, info)
                }
            }
        }
        
        options?.progressHandler = progressHandler
        PHImageManager.default().requestAVAsset(forVideo: self, options: options) { (avAsset, mix, info) in
            guard let avAsset = avAsset else { return }
            DispatchQueue.main.async {
                completionHandler(avAsset, info)
            }
        }
    }
    
}

//MARK: - PHAssetCollection
extension PHAssetCollection {
    
       static func fetchAlbums(hiddenVideoAlbum:Bool = false, completionHandler: @escaping ([PhotoAlbum]) -> Void) {
           
           // fetch all albums
           let smartAlbumCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
           let userAlbumCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
           let allAssetCount = PHAsset.fetchAssets(with: nil).count
           
           // fetch collection in background thread
           var albums: [PhotoAlbum] = []
           DispatchQueue.global().async {
               smartAlbumCollections.enumerateObjects { (collection, index, stop) in
                   let collectionAssets = PHAsset.fetchAssets(in: collection, options: nil)
                   let lastestAsset = collectionAssets.lastObject
                   if collectionAssets.count == allAssetCount  {
                       albums.insert(PhotoAlbum(name: collection.localizedTitle ?? "", assetResult: lastestAsset, assetCollection: collection), at: 0)
                   } else if lastestAsset != nil {
                       if !(hiddenVideoAlbum && collection.assetCollectionSubtype == .smartAlbumVideos) {
                           albums.append(PhotoAlbum(name: collection.localizedTitle ?? "", assetResult: lastestAsset, assetCollection: collection))
                       }
                   }
               }
               
               userAlbumCollections.enumerateObjects { (collection, index, stop) in
                   let lastestAsset = PHAsset.fetchAssets(in: collection, options: nil).lastObject
                   if lastestAsset != nil {
                       albums.append(PhotoAlbum(name: collection.localizedTitle ?? "", assetResult: lastestAsset, assetCollection: collection))
                   }
               }
               
               DispatchQueue.main.async {
                   completionHandler(albums)
               }
           }
       }
}

// - PhotoAlbum
struct PhotoAlbum {
    let name: String
    let assetResult: PHAsset?
    let assetCollection: PHAssetCollection
    var fetchResultOption: PHFetchOptions?
    lazy var collectionResults: PHFetchResult<PHAsset> = {
        return PHAsset.fetchAssets(in: self.assetCollection, options: self.fetchResultOption)
    }()
}

extension PHAssetCollection {
    var photosCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        return result.count
    }

    var videoCount: Int {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        let result = PHAsset.fetchAssets(in: self, options: fetchOptions)
        return result.count
    }
}
