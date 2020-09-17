//
//  PhotoPickerOptionsInfo.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/4/10.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

public typealias PhotoPickerOptionsInfo = [PhotoPickerOptionsInfoItem]

extension Array where Element == PhotoPickerOptionsInfoItem {
    static let empty: PhotoPickerOptionsInfo = []
}

public enum PhotoPickerOptionsInfoItem {
    public enum PhotoDirection {
        case up
        case down
    }
    public enum MaximumSelectCount {
        case infinite
        case count(Int)
    }
    
    /// item count each row, default is 3
    case itemCountForRow(Int)
    /// the item spacing value, default is 0
    case itemMinimumSpacing(CGFloat)
    /// edge, default is 0
    case collectionViewEdge(CGFloat)
    /// photo direction, default down
    case photoDirection(PhotoDirection)
    /// Maximum count for Image, default is 9
    case maximumSelectCount(MaximumSelectCount)
    /// whether hidden video item, default is false
    case isHiddenVideo(Bool)
    /// Maximum count for video, default is infinite
    case maximumVideoSelectCount(MaximumSelectCount)
}

public struct PhotoPickerParsedOptionsInfo {
    
    public var itemMinimumSpacing: CGFloat = 3
    public var itemCountForRow: Int = 3
    public var collectionViewEdge: CGFloat = 0
    public var photoDirection: PhotoPickerOptionsInfoItem.PhotoDirection = .down
    public var isHiddenVideo: Bool = false
    public var maximumVideoSelectCount: PhotoPickerOptionsInfoItem.MaximumSelectCount = .infinite
    public var maximumSelectCount: PhotoPickerOptionsInfoItem.MaximumSelectCount = .count(9)
    
    init(_ info: PhotoPickerOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .itemCountForRow(let value): self.itemCountForRow = value
            case .itemMinimumSpacing(let value): self.itemMinimumSpacing = value
            case .collectionViewEdge(let value): self.collectionViewEdge = value
            case .photoDirection(let value): self.photoDirection = value
            case .isHiddenVideo(let value): self.isHiddenVideo = value
            case .maximumVideoSelectCount(let value): self.maximumVideoSelectCount = value
            case .maximumSelectCount(let value): self.maximumSelectCount = value
            }
        }
    }
}
