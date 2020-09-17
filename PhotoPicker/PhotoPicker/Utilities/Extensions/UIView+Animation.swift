//
//  UIView+Animation.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/5.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

extension UIView {
    
    public class func loadNib<T: UIView>(_ type: T.Type) -> T {
        let typeString = String(describing: type)
        let boundle = Bundle(for: T.self)
        let view = boundle.loadNibNamed(typeString, owner: nil, options: nil)?.first as! T
        return view
    }
    
    // spring bounce animation
    public func springBounce(duration: TimeInterval = 0.7, damping: CGFloat = 0.3, scale: CGFloat = 0.6) {
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: damping) {
            self.transform = CGAffineTransform.identity
        }
        animator.startAnimation()
    }
    
}
