//
//  DynamicLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - UITableViewCell+DynamicLayout
extension Wrapper where Base: UITableViewCell {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.__fw_maxYViewFixed }
        set { base.__fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.__fw_maxYViewPadding }
        set { base.__fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.__fw_maxYViewExpanded }
        set { base.__fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.__fw_cell(with: tableView, style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// 根据配置自动计算cell高度，不使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        configuration: @escaping (Base) -> Void
    ) -> CGFloat {
        return Base.__fw_height(with: tableView) { cell in
            configuration(cell as! Base)
        }
    }
    
}

// MARK: - UITableViewHeaderFooterView+DynamicLayout
extension Wrapper where Base: UITableViewHeaderFooterView {
    
    /// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.__fw_maxYViewFixed }
        set { base.__fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.__fw_maxYViewPadding }
        set { base.__fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.__fw_maxYViewExpanded }
        set { base.__fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public static func headerFooterView(
        tableView: UITableView,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.__fw_headerFooterView(with: tableView, reuseIdentifier: reuseIdentifier)
    }

    /// 根据配置自动计算cell高度，不使用缓存，子类可重写
    public static func height(
        tableView: UITableView,
        type: HeaderFooterViewType,
        configuration: @escaping (Base) -> Void
    ) -> CGFloat {
        return Base.__fw_height(with: tableView, type: type) { headerFooterView in
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
        base.__fw_clearHeightCache()
    }
    
    /// 指定indexPath设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
    public func setCellHeightCache(_ height: CGFloat, for indexPath: IndexPath) {
        base.__fw_setCellHeightCache(height, for: indexPath)
    }

    /// 指定key设置cell高度缓存，如willDisplayCell调用，height为cell.frame.size.height，设置为0时清除缓存
    public func setCellHeightCache(_ height: CGFloat, for key: NSCopying) {
        base.__fw_setCellHeightCache(height, forKey: key)
    }

    /// 指定indexPath获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
    public func cellHeightCache(for indexPath: IndexPath) -> CGFloat {
        return base.__fw_cellHeightCache(for: indexPath)
    }

    /// 指定key获取cell缓存高度，如estimatedHeightForRow调用，默认值automaticDimension
    public func cellHeightCache(for key: NSCopying) -> CGFloat {
        return base.__fw_cellHeightCache(forKey: key)
    }

    /// 指定section设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
    public func setHeaderFooterHeightCache(_ height: CGFloat, type: HeaderFooterViewType, for section: Int) {
        base.__fw_setHeaderFooterHeightCache(height, type: type, forSection: section)
    }

    /// 指定key设置HeaderFooter高度缓存，如willDisplayHeaderFooter调用，height为view.frame.size.height，设置为0时清除缓存
    public func setHeaderFooterHeightCache(_ height: CGFloat, type: HeaderFooterViewType, for key: NSCopying) {
        base.__fw_setHeaderFooterHeightCache(height, type: type, forKey: key)
    }

    /// 指定section获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
    public func headerFooterHeightCache(_ type: HeaderFooterViewType, forSection section: Int) -> CGFloat {
        return base.__fw_headerFooterHeightCache(type, forSection: section)
    }

    /// 指定key获取HeaderFooter缓存高度，如estimatedHeightForHeaderFooter调用，默认值automaticDimension
    public func headerFooterHeightCache(_ type: HeaderFooterViewType, for key: NSCopying) -> CGFloat {
        return base.__fw_headerFooterHeightCache(type, forKey: key)
    }

    // MARK: - Cell
    /// 获取 Cell 需要的高度，内部无缓存操作
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell高度
    public func height<T: UITableViewCell>(
        cellClass: T.Type,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withCellClass: cellClass) { cell in
            configuration(cell as! T)
        }
    }
    
    /// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 indexPath
    /// - Parameters:
    ///   - cellClass: cell class
    ///   - indexPath: 使用 indexPath 做缓存标识
    ///   - configuration: 布局 cell，内部不会拥有 Block，不需要 __weak
    /// - Returns: cell高度
    public func height<T: UITableViewCell>(
        cellClass: T.Type,
        cacheBy indexPath: IndexPath,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withCellClass: cellClass, cacheBy: indexPath) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的高度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - cellClass: cell class
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局 cell，内部不会拥有 Block，不需要 __weak
    /// - Returns: cell高度
    public func height<T: UITableViewCell>(
        cellClass: T.Type,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withCellClass: cellClass, cacheByKey: key) { cell in
            configuration(cell as! T)
        }
    }

    // MARK: - HeaderFooterView
    /// 获取 HeaderFooter 需要的高度，内部无缓存操作
    /// - Parameters:
    ///   - headerFooterViewClass: HeaderFooter class
    ///   - type: HeaderFooter类型，Header 或者 Footer
    ///   - configuration: 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
    /// - Returns: HeaderFooter高度
    public func height<T: UITableViewHeaderFooterView>(
        headerFooterViewClass: T.Type,
        type: HeaderFooterViewType,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withHeaderFooterViewClass: headerFooterViewClass, type: type) { headerFooterView in
            configuration(headerFooterView as! T)
        }
    }
    
    /// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 section
    /// - Parameters:
    ///   - headerFooterViewClass: HeaderFooter class
    ///   - type: HeaderFooter类型，Header 或者 Footer
    ///   - section: 使用 section 做缓存标识
    ///   - configuration: 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
    /// - Returns: HeaderFooter高度
    public func height<T: UITableViewHeaderFooterView>(
        headerFooterViewClass: T.Type,
        type: HeaderFooterViewType,
        cacheBy section: Int,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withHeaderFooterViewClass: headerFooterViewClass, type: type, cacheBySection: section) { headerFooterView in
            configuration(headerFooterView as! T)
        }
    }

    /// 获取 HeaderFooter 需要的高度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - headerFooterViewClass: HeaderFooter class
    ///   - type: HeaderFooter类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局 HeaderFooter，内部不会拥有 Block，不需要 __weak
    /// - Returns: HeaderFooter高度
    public func height<T: UITableViewHeaderFooterView>(
        headerFooterViewClass: T.Type,
        type: HeaderFooterViewType,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGFloat {
        return base.__fw_height(withHeaderFooterViewClass: headerFooterViewClass, type: type, cacheByKey: key) { headerFooterView in
            configuration(headerFooterView as! T)
        }
    }
    
}

// MARK: - UICollectionViewCell+DynamicLayout
extension Wrapper where Base: UICollectionViewCell {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.__fw_maxYViewFixed }
        set { base.__fw_maxYViewFixed = newValue }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.__fw_maxYViewPadding }
        set { base.__fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.__fw_maxYViewExpanded }
        set { base.__fw_maxYViewExpanded = newValue }
    }

    /// 免注册创建UICollectionViewCell，内部自动处理缓冲池，指定reuseIdentifier
    public static func cell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.__fw_cell(with: collectionView, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
    }

    /// 根据配置自动计算view大小，子类可重写
    public static func size(
        collectionView: UICollectionView,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView) { cell in
            configuration(cell as! Base)
        }
    }

    /// 根据配置自动计算view大小，固定宽度，子类可重写
    public static func size(
        collectionView: UICollectionView,
        width: CGFloat,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView, width: width) { cell in
            configuration(cell as! Base)
        }
    }

    /// 根据配置自动计算view大小，固定高度，子类可重写
    public static func size(
        collectionView: UICollectionView,
        height: CGFloat,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView, height: height) { cell in
            configuration(cell as! Base)
        }
    }
    
}

// MARK: - UICollectionReusableView+DynamicLayout
extension Wrapper where Base: UICollectionReusableView {
    
    /// 如果用来确定ReusableView所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var maxYViewFixed: Bool {
        get { return base.__fw_maxYViewFixed }
        set { base.__fw_maxYViewFixed = newValue }
    }

    /// 最大Y尺寸视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开ReusableView，默认0
    public var maxYViewPadding: CGFloat {
        get { return base.__fw_maxYViewPadding }
        set { base.__fw_maxYViewPadding = newValue }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var maxYViewExpanded: Bool {
        get { return base.__fw_maxYViewExpanded }
        set { base.__fw_maxYViewExpanded = newValue }
    }
    
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public static func reusableView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Base {
        return Base.__fw_reusableView(with: collectionView, kind: kind, indexPath: indexPath, reuseIdentifier: reuseIdentifier)
    }

    /// 根据配置自动计算view大小，子类可重写
    public static func size(
        collectionView: UICollectionView,
        kind: String,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView, kind: kind) { reusableView in
            configuration(reusableView as! Base)
        }
    }

    /// 根据配置自动计算view大小，固定宽度，子类可重写
    public static func size(
        collectionView: UICollectionView,
        width: CGFloat,
        kind: String,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView, width: width, kind: kind) { reusableView in
            configuration(reusableView as! Base)
        }
    }

    /// 根据配置自动计算view大小，固定高度，子类可重写
    public static func size(
        collectionView: UICollectionView,
        height: CGFloat,
        kind: String,
        configuration: @escaping (Base) -> Void
    ) -> CGSize {
        return Base.__fw_size(with: collectionView, height: height, kind: kind) { reusableView in
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
        base.__fw_clearSizeCache()
    }
    
    /// 指定indexPath设置cell尺寸缓存，设置为zero时清除缓存
    public func setCellSizeCache(_ size: CGSize, for indexPath: IndexPath) {
        base.__fw_setCellSizeCache(size, for: indexPath)
    }

    /// 指定key设置cell尺寸缓存，设置为zero时清除缓存
    public func setCellSizeCache(_ size: CGSize, for key: NSCopying) {
        base.__fw_setCellSizeCache(size, forKey: key)
    }

    /// 指定indexPath获取cell缓存尺寸，默认值automaticSize
    public func cellSizeCache(for indexPath: IndexPath) -> CGSize {
        return base.__fw_cellSizeCache(for: indexPath)
    }

    /// 指定key获取cell缓存尺寸，默认值automaticSize
    public func cellSizeCache(for key: NSCopying) -> CGSize {
        return base.__fw_cellSizeCache(forKey: key)
    }

    /// 指定section设置ReusableView尺寸缓存，设置为zero时清除缓存
    public func setReusableViewSizeCache(_ size: CGSize, kind: String, for section: Int) {
        base.__fw_setReusableViewSizeCache(size, kind: kind, forSection: section)
    }

    /// 指定key设置ReusableView尺寸缓存，设置为zero时清除缓存
    public func setReusableViewSizeCache(_ size: CGSize, kind: String, for key: NSCopying) {
        base.__fw_setReusableViewSizeCache(size, kind: kind, forKey: key)
    }

    /// 指定section获取ReusableView缓存尺寸，默认值automaticSize
    public func reusableViewSizeCache(_ kind: String, forSection section: Int) -> CGSize {
        return base.__fw_reusableViewSizeCache(kind, forSection: section)
    }

    /// 指定key获取ReusableView缓存尺寸，默认值automaticSize
    public func reusableViewSizeCache(_ kind: String, for key: NSCopying) -> CGSize {
        return base.__fw_reusableViewSizeCache(kind, forKey: key)
    }

    // MARK: - Cell
    /// 获取 Cell 需要的尺寸，内部无缓存操作
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，固定宽度，内部无缓存操作
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - width: 固定宽度
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        width: CGFloat,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, width: width) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，固定高度，内部无缓存操作
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - height: 固定高度
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        height: CGFloat,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, height: height) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，内部自动处理缓存，缓存标识 indexPath
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - indexPath: 使用 indexPath 做缓存标识
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        cacheBy indexPath: IndexPath,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, cacheBy: indexPath) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 indexPath
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - width: 固定宽度
    ///   - indexPath: 使用 indexPath 做缓存标识
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        width: CGFloat,
        cacheBy indexPath: IndexPath,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, width: width, cacheBy: indexPath) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 indexPath
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - height: 固定高度
    ///   - indexPath: 使用 indexPath 做缓存标识
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        height: CGFloat,
        cacheBy indexPath: IndexPath,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, height: height, cacheBy: indexPath) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, cacheByKey: key) { cell in
            configuration(cell as! T)
        }
    }
    
    /// 获取 Cell 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - width: 固定宽度
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        width: CGFloat,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, width: width, cacheByKey: key) { cell in
            configuration(cell as! T)
        }
    }

    /// 获取 Cell 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - cellClass: cell类
    ///   - height: 固定高度
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局cell句柄，内部不会拥有Block，不需要__weak
    /// - Returns: cell尺寸
    public func size<T: UICollectionViewCell>(
        cellClass: T.Type,
        height: CGFloat,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withCellClass: cellClass, height: height, cacheByKey: key) { cell in
            configuration(cell as! T)
        }
    }

    // MARK: - ReusableView
    /// 获取 ReusableView 需要的尺寸，内部无缓存操作
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        kind: String,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, kind: kind) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定宽度，内部无缓存操作
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - width: 固定宽度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        width: CGFloat,
        kind: String,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, width: width, kind: kind) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定高度，内部无缓存操作
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - height: 固定高度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        height: CGFloat,
        kind: String,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, height: height, kind: kind) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，内部自动处理缓存，缓存标识 section
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - section: 使用 section 做缓存标识
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        kind: String,
        cacheBy section: Int,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, kind: kind, cacheBySection: section) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 section
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - width: 固定宽度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - section: 使用 section 做缓存标识
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        width: CGFloat,
        kind: String,
        cacheBy section: Int,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, width: width, kind: kind, cacheBySection: section) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 section
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - height: 固定高度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - section: 使用 section 做缓存标识
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        height: CGFloat,
        kind: String,
        cacheBy section: Int,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, height: height, kind: kind, cacheBySection: section) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        kind: String,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, kind: kind, cacheByKey: key) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定宽度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - width: 固定宽度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        width: CGFloat,
        kind: String,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, width: width, kind: kind, cacheByKey: key) { reusableView in
            configuration(reusableView as! T)
        }
    }

    /// 获取 ReusableView 需要的尺寸，固定高度，内部自动处理缓存，缓存标识 key
    /// - Parameters:
    ///   - reusableViewClass: ReusableView class
    ///   - height: 固定高度
    ///   - kind: ReusableView类型，Header 或者 Footer
    ///   - key: 使用 key 做缓存标识，如数据唯一id，对象hash等
    ///   - configuration: 布局 ReusableView，内部不会拥有 Block，不需要 __weak
    /// - Returns: ReusableView尺寸
    public func size<T: UICollectionReusableView>(
        reusableViewClass: T.Type,
        height: CGFloat,
        kind: String,
        cacheBy key: NSCopying?,
        configuration: @escaping (T) -> Void
    ) -> CGSize {
        return base.__fw_size(withReusableViewClass: reusableViewClass, height: height, kind: kind, cacheByKey: key) { reusableView in
            configuration(reusableView as! T)
        }
    }
    
}
