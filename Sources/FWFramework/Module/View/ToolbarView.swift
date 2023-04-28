//
//  ToolbarView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 扩展titleView，可继承，用于navigationItem.titleView需要撑开的场景
///
/// 组件自动兼容各版本系统titleView左右间距(默认16)，具体差异如下：
/// iOS16+：系统titleView左右最小间距为16，组件默认处理为16
/// iOS15-：系统titleView左右最小间距为8，组件默认处理为16
/// 注意：扩展区域不可点击，如需点击，可使用isPenetrable实现
open class ExpandedTitleView: UIView {
    
    /// 指定内容视图并快速创建titleView
    open class func titleView(_ contentView: UIView) -> Self {
        let titleView = self.init()
        titleView.contentView = contentView
        return titleView
    }
    
    /// 设置离导航栏最小间距，默认16，超出区域不可点击
    open var navigationBarSpacing: CGFloat = 16 {
        didSet { setNeedsLayout() }
    }
    
    /// 指定并添加内容视图
    open weak var contentView: UIView? {
        didSet {
            guard contentView != oldValue else { return }
            oldValue?.removeFromSuperview()
            if let contentView = contentView,
               contentView.superview == nil {
                addSubview(contentView)
                contentView.fw_pinEdges(toSuperview: contentInset)
            }
        }
    }
    
    /// 内容视图间距，默认zero
    open var contentInset: UIEdgeInsets = .zero {
        didSet {
            if let contentView = contentView {
                contentView.fw_pinEdges(toSuperview: contentInset)
                setNeedsLayout()
            }
        }
    }
    
    /// 最大适配间距，大于该间距无需处理，iOS16+系统默认16，iOS15-系统默认8，取较大值
    private var maximumFittingSpacing: CGFloat = 16
    
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let navigationBar = searchNavigationBar(self) else { return }
        var convertFrame = convert(bounds, to: navigationBar)
        if convertFrame.width > navigationBar.frame.width { return }
        
        let leftSpacing = convertFrame.minX
        let rightSpacing = navigationBar.frame.width - convertFrame.maxX
        if leftSpacing >= 0 && leftSpacing <= maximumFittingSpacing {
            convertFrame.origin.x = navigationBarSpacing - leftSpacing
            convertFrame.size.width -= navigationBarSpacing - leftSpacing
        }
        if rightSpacing >= 0 && rightSpacing <= maximumFittingSpacing {
            convertFrame.origin.x -= navigationBarSpacing - rightSpacing
            convertFrame.size.width -= navigationBarSpacing - rightSpacing
        }
        self.frame = convertFrame
        contentView?.frame = self.bounds.inset(by: contentInset)
    }
    
    private func searchNavigationBar(_ child: UIView) -> UINavigationBar? {
        guard let parent = child.superview else { return nil }
        if let navigationBar = parent as? UINavigationBar { return navigationBar }
        return searchNavigationBar(parent)
    }
    
}
