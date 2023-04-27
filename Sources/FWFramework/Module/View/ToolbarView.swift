//
//  ToolbarView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 扩展titleView，可继承，用于navigationItem.titleView需要撑开的场景
open class ExpandedTitleView: UIView {
    
    /// 指定内容视图并快速创建titleView
    open class func titleView(_ contentView: UIView) -> Self {
        let titleView = self.init()
        titleView.addSubview(contentView)
        contentView.fw_pinEdges()
        return titleView
    }
    
    /// 初始化，默认导航栏尺寸
    public required init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.fw_screenWidth, height: UIScreen.fw_navigationBarHeight))
    }
    
    /// 指定frame并初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// 解码初始化，默认导航栏尺寸
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        frame = CGRect(x: 0, y: 0, width: UIScreen.fw_screenWidth, height: UIScreen.fw_navigationBarHeight)
    }
    
    open override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
}
