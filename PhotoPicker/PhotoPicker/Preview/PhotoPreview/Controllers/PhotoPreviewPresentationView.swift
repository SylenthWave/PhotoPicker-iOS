//
//  PhotoPreviewPresentationView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/7.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

typealias RepresentationView = PhotoPreviewRepresentationView & PhotoPreviewRepresentationViewDelegate

//MARK: PhotoPreviewRepresentationViewDelegate
protocol PhotoPreviewRepresentationViewDelegate: NSObject {
    var backButton: UIButton { get }
    func didUpdatePhotoStroage(photoStorage: PhotoStorage)
}

//MARK: PhotoPreviewRepresentationView
class PhotoPreviewRepresentationView: UIView {
    
    var photoStorage: PhotoStorage?
    var currentCount: Int = 0
    weak var previewViewController: PhotoPreviewViewController?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return  view == self ? nil : view
    }
}

//MARK: PhotoPreviewViewControllerDelegate
protocol PhotoPreviewViewControllerDelegate: NSObject {
    func representationView() -> RepresentationView
}
