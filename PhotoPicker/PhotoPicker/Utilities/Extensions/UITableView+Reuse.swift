//
//  UITableView+Reuse.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/1/9.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

protocol ReusableView: class {
    static var reuseIdentifier: String {get}
}

extension ReusableView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UIView: ReusableView {}

extension UICollectionView {
    
    func registerCell<T: UICollectionViewCell>(_ type: T.Type) {
        let bundle = Bundle(for: T.self)
        if bundle.path(forResource: String(describing: type), ofType: "nib") != nil, let nibs = bundle.loadNibNamed(type.reuseIdentifier, owner: nil, options: nil), nibs.count > 0 {
            self.register(UINib(nibName: type.reuseIdentifier, bundle: bundle), forCellWithReuseIdentifier: type.reuseIdentifier)
        } else {
            self.register(type, forCellWithReuseIdentifier: type.reuseIdentifier)
        }
    }
    
    func dequeueReuseCell<T: UICollectionViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: type.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
    
    func registerSupplementaryView<T: UICollectionReusableView>(_ type: T.Type, kind: String) {
        let bundle = Bundle(for: T.self)
        if bundle.path(forResource: String(describing: type), ofType: "nib") != nil, let nibs = bundle.loadNibNamed(type.reuseIdentifier, owner: nil, options: nil), nibs.count > 0 {
            self.register(UINib(nibName: type.reuseIdentifier, bundle: bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: type.reuseIdentifier)
        } else {
            self.register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: type.reuseIdentifier)
        }
    }

    func dequeueReuseSupplementaryView<T: UICollectionReusableView>(_ type: T.Type, kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        guard let supplementaryView = self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: type.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return supplementaryView
    }
    
}

extension UITableView {
    
    func registerCell<T: UITableViewCell>(_ type: T.Type) {
        let bundle = Bundle(for: T.self)
        if bundle.path(forResource: String(describing: type), ofType: "nib") != nil, let nibs = bundle.loadNibNamed(String(describing: type), owner: nil, options: nil), nibs.count > 0 {
            self.register(UINib(nibName: String(describing: type), bundle: bundle), forCellReuseIdentifier: T.reuseIdentifier)
        } else {
            self.register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
        }
    }
    
    func registerHeaderFooter<T: UIView>(_ type: T.Type) {
        let bundle = Bundle(for: T.self)
        if bundle.path(forResource: String(describing: type), ofType: "nib") != nil, let nibs = bundle.loadNibNamed(String(describing: type), owner: nil, options: nil), nibs.count > 0 {
            self.register(UINib(nibName: String(describing: type), bundle: bundle), forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        } else {
            self.register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        }
    }

    func dequeueReusableCell<T: UITableViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        return cell
    }
    
    func dequeueReusableHeaderFooter<T: UIView>(_ type: T.Type) -> T {
        guard let headerFooter = self.dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            fatalError("Could not dequeue header footer with identifier: \(T.reuseIdentifier)")
        }
        return headerFooter
    }
    
}
