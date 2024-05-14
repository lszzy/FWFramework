//
//  DynamicLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIView
extension Wrapper where Base: UIView {
    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        var fittingHeight: CGFloat = 0
        // 添加固定的width约束，从而使动态视图(如UILabel)纵向扩张。而不是水平增长，flow-layout的方式
        let widthFenceConstraint = NSLayoutConstraint(item: base, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
        base.addConstraint(widthFenceConstraint)
        // 自动布局引擎计算
        fittingHeight = base.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        base.removeConstraint(widthFenceConstraint)
        
        if (fittingHeight == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingHeight = base.sizeThatFits(CGSize(width: width, height: 0)).height
        }
        return fittingHeight
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        var fittingWidth: CGFloat = 0
        // 添加固定的height约束，从而使动态视图(如UILabel)横向扩张。而不是纵向增长，flow-layout的方式
        let heightFenceConstraint = NSLayoutConstraint(item: base, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
        base.addConstraint(heightFenceConstraint)
        // 自动布局引擎计算
        fittingWidth = base.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        base.removeConstraint(heightFenceConstraint)
        
        if (fittingWidth == 0) {
            // 尝试frame布局，调用sizeThatFits:
            fittingWidth = base.sizeThatFits(CGSize(width: 0, height: height)).width
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
    public func dynamicHeight(
        width: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        let view = UIView()
        view.addSubview(base)
        view.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        base.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        
        var dynamicHeight: CGFloat = 0
        // 自动撑开方式
        if maxYViewExpanded {
            dynamicHeight = layoutHeight(width: width)
        // 无需撑开
        } else {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            var maxY: CGFloat = 0
            if let maxYView = maxYView {
                maxY = CGRectGetMaxY(maxYView.frame)
            } else {
                for tempView in base.subviews.reversed() {
                    let tempY = CGRectGetMaxY(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                    }
                }
            }
            dynamicHeight = maxY + maxYViewPadding
        }
        
        base.removeFromSuperview()
        base.frame = CGRect(x: 0, y: 0, width: width, height: dynamicHeight)
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
    public func dynamicWidth(
        height: CGFloat,
        maxYViewExpanded: Bool = false,
        maxYViewPadding: CGFloat = 0,
        maxYView: UIView? = nil
    ) -> CGFloat {
        let view = UIView()
        view.addSubview(base)
        view.frame = CGRect(x: 0, y: 0, width: 0, height: height)
        base.frame = CGRect(x: 0, y: 0, width: 0, height: height)
        
        var dynamicWidth: CGFloat = 0
        // 自动撑开方式
        if maxYViewExpanded {
            dynamicWidth = layoutWidth(height: height)
        // 无需撑开
        } else {
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            var maxY: CGFloat = 0
            if let maxYView = maxYView {
                maxY = CGRectGetMaxX(maxYView.frame)
            } else {
                for tempView in base.subviews.reversed() {
                    let tempY = CGRectGetMaxX(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                    }
                }
            }
            dynamicWidth = maxY + maxYViewPadding
        }
        
        base.removeFromSuperview()
        base.frame = CGRect(x: 0, y: 0, width: dynamicWidth, height: height)
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
    @_spi(FW) public func dynamicSize<T: UIView & DynamicLayoutViewProtocol>(
        viewClass: T.Type,
        viewIdentifier: String,
        width fixedWidth: CGFloat = 0,
        height fixedHeight: CGFloat = 0,
        configuration: (T) -> Void
    ) -> CGSize {
        // 获取用于计算尺寸的视图
        let classIdentifier = NSStringFromClass(viewClass).appending(viewIdentifier)
        var dict = property(forName: "dynamicSizeViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            setProperty(dict, forName: "dynamicSizeViews")
        }
        var view: UIView
        if let reuseView = dict?[classIdentifier] as? UIView {
            view = reuseView
        } else {
            let dynamicView = viewClass.dynamicLayoutView()
            view = UIView()
            view.addSubview(dynamicView)
            dict?[classIdentifier] = view
        }
        guard let dynamicView = view.subviews.first as? T else { return .zero }
        
        // 自动获取宽度
        var width = fixedWidth
        var height = fixedHeight
        if width <= 0 && height <= 0 {
            width = CGRectGetWidth(base.frame)
            if width <= 0, let superview = base.superview {
                if !superview.fw.propertyBool(forName: "dynamicSizeLayouted") {
                    superview.fw.setPropertyBool(true, forName: "dynamicSizeLayouted")
                    
                    superview.setNeedsLayout()
                    superview.layoutIfNeeded()
                }
                width = CGRectGetWidth(base.frame)
            }
        }
        
        // 设置frame并布局视图
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dynamicView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        dynamicView.dynamicLayoutPrepare()
        configuration(dynamicView)
        
        // 自动撑开方式
        if dynamicView.maxYViewExpanded {
            if fixedHeight > 0 {
                width = dynamicView.fw.layoutWidth(height: height)
            } else {
                height = dynamicView.fw.layoutHeight(width: width)
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
        if dynamicView.maxYViewFixed {
            if let maxYView = dynamicView.maxYView {
                maxY = maxYBlock(maxYView)
            } else {
                var maxYView: UIView?
                for tempView in dynamicView.dynamicLayoutContentView.subviews.reversed() {
                    let tempY = maxYBlock(tempView)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                dynamicView.maxYView = maxYView
            }
        } else {
            for tempView in dynamicView.dynamicLayoutContentView.subviews.reversed() {
                let tempY = maxYBlock(tempView)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += dynamicView.maxYViewPadding
        return fixedHeight > 0 ? CGSize(width: maxY, height: height) : CGSize(width: width, height: maxY)
    }
}

// MARK: - Wrapper+UITableViewCell
extension Wrapper where Base: UITableViewCell {
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.maxYViewFixed }
        set { base.maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.maxYViewPadding }
        set { base.maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.maxYViewExpanded }
        set { base.maxYViewExpanded = newValue }
    }
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Base {
        return tableView.fw.cell(of: Base.self, style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGFloat {
        return tableView.fw.height(cellClass: Base.self, cacheBy: key, configuration: configuration)
    }
}

// MARK: - Wrapper+UITableViewHeaderFooterView
extension Wrapper where Base: UITableViewHeaderFooterView {
    /// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.maxYViewFixed }
        set { base.maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.maxYViewPadding }
        set { base.maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.maxYViewExpanded }
        set { base.maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public static func headerFooterView(
        tableView: UITableView,
        reuseIdentifier: String? = nil
    ) -> Base {
        return tableView.fw.headerFooterView(of: Base.self, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGFloat {
        return tableView.fw.height(headerFooterViewClass: Base.self, type: type, cacheBy: key, configuration: configuration)
    }
}

// MARK: - Wrapper+UITableView
/// 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 通常使用rowHeight为automaticDimension自动撑开布局即可，无需计算高度；
/// 适用于需要计算高度或automaticDimension不满足需求的场景；
/// 如果使用系统自动高度，建议设置estimatedRowHeight提高性能
/// - see: [UITableViewDynamicLayoutCacheHeight](https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight)
extension Wrapper where Base: UITableView {
    // MARK: - Cache
    /// 手工清空高度缓存，用于高度发生变化的情况
    public func clearHeightCache() {
        let heightCache = dynamicLayoutHeightCache
        heightCache.heightHorizontalDictionary.removeAll()
        heightCache.heightVerticalDictionary.removeAll()
        
        heightCache.headerHorizontalDictionary.removeAll()
        heightCache.headerVerticalDictionary.removeAll()
        
        heightCache.footerHorizontalDictionary.removeAll()
        heightCache.footerVerticalDictionary.removeAll()
    }

    /// 指定key设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
    public func setCellHeightCache(_ height: CGFloat, for key: AnyHashable) {
        let heightCache = dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            heightCache.heightVerticalDictionary[key] = height > 0 ? height : nil
        } else {
            heightCache.heightHorizontalDictionary[key] = height > 0 ? height : nil
        }
    }

    /// 指定key获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
    public func cellHeightCache(for key: AnyHashable) -> CGFloat {
        let heightCache = dynamicLayoutHeightCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return heightCache.heightVerticalDictionary[key] ?? UITableView.automaticDimension
        } else {
            return heightCache.heightHorizontalDictionary[key] ?? UITableView.automaticDimension
        }
    }

    /// 指定key设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
    public func setHeaderFooterHeightCache(_ height: CGFloat, type: HeaderFooterViewType, for key: AnyHashable) {
        let heightCache = dynamicLayoutHeightCache
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
    public func headerFooterHeightCache(_ type: HeaderFooterViewType, for key: AnyHashable) -> CGFloat {
        let heightCache = dynamicLayoutHeightCache
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
    
    private var dynamicLayoutHeightCache: DynamicLayoutHeightCache {
        if let heightCache = property(forName: "dynamicLayoutHeightCache") as? DynamicLayoutHeightCache {
            return heightCache
        } else {
            let heightCache = DynamicLayoutHeightCache()
            setProperty(heightCache, forName: "dynamicLayoutHeightCache")
            return heightCache
        }
    }

    // MARK: - Cell
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public func cell<T: UITableViewCell>(
        of cellClass: T.Type,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> T {
        let identifier = reuseIdentifier ?? NSStringFromClass(cellClass).appending("FWDynamicLayoutReuseIdentifier")
        if let cell = base.dequeueReusableCell(withIdentifier: identifier) as? T { return cell }
        return cellClass.init(style: style, reuseIdentifier: identifier)
    }
    
    /// 获取 Cell 需要的高度，可指定key使用缓存
    /// - Parameters:
    ///   - cellClass: cell class
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 cell，内部不会拥有 Block，不需要 __weak
    /// - Returns: cell高度
    public func height<T: UITableViewCell>(
        cellClass: T.Type,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGFloat {
        guard let key = key else {
            let cellSize = dynamicSize(viewClass: cellClass, viewIdentifier: "", configuration: configuration)
            return cellSize.height
        }
        
        var cellHeight = cellHeightCache(for: key)
        if cellHeight != UITableView.automaticDimension {
            return cellHeight
        }
        let cellSize = dynamicSize(viewClass: cellClass, viewIdentifier: "", configuration: configuration)
        cellHeight = cellSize.height
        let shouldCache = cellSize.width > 0
        if shouldCache {
            setCellHeightCache(cellHeight, for: key)
        }
        return cellHeight
    }

    // MARK: - HeaderFooterView
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public func headerFooterView<T: UITableViewHeaderFooterView>(
        of headerFooterViewClass: T.Type,
        reuseIdentifier: String? = nil
    ) -> T {
        let identifier = reuseIdentifier ?? NSStringFromClass(headerFooterViewClass).appending("FWDynamicLayoutReuseIdentifier")
        if !propertyBool(forName: identifier) {
            base.register(headerFooterViewClass, forHeaderFooterViewReuseIdentifier: identifier)
            setPropertyBool(true, forName: identifier)
        }
        return base.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
    }
    
    /// 获取 HeaderFooter 需要的高度，可指定key使用缓存
    /// - Parameters:
    ///   - headerFooterViewClass: HeaderFooter class
    ///   - type: HeaderFooter类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
    /// - Returns: HeaderFooter高度
    public func height<T: UITableViewHeaderFooterView>(
        headerFooterViewClass: T.Type,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGFloat {
        guard let key = key else {
            let viewSize = dynamicSize(viewClass: headerFooterViewClass, viewIdentifier: "\(type.rawValue)", configuration: configuration)
            return viewSize.height
        }
        
        var viewHeight = headerFooterHeightCache(type, for: key)
        if viewHeight != UITableView.automaticDimension {
            return viewHeight
        }
        let viewSize = dynamicSize(viewClass: headerFooterViewClass, viewIdentifier: "\(type.rawValue)", configuration: configuration)
        viewHeight = viewSize.height
        let shouldCache = viewSize.width > 0
        if shouldCache {
            setHeaderFooterHeightCache(viewHeight, type: type, for: key)
        }
        return viewHeight
    }
}

// MARK: - Wrapper+UICollectionViewCell
extension Wrapper where Base: UICollectionViewCell {
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.maxYViewFixed }
        set { base.maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.maxYViewPadding }
        set { base.maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.maxYViewExpanded }
        set { base.maxYViewExpanded = newValue }
    }

    /// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
    public static func cell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return collectionView.fw.cell(of: Base.self, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
    }

    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGSize {
        return collectionView.fw.size(cellClass: Base.self, width: width, height: height, cacheBy: key, configuration: configuration)
    }
}

// MARK: - Wrapper+UICollectionReusableView
extension Wrapper where Base: UICollectionReusableView {
    /// 如果用来确定ReusableView所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.maxYViewFixed }
        set { base.maxYViewFixed = newValue }
    }

    /// 最大Y尺寸视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开ReusableView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.maxYViewPadding }
        set { base.maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.maxYViewExpanded }
        set { base.maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public static func reusableView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return collectionView.fw.reusableView(of: Base.self, kind: kind, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        kind: String,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGSize {
        return collectionView.fw.size(reusableViewClass: Base.self, width: width, height: height, kind: kind, cacheBy: key, configuration: configuration)
    }
}

// MARK: - Wrapper+UICollectionView
/// 集合自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 如果使用系统自动尺寸，建议设置estimatedItemSize提高性能
extension Wrapper where Base: UICollectionView {
    // MARK: - Cache
    /// 手工清空尺寸缓存，用于尺寸发生变化的情况
    public func clearSizeCache() {
        let sizeCache = dynamicLayoutSizeCache
        sizeCache.sizeHorizontalDictionary.removeAll()
        sizeCache.sizeVerticalDictionary.removeAll()
        
        sizeCache.headerHorizontalDictionary.removeAll()
        sizeCache.headerVerticalDictionary.removeAll()
        
        sizeCache.footerHorizontalDictionary.removeAll()
        sizeCache.footerVerticalDictionary.removeAll()
    }

    /// 指定key设置cell尺寸缓存，设置为zero时清除缓存
    public func setCellSizeCache(_ size: CGSize, for key: AnyHashable) {
        let sizeCache = dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            sizeCache.sizeVerticalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
        } else {
            sizeCache.sizeHorizontalDictionary[key] = size.width > 0 && size.height > 0 ? size : nil
        }
    }

    /// 指定key获取cell缓存尺寸，默认值automaticSize
    public func cellSizeCache(for key: AnyHashable) -> CGSize {
        let sizeCache = dynamicLayoutSizeCache
        if UIScreen.main.bounds.height > UIScreen.main.bounds.width {
            return sizeCache.sizeVerticalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
        } else {
            return sizeCache.sizeHorizontalDictionary[key] ?? UICollectionViewFlowLayout.automaticSize
        }
    }

    /// 指定key设置ReusableView尺寸缓存，设置为zero时清除缓存
    public func setReusableViewSizeCache(_ size: CGSize, kind: String, for key: AnyHashable) {
        let sizeCache = dynamicLayoutSizeCache
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
    public func reusableViewSizeCache(_ kind: String, for key: AnyHashable) -> CGSize {
        let sizeCache = dynamicLayoutSizeCache
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
    
    private var dynamicLayoutSizeCache: DynamicLayoutSizeCache {
        if let sizeCache = property(forName: "dynamicLayoutSizeCache") as? DynamicLayoutSizeCache {
            return sizeCache
        } else {
            let sizeCache = DynamicLayoutSizeCache()
            setProperty(sizeCache, forName: "dynamicLayoutSizeCache")
            return sizeCache
        }
    }

    // MARK: - Cell
    /// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
    public func cell<T: UICollectionViewCell>(
        of cellClass: T.Type,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> T {
        let identifier = reuseIdentifier ?? NSStringFromClass(cellClass).appending("FWDynamicLayoutReuseIdentifier")
        if !propertyBool(forName: identifier) {
            base.register(cellClass, forCellWithReuseIdentifier: identifier)
            setPropertyBool(true, forName: identifier)
        }
        return base.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }
    
    /// 获取 Cell 需要的尺寸，可固定宽度或高度，可指定key使用缓存
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - width: 固定宽度，默认0不固定
    ///   - height: 固定高度，默认0不固定
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGSize {
        guard let key = key else {
            return dynamicSize(viewClass: cellClass, viewIdentifier: "\(width)-\(height)", width: width, height: height, configuration: configuration)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var cellSize = cellSizeCache(for: cacheKey)
        if cellSize != UICollectionViewFlowLayout.automaticSize {
            return cellSize
        }
        cellSize = dynamicSize(viewClass: cellClass, viewIdentifier: "\(width)-\(height)", width: width, height: height, configuration: configuration)
        let shouldCache = height > 0 || cellSize.width > 0
        if shouldCache {
            setCellSizeCache(cellSize, for: cacheKey)
        }
        return cellSize
    }

    // MARK: - ReusableView
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public func reusableView<T: UICollectionReusableView>(
        of reusableViewClass: T.Type,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> T {
        let identifier = reuseIdentifier ?? NSStringFromClass(reusableViewClass).appending("FWDynamicLayoutReuseIdentifier")
        let kindIdentifier = identifier + kind
        if !propertyBool(forName: kindIdentifier) {
            base.register(reusableViewClass, forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
            setPropertyBool(true, forName: kindIdentifier)
        }
        return base.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! T
    }
    
    /// 获取 ReusableView 需要的尺寸，可固定宽度或高度，可指定key使用缓存
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - width: 固定宽度，默认0不固定
    ///   - height: 固定高度，默认0不固定
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等，默认nil
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        kind: String,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGSize {
        guard let key = key else {
            return dynamicSize(viewClass: reusableViewClass, viewIdentifier: "\(kind)-\(width)-\(height)", width: width, height: height, configuration: configuration)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var viewSize = reusableViewSizeCache(kind, for: cacheKey)
        if viewSize != UICollectionViewFlowLayout.automaticSize {
            return viewSize
        }
        viewSize = dynamicSize(viewClass: reusableViewClass, viewIdentifier: "\(kind)-\(width)-\(height)", width: width, height: height, configuration: configuration)
        let shouldCache = height > 0 || viewSize.width > 0
        if shouldCache {
            setReusableViewSizeCache(viewSize, kind: kind, for: cacheKey)
        }
        return viewSize
    }
}

// MARK: - HeaderFooterViewType
public enum HeaderFooterViewType: Int {
    case header = 0
    case footer = 1
}

// MARK: - DynamicLayoutViewProtocol
/// 动态布局视图协议
@_spi(FW) public protocol DynamicLayoutViewProtocol {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    var maxYViewFixed: Bool { get set }
    
    /// 最大Y视图的底部内边距(横向时为X)，可避免新创建View来撑开Cell，默认0
    var maxYViewPadding: CGFloat { get set }
    
    /// 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    var maxYViewExpanded: Bool { get set }
    
    /// 创建可重用动态布局视图方法
    static func dynamicLayoutView() -> Self
    
    /// 获取可重用动态布局视图内容视图
    var dynamicLayoutContentView: UIView { get }
    
    /// 准备可重用动态布局视图方法
    func dynamicLayoutPrepare()
    
}

@_spi(FW) extension DynamicLayoutViewProtocol where Self: UIView {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { fw.propertyBool(forName: "maxYViewFixed") }
        set { fw.setPropertyBool(newValue, forName: "maxYViewFixed") }
    }

    /// 最大Y视图的底部内边距(横向时为X)，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get {
            if let number = fw.propertyNumber(forName: "maxYViewPadding") {
                return number.doubleValue
            }
            return .zero
        }
        set {
            fw.setPropertyNumber(NSNumber(value: newValue), forName: "maxYViewPadding")
        }
    }

    /// 最大Y视图是否撑开布局(横向时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { fw.propertyBool(forName: "maxYViewExpanded") }
        set { fw.setPropertyBool(newValue, forName: "maxYViewExpanded") }
    }
    
    fileprivate var maxYView: UIView? {
        get { fw.property(forName: "maxYView") as? UIView }
        set { fw.setProperty(newValue, forName: "maxYView") }
    }
    
    /// 创建可重用动态布局视图方法
    public static func dynamicLayoutView() -> Self {
        if let cellClass = self as? UITableViewCell.Type {
            return cellClass.init(style: .default, reuseIdentifier: nil) as! Self
        } else if let viewClass = self as? UITableViewHeaderFooterView.Type {
            return viewClass.init(reuseIdentifier: nil) as! Self
        }
        return self.init(frame: .zero)
    }
    
    /// 获取可重用动态布局视图内容视图
    public var dynamicLayoutContentView: UIView {
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
    public func dynamicLayoutPrepare() {
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

@_spi(FW) extension UITableViewCell: DynamicLayoutViewProtocol {}
@_spi(FW) extension UITableViewHeaderFooterView: DynamicLayoutViewProtocol {}
@_spi(FW) extension UICollectionReusableView: DynamicLayoutViewProtocol {}

// MARK: - DynamicLayoutHeightCache
fileprivate class DynamicLayoutHeightCache: NSObject {
    
    var heightHorizontalDictionary: [AnyHashable: CGFloat] = [:]
    var heightVerticalDictionary: [AnyHashable: CGFloat] = [:]
    
    var headerHorizontalDictionary: [AnyHashable: CGFloat] = [:]
    var headerVerticalDictionary: [AnyHashable: CGFloat] = [:]
    
    var footerHorizontalDictionary: [AnyHashable: CGFloat] = [:]
    var footerVerticalDictionary: [AnyHashable: CGFloat] = [:]
    
}

// MARK: - DynamicLayoutSizeCache
fileprivate class DynamicLayoutSizeCache: NSObject {
    
    var sizeHorizontalDictionary: [AnyHashable: CGSize] = [:]
    var sizeVerticalDictionary: [AnyHashable: CGSize] = [:]
    
    var headerHorizontalDictionary: [AnyHashable: CGSize] = [:]
    var headerVerticalDictionary: [AnyHashable: CGSize] = [:]
    
    var footerHorizontalDictionary: [AnyHashable: CGSize] = [:]
    var footerVerticalDictionary: [AnyHashable: CGSize] = [:]
    
}
