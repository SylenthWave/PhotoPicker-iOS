//
//  ImageFetcher.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/7.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

class ImageFetchOpeation: Operation {
    
    var identifier: String
    var imageData: Data
    
    private(set) var fetchedImage: UIImage?
    
    var fetchImageSize: CGSize?
    
    init(identifier: String, imageData: Data) {
        self.imageData = imageData
        self.identifier = identifier
        super.init()
    }
    
    override func main() {
        let size = fetchImageSize ?? CGSize(width: UIScreen.main.bounds.size.width * 2, height: UIScreen.main.bounds.size.height * 2)
        self.fetchedImage = self.downsample(data: imageData, to: size, scale: UIScreen.main.scale)
    }
    
    private func downsample(data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache : false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        
        let maxDimentionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways : true,
            kCGImageSourceCreateThumbnailWithTransform : true,
            kCGImageSourceShouldCacheImmediately : true,
            kCGImageSourceThumbnailMaxPixelSize : maxDimentionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }

}

class ImageFetcher {
            
    public var fetchImageSize: CGSize?
    
    private let serialAccessQueue = OperationQueue()
    
    private let fetchQueue = OperationQueue()

    private var completionHandlers = [String : [(UIImage?) -> Void]]()
    
    private var cache = NSCache<NSString, UIImage>()
    
    init() {
        serialAccessQueue.maxConcurrentOperationCount = 1
    }
    
    public func fetchAsync(_ identifier: String, imageData: Data, completion: ((UIImage?) -> Void)? = nil) {
        
        serialAccessQueue.addOperation {
            
            if let completion = completion {
                let handlers = self.completionHandlers[identifier, default: []]
                self.completionHandlers[identifier] = handlers + [completion]
            }
            
            self.fetchData(for: imageData, identifier: identifier)
        }
    }
    
    public func fetchedData(for identifier: String) -> UIImage? {
        return cache.object(forKey: NSString(string: identifier))
    }
    
    public func cancelFetch(_ identifier: String) {
        serialAccessQueue.addOperation {
            self.fetchQueue.isSuspended = true
            defer {
                self.fetchQueue.isSuspended = false
            }
            
            self.operation(for: identifier)?.cancel()
            self.completionHandlers[identifier] = nil
        }
    }
    
    private func fetchData(for imageData: Data, identifier: String) {
        guard operation(for: identifier) == nil else { return }
        
        if let data = fetchedData(for: identifier) {
            invokeCompletionHandlers(for: identifier, with: data)
        } else {
            let operation = ImageFetchOpeation(identifier: identifier, imageData: imageData)
            operation.fetchImageSize = fetchImageSize
            operation.completionBlock = { [weak operation] in
                guard let fetchedImage = operation?.fetchedImage else { return }
                self.cache.setObject(fetchedImage, forKey: NSString(string: identifier))

                self.serialAccessQueue.addOperation {
                    self.invokeCompletionHandlers(for: identifier, with: fetchedImage)
                }
            }
            
            fetchQueue.addOperation(operation)
        }
    }
    
    private func operation(for identifier: String) -> ImageFetchOpeation? {
        for case let fetchOperation as ImageFetchOpeation in fetchQueue.operations
            where !fetchOperation.isCancelled && fetchOperation.identifier == identifier {
            return fetchOperation
        }
        
        return nil
    }

    private func invokeCompletionHandlers(for identifier: String, with fetchedData: UIImage) {
        let completionHandlers = self.completionHandlers[identifier, default: []]
        self.completionHandlers[identifier] = nil

        for completionHandler in completionHandlers {
            DispatchQueue.main.async {
                completionHandler(fetchedData)
            }
        }
    }
    
}
