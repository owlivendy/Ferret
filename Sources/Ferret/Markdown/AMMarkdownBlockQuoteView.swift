//
//  AMMarkdownBlockQuoteView.swift
//  ChinaHomelife247
//
//  Created by shenxiaofei on 2026/3/26.
//  Copyright © 2026 shenxiaofei. All rights reserved.
//

import UIKit

final class AMMarkdownBlockQuoteView: UIView {
    private let barView = UIView(frame: .zero)
    private let backgroundContainer = UIView(frame: .zero)
    private let textView = UITextView(frame: .zero)
    
    private let style: AMMarkdownViewStyle
    
    init(frame: CGRect, style: AMMarkdownViewStyle) {
        self.style = style
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .clear
        
        backgroundContainer.backgroundColor = style.blockQuoteBackgroundColor
        backgroundContainer.layer.cornerRadius = style.blockQuoteCornerRadius
        backgroundContainer.clipsToBounds = true
        
        barView.backgroundColor = style.blockQuoteBarColor
        barView.layer.cornerRadius = style.blockQuoteBarWidth / 2
        barView.clipsToBounds = true
        
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = []
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        addSubview(backgroundContainer)
        // 竖线直接挂在根视图，顶到内容前缘，不被背景 inset 挤进去
        addSubview(barView)
        backgroundContainer.addSubview(textView)
    }
    
    func configure(text: NSAttributedString, width: CGFloat, delegate: UITextViewDelegate?) {
        textView.delegate = delegate
        textView.attributedText = text
        
        let contentWidth = max(
            1,
            width
            - style.blockQuoteContentInset.left
            - style.blockQuoteBarWidth
            - style.blockQuoteBarSpacing
            - style.blockQuoteContentInset.right
        )
        
        let size = AMMarkdownView.heightWithAttiribute(text, width: contentWidth, markdownStyle: style, addCommonPragraph: false)
        let textHeight = ceil(size.height)
        let totalHeight = textHeight
            + style.blockQuoteContentInset.top
            + style.blockQuoteContentInset.bottom
        frame.size = CGSize(width: width, height: totalHeight)
        
        backgroundContainer.am.make { make in
            make.size.equalToSize(size: CGSize(width: width, height: totalHeight))
            make.top.equalToSuper(view: self.am.top)
            make.leading.equalToSuper(view: self.am.leading)
        }
        
        barView.am.make { make in
            make.size.equalToSize(size: CGSize(
                width: style.blockQuoteBarWidth,
                height: textHeight
            ))
            make.top.equalToSuper(view: self.am.top).offset(style.blockQuoteContentInset.top)
            make.leading.equalToSuper(view: self.am.leading).offset(style.blockQuoteContentInset.left)
        }
        
        textView.am.make { make in
            make.size.equalToSize(size: CGSize(width: contentWidth, height: textHeight))
            make.top.equalToSuper(view: backgroundContainer.am.top).offset(style.blockQuoteContentInset.top)
            make.leading.equalToSuper(view: backgroundContainer.am.leading)
                .offset(style.blockQuoteContentInset.left + style.blockQuoteBarWidth + style.blockQuoteBarSpacing)
        }
    }
    
    nonisolated static func measuredHeight(text: NSAttributedString, width: CGFloat, style: AMMarkdownViewStyle) -> CGFloat {
        let contentWidth = max(
            1,
            width
            - style.blockQuoteContentInset.left
            - style.blockQuoteBarWidth
            - style.blockQuoteBarSpacing
            - style.blockQuoteContentInset.right
        )
        let size = AMMarkdownView.heightWithAttiribute(text, width: contentWidth, markdownStyle: style, addCommonPragraph: false)
        return ceil(size.height) + style.blockQuoteContentInset.top + style.blockQuoteContentInset.bottom
    }
}
