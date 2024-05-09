//
//  FloatingView.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/28.
//

import UIKit

/// 浮动布局视图
///
/// 做类似 CSS 里的 float:left 的布局，自行使用 addSubview: 将子 View 添加进来即可。
/// 支持通过 `contentMode` 属性修改子 View 的对齐方式，目前仅支持 `UIViewContentModeLeft` 和 `UIViewContentModeRight`，默认为 `UIViewContentModeLeft`
///
/// [QMUI_iOS](https://github.com/Tencent/QMUI_iOS)
open class FloatingView: UIView {

    /// 用于属性 maximumItemSize，是它的默认值。表示 item 的最大宽高会自动根据当前 floatView 的内容大小来调整，从而避免 item 内容过多时可能溢出 floatView
    public static let automaticalMaximumItemSize = CGSize(width: -1, height: -1)
    
    /// 内部的间距，默认为 zero
    open var padding: UIEdgeInsets = .zero
    
    /// item 的最小宽高，默认为 CGSizeZero，也即不限制
    @IBInspectable open var minimumItemSize: CGSize = .zero
    
    /// item 的最大宽高，默认为 AutomaticalMaximumItemSize，也即不超过 floatView 自身最大内容宽高
    @IBInspectable open var maximumItemSize: CGSize = FloatingView.automaticalMaximumItemSize
    
    /// item 之间的间距，默认为 zero
    ///
    /// 上、下、左、右四个边缘的 item 布局时不会考虑 itemMargins.top/bottom/left/right
    open var itemMargins: UIEdgeInsets = .zero
    
    // MARK: - Lifecycle
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    private func didInitialize() {
        contentMode = .left
    }
    
    // MARK: - Public
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return layoutSubviews(size: size, shouldLayout: false)
    }
    
    open override var intrinsicContentSize: CGSize {
        return sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutSubviews(size: bounds.size, shouldLayout: true)
    }
    
    // MARK: - Private
    @discardableResult
    private func layoutSubviews(size: CGSize, shouldLayout: Bool) -> CGSize {
        let visibleItemViews = subviews.filter { !$0.isHidden }
        if visibleItemViews.isEmpty {
            return CGSize(width: padding.left + padding.right, height: padding.top + padding.bottom)
        }
        
        // 如果是左对齐，则代表 item 左上角的坐标，如果是右对齐，则代表 item 右上角的坐标
        var itemViewOrigin = CGPoint(x: switchValue(padding.left, size.width - padding.right), y: padding.top)
        var currentRowMaxY = itemViewOrigin.y
        let maximumItemSize = (maximumItemSize == FloatingView.automaticalMaximumItemSize) ? CGSize(width: size.width - (padding.left + padding.right), height: size.height - (padding.top + padding.bottom)) : maximumItemSize
        var line: Int = -1
        for i in 0 ..< visibleItemViews.count {
            let itemView = visibleItemViews[i]
            
            var itemViewFrame: CGRect
            var itemViewSize = itemView.sizeThatFits(maximumItemSize)
            itemViewSize.width = min(maximumItemSize.width, max(minimumItemSize.width, itemViewSize.width))
            itemViewSize.height = min(maximumItemSize.height, max(minimumItemSize.height, itemViewSize.height))
            
            let shouldBreakline = (i == 0) ? true : switchValue(itemViewOrigin.x + itemMargins.left + itemViewSize.width + padding.right > size.width, itemViewOrigin.x - itemMargins.right - itemViewSize.width - padding.left < 0)
            if shouldBreakline {
                line += 1
                currentRowMaxY += (line > 0) ? itemMargins.top : 0
                // 换行，每一行第一个 item 是不考虑 itemMargins 的
                itemViewFrame = CGRect(x: switchValue(padding.left, size.width - padding.right - itemViewSize.width), y: currentRowMaxY, width: itemViewSize.width, height: itemViewSize.height)
                itemViewOrigin.y = itemViewFrame.minY
            } else {
                // 当前行放得下
                itemViewFrame = CGRect(x: switchValue(itemViewOrigin.x + itemMargins.left, itemViewOrigin.x - itemMargins.right - itemViewSize.width), y: itemViewOrigin.y, width: itemViewSize.width, height: itemViewSize.height)
            }
            itemViewOrigin.x = switchValue(itemViewFrame.maxX + itemMargins.right, itemViewFrame.minX - itemMargins.left)
            currentRowMaxY = max(currentRowMaxY, itemViewFrame.maxY + itemMargins.bottom)
            
            if shouldLayout {
                itemView.frame = itemViewFrame
            }
        }
        
        // 最后一行不需要考虑 itemMarins.bottom，所以这里减掉
        currentRowMaxY -= itemMargins.bottom
        let resultSize = CGSize(width: size.width, height: currentRowMaxY + padding.bottom)
        return resultSize
    }
    
    private func switchValue<T>(_ leftValue: T, _ rightValue: T) -> T {
        return contentMode == .right ? rightValue : leftValue
    }

}
