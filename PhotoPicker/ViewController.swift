//
//  ViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/1/7.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tappedAlbumButton(_ sender: Any) {
        PhotoPicker.presentPhotoPicker(in: self) { (result) in
            print(result.assets)
        }
    }
}

