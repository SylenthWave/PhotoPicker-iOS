//
//  CenterForceCollectionViewLayout.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/5/28.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class CenterForceCollectionViewLayout: UICollectionViewLayout {
    
    var cacheAttirbutes: [UICollectionViewLayoutAttributes] = []

    var totalSize: CGSize = .zero
    var itemSpecing: CGFloat = 20
    var itemSize: CGSize = CGSize(width: 200, height: 200)
    var resetOffset: Bool = true
    var transformScale: CGFloat = 200
    var distanceFactor: CGFloat = 0.7
    var offsetDelta: CGFloat = 200
    
    var itemCount: Int?

    var itemComponentWidth: CGFloat {
        return itemSize.width + (itemSpecing * 2)
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        self.itemSize = CGSize(width: collectionView.bounds.width - 2*itemSpecing , height: collectionView.bounds.height - 80)
        if itemCount == nil { itemCount = collectionView.numberOfItems(inSection: 0) }
        if itemCount == 0 { return .zero }
        totalSize = CGSize(width: itemComponentWidth * CGFloat(itemCount ?? 0), height: itemSize.height)
        return CGSize(width: totalSize.width , height: totalSize.height)
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = self.collectionView else { return }
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
    }

    func attributesIn(rect: CGRect) -> [UICollectionViewLayoutAttributes] {
        
        let originX = rect.origin.x
        let maxX = rect.maxX

        let firstIndex = Int(max(0, floor(abs(originX/itemComponentWidth))))
        let lastIndex = Int(floor((maxX)/itemComponentWidth))
        if firstIndex > lastIndex { return [] }

        var attributes: [UICollectionViewLayoutAttributes] = []
        if lastIndex - firstIndex == 0 {
            if let attribute = self.attributeAtIndex(index: 0) {
                attributes.append(attribute)
            }
        } else {
            for times in 0 ..< (lastIndex - firstIndex) {
                let index = firstIndex + times
                if let attribute = self.attributeAtIndex(index: index) {
                    attributes.append(attribute)
                }
            }
        }
        return attributes
    }
    
    private func configureAttributes(for attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = self.collectionView else { return }
        let offset =  collectionView.contentOffset

        let visualRect = CGRect(x: offset.x, y: offset.y, width: collectionView.bounds.width, height: collectionView.bounds.height)
        let visualCenterX = visualRect.midX
        let attributeCenterX =  attributes.center.x

        let distance = abs(visualCenterX - attributeCenterX)
        let scale = CGFloat(transformScale / (transformScale + distance * (1 - distanceFactor) ))
        attributes.zIndex = Int(scale * 100000)
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0)
    }

    func attributeAtIndex(index: Int) -> UICollectionViewLayoutAttributes? {
        if itemCount == 0 { return nil }

        let x = itemSpecing + itemComponentWidth * CGFloat(index)
        let times = Int(floor(x/(totalSize.width)))
        let item = index - times * (itemCount ?? 0)
        
        let attribute = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: 0))
        attribute.frame = CGRect(x: x, y: 40, width: itemSize.width, height: itemSize.height)
        self.configureAttributes(for: attribute)
        return attribute
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.attributesIn(rect: rect)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.attributeAtIndex(index: indexPath.row)
    }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = self.collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        let idx = proposedContentOffset.x == 0 ? 0 : floor(proposedContentOffset.x/itemComponentWidth)
        guard let attribute = self.attributeAtIndex(index: Int(idx)) else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        var x: CGFloat = attribute.frame.minX
        if collectionView.contentOffset.x >= self.collectionViewContentSize.width - collectionView.bounds.width {
            x = self.collectionViewContentSize.width - collectionView.bounds.width
        }
        return CGPoint(x: x, y: proposedContentOffset.y)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}


