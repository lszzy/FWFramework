//
//  DynamicLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - DynamicLayoutViewProtocol
/// 动态布局视图协议
@_spi(FW) public protocol DynamicLayoutViewProtocol {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    var fw_maxYViewFixed: Bool { get set }
    
    /// 最大Y视图的底部内边距(横向时为X)，可避免新创建View来撑开Cell，默认0
    var fw_maxYViewPadding: CGFloat { get set }
    
    /// 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    var fw_maxYViewExpanded: Bool { get set }
    
    /// 创建可重用动态布局视图方法
    static func fw_dynamicLayoutView() -> Self
    
    /// 获取可重用动态布局视图内容视图
    var fw_dynamicLayoutContentView: UIView { get }
    
    /// 准备可重用动态布局视图方法
    func fw_dynamicLayoutPrepare()
    
}

@_spi(FW) extension DynamicLayoutViewProtocol where Self: UIView {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var fw_maxYViewFixed: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewFixed") }
    }

    /// 最大Y视图的底部内边距(横向时为X)，可避免新创建View来撑开Cell，默认0
    public var fw_maxYViewPadding: CGFloat {
        get {
            if let number = fw_propertyNumber(forName: "fw_maxYViewPadding") {
                return number.doubleValue
            }
            return .zero
        }
        set {
            fw_setPropertyNumber(NSNumber(value: newValue), forName: "fw_maxYViewPadding")
        }
    }

    /// 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var fw_maxYViewExpanded: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewExpanded") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewExpanded") }
    }
    
    fileprivate var fw_maxYView: UIView? {
        get { fw_property(forName: "fw_maxYView") as? UIView }
        set { fw_setProperty(newValue, forName: "fw_maxYView") }
    }
    
    /// 创建可重用动态布局视图方法
    public static func fw_dynamicLayoutView() -> Self {
        if let cellClass = self as? UITableViewCell.Type {
            return cellClass.init(style: .default, reuseIdentifier: nil) as! Self
        } else if let viewClass = self as? UITableViewHeaderFooterView.Type {
            return viewClass.init(reuseIdentifier: nil) as! Self
        }
        return self.init(frame: .zero)
    }
    
    /// 获取可重用动态布局视图内容视图
    public var fw_dynamicLayoutContentView: UIView {
        if let cell = self as? UITableViewCell {
            return cell.contentView
        } else if let view = self as? UITableViewHeaderFooterView {
            return view.contentView.subviews.count > 0 ? view.contentView : view
        } else if let cell = self as? UICollectionViewCell {
            return cell.contentView
        }
        return self
    }
    
    /// 可重用动态布局视图重用方法
    public func fw_dynamicLayoutPrepare() {
        if let cell = self as? UITableViewCell {
            cell.prepareForReuse()
        } else if let view = self as? UITableViewHeaderFooterView {
            view.prepareForReuse()
        } else if let cell = self as? UICollectionViewCell {
            cell.prepareForReuse()
        } else if let view = self as? UICollectionReusableView {
            view.prepareForReuse()
        }
    }
    
}

// MARK: - UIView+DynamicLayout
@_spi(FW) extension UIView {
    
    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法。注意UILabel可使用preferredMaxLayoutWidth限制多行文本自动布局时的最大宽度
    public func fw_layoutHeight(width: CGFloat) -> CGFloat {
        var fittingHeight: CGFloat = 0
        // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
        let widthFenceConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        self.addConstraint(widthFenceConstraint)
        // 自动布局引擎计算
        fittingHeight = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        self.removeConstraint(widthFenceConstraint)
        
        if (fittingHeight == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingHeight = self.sizeThatFits(CGSize(width: width, height: 0)).height
        }
        return fittingHeight
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func fw_layoutWidth(height: CGFloat) -> CGFloat {
        var fittingWidth: CGFloat = 0
        // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
        let heightFenceConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        self.addConstraint(heightFenceConstraint)
        // 自动布局引擎计算
        fittingWidth = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        self.removeConstraint(heightFenceConstraint)
        
        if (fittingWidth == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingWidth = self.sizeThatFits(CGSize(width: 0, height: height)).width
        }
        return fittingWidth
    }
    
    /// 计算动态AutoLayout布局视图指定宽度时的高度。
    ///
    /// 注意调用后会重置superview和frame，一般用于未添加到superview时的场景，cell等请使用DynamicLayout
    /// - Parameters:
    ///   - width: 指定宽度
    ///   - maxYViewExpanded: 最大Y视图是否撑开布局，需布局约束完整。默认false，无需撑开布局
    ///   - maxYViewPadding: 最大Y视图的底部内边距，maxYViewExpanded为true时不起作用，默认0
    ///   - maxYView: 指定最大Y视图，默认nil
    /// - Returns: 高度
    public func fw_dynamicHeight(
        width: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        let view = UIView()
        view.addSubview(self)
        view.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        frame = CGRect(x: 0, y: 0, width: width, height: 0)
        
        var dynamicHeight: CGFloat = 0
        // 自动撑开方式
        if maxYViewExpanded {
            dynamicHeight = fw_layoutHeight(width: width)
        // 无需撑开
        } else {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            var maxY: CGFloat = 0
            if let maxYView = maxYView {
                maxY = CGRectGetMaxY(maxYView.frame)
            } else {
                for tempView in subviews.reversed() {
                    let tempY = CGRectGetMaxY(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                    }
                }
            }
            dynamicHeight = maxY + maxYViewPadding
        }
        
        removeFromSuperview()
        frame = CGRect(x: 0, y: 0, width: width, height: dynamicHeight)
        return dynamicHeight
    }
    
    /// 计算动态AutoLayout布局视图指定高度时的宽度。
    ///
    /// 注意调用后会重置superview和frame，一般用于未添加到superview时的场景，cell等请使用DynamicLayout
    /// - Parameters:
    ///   - height: 指定高度
    ///   - maxYViewExpanded: 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认false，无需撑开布局
    ///   - maxYViewPadding: 最大Y视图的底部内边距(横向时为X)，maxYViewExpanded为true时不起作用，默认0
    ///   - maxYView: 指定最大Y视图(横向时为X)，默认nil
    /// - Returns: 宽度
    public func fw_dynamicWidth(
        height: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        let view = UIView()
        view.addSubview(self)
        view.frame = CGRect(x: 0, y: 0, width: 0, height: height)
        frame = CGRect(x: 0, y: 0, width: 0, height: height)
        
        var dynamicWidth: CGFloat = 0
        // 自动撑开方式
        if maxYViewExpanded {
            dynamicWidth = fw_layoutWidth(height: height)
        // 无需撑开
        } else {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            var maxY: CGFloat = 0
            if let maxYView = maxYView {
                maxY = CGRectGetMaxX(maxYView.frame)
            } else {
                for tempView in subviews.reversed() {
                    let tempY = CGRectGetMaxX(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                    }
                }
            }
            dynamicWidth = maxY + maxYViewPadding
        }
        
        removeFromSuperview()
        frame = CGRect(x: 0, y: 0, width: dynamicWidth, height: height)
        return dynamicWidth
    }
    
    /// 获取动态布局视图类的尺寸，可固定宽度或高度
    /// - Parameters:
    ///   - viewClass: 视图类
    ///   - viewIdentifier: 视图标记
    ///   - fixedWidth: 固定宽度，默认0不固定
    ///   - fixedHeight: 固定高度，默认0不固定
    ///   - configuration: 布局cell句柄，内部不会持有Block，不需要weak
    /// - Returns: 尺寸
    public func fw_dynamicSize<T: UIView & DynamicLayoutViewProtocol>(
        viewClass: T.Type,
        viewIdentifier: String,
        width fixedWidth: CGFloat = 0,
        height fixedHeight: CGFloat = 0,
        configuration: (T) -> Void
    ) -> CGSize {
        // 获取用于计算尺寸的视图
        let classIdentifier = NSStringFromClass(viewClass).appending(viewIdentifier)
        var dict = fw_property(forName: "fw_dynamicSizeViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            fw_setProperty(dict, forName: "fw_dynamicSizeViews")
        }
        var view: UIView
        if let reuseView = dict?[classIdentifier] as? UIView {
            view = reuseView
        } else {
            let dynamicView = viewClass.fw_dynamicLayoutView()
            view = UIView()
            view.addSubview(dynamicView)
            dict?[classIdentifier] = view
        }
        guard let dynamicView = view.subviews.first as? T else { return .zero }
        
        // 自动获取宽度
        var width = fixedWidth
        var height = fixedHeight
        if width <= 0 && height <= 0 {
            width = CGRectGetWidth(frame)
            if width <= 0, let superview = superview {
                if !superview.fw_propertyBool(forName: "fw_dynamicSizeLayouted") {
                    superview.fw_setPropertyBool(true, forName: "fw_dynamicSizeLayouted")
                    
                    superview.setNeedsLayout()
                    superview.layoutIfNeeded()
                }
                width = CGRectGetWidth(frame)
            }
        }
        
        // 设置frame并布局视图
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dynamicView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dynamicView.fw_dynamicLayoutPrepare()
        configuration(dynamicView)
        
        // 自动撑开方式
        if dynamicView.fw_maxYViewExpanded {
            if fixedHeight > 0 {
                width = dynamicView.fw_layoutWidth(height: height)
            } else {
                height = dynamicView.fw_layoutHeight(width: width)
            }
            return CGSize(width: width, height: height)
        }
        
        // 无需撑开方式
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        var maxY: CGFloat = 0
        let maxYBlock: (UIView) -> CGFloat = { view in
            return fixedHeight > 0 ? CGRectGetMaxX(view.frame) : CGRectGetMaxY(view.frame)
        }
        if dynamicView.fw_maxYViewFixed {
            if let maxYView = dynamicView.fw_maxYView {
                maxY = maxYBlock(maxYView)
            } else {
                var maxYView: UIView?
                for tempView in dynamicView.fw_dynamicLayoutContentView.subviews.reversed() {
                    let tempY = maxYBlock(tempView)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                dynamicView.fw_maxYView = maxYView
            }
        } else {
            for tempView in dynamicView.fw_dynamicLayoutContentView.subviews.reversed() {
                let tempY = maxYBlock(tempView)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += dynamicView.fw_maxYViewPadding
        return fixedHeight > 0 ? CGSize(width: maxY, height: height) : CGSize(width: width, height: maxY)
    }
    
}

// MARK: - UITableViewCell+DynamicLayout
@_spi(FW) extension UITableViewCell: DynamicLayoutViewProtocol {
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func fw_cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(self).appending("FWDynamicLayoutReuseIdentifier")
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? Self {
            return cell
        }
        return Self(style: style, reuseIdentifier: identifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func fw_height(
        tableView: UITableView,
        cacheBy key: AnyHashable? = nil,
        configuration: (UITableViewCell) -> Void
    ) -> CGFloat {
        return tableView.fw_height(cellClass: self, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UITableViewHeaderFooterView+DynamicLayout
public enum HeaderFooterViewType: Int {
    case header = 0
    case footer = 1
}

@_spi(FW) extension UITableViewHeaderFooterView: DynamicLayoutViewProtocol {
    
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public static func fw_headerFooterView(
        tableView: UITableView,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(self).appending("FWDynamicLayoutReuseIdentifier")
        if tableView.fw_propertyBool(forName: identifier) {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! Self
        }
        tableView.register(self, forHeaderFooterViewReuseIdentifier: identifier)
        tableView.fw_setPropertyBool(true, forName: identifier)
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! Self
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func fw_height(
        tableView: UITableView,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: (UITableViewHeaderFooterView) -> Void
    ) -> CGFloat {
        return tableView.fw_height(headerFooterViewClass: self, type: type, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UITableView+DynamicLayout
/// 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 通常使用rowHeight为automaticDimension自动撑开布局即可，无需计算高度；
/// 适用于需要计算高度或automaticDimension不满足需求的场景；
/// 如果使用系统自动高度，建议设置estimatedRowHeight提高性能
/// - see: [UITableViewDynamicLayoutCacheHeight](https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight)
@_spi(FW) extension UITableView {
    
    // MARK: - DynamicLayoutHeightCache
    private class DynamicLayoutHeightCache: NSObject {
        
        var heightHorizontalDictionary: [AnyHashable: CGFloat] = [:]
        var heightVerticalDictionary: [AnyHashable: CGFloat] = [:]
        
        var headerHorizontalDictionary: [AnyHashable: CGFloat] = [:]
        var headerVerticalDictionary: [AnyHashable: CGFloat] = [:]
        
        var footerHorizontalDictionary: [AnyHashable: CGFloat] = [:]
        var footerVerticalDictionary: [AnyHashable: CGFloat] = [:]
        
    }
    
    // MARK: - Cache
    /// 手工清空高度缓存，用于高度发生变化的情况
    public func fw_clearHeightCache() {
        let heightCache = self.fw_dynamicLayoutHeightCache
        heightCache.heightHorizontalDictionary.removeAll()
        heightCache.heightVerticalDictionary.removeAll()
        
        heightCache.headerHorizontalDictionary.removeAll()
        heightCache.headerVerticalDictionary.removeAll()
        
        heightCache.footerHorizontalDictionary.removeAll()
        heightCache.footerVerticalDictionary.removeAll()
    }

    /// 指定key设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
    public func fw_setCellHeightCache(_ height: CGFloat, for key: AnyHashable) {
        let heightCache = self.fw_dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            heightCache.heightVerticalDictionary[key] = height > 0 ? height : nil
        } else {
            heightCache.heightHorizontalDictionary[key] = height > 0 ? height : nil
        }
    }

    /// 指定key获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
    public func fw_cellHeightCache(for key: AnyHashable) -> CGFloat {
        let heightCache = self.fw_dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return heightCache.heightVerticalDictionary[key] ?? UITableView.automaticDimension
        } else {
            return heightCache.heightHorizontalDictionary[key] ?? UITableView.automaticDimension
        }
    }

    /// 指定key设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
    public func fw_setHeaderFooterHeightCache(_ height: CGFloat, type: HeaderFooterViewType, for key: AnyHashable) {
        let heightCache = self.fw_dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            if type == .header {
                heightCache.headerVerticalDictionary[key] = height > 0 ? height : nil
            } else {
                heightCache.footerVerticalDictionary[key] = height > 0 ? height : nil
            }
        } else {
            if type == .header {
                heightCache.headerHorizontalDictionary[key] = height > 0 ? height : nil
            } else {
                heightCache.footerHorizontalDictionary[key] = height > 0 ? height : nil
            }
        }
    }

    /// 指定key获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
    public func fw_headerFooterHeightCache(_ type: HeaderFooterViewType, for key: AnyHashable) -> CGFloat {
        let heightCache = self.fw_dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            if type == .header {
                return heightCache.headerVerticalDictionary[key] ?? UITableView.automaticDimension
            } else {
                return heightCache.footerVerticalDictionary[key] ?? UITableView.automaticDimension
            }
        } else {
            if type == .header {
                return heightCache.headerHorizontalDictionary[key] ?? UITableView.automaticDimension
            } else {
                return heightCache.footerHorizontalDictionary[key] ?? UITableView.automaticDimension
            }
        }
    }
    
    private var fw_dynamicLayoutHeightCache: DynamicLayoutHeightCache {
        if let heightCache = fw_property(forName: "fw_dynamicLayoutHeightCache") as? DynamicLayoutHeightCache {
            return heightCache
        } else {
            let heightCache = DynamicLayoutHeightCache()
            fw_setProperty(heightCache, forName: "fw_dynamicLayoutHeightCache")
            return heightCache
        }
    }

    // MARK: - Cell
    /// 获取 Cell 需要的高度，可指定key使用缓存
    /// - Parameters:
    ///   - cellClass: cell class
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 cell，内部不会拥有 Block，不需要 __weak
    /// - Returns: cell高度
    public func fw_height(
        cellClass: UITableViewCell.Type,
        cacheBy key: AnyHashable? = nil,
        configuration: (UITableViewCell) -> Void
    ) -> CGFloat {
        guard let key = key else {
            let cellSize = fw_dynamicSize(viewClass: cellClass, viewIdentifier: "", configuration: configuration)
            return cellSize.height
        }
        
        var cellHeight = fw_cellHeightCache(for: key)
        if cellHeight != UITableView.automaticDimension {
            return cellHeight
        }
        let cellSize = fw_dynamicSize(viewClass: cellClass, viewIdentifier: "", configuration: configuration)
        cellHeight = cellSize.height
        let shouldCache = cellSize.width > 0
        if shouldCache {
            fw_setCellHeightCache(cellHeight, for: key)
        }
        return cellHeight
    }

    // MARK: - HeaderFooterView
    /// 获取 HeaderFooter 需要的高度，可指定key使用缓存
    /// - Parameters:
    ///   - headerFooterViewClass: HeaderFooter class
    ///   - type: HeaderFooter类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
    /// - Returns: HeaderFooter高度
    public func fw_height(
        headerFooterViewClass: UITableViewHeaderFooterView.Type,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: (UITableViewHeaderFooterView) -> Void
    ) -> CGFloat {
        guard let key = key else {
            let viewSize = fw_dynamicSize(viewClass: headerFooterViewClass, viewIdentifier: "\(type.rawValue)", configuration: configuration)
            return viewSize.height
        }
        
        var viewHeight = fw_headerFooterHeightCache(type, for: key)
        if viewHeight != UITableView.automaticDimension {
            return viewHeight
        }
        let viewSize = fw_dynamicSize(viewClass: headerFooterViewClass, viewIdentifier: "\(type.rawValue)", configuration: configuration)
        viewHeight = viewSize.height
        let shouldCache = viewSize.width > 0
        if shouldCache {
            fw_setHeaderFooterHeightCache(viewHeight, type: type, for: key)
        }
        return viewHeight
    }
    
}

// MARK: - UICollectionViewCell+DynamicLayout
@_spi(FW) extension UICollectionViewCell {

    /// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
    public static func fw_cell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(self).appending("FWDynamicLayoutReuseIdentifier")
        if collectionView.fw_propertyBool(forName: identifier) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Self
        }
        collectionView.register(self, forCellWithReuseIdentifier: identifier)
        collectionView.fw_setPropertyBool(true, forName: identifier)
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Self
    }

    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func fw_size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (UICollectionViewCell) -> Void
    ) -> CGSize {
        return collectionView.fw_size(cellClass: self, width: width, height: height, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UICollectionReusableView+DynamicLayout
@_spi(FW) extension UICollectionReusableView: DynamicLayoutViewProtocol {
    
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public static func fw_reusableView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(self).appending("FWDynamicLayoutReuseIdentifier")
        let kindIdentifier = identifier + kind
        if collectionView.fw_propertyBool(forName: kindIdentifier) {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! Self
        }
        collectionView.register(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
        collectionView.fw_setPropertyBool(true, forName: kindIdentifier)
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! Self
    }

    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func fw_size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        kind: String,
        cacheBy key: AnyHashable? = nil,
        configuration: (UICollectionReusableView) -> Void
    ) -> CGSize {
        return collectionView.fw_size(reusableViewClass: self, width: width, height: height, kind: kind, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UICollectionView+DynamicLayout
/// 集合自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 如果使用系统自动尺寸，建议设置estimatedItemSize提高性能
@_spi(FW) extension UICollectionView {
    
    // MARK: - DynamicLayoutSizeCache
    private class DynamicLayoutSizeCache: NSObject {
        
        var sizeHorizontalDictionary: [AnyHashable: CGSize] = [:]
        var sizeVerticalDictionary: [AnyHashable: CGSize] = [:]
        
        var headerHorizontalDictionary: [AnyHashable: CGSize] = [:]
        var headerVerticalDictionary: [AnyHashable: CGSize] = [:]
        
        var footerHorizontalDictionary: [AnyHashable: CGSize] = [:]
        var footerVerticalDictionary: [AnyHashable: CGSize] = [:]
        
    }
    
    // MARK: - Cache
    /// 手工清空尺寸缓存，用于尺寸发生变化的情况
    public func fw_clearSizeCache() {
        let sizeCache = self.fw_dynamicLayoutSizeCache
        sizeCache.sizeHorizontalDictionary.removeAll()
        sizeCache.sizeVerticalDictionary.removeAll()
        
        sizeCache.headerHorizontalDictionary.removeAll()
        sizeCache.headerVerticalDictionary.removeAll()
        
        sizeCache.footerHorizontalDictionary.removeAll()
        sizeCache.footerVerticalDictionary.removeAll()
    }

    /// 指定key设置cell尺寸缓存，设置为zero时清除缓存
    public func fw_setCellSizeCache(_ size: CGSize, for key: AnyHashable) {
        let sizeCache = self.fw_dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            sizeCache.sizeVerticalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
        } else {
            sizeCache.sizeHorizontalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
        }
    }

    /// 指定key获取cell缓存尺寸，默认值automaticSize
    public func fw_cellSizeCache(for key: AnyHashable) -> CGSize {
        let sizeCache = self.fw_dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return sizeCache.sizeVerticalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
        } else {
            return sizeCache.sizeHorizontalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
        }
    }

    /// 指定key设置ReusableView尺寸缓存，设置为zero时清除缓存
    public func fw_setReusableViewSizeCache(_ size: CGSize, kind: String, for key: AnyHashable) {
        let sizeCache = self.fw_dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            if kind == UICollectionView.elementKindSectionHeader {
                sizeCache.headerVerticalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
            } else {
                sizeCache.footerVerticalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
            }
        } else {
            if kind == UICollectionView.elementKindSectionHeader {
                sizeCache.headerHorizontalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
            } else {
                sizeCache.footerHorizontalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
            }
        }
    }

    /// 指定key获取ReusableView缓存尺寸，默认值automaticSize
    public func fw_reusableViewSizeCache(_ kind: String, for key: AnyHashable) -> CGSize {
        let sizeCache = self.fw_dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            if kind == UICollectionView.elementKindSectionHeader {
                return sizeCache.headerVerticalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
            } else {
                return sizeCache.footerVerticalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
            }
        } else {
            if kind == UICollectionView.elementKindSectionHeader {
                return sizeCache.headerHorizontalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
            } else {
                return sizeCache.footerHorizontalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
            }
        }
    }
    
    private var fw_dynamicLayoutSizeCache: DynamicLayoutSizeCache {
        if let sizeCache = fw_property(forName: "fw_dynamicLayoutSizeCache") as? DynamicLayoutSizeCache {
            return sizeCache
        } else {
            let sizeCache = DynamicLayoutSizeCache()
            fw_setProperty(sizeCache, forName: "fw_dynamicLayoutSizeCache")
            return sizeCache
        }
    }

    // MARK: - Cell
    /// 获取 Cell 需要的尺寸，可固定宽度或高度，可指定key使用缓存
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - width: 固定宽度，默认0不固定
    ///   - height: 固定高度，默认0不固定
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func fw_size(
        cellClass: UICollectionViewCell.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (UICollectionViewCell) -> Void
    ) -> CGSize {
        guard let key = key else {
            return fw_dynamicSize(viewClass: cellClass, viewIdentifier: "\(width)-\(height)", width: width, height: height, configuration: configuration)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var cellSize = fw_cellSizeCache(for: cacheKey)
        if cellSize != UICollectionViewFlowLayout.automaticSize {
            return cellSize
        }
        cellSize = fw_dynamicSize(viewClass: cellClass, viewIdentifier: "\(width)-\(height)", width: width, height: height, configuration: configuration)
        let shouldCache = height > 0 || cellSize.width > 0
        if shouldCache {
            fw_setCellSizeCache(cellSize, for: cacheKey)
        }
        return cellSize
    }

    // MARK: - ReusableView
    /// 获取 ReusableView 需要的尺寸，可固定宽度或高度，可指定key使用缓存
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - width: 固定宽度，默认0不固定
    ///   - height: 固定高度，默认0不固定
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func fw_size(
        reusableViewClass: UICollectionReusableView.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        kind: String,
        cacheBy key: AnyHashable? = nil,
        configuration: (UICollectionReusableView) -> Void
    ) -> CGSize {
        guard let key = key else {
            return fw_dynamicSize(viewClass: reusableViewClass, viewIdentifier: "\(kind)-\(width)-\(height)", width: width, height: height, configuration: configuration)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var viewSize = fw_reusableViewSizeCache(kind, for: cacheKey)
        if viewSize != UICollectionViewFlowLayout.automaticSize {
            return viewSize
        }
        viewSize = fw_dynamicSize(viewClass: reusableViewClass, viewIdentifier: "\(kind)-\(width)-\(height)", width: width, height: height, configuration: configuration)
        let shouldCache = height > 0 || viewSize.width > 0
        if shouldCache {
            fw_setReusableViewSizeCache(viewSize, kind: kind, for: cacheKey)
        }
        return viewSize
    }
    
}
