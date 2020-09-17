//
//  Photofetcher.swift
//  Photofetcher
//
//  Created by SylenthWave on 2020/1/7.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

//MARK: - PhotoPicker
public struct PhotoPicker  {
    
    public typealias PickerControllers = (nav: PhotoPickerTransitionNavigationController, picker: PhotoPickerViewController)
    
    public static func presentPhotoPicker(in viewController: UIViewController, selectedAssets: [PHAsset] = [], optionsInfo: PhotoPickerOptionsInfo? = nil, completionHandler: ((PhotoPickerViewController.CompletionResult) -> Void)?) {
        PhotoPicker.authorization (In: viewController, completionHandler: {
            let pickerViewControllers = PhotoPicker.pickerController(optionsInfo: optionsInfo, selectedAssets: selectedAssets)
            pickerViewControllers.picker.completionHandler = completionHandler
            viewController.present(pickerViewControllers.nav, animated: true, completion: nil)
        })
    }
    
    public static func presentPhotoPickerWithoutDimiss(in viewController: UIViewController, selectedAssets: [PHAsset] = [], optionsInfo: PhotoPickerOptionsInfo? = nil, completionHandlerWithoutDimiss: ((PhotoPickerViewController.CompletionResult, PhotoPickerViewController) -> Void)?) {
        
        PhotoPicker.authorization(In: viewController, completionHandler: {
            let pickerViewControllers = PhotoPicker.pickerController(optionsInfo: optionsInfo, selectedAssets: selectedAssets)
            pickerViewControllers.picker.completionHandlerWithoutDimiss = completionHandlerWithoutDimiss
            viewController.present(pickerViewControllers.nav, animated: true, completion: nil)
        })
    }
    
    
    private static func pickerController(optionsInfo: PhotoPickerOptionsInfo? = nil, selectedAssets: [PHAsset] = []) -> PickerControllers {
        let pickerVC: PhotoPickerViewController
        if let info = optionsInfo {
            pickerVC = PhotoPickerViewController(optionsInfo: info, selectedAssets: selectedAssets)
        } else {
            pickerVC = PhotoPickerViewController(selectedAssets: selectedAssets)
        }
        let nav = PhotoPickerTransitionNavigationController(rootViewController: pickerVC)
        nav.modalPresentationStyle = .overCurrentContext
        nav.modalPresentationCapturesStatusBarAppearance = true
        return PickerControllers(nav,pickerVC)
    }
    
    
    public static func authorization(In viewController: UIViewController, completionHandler: @escaping () -> Void) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        if authorizationStatus == .authorized {
            completionHandler()
        } else {
            PHPhotoLibrary.requestAuthorization { state in
                DispatchQueue.main.async {
                    if state == .authorized {
                        completionHandler()
                    } else {
                        let appInfo = Bundle.main.infoDictionary
                        let appName = appInfo?["CFBundleDisplayName"] as? String
                        
                        let title = "没有获得相册访问权限，请到设置开启\(appName ?? "Photos")的相册访问权限"
                        let content = "请在系统设置中检查 \(appName ?? "Photos") 的相册访问权限是否开启"
                        
                        let alertVC = UIAlertController(title: title, message: content, preferredStyle: .alert)
                        alertVC.addAction(UIAlertAction(title: "知道了", style: .cancel, handler: nil))
                        viewController.present(alertVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
}

