//
//  AlbumWapperViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/1.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: AlbumWapperViewController
class AlbumWapperViewController: UIViewController {
    
    enum AlbumAnimationState {
        case show
        case dismiss
    }
    
    // handler dismiss event
    public var dismissHandler: (() -> Void)?
    
    // refresh action
    public var refreshAlbum: ((PhotoAlbum) -> Void)?
    
    public var isHiddenVideo: Bool = false {
        didSet {
            self.albumsVC.isHiddenVideoAblum = self.isHiddenVideo
        }
    }

    private lazy var albumsVC: AlbumListViewController = {
        let vc = AlbumListViewController()
        return vc
    }()
    
    private lazy var blurView: UIVisualEffectView = {
        let effect: UIBlurEffect
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .prominent)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedBlackView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
   
    public func presentedIn(_ viewController: UIViewController) {
        viewController.addChild(self)
        viewController.view.addSubview(self.view)
        self.willMove(toParent: viewController)
        self.animationAlbumList(state: .show)
    }
    
    public func dismiss() {
        self.animationAlbumList(state: .dismiss)
    }

}

//MARK: Private methods
extension AlbumWapperViewController {
    
    private func setup() {
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(self.blurView)
        NSLayoutConstraint.activate([
            self.blurView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.blurView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.blurView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.blurView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.albumsVC.didSelectAlbum = self.refreshAlbum
    }
    
    @objc private func tappedBlackView() {
        self.animationAlbumList(state: .dismiss)
        self.dismissHandler?()
    }

    private func animationAlbumList(state: AlbumAnimationState) {
        
        let barHeight: CGFloat = (self.navigationController?.navigationBar.bounds.height ?? 44) + UIApplication.shared.statusBarFrame.height
        let duration: TimeInterval = 0.35
        
        switch state {
        case .show:
            
            self.addChild(self.albumsVC)
            self.view.addSubview(self.albumsVC.view)
            self.albumsVC.willMove(toParent: self)
            self.albumsVC.view.frame = CGRect(x: 0, y: barHeight, width: self.view.bounds.width, height: 0)
            self.albumsVC.view.layoutIfNeeded()
            self.blurView.alpha = 0
            UIView.animate(withDuration: duration, animations: {
                self.albumsVC.view.frame = CGRect(x: 0, y: barHeight, width: self.view.bounds.width, height: self.view.bounds.height - barHeight - 100)
                self.albumsVC.view.layoutIfNeeded()
                self.blurView.alpha = 1.0
            })
            
        case .dismiss:
            
            self.dismissHandler?()
            self.albumsVC.view.layoutIfNeeded()
            UIView.animate(withDuration: duration, animations: {
                self.albumsVC.view.frame = CGRect(x: 0, y: barHeight, width: self.view.bounds.width, height: 0)
                self.albumsVC.view.layoutIfNeeded()
                self.blurView.alpha = 0
            }) { animated in
                self.albumsVC.removeFromParent()
                self.albumsVC.view.removeFromSuperview()
                self.removeFromParent()
                self.view.removeFromSuperview()
            }
            
        }
    }
    
}
