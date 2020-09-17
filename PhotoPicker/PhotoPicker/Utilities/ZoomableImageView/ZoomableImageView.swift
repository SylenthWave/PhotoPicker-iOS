//
//  ZoomableImageView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/13.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: Life
class ZoomableImageView: UIView {
    
    enum ZoomState {
        case original
        case zomming
        case full
    }
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {}
        return scrollView
    }()
    
    private(set) lazy var pinchGesture: UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer()
        gesture.addTarget(self, action: #selector(handlePinch(_:)))
        return gesture
    }()
    
    private(set) lazy var doubleClickTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(doubleClick(_:)))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    private lazy var tipView: UIView = {
        let view = UIView()
        view.bounds = CGRect(x: 0, y: 0, width: 10, height: 10)
        view.layer.cornerRadius = 5
        view.backgroundColor = UIColor.systemPink
        return view
    }()
    
    private(set) var zoomState: ZoomState = .original
    private var previousScale: CGFloat = 1.0
    private var imageKVOToken: NSKeyValueObservation?
    public var maxScaleFactor: CGFloat = 1.3
    public var normallyMaxSizeDelta: CGFloat = 300
    public var willZoom: (() -> Void)?
    public var didZoom: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.imageView)
        self.addGestureRecognizer(self.pinchGesture)
        self.addGestureRecognizer(self.doubleClickTapGesture)
        
        self.imageKVOToken = self.imageView.observe(\.image, options: .new, changeHandler: {[weak self] (imageView, value) in
            guard let self = self else { return }
            if self.zoomState == .original {
                self.scrollView.contentSize = self.originalSize(imageView: imageView)
                self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.contentSize)
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.imageKVOToken?.invalidate()
    }
    
}

//MAKR: Layout
extension ZoomableImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.imageView.bounds == .zero && self.scrollView.bounds == .zero {
            self.scrollView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)
        }
    }
}

//MARK: Double click
extension ZoomableImageView {
    @objc private func doubleClick(_ gesture: UITapGestureRecognizer) {
        self.willZoom?()
        switch self.zoomState {
        case .full:
            let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) {
                self.scrollView.contentSize = self.originalSize(imageView: self.imageView)
                self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.contentSize)
                self.resetScrollViewContentOffset(size: self.scrollView.contentSize)
            }
            animator.addCompletion { _ in
                // restore the imageView scale to identity
                self.imageView.bounds = CGRect(origin: .zero, size: self.originalSize(imageView: self.imageView))
                self.imageView.transform = .identity
                self.zoomState = .original
                self.previousScale = 1
                self.didZoom?()
            }
            animator.startAnimation()
        case .original, .zomming:
            self.resetAnthorPointPosition(gesture: gesture)
            let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) {
                self.scrollView.contentSize = self.maximumSize(imageView: self.imageView)
                self.imageView.frame = CGRect(x: 0, y: 0, width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height)
                self.resetScrollViewContentOffset(size: self.scrollView.contentSize)
            }
            animator.addCompletion { _ in
                self.zoomState = .full
                self.didZoom?()
            }
            animator.startAnimation()
        }
    }
    
    public func resetToOrigin() {
        self.imageView.bounds = CGRect(origin: .zero, size: self.originalSize(imageView: self.imageView))
        self.imageView.transform = .identity
        self.zoomState = .original
        self.previousScale = 1
    }
}

//MARK: Pinch gesture handler
extension ZoomableImageView {
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            self.willZoom?()
            gesture.scale = self.previousScale
            self.resetAnthorPointPosition(gesture: gesture)
        case .changed:
            self.imageView.transform = CGAffineTransform(scaleX: gesture.scale, y: gesture.scale)
        case .ended, .cancelled, .failed:
            let normallyMaxSize = self.maximumSize(imageView: self.imageView)
            
            let beyondMax = self.imageView.frame.width > normallyMaxSize.width
            let beyondMin = self.imageView.frame.width < self.scrollView.bounds.width
            
            // setup contentOffset when gesture end
            func setupScrollViewOffset() {
                var anchor = self.imageView.layer.anchorPoint
                let aspectImageSize = self.imageView.aspectFitImageSize(size: self.bounds.size)
                let topEdge = self.bounds.height/2 - aspectImageSize.height/2
                let bottomEdge = self.bounds.height/2 + aspectImageSize.height/2
                if anchor.x < 0.1 { anchor.x = 0 }
                if anchor.x > 0.9 { anchor.x = 1 }
                if anchor.y < ((topEdge/self.bounds.height) + 0.1) { anchor.y = 0 }
                if anchor.y > ((bottomEdge/self.bounds.height) - 0.1) { anchor.y = 1 }
                self.scrollView.contentOffset = CGPoint(x: (self.scrollView.contentSize.width - self.bounds.width) * anchor.x , y: (self.scrollView.contentSize.height - self.bounds.height) * anchor.y)
            }
            
            // setup vibration
            func vibration() {
                let vibration = UIImpactFeedbackGenerator(style: .light)
                if #available(iOS 13.0, *) {
                    vibration.impactOccurred(intensity: 0.8)
                } else {
                    vibration.impactOccurred()
                }
            }
            
            if beyondMax {
                // should change normally max size(equal scaling) to the real max size
                let shouldSetMaxSize: Bool = self.imageView.frame.width > normallyMaxSize.width + self.normallyMaxSizeDelta
                // set previous scale
                self.previousScale = gesture.scale
                
                let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) {
                    // change size
                    self.scrollView.contentSize = CGSize(
                        width: normallyMaxSize.width * (shouldSetMaxSize ? self.maxScaleFactor : 1.0),
                        height: normallyMaxSize.height * (shouldSetMaxSize ? self.maxScaleFactor : 1.0)
                    )
                    self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.contentSize)
                    // offset scrollView
                    setupScrollViewOffset()
                    // vibration when contentSize maximum
                    if shouldSetMaxSize { vibration() }
                }
                animator.addCompletion { position in
                    self.zoomState = .full
                    self.didZoom?()
                }
                animator.startAnimation()
                
            } else if beyondMin {
                let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) {
                    // change size
                    self.scrollView.contentSize = self.originalSize(imageView: self.imageView)
                    self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.contentSize)
                    // vibration when contentSize has minumum
                    vibration()
                }
                animator.addCompletion { position in
                    // restore the imageView scale to identity
                    self.imageView.bounds = CGRect(origin: .zero, size: self.originalSize(imageView: self.imageView))
                    self.imageView.transform = .identity
                    self.previousScale = 1.0
                    self.zoomState = .original
                }
                animator.startAnimation()
            } else {
                // set previous scale
                self.previousScale = gesture.scale
                
                // calculate scrollView contentSize height
                guard let imageSize = self.imageView.image?.size else { return }
                let height: CGFloat
                if imageSize.width > imageSize.height {
                    height = self.bounds.height
                } else {
                    let aspectFitImageSize = self.imageView.aspectFitImageSize(size: self.imageView.frame.size)
                    if aspectFitImageSize.height > self.bounds.height {
                        height = aspectFitImageSize.height
                    } else {
                        height = self.bounds.height
                    }
                }
                
                let animator = UIViewPropertyAnimator(duration: 0.4, curve: .easeInOut) {
                    // change size
                    self.scrollView.contentSize = CGSize(width: self.imageView.frame.width, height: height)
                    self.imageView.frame = CGRect(origin: .zero, size: self.scrollView.contentSize)
                    //reset content offset
                    setupScrollViewOffset()
                }
                animator.addCompletion { _ in
                    self.zoomState = .zomming
                    self.didZoom?()
                }
                animator.startAnimation()
            }
            
        default: break
        }
    }
}

//MARK: Zoom offset
extension ZoomableImageView {
    
    private func resetScrollViewContentOffset(size: CGSize) {
        
        // use current image anhorPhoint to calculated the offset point
        let anchor = self.imageView.layer.anchorPoint
        
        let handler = NSDecimalNumberHandler(roundingMode: .up, scale: 2, raiseOnExactness: true, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let anchorX = CGFloat(NSDecimalNumber(value: Double(anchor.x)).rounding(accordingToBehavior: handler).doubleValue)
        let anchorY = CGFloat(NSDecimalNumber(value: Double(anchor.y)).rounding(accordingToBehavior: handler).doubleValue)
        
        // original offset point
        var x = self.scrollView.contentSize.width * anchorX
        var y =  self.scrollView.contentSize.height * anchorY

        // the safe area for size
        let maxX = size.width - self.bounds.width/2
        let minX = self.bounds.width/2
        let minY = self.bounds.height/2
        let maxY = size.height - self.bounds.height/2
        
        // x coordnate safe area
        if x > maxX {
            x = size.width - self.bounds.width
        } else if x < minX {
            x = 0
        } else {
            x = x - self.bounds.width/2
        }
        
        // y coordnate safe area
        if y > maxY {
            y = size.height - self.bounds.height
        } else if y < minY {
            y = 0
        } else {
            y = y - self.bounds.height/2
        }
        
        // set offset
        self.scrollView.contentOffset = CGPoint(x: x, y: y)
        
    }
    
    // reset image view anthor point when gesture began
    private func resetAnthorPointPosition(gesture: UIGestureRecognizer) {
        let location = gesture.location(in: self.scrollView)
        self.imageView.resetAspectFitImageAnchorPoisitionToPoint(point: location, size: self.scrollView.contentSize)
        //self.tipView.center = point
        //self.scrollView.addSubview(self.tipView)
    }
    
    // normally maximum size, scale by image size
    private func maximumSize(imageView: UIImageView) -> CGSize {
        guard let imageSize = imageView.image?.size else { return .zero }
        if imageSize.width >= imageSize.height {
            let width = (imageSize.width * self.bounds.height) / imageSize.height
            return CGSize(width: width, height: self.bounds.height)
        } else {
            let width = self.bounds.width * 2.5
            let height = (imageSize.height * width) / imageSize.width
            return  CGSize(width: width, height: height)
        }
    }
    
    // the image view originalSize
    private func originalSize(imageView: UIImageView) -> CGSize {
        var size = imageView.imageViewAspectFitSizeForScreenSize
        if size.height < self.bounds.height { size.height = self.bounds.height }
        return size
    }
    
}

//MARK: UIImageView + Extension
extension UIImageView {
    
    var imageViewAspectFitSizeForScreenSize: CGSize {
        guard let imageSize = self.image?.size else { return .zero }
        let screenWidth = UIScreen.main.bounds.width
        let ratioHeight = (screenWidth * imageSize.height) / imageSize.width
        return CGSize(width: screenWidth, height: ratioHeight)
    }

     func aspectFitImageSize(size: CGSize) -> CGSize {
           guard let imageSize = self.image?.size else { return .zero }
           let ratioWidth = (size.height * imageSize.width) / imageSize.height
           let ratioHeight = (size.width * imageSize.height) / imageSize.width
           
           if self.bounds.width > ratioWidth {
               return CGSize(width: ratioWidth, height: size.height)
           } else {
               return CGSize(width: size.width, height: ratioHeight)
           }
       }
    
    @discardableResult
    func resetAspectFitImageAnchorPoisitionToPoint(point: CGPoint, size: CGSize) -> CGPoint {
        let aspectImageSize = self.aspectFitImageSize(size: size)
        
        var position: CGPoint
        let topEdge = self.bounds.height/2 - aspectImageSize.height/2
        let bottomEdge = self.bounds.height/2 + aspectImageSize.height/2
        if size.height == UIScreen.main.bounds.height {
            if point.y < topEdge {
                // 图片上边界
                position = CGPoint(x: point.x, y: topEdge)
            } else if point.y > bottomEdge {
                // 图片下边界
                position = CGPoint(x: point.x, y: bottomEdge)
            } else {
                // 图片中
                position = point
            }
        } else {
            position = point
        }
        
        
        self.layer.anchorPoint = CGPoint(x: position.x / self.frame.width, y: position.y / self.frame.height)
        self.layer.position = position
        return position
    }
}
