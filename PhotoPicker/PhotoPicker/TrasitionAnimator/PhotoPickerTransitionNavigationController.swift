//
//  CustomTransitionNavigationController.swift
//  TestAnimationTransition
//
//  Created by SylenthWave on 2020/3/14.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: PhotoPickerTransitionNavigationController
public class PhotoPickerTransitionNavigationController: UINavigationController {
    
    var transitionWapper: ImagePopoverTransitioningWapper

    override init(rootViewController: UIViewController) {
        self.transitionWapper = ImagePopoverTransitioningWapper()
        super.init(rootViewController: rootViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.transitionWapper = ImagePopoverTransitioningWapper()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.transitionWapper = ImagePopoverTransitioningWapper()
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.delegate = self
    }
}

//MARK: UINavigationControllerDelegate
extension PhotoPickerTransitionNavigationController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            self.transitionWapper.animatedTransitioning.operation = .push
            return self.transitionWapper.animatedTransitioning
        case .pop:
            if self.transitionWapper.animatedTransitioning.isInteractive {
                self.transitionWapper.animatedTransitioning.operation = .interactive
            } else {
                self.transitionWapper.animatedTransitioning.operation = .pop
            }
            return self.transitionWapper.animatedTransitioning
        default: return nil
        }
    }
        
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.transitionWapper.animatedTransitioning.interactiveTransition
    }
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is PhotoPickerViewController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is PhotoPickerViewController {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
}
