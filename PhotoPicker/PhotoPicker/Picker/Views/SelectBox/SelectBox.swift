//
//  SelectBox.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/3/3.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

//MARK: Life
class SelectBox: UIView {
    
    enum State: Equatable {
        case selected
        case selectedWithCount(count:Int, animated: Bool)
        case unselected
        case disable
    }
    
    // change the select box state
    public var changeState: ((SelectBox) -> Void)?
    
    public var currentState: State = .unselected {
        willSet {
            self.resetImageView(state: newValue)
        }
    }
    
    public var selectedImage: UIImage? = UIImage(podAssetName: "circle_selected_image")
    public var unselectImage: UIImage? = UIImage(podAssetName: "unselect_image")
    public var resetSelectImagePostion: CGRect = .zero {
        willSet {
            self.selectImageView.removeFromSuperview()
            self.addSubview(self.selectImageView)
            NSLayoutConstraint.activate([
                self.selectImageView.widthAnchor.constraint(equalToConstant: newValue.width),
                self.selectImageView.heightAnchor.constraint(equalToConstant: newValue.height),
                self.selectImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -newValue.origin.x),
                self.selectImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: newValue.origin.y)
            ])
        }
    }


    private lazy var backgroundButton: UIButton = {
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(self.tappedSelectButton(sender:)), for: .touchUpInside)
        return btn
    }()

    private(set) lazy var selectImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = self.unselectImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.text = "0"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.selectImageView.layer.cornerRadius = self.selectImageView.bounds.width/2
    }
    
}

//MARK: Setup
extension SelectBox {
    
    private func setup() {
        self.backgroundColor = UIColor.clear
        self.setupBackgroundButton()
        self.setupSelectImageView()
        self.setupNumberLabel()
        self.currentState = .unselected
    }
    
    private func setupBackgroundButton() {
        self.addSubview(self.backgroundButton)
        NSLayoutConstraint.activate([
            self.backgroundButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.backgroundButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.backgroundButton.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundButton.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    private func setupSelectImageView() {
        if !self.subviews.contains(self.selectImageView) {
            self.addSubview(self.selectImageView)
            NSLayoutConstraint.activate([
                self.selectImageView.widthAnchor.constraint(equalTo: self.widthAnchor),
                self.selectImageView.heightAnchor.constraint(equalTo: self.heightAnchor),
                self.selectImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                self.selectImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
        }
    }
    
    private func setupNumberLabel() {
        self.addSubview(self.numberLabel)
        NSLayoutConstraint.activate([
            self.numberLabel.centerXAnchor.constraint(equalTo: self.selectImageView.centerXAnchor),
            self.numberLabel.centerYAnchor.constraint(equalTo: self.selectImageView.centerYAnchor)
        ])
    }

}

//MARK: Action
extension SelectBox {
    
    @objc private func tappedSelectButton(sender: UIButton) {
        self.changeState?(self)
    }
    
    private func resetImageView(state: State) {
        self.backgroundButton.isEnabled = true
        switch state {
        case .selected:
            
            self.selectImageView.image = self.selectedImage
            self.selectImageView.backgroundColor = UIColor.clear
            self.numberLabel.text = ""
            self.numberLabel.isHidden = true
            
        case .selectedWithCount(let count, let animated):
            
            self.selectImageView.image = nil
            self.selectImageView.backgroundColor = UIColor.green
            self.numberLabel.isHidden = false
            self.numberLabel.text = "\(count)"
            //show spring bounce animation
            if animated {
                self.selectImageView.springBounce()
            }
            
        case .unselected:
            
            self.selectImageView.image = self.unselectImage
            self.selectImageView.backgroundColor = UIColor.clear
            self.numberLabel.text = ""
            self.numberLabel.isHidden = true

        case .disable:
            
            self.selectImageView.image = UIImage(podAssetName: "select_disable_icon")
            self.selectImageView.backgroundColor = UIColor.clear
            self.numberLabel.text = ""
            self.numberLabel.isHidden = true
            self.backgroundButton.isEnabled = false
            
        }
        
    }
    
}
