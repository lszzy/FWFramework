//
//  BadgeView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

/// 提醒灯视图协议
public protocol BadgeViewProtocol {
    /// 提醒灯文本标签，默认nil
    var badgeLabel: UILabel? { get }
    /// 通用提醒灯右上偏移值，默认zero
    var badgeOffset: CGPoint { get }
    /// 导航栏提醒灯右上偏移值，默认badgeOffset
    var navbarBadgeOffset: CGPoint { get }
    /// 标签栏提醒灯右上偏移值，默认badgeOffset
    var tabbarBadgeOffset: CGPoint { get }
}

/// 提醒灯视图协议默认实现
extension BadgeViewProtocol {
    public var badgeLabel: UILabel? { nil }
    public var badgeOffset: CGPoint { .zero }
    public var navbarBadgeOffset: CGPoint { badgeOffset }
    public var tabbarBadgeOffset: CGPoint { badgeOffset }
}

/// 自带提醒灯样式
public enum BadgeStyle: Int {
    /// 自定义
    case custom = 0
    /// 小红点，圆形，默认(10)*(10)
    case dot
    /// 小文本，同系统标签，默认(18+)*(18)，12号普通字体
    case small
    /// 大文本，同系统桌面，默认(24+)*(24)，14号普通字体
    case big
}

/// 提醒灯视图，默认禁用userInteractionEnabled，使用非等比例缩放布局
open class BadgeView: UIView, BadgeViewProtocol {
    
    /// 提醒灯样式，默认自定义
    open private(set) var badgeStyle: BadgeStyle = .custom
    
    /// 提醒灯文本标签。可自定义样式
    open private(set) var badgeLabel: UILabel?
    
    /// 提醒灯右上偏移值
    open private(set) var badgeOffset: CGPoint = .zero
    
    /// 导航栏提醒灯右上偏移值，默认badgeOffset
    open var navbarBadgeOffset: CGPoint {
        return badgeStyle == .custom ? badgeOffset : .zero
    }
    
    /// 标签栏提醒灯右上偏移值，默认badgeOffset
    open var tabbarBadgeOffset: CGPoint {
        return badgeStyle == .custom ? badgeOffset : CGPoint(x: badgeOffset.x, y: -2.0)
    }
    
    /// 初始化方法，宽高自动布局，其它手工布局
    /// - Parameters:
    ///   - badgeStyle: 提醒灯样式
    ///   - badgeHeight: 提醒灯高度，nil时使用默认
    ///   - badgeOffset: 提醒灯偏移，nil时使用默认
    ///   - textInset: 文本提醒灯边距，nil时使用默认
    ///   - fontSize: 文本提醒灯字体，nil时使用默认
    public init(badgeStyle: BadgeStyle, badgeHeight: CGFloat? = nil, badgeOffset: CGPoint? = nil, textInset: CGFloat? = nil, fontSize: CGFloat? = nil) {
        super.init(frame: .zero)
        self.badgeStyle = badgeStyle
        
        switch badgeStyle {
        case .dot:
            setupDot(badgeHeight: badgeHeight ?? 10, badgeOffset: badgeOffset ?? CGPoint(x: 3, y: 3))
        case .small:
            setupLabel(badgeHeight: badgeHeight ?? 18, badgeOffset: badgeOffset ?? CGPoint(x: 7, y: 7), textInset: textInset ?? 5, fontSize: fontSize ?? 12)
        case .big:
            setupLabel(badgeHeight: badgeHeight ?? 24, badgeOffset: badgeOffset ?? CGPoint(x: 9, y: 9), textInset: textInset ?? 6, fontSize: fontSize ?? 14)
        default:
            setupLabel(badgeHeight: badgeHeight ?? 18, badgeOffset: badgeOffset ?? CGPoint(x: 7, y: 7), textInset: textInset ?? 5, fontSize: fontSize ?? 12)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupDot(badgeHeight: CGFloat, badgeOffset: CGPoint) {
        self.badgeOffset = badgeOffset
        
        isUserInteractionEnabled = false
        backgroundColor = UIColor.red
        layer.cornerRadius = badgeHeight / 2
        fw_autoScaleLayout = false
        fw_setDimensions(CGSize(width: badgeHeight, height: badgeHeight))
    }
    
    private func setupLabel(badgeHeight: CGFloat, badgeOffset: CGPoint, textInset: CGFloat, fontSize: CGFloat) {
        self.badgeOffset = badgeOffset
        
        isUserInteractionEnabled = false
        backgroundColor = UIColor.red
        layer.cornerRadius = badgeHeight / 2
        fw_autoScaleLayout = false
        fw_setDimension(.height, size: badgeHeight)
        fw_setDimension(.width, size: badgeHeight, relation: .greaterThanOrEqual)
        
        let badgeLabel = UILabel()
        self.badgeLabel = badgeLabel
        badgeLabel.textColor = UIColor.white
        badgeLabel.font = UIFont.systemFont(ofSize: fontSize)
        badgeLabel.textAlignment = .center
        addSubview(badgeLabel)
        badgeLabel.fw_autoScaleLayout = false
        badgeLabel.fw_alignCenter()
        badgeLabel.fw_pinEdge(toSuperview: .right, inset: textInset, relation: .greaterThanOrEqual)
        badgeLabel.fw_pinEdge(toSuperview: .left, inset: textInset, relation: .greaterThanOrEqual)
    }
    
}

@_spi(FW) extension UIView {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: UIView & BadgeViewProtocol, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        badgeView.badgeLabel?.text = badgeValue
        badgeView.tag = 2041
        self.addSubview(badgeView)
        self.bringSubviewToFront(badgeView)
        
        // 默认偏移
        badgeView.fw_pinEdge(toSuperview: .top, inset: -badgeView.badgeOffset.y)
        badgeView.fw_pinEdge(toSuperview: .right, inset: -badgeView.badgeOffset.x)
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let badgeView = self.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}

@_spi(FW) extension UIBarItem {
    
    /// 获取UIBarItem(UIBarButtonItem、UITabBarItem)内部的view，通常对于navigationItem和tabBarItem而言，需要在设置为item后并且在bar可见时(例如 viewDidAppear:及之后)获取fwView才有值
    public weak var fw_view: UIView? {
        if let barItem = self as? UIBarButtonItem {
            if barItem.customView != nil {
                return barItem.customView
            }
        }
        
        if self.responds(to: NSSelectorFromString("view")) {
            return self.fw_invokeGetter("view") as? UIView
        }
        return nil
    }

    /// 当item内的view生成后就会调用一次这个block，仅对UIBarButtonItem、UITabBarItem有效
    public var fw_viewLoadedBlock: ((UIBarItem, UIView) -> Void)? {
        get {
            return fw_property(forName: "fw_viewLoadedBlock") as? (UIBarItem, UIView) -> Void
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_viewLoadedBlock")
            
            if let view = self.fw_view {
                newValue?(self, view)
            } else {
                self.fw_observeProperty("view") { object, change in
                    guard let object = object as? UIBarItem, change[.newKey] != nil else { return }
                    object.fw_unobserveProperty("view")
                    
                    if let view = object.fw_view {
                        object.fw_viewLoadedBlock?(object, view)
                    }
                }
            }
        }
    }
    
}

@_spi(FW) extension UIBarButtonItem {
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: UIView & BadgeViewProtocol, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
        self.fw_viewLoadedBlock = { item, view in
            badgeView.badgeLabel?.text = badgeValue
            badgeView.tag = 2041
            view.addSubview(badgeView)
            view.bringSubviewToFront(badgeView)
            
            // 自定义视图时默认偏移，否则固定偏移
            badgeView.fw_pinEdge(toSuperview: .top, inset: -badgeView.navbarBadgeOffset.y)
            badgeView.fw_pinEdge(toSuperview: .right, inset: -badgeView.navbarBadgeOffset.x)
        }
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let superview = self.fw_view,
           let badgeView = superview.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}

@_spi(FW) extension UITabBarItem {
    
    private static var fw_staticBadgeViewSwizzled = false
    
    fileprivate static func fw_swizzleBadgeView() {
        guard !fw_staticBadgeViewSwizzled else { return }
        fw_staticBadgeViewSwizzled = true
        
        NSObject.fw_swizzleMethod(
            objc_getClass("UITabBarButton"),
            selector: #selector(UIView.layoutSubviews),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            // 解决因为层级关系变化导致的badgeView被遮挡问题
            for subview in selfObject.subviews {
                if let badgeView = subview as? UIView & BadgeViewProtocol {
                    selfObject.bringSubviewToFront(badgeView)
                    
                    // 解决iOS13因为磨砂层切换导致的badgeView位置不对问题
                    if let imageView = UITabBarItem.fw_imageView(selfObject) {
                        badgeView.fw_pinEdge(.left, toEdge: .right, ofView: imageView, offset: -badgeView.tabbarBadgeOffset.x)
                    }
                    break
                }
            }
        }}
    }
    
    private static func fw_imageView(_ tabBarButton: UIView) -> UIImageView? {
        var superview = tabBarButton
        // iOS 13 下如果 tabBar 是磨砂的，则每个 button 内部都会有一个磨砂，而磨砂再包裹了 imageView、label 等 subview，但某些时机后系统又会把 imageView、label 挪出来放到 button 上，所以这里做个保护
        if let effectView = tabBarButton.subviews.first as? UIVisualEffectView,
           effectView.contentView.subviews.count > 0 {
            superview = effectView.contentView
        }
        
        for subview in superview.subviews {
            // iOS10及以后，imageView都是用UITabBarSwappableImageView实现的，所以遇到这个class就直接拿
            if NSStringFromClass(subview.classForCoder) == "UITabBarSwappableImageView" {
                return subview as? UIImageView
            }
        }
        return nil
    }
    
    /// 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
    public weak var fw_imageView: UIImageView? {
        if let tabBarButton = self.fw_view {
            return UITabBarItem.fw_imageView(tabBarButton)
        }
        return nil
    }
    
    /// 显示右上角提醒灯，上右偏移指定距离
    public func fw_showBadgeView(_ badgeView: UIView & BadgeViewProtocol, badgeValue: String? = nil) {
        self.fw_hideBadgeView()
        
        UITabBarItem.fw_swizzleBadgeView()
        // 查找内部视图，由于view只有显示到页面后才存在，所以使用回调存在后才添加
        self.fw_viewLoadedBlock = { item, view in
            guard let item = item as? UITabBarItem,
                  let imageView = item.fw_imageView else { return }
            
            badgeView.badgeLabel?.text = badgeValue
            badgeView.tag = 2041
            view.addSubview(badgeView)
            view.bringSubviewToFront(badgeView)
            
            badgeView.fw_pinEdge(toSuperview: .top, inset: -badgeView.tabbarBadgeOffset.y)
            badgeView.fw_pinEdge(.left, toEdge: .right, ofView: imageView, offset: -badgeView.tabbarBadgeOffset.x)
        }
    }

    /// 隐藏提醒灯
    public func fw_hideBadgeView() {
        if let superview = self.fw_view,
           let badgeView = superview.viewWithTag(2041) {
            badgeView.removeFromSuperview()
        }
    }
    
}
