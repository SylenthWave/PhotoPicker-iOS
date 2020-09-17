//
//  AlbumListViewController.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/1/9.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit
import Photos

class AlbumListViewController: UIViewController {
    
    public var didSelectAlbum: ((PhotoAlbum) -> Void)?
    
    public var isHiddenVideoAblum: Bool = true
    
    private var albums: [PhotoAlbum] = []
        
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.registerCell(AlbumCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupTableView()
        self.loadAlbums()
    }
    
    func setupTableView() {
        self.view.addSubview(self.tableView)
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    }
    
    func loadAlbums() {
        PHAssetCollection.fetchAlbums(hiddenVideoAlbum: self.isHiddenVideoAblum) { albums in
            self.albums = albums
            self.tableView.reloadData()
        }
    }
}

extension AlbumListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(AlbumCell.self, forIndexPath: indexPath)
        let album = self.albums[indexPath.row]
        cell.setup(photoAlbum: album)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let photoAlbum = self.albums[indexPath.row]
        self.didSelectAlbum?(photoAlbum)
    }
}
