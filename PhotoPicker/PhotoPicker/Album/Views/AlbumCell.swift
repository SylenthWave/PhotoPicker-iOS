//
//  AlbumCell.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/1/9.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

class AlbumCell: UITableViewCell {

    private var assetId: String = ""
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.coverImageView.contentMode = .scaleAspectFill
        self.coverImageView.layer.cornerRadius = 4
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension AlbumCell {
    func setup(photoAlbum: PhotoAlbum) {
        if let photoAsset = photoAlbum.assetResult {
            self.assetId = photoAsset.localIdentifier
            PHImageManager.default().requestImage(for: photoAsset, targetSize: CGSize(width: 40, height: 40), contentMode: .default, options: nil) { (image, info) in
                if self.assetId == photoAsset.localIdentifier {
                    self.coverImageView.image = image
                }
            }
        }
        self.titleLabel.text = photoAlbum.name
        let result = PHAsset.fetchAssets(in: photoAlbum.assetCollection, options: nil)
        self.countLabel.text = "\(result.count)"
    }
}
