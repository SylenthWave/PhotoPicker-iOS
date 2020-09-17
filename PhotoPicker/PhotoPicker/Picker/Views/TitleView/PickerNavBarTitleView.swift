//
//  PickerNavBarTitleView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/2/20.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: PickerNavBarTitleView
class PickerNavBarTitleView: UIView {
    
    enum State {
        case open
        case close
    }
    
    // set title will reset layout
    public var title: String = "" {
        willSet {
            self.titleLabel.text = newValue
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    // trigger click return current state
    public var click: ((State) -> Void)?
    
    
    public var state: State = .close {
        didSet {
            UIView.animate(withDuration: 0.2) {
                switch self.state {
                case .open:
                    let radians: CGFloat = .pi
                    self.iconImageView.transform = self.iconImageView.transform.rotated(by: radians)
                case .close:
                    self.iconImageView.transform = .identity
                }
                
            }
        }
    }
    
    private let iconImageSize = CGSize(width: 16, height: 16)
    private let iconImageMergin: CGFloat = 10
    private let height: CGFloat = 44

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(podAssetName: "direction_arrow_down")
        return imageView
    }()
    
    public lazy var button: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupButton()
        self.setupTitleLabel()
        self.setupIconImageView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print(self.frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonAction() {
        if self.state == .close {
            self.state = .open
        } else {
            self.state = .close
        }
        self.click?(self.state)
    }
}

//MARK: Override
extension PickerNavBarTitleView {

    override var intrinsicContentSize: CGSize {
        let titleLabelSize = self.titleLabel.sizeThatFits(CGSize(width: CGFloat.leastNormalMagnitude, height: self.height))
        return CGSize(width: self.layoutMargins.left + self.layoutMargins.right + titleLabelSize.width + self.iconImageSize.width + self.iconImageMergin, height: self.height)
    }
}

//MARK: Layout
extension PickerNavBarTitleView {
    
    private func setupButton() {
        self.addSubview(self.button)
        NSLayoutConstraint.activate([
            self.button.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.button.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.button.topAnchor.constraint(equalTo: self.topAnchor),
            self.button.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    private func setupTitleLabel() {
        self.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: ((self.iconImageSize.width + self.iconImageMergin)/2)),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    private func setupIconImageView() {
        self.addSubview(self.iconImageView)
        NSLayoutConstraint.activate([
            self.iconImageView.trailingAnchor.constraint(equalTo: self.titleLabel.leadingAnchor, constant: -self.iconImageMergin),
            self.iconImageView.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            self.iconImageView.widthAnchor.constraint(equalToConstant: self.iconImageSize.width),
            self.iconImageView.heightAnchor.constraint(equalToConstant: self.iconImageSize.height)
        ])
    }
    
}
