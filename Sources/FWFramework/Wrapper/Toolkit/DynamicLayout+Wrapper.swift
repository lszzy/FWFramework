//
//  DynamicLayout+Wrapper.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UIView+DynamicLayout
extension Wrapper where Base: UIView {
    
    /// 计算动态布局视图指定宽度时的高度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutHeight(width: CGFloat) -> CGFloat {
        return base.fw_layoutHeight(width: width)
    }

    /// 计算动态布局视图指定高度时的宽度。使用AutoLayout必须约束完整，不使用AutoLayout会调用view的sizeThatFits:方法
    public func layoutWidth(height: CGFloat) -> CGFloat {
        return base.fw_layoutWidth(height: height)
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
        return base.fw_dynamicHeight(width: width, maxYViewExpanded: maxYViewExpanded, maxYViewPadding: maxYViewPadding, maxYView: maxYView)
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
        return base.fw_dynamicWidth(height: height, maxYViewExpanded: maxYViewExpanded, maxYViewPadding: maxYViewPadding, maxYView: maxYView)
    }
    
}

// MARK: - UITableViewCell+DynamicLayout
extension Wrapper where Base: UITableViewCell {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.fw_maxYViewFixed }
        set { base.fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.fw_maxYViewPadding }
        set { base.fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.fw_maxYViewExpanded }
        set { base.fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.fw_cell(tableView: tableView, style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGFloat {
        return Base.fw_height(tableView: tableView, cacheBy: key) { cell in
            configuration(cell as! Base)
        }
    }
    
}

// MARK: - UITableViewHeaderFooterView+DynamicLayout
extension Wrapper where Base: UITableViewHeaderFooterView {
    
    /// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.fw_maxYViewFixed }
        set { base.fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.fw_maxYViewPadding }
        set { base.fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.fw_maxYViewExpanded }
        set { base.fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public static func headerFooterView(
        tableView: UITableView,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.fw_headerFooterView(tableView: tableView, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGFloat {
        return Base.fw_height(tableView: tableView, type: type, cacheBy: key) { headerFooterView in
            configuration(headerFooterView as! Base)
        }
    }
    
}

// MARK: - UITableView+DynamicLayout
/// 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 如果使用系统自动高度，建议设置estimatedRowHeight提高性能
/// - see: [UITableViewDynamicLayoutCacheHeight](https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight)
extension Wrapper where Base: UITableView {
    
    // MARK: - Cache
    /// 手工清空高度缓存，用于高度发生变化的情况
    public func clearHeightCache() {
        base.fw_clearHeightCache()
    }

    /// 指定key设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
    public func setCellHeightCache(_ height: CGFloat, for key: AnyHashable) {
        base.fw_setCellHeightCache(height, for: key)
    }

    /// 指定key获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
    public func cellHeightCache(for key: AnyHashable) -> CGFloat {
        return base.fw_cellHeightCache(for: key)
    }

    /// 指定key设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
    public func setHeaderFooterHeightCache(_ height: CGFloat, type: HeaderFooterViewType, for key: AnyHashable) {
        base.fw_setHeaderFooterHeightCache(height, type: type, for: key)
    }

    /// 指定key获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
    public func headerFooterHeightCache(_ type: HeaderFooterViewType, for key: AnyHashable) -> CGFloat {
        return base.fw_headerFooterHeightCache(type, for: key)
    }

    // MARK: - Cell
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
        return base.fw_height(cellClass: cellClass, cacheBy: key) { cell in
            configuration(cell as! T)
        }
    }

    // MARK: - HeaderFooterView
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
        return base.fw_height(headerFooterViewClass: headerFooterViewClass, type: type, cacheBy: key) { headerFooterView in
            configuration(headerFooterView as! T)
        }
    }
    
}

// MARK: - UICollectionViewCell+DynamicLayout
extension Wrapper where Base: UICollectionViewCell {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.fw_maxYViewFixed }
        set { base.fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.fw_maxYViewPadding }
        set { base.fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.fw_maxYViewExpanded }
        set { base.fw_maxYViewExpanded = newValue }
    }

    /// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
    public static func cell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.fw_cell(collectionView: collectionView, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
    }

    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (Base) -> Void
    ) -> CGSize {
        return Base.fw_size(collectionView: collectionView, width: width, height: height, cacheBy: key) { cell in
            configuration(cell as! Base)
        }
    }
    
}

// MARK: - UICollectionReusableView+DynamicLayout
extension Wrapper where Base: UICollectionReusableView {
    
    /// 如果用来确定ReusableView所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.fw_maxYViewFixed }
        set { base.fw_maxYViewFixed = newValue }
    }

    /// 最大Y尺寸视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开ReusableView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.fw_maxYViewPadding }
        set { base.fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.fw_maxYViewExpanded }
        set { base.fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public static func reusableView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.fw_reusableView(collectionView: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
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
        return Base.fw_size(collectionView: collectionView, width: width, height: height, kind: kind, cacheBy: key) { reusableView in
            configuration(reusableView as! Base)
        }
    }
    
}

// MARK: - UICollectionView+DynamicLayout
/// 集合自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
/// 如果使用系统自动尺寸，建议设置estimatedItemSize提高性能
extension Wrapper where Base: UICollectionView {
    
    // MARK: - Cache
    /// 手工清空尺寸缓存，用于尺寸发生变化的情况
    public func clearSizeCache() {
        base.fw_clearSizeCache()
    }

    /// 指定key设置cell尺寸缓存，设置为zero时清除缓存
    public func setCellSizeCache(_ size: CGSize, for key: AnyHashable) {
        base.fw_setCellSizeCache(size, for: key)
    }

    /// 指定key获取cell缓存尺寸，默认值automaticSize
    public func cellSizeCache(for key: AnyHashable) -> CGSize {
        return base.fw_cellSizeCache(for: key)
    }

    /// 指定key设置ReusableView尺寸缓存，设置为zero时清除缓存
    public func setReusableViewSizeCache(_ size: CGSize, kind: String, for key: AnyHashable) {
        base.fw_setReusableViewSizeCache(size, kind: kind, for: key)
    }

    /// 指定key获取ReusableView缓存尺寸，默认值automaticSize
    public func reusableViewSizeCache(_ kind: String, for key: AnyHashable) -> CGSize {
        return base.fw_reusableViewSizeCache(kind, for: key)
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
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGSize {
        return base.fw_size(cellClass: cellClass, width: width, height: height, cacheBy: key) { cell in
            configuration(cell as! T)
        }
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
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        width: CGFloat = 0,
        height: CGFloat = 0,
        kind: String,
        cacheBy key: AnyHashable? = nil,
        configuration: (T) -> Void
    ) -> CGSize {
        return base.fw_size(reusableViewClass: reusableViewClass, width: width, height: height, kind: kind, cacheBy: key) { reusableView in
            configuration(reusableView as! T)
        }
    }
    
}
