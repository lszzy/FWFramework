//
//  FWScrollView.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/25.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

/// 框架滚动视图，内容过多时可自动滚动，需布局约束完整
@objcMembers public class FWScrollView: UIView {
    public lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()
    
    public lazy var contentView: UIView = {
        let contentView = UIView()
        return contentView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(scrollView)
        scrollView.fwPinEdgesToSuperview()
        scrollView.addSubview(contentView)
        contentView.fwPinEdgesToSuperview()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
