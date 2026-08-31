//
//  AMMarkdownTableCellView.swift
//  ChinaHomelife247
//
//  Created by shenxiaofei on 2026/3/27.
//  Copyright © 2026 shenxiaofei. All rights reserved.
//

import UIKit

final class AMMarkdownTableCellView: UIView {
    var lineColor: UIColor = UIColor.hex(string: "#E9E9E9")
    var lineWidth: CGFloat = 1.0 / UIScreen.main.scale
    
    var drawTop: Bool = false
    var drawLeft: Bool = false
    var drawRight: Bool = true
    var drawBottom: Bool = true
    
    private let topLayer = CALayer()
    private let leftLayer = CALayer()
    private let rightLayer = CALayer()
    private let bottomLayer = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(topLayer)
        layer.addSublayer(leftLayer)
        layer.addSublayer(rightLayer)
        layer.addSublayer(bottomLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topLayer.backgroundColor = lineColor.cgColor
        leftLayer.backgroundColor = lineColor.cgColor
        rightLayer.backgroundColor = lineColor.cgColor
        bottomLayer.backgroundColor = lineColor.cgColor
        
        topLayer.isHidden = !drawTop
        leftLayer.isHidden = !drawLeft
        rightLayer.isHidden = !drawRight
        bottomLayer.isHidden = !drawBottom
        
        let w = bounds.width
        let h = bounds.height
        topLayer.frame = CGRect(x: 0, y: 0, width: w, height: lineWidth)
        leftLayer.frame = CGRect(x: 0, y: 0, width: lineWidth, height: h)
        rightLayer.frame = CGRect(x: w - lineWidth, y: 0, width: lineWidth, height: h)
        bottomLayer.frame = CGRect(x: 0, y: h - lineWidth, width: w, height: lineWidth)
    }
}
