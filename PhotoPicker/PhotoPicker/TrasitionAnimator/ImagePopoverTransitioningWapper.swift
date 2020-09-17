//
//  AlbumTrasitionAnimator.swift
//  Photofetcher
//
//  Created by sylenthwave on 2020/2/23.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

//MARK: ImagePopoverTransitioningWapperDatasource
protocol ImagePopoverTransitioningWapperDatasource: NSObject {
    // the transitioning image
    func image(fetcher: @escaping (UIView) -> Void)
    // image original frame
    func imageOriginalFrame() -> CGRect
    // image final frame
    func imageFinalFrame() -> CGRect
    // when animation in scrollView
    // you should return the scrollView to aviod pan gesture conflict
    func simulanteousScrollView() -> UIScrollView?
    // you can add aniational animation when transition start
    func addAdditionalAnimaton(transitionWapper: ImagePopoverTransitioningWapper) -> (() -> Void)?
}

extension ImagePopoverTransitioningWapperDatasource {
    func simulanteousScrollView() -> UIScrollView? { return nil }
    func addAdditionalAnimaton(transitionWapper: ImagePopoverTransitioningWapper) -> (() -> Void)? { return nil }
}

//MARK: ImagePopoverTransitioningWapperDelegate
protocol ImagePopoverTransitioningWapperDelegate: NSObject {
    // the method will called when transition will start
    // you can use this method to make some preparaions
    func transitionWillStart(transition: ImagePopoverTransitioningWapper)
    // the method will called when transition will end
    // you can use this method to clean up
    func transitionWillEnd(transition: ImagePopoverTransitioningWapper, isComplete: Bool)
    // the method will called when trasition did completion
    func transitioningDidCompletion(transitioning: ImagePopoverTransitioningWapper)
}

extension ImagePopoverTransitioningWapperDelegate {
    func transitionWillStart(transition: ImagePopoverTransitioningWapper) { }
    func transitionWillEnd(transition: ImagePopoverTransitioningWapper, isComplete: Bool) { }
    func transitioningDidComplete(transitioning: ImagePopoverTransitioningWapper) { }
}

//MARK: ImagePopoverTransitioningWapper
class ImagePopoverTransitioningWapper: NSObject {
    
    public weak var datasoruce: ImagePopoverTransitioningWapperDatasource?
    public weak var delegate: ImagePopoverTransitioningWapperDelegate?
    
    // handle gesture conflict
    public var shouldSimultaneousHandleGesture: Bool = false
    
    private(set) lazy var animatedTransitioning: CustomAnimatedTransitioning = {
        let transitioning = CustomAnimatedTransitioning()
        return transitioning
    }()

    private var backgroundAlphaAnimator: UIViewPropertyAnimator?
    private var imageViewOriginalCenter: CGPoint = .zero
    private var dragTimes: Int = 0
    private var hasCancel: Bool = false

    lazy var imageView: UIView = {
        let imageView = UIView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init() {
        super.init()
        self.setupPushAnimation()
        self.setupPopAnimation()
        self.setupInteractiveAnimation()
    }
}

//MARK: push animation
extension ImagePopoverTransitioningWapper {
    
    private func setupPushAnimation() {
        
        self.animatedTransitioning.addAnimation(operation: .push) { [weak self] (context, customTransitioning) in
            guard let self = self else { return }
            self.delegate?.transitionWillStart(transition: self)

            let containerView = context.containerView
            guard let toView = context.view(forKey: .to) else { return }
            guard let fromView = context.view(forKey: .from) else { return }
            
            containerView.addSubview(toView)

            self.datasoruce?.image(fetcher: { [weak self] view in
                guard let self = self else { return }
                self.imageView.removeFromSuperview()
                
                self.imageView = view
                self.imageView.frame = self.datasoruce?.imageOriginalFrame() ?? .zero
                self.imageView.contentMode = .scaleAspectFit
                self.imageView.clipsToBounds = true
                containerView.addSubview(self.imageView)
            })
            
            fromView.alpha = 0
            toView.alpha = 1
            let animator = UIViewPropertyAnimator(duration: customTransitioning.duration, dampingRatio: 0.8) {
                self.imageView.contentMode = .scaleAspectFill
                self.imageView.frame = self.datasoruce?.imageFinalFrame() ?? .zero
            }
            
            if let animation = self.datasoruce?.addAdditionalAnimaton(transitionWapper: self) {
                animator.addAnimations(animation)
            }
            
            animator.addCompletion { position in
                if !context.transitionWasCancelled {
                    self.delegate?.transitioningDidCompletion(transitioning: self)
                }
                self.imageView.removeFromSuperview()
                context.completeTransition(!context.transitionWasCancelled)
            }
            animator.startAnimation()
        }
    }
    
}

//MARK: pop animation
extension ImagePopoverTransitioningWapper {
    
    func setupPopAnimation() {
        self.animatedTransitioning.addAnimation(operation: .pop) { [weak self] (context, customTransitioning) in
            guard let self = self else { return }
            self.delegate?.transitionWillStart(transition: self)

            let containerView = context.containerView
            guard let toView = context.view(forKey: .to) else { return }
            guard let fromView = context.view(forKey: .from) else { return }
            
            containerView.addSubview(toView)
            
            self.datasoruce?.image(fetcher: {[weak self] view in
                guard let self = self else { return }
                self.imageView.removeFromSuperview()
                
                self.imageView = view
                if let layer = self.imageView.layer as? AVPlayerLayer {
                    layer.videoGravity = .resizeAspect
                } else {
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.clipsToBounds = true
                }
                let frame = self.datasoruce?.imageOriginalFrame() ?? .zero
                self.imageView.frame = frame
                self.imageView.layoutIfNeeded()
                containerView.addSubview(self.imageView)
            })

            toView.alpha = 0
            fromView.alpha = 1
            let animator = UIViewPropertyAnimator(duration: customTransitioning.duration, dampingRatio: 0.88) {
                toView.alpha = 1
                fromView.alpha = 0
                if let layer = self.imageView.layer as? AVPlayerLayer {
                    layer.videoGravity = .resizeAspectFill
                } else {
                    self.imageView.contentMode = .scaleAspectFill
                }
                self.imageView.frame = self.datasoruce?.imageFinalFrame() ?? .zero
            }
            
            if let animation = self.datasoruce?.addAdditionalAnimaton(transitionWapper: self) {
                animator.addAnimations(animation)
            }
            
            animator.addCompletion { position in
                let isComplete = !context.transitionWasCancelled
                self.delegate?.transitionWillEnd(transition: self, isComplete: isComplete)
                self.imageView.removeFromSuperview()
                context.completeTransition(isComplete)
                if isComplete {
                    self.delegate?.transitioningDidCompletion(transitioning: self)
                }
            }
            animator.startAnimation()
        }
    }
}


//MARK: Interactive animation
extension ImagePopoverTransitioningWapper {
    
    func setupInteractiveAnimation() {
        
        // will start interactive transitioning
        self.animatedTransitioning.interactiveTransitioningWillStart { [weak self] context  in
            guard let self = self else { return }
            
            self.delegate?.transitionWillStart(transition: self)
            guard let fromView = context.view(forKey: .from) else { return }
            guard let toView = context.view(forKey: .to) else { return }
            let containerView = context.containerView
            containerView.addSubview(toView)
            fromView.alpha = 1.0
            self.datasoruce?.image(fetcher: {[weak self] view in
                guard let self = self else { return }
                self.imageView.removeFromSuperview()
                
                self.imageView = view
                if let layer = self.imageView.layer as? AVPlayerLayer {
                    layer.videoGravity = .resizeAspect
                } else {
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.clipsToBounds = true
                }
                self.imageView.frame = self.datasoruce?.imageOriginalFrame() ?? .zero
                containerView.addSubview(self.imageView)
                
            })
        }
        
        // interactive handler
        self.animatedTransitioning.interactiveHandler { [weak self] (context, gesture, customAnimatedTransitioning) in
            guard let self = self else { return }
            
            guard let fromView = context.view(forKey: .from) else { return }
            guard let toView = context.view(forKey: .to) else { return }
        
            let height = self.imageView.bounds.height < UIScreen.main.bounds.height ? UIScreen.main.bounds.height : (self.datasoruce?.imageOriginalFrame().height ?? 0)
            switch gesture.state {
            case .began:
                self.backgroundAlphaAnimator = UIViewPropertyAnimator(duration: 0.4, curve: .easeOut, animations: {
                    fromView.alpha = 0.0
                    toView.alpha = 1.0
                })
                if let animation = self.datasoruce?.addAdditionalAnimaton(transitionWapper: self) {
                    self.backgroundAlphaAnimator?.addAnimations(animation)
                }
                self.backgroundAlphaAnimator?.pauseAnimation()
                self.imageView.frame = self.datasoruce?.imageOriginalFrame() ?? .zero
                self.imageViewOriginalCenter = self.imageView.center
                self.dragTimes = 0
                self.hasCancel = false
            case .changed:
                
                if self.animatedTransitioning.canCancel,
                    self.shouldSimultaneousHandleGesture,
                    let scrollView = self.datasoruce?.simulanteousScrollView(),
                    scrollView.contentOffset.y > 0, context.isInteractive {
                    
                    toView.alpha = 0
                    self.backgroundAlphaAnimator?.stopAnimation(false)
                    self.backgroundAlphaAnimator?.finishAnimation(at: .start)
                    self.imageView.removeFromSuperview()
                    context.cancelInteractiveTransition()
                    context.completeTransition(false)
                    fromView.isHidden = false
                    self.hasCancel = true
                    self.delegate?.transitionWillEnd(transition: self, isComplete: false)
                    return
                }
                
                let p = gesture.translation(in: fromView)
                //print("pan location in toView = \(p)")
                self.imageView.center = CGPoint(x: self.imageViewOriginalCenter.x + p.x, y: self.imageViewOriginalCenter.y + p.y)
                
                var scaleFactor = (height - p.y) / height
                if scaleFactor > 1.0 {
                    scaleFactor = 1.0
                }
                if scaleFactor < 0.5 {
                    scaleFactor = 0.5
                }
                
                var alphaFactor = p.y / (UIScreen.main.bounds.height/2 - 100)
                if alphaFactor < 0 {
                    alphaFactor = 0
                }
                self.imageView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
                context.updateInteractiveTransition(alphaFactor)
                self.backgroundAlphaAnimator?.fractionComplete = alphaFactor
                print("changed")
                
            case .ended:
                
                // resolve the gesture conflict to cancel end animation
                if self.hasCancel { return }

                let p = gesture.translation(in: fromView)
                debugPrint("pan location in toView = \(p)")
                let shouldPop = p.y > 100

                if shouldPop {
                    self.backgroundAlphaAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                } else {
                    self.backgroundAlphaAnimator?.stopAnimation(false)
                    self.backgroundAlphaAnimator?.finishAnimation(at: .start)
                }

                let positionAnimator = UIViewPropertyAnimator(duration: self.animatedTransitioning.duration, dampingRatio: 0.7, animations: {
                    if let layer = self.imageView.layer as? AVPlayerLayer {
                        layer.videoGravity = .resizeAspectFill
                    } else {
                        self.imageView.contentMode = .scaleAspectFill
                    }
                    if shouldPop {
                        self.imageView.frame = self.datasoruce?.imageFinalFrame() ?? .zero
                    } else {
                        self.imageView.center = self.imageViewOriginalCenter
                        self.imageView.transform = .identity
                    }
                })
                positionAnimator.addCompletion { _ in
                    self.delegate?.transitionWillEnd(transition: self, isComplete: shouldPop)
                    toView.alpha = shouldPop ? 1 : 0
                    self.imageView.removeFromSuperview()
                    if shouldPop {
                        self.imageView.transform = .identity
                        context.finishInteractiveTransition()
                        context.completeTransition(true)
                        self.delegate?.transitioningDidCompletion(transitioning: self)
                    } else {
                        context.cancelInteractiveTransition()
                        context.completeTransition(false)
                        fromView.isHidden = false
                    }
                    
                }
                positionAnimator.startAnimation()
               
            case .cancelled:
                context.cancelInteractiveTransition()
                context.completeTransition(false)
                fromView.isHidden = false
            default: break
            }

        }
    }
    
}
