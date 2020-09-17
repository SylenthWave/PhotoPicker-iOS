//
//  RoundProgressView.swift
//  PhotoPicker
//
//  Created by SylenthWave on 2020/6/8.
//  Copyright © 2020 SylenthWave. All rights reserved.
//

import UIKit

final class RoundProgressView: UIView {
    
    public var progress: CGFloat = 0 {
        didSet {
            self.progressView.progress = progress
        }
    }
    
    private lazy var progressView: InnerRoundProgressView = {
        let view = InnerRoundProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let edge: CGFloat = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
        self.addSubview(self.progressView)
        NSLayoutConstraint.activate([
            self.progressView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: edge),
            self.progressView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -edge),
            self.progressView.topAnchor.constraint(equalTo: self.topAnchor, constant: edge),
            self.progressView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -edge)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let center = CGPoint(x: rect.width/2, y: rect.height/2)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2)
        
        context.addArc(center: center, radius: rect.width/2 - edge, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        context.closePath()
        context.strokePath()
    }
    
}

private class InnerRoundProgressView: UIView {
    
    public var progress: CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    private var maxValue: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.width/2, y: rect.height/2)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.white.cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.addArc(center: center, radius: rect.width/2, startAngle: 3/4 * maxValue * CGFloat.pi, endAngle: (3/4 * maxValue + maxValue * self.progress) * CGFloat.pi, clockwise: false)
        context.addLine(to: center)
        context.closePath()
        context.fillPath()
    }
    
}

