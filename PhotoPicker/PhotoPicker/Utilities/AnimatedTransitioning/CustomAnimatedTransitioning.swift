//
//  CustomAnimatedTransitioning.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/24.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: InteractiveTransition
class InteractiveTransition: NSObject, UIViewControllerInteractiveTransitioning {
    
    public var willStartInteractiveTransition: ((UIViewControllerContextTransitioning) -> Void)?
    
    public var context: UIViewControllerContextTransitioning?

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.context = transitionContext
        self.willStartInteractiveTransition?(transitionContext)
    }
}

//MARK: CustomAnimatedTransitioning
class CustomAnimatedTransitioning: NSObject {
    
    enum Operation {
        case push
        case pop
        case interactive
    }
    
    // Animating druation
    public var duration: TimeInterval = 0.5
    
    // Operation
    public var operation: Operation = .push
    
    public var isInteractive: Bool {
        return self.interactiveTransition != nil
    }
    
    private(set) var canCancel: Bool = false
    
    // Pan Gesture
    private(set) lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_ :)))
        return gesture
    }()
    
    // Current trasitioning context
    private(set) var context: UIViewControllerContextTransitioning?
    
    // Interactive transition
    private(set) var interactiveTransition: InteractiveTransition?
    
    // callback
    private var pushAnimation: ((UIViewControllerContextTransitioning, CustomAnimatedTransitioning) -> Void)?
    private var popAnimation: ((UIViewControllerContextTransitioning, CustomAnimatedTransitioning) -> Void)?
    private var interactiveHandler: ((UIViewControllerContextTransitioning, UIPanGestureRecognizer, CustomAnimatedTransitioning) -> Void)?
    private var interactiveWillStart: ((UIViewControllerContextTransitioning) -> Void)?
    private var beganGesture: UIPanGestureRecognizer?
    
    // Add aniamtion for context
    func addAnimation(operation: Operation, animation: @escaping (UIViewControllerContextTransitioning, CustomAnimatedTransitioning) -> Void) {
        switch operation {
        case .push:
            self.pushAnimation = animation
        case .pop:
            self.popAnimation = animation
        case .interactive:
            fatalError()
        }
    }
    
    // Interactive transition will start
    func interactiveTransitioningWillStart(context: @escaping (UIViewControllerContextTransitioning) -> Void) {
        self.interactiveWillStart = context
    }
    
    // Gesture handle with context
    func interactiveHandler(context: @escaping (UIViewControllerContextTransitioning, UIPanGestureRecognizer, CustomAnimatedTransitioning) -> Void) {
        self.interactiveHandler = context
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let context = self.context else { return }
        guard let toVC = context.viewController(forKey: .to) else { return }
        switch gesture.state {
        case .began:
            self.beganGesture = gesture
            self.interactiveTransition = InteractiveTransition()
            toVC.navigationController?.popViewController(animated: true)
            let group = DispatchGroup()
            group.enter()
            self.interactiveTransition?.willStartInteractiveTransition = {[weak self] context in
                guard let self = self else { return }
                self.context = context
                group.leave()
                self.interactiveWillStart?(context)
                self.interactiveHandler?(context, gesture, self)
                self.canCancel = true
            }
        case .cancelled, .failed, .ended, .possible:
            if let context = self.interactiveTransition?.context {
                self.interactiveHandler?(context, gesture, self)
                self.interactiveTransition = nil
                self.canCancel = false
            }
        case .changed:
            if let context = self.interactiveTransition?.context {
                self.interactiveHandler?(context, gesture, self)
            }
        @unknown default:
            break
        }
       
    }
}

//MARK: CustomAnimatedTransitioning
extension CustomAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        self.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.context = transitionContext
        guard let toView = transitionContext.view(forKey: .to) else { return }
        switch self.operation {
        case .push:
            toView.addGestureRecognizer(self.panGesture)
            self.pushAnimation?(transitionContext, self)
        case .pop:
            self.popAnimation?(transitionContext, self)
        case .interactive:
            fatalError()
        }
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        // to resolve context retain cycle
        if transitionCompleted && self.operation != .push {
            self.context = nil
        }
    }
    
}
