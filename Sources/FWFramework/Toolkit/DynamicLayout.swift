//
//  DynamicLayout.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - UITableViewCell+DynamicLayout
@_spi(FW) extension UITableViewCell {
    
    /// 如果用来确定Cell所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var fw_maxYViewFixed: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewFixed") }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开Cell，默认0
    public var fw_maxYViewPadding: CGFloat {
        get {
            if let number = fw_property(forName: "fw_maxYViewPadding") as? NSNumber {
                return number.doubleValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_maxYViewPadding")
        }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var fw_maxYViewExpanded: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewExpanded") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewExpanded") }
    }
    
    fileprivate var fw_maxYView: UIView? {
        get { fw_property(forName: "fw_maxYView") as? UIView }
        set { fw_setProperty(newValue, forName: "fw_maxYView") }
    }
    
    /// 免注册创建UITableViewCell，内部自动处理缓冲池，可指定style类型和reuseIdentifier
    public static func fw_cell(
        tableView: UITableView,
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(Self.classForCoder()).appending("FWDynamicLayoutReuseIdentifier")
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? Self {
            return cell
        }
        return Self(style: style, reuseIdentifier: identifier)
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func fw_height(
        tableView: UITableView,
        cacheBy key: AnyHashable? = nil,
        configuration: @escaping (UITableViewCell) -> Void
    ) -> CGFloat {
        return tableView.fw_height(cellClass: self, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UITableViewHeaderFooterView+DynamicLayout
public enum HeaderFooterViewType: Int {
    case header = 0
    case footer = 1
}

@_spi(FW) extension UITableViewHeaderFooterView {
    
    /// 如果用来确定HeaderFooterView所需高度的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var fw_maxYViewFixed: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewFixed") }
    }

    /// 最大Y视图的底部内边距，可避免新创建View来撑开HeaderFooterView，默认0
    public var fw_maxYViewPadding: CGFloat {
        get {
            if let number = fw_property(forName: "fw_maxYViewPadding") as? NSNumber {
                return number.doubleValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_maxYViewPadding")
        }
    }

    /// 最大Y视图是否撑开布局，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var fw_maxYViewExpanded: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewExpanded") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewExpanded") }
    }
    
    fileprivate var fw_maxYView: UIView? {
        get { fw_property(forName: "fw_maxYView") as? UIView }
        set { fw_setProperty(newValue, forName: "fw_maxYView") }
    }
    
    /// 免注册alloc创建UITableViewHeaderFooterView，内部自动处理缓冲池，指定reuseIdentifier
    public static func fw_headerFooterView(
        tableView: UITableView,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(Self.classForCoder()).appending("FWDynamicLayoutReuseIdentifier")
        if tableView.fw_propertyBool(forName: identifier) {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! Self
        }
        tableView.register(Self.classForCoder(), forHeaderFooterViewReuseIdentifier: identifier)
        tableView.fw_setPropertyBool(true, forName: identifier)
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! Self
    }
    
    /// 根据配置自动计算cell高度，可指定key使用缓存，子类可重写
    public static func fw_height(
        tableView: UITableView,
        type: HeaderFooterViewType,
        cacheBy key: AnyHashable? = nil,
        configuration: @escaping (UITableViewHeaderFooterView) -> Void
    ) -> CGFloat {
        return tableView.fw_height(headerFooterViewClass: self, type: type, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UITableView+DynamicLayout
/// 表格自动计算并缓存cell高度分类，最底部view的MaxY即为cell高度，自定义方案实现
///
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
        configuration: @escaping (UITableViewCell) -> Void
    ) -> CGFloat {
        guard let key = key else {
            return fw_dynamicHeight(cellClass: cellClass, configuration: configuration, shouldCache: nil)
        }
        
        var cellHeight = fw_cellHeightCache(for: key)
        if cellHeight != UITableView.automaticDimension {
            return cellHeight
        }
        var shouldCache = true
        cellHeight = fw_dynamicHeight(cellClass: cellClass, configuration: configuration, shouldCache: &shouldCache)
        if shouldCache {
            fw_setCellHeightCache(cellHeight, for: key)
        }
        return cellHeight
    }
    
    private func fw_dynamicView(cellClass: UITableViewCell.Type) -> UIView {
        let classIdentifier = NSStringFromClass(cellClass)
        var dict = fw_property(forName: "fw_dynamicCellViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            fw_setProperty(dict, forName: "fw_dynamicCellViews")
        }
        if let view = dict?[classIdentifier] as? UIView {
            return view
        }
        
        // 这里使用默认的 UITableViewCellStyleDefault 类型。如果需要自定义高度，通常都是使用的此类型, 暂时不考虑其他
        let cell = cellClass.init(style: .default, reuseIdentifier: nil)
        let view = UIView()
        view.addSubview(cell)
        dict?[classIdentifier] = view
        return view
    }
    
    private func fw_dynamicHeight(cellClass: UITableViewCell.Type, configuration: @escaping (UITableViewCell) -> Void, shouldCache: UnsafeMutablePointer<Bool>?) -> CGFloat {
        let view = fw_dynamicView(cellClass: cellClass)
        var width = CGRectGetWidth(self.frame)
        if width <= 0 && self.superview != nil {
            // 获取 TableView 宽度
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
            width = CGRectGetWidth(self.frame)
        }
        if let shouldCache = shouldCache {
            shouldCache.pointee = width > 0
        }
        
        // 设置 Frame
        view.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        guard let cell = view.subviews.first as? UITableViewCell else { return .zero }
        cell.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        
        // 让外面布局 Cell
        cell.prepareForReuse()
        configuration(cell)
        
        // 自动撑开方式
        if cell.fw_maxYViewExpanded {
            return cell.fw_layoutHeight(width: width)
        }
        
        // 刷新布局
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 获取需要的高度
        var maxY: CGFloat = 0
        if cell.fw_maxYViewFixed {
            if let maxYView = cell.fw_maxYView {
                maxY = CGRectGetMaxY(maxYView.frame)
            } else {
                var maxYView: UIView?
                for tempView in cell.contentView.subviews.reversed() {
                    let tempY = CGRectGetMaxY(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                cell.fw_maxYView = maxYView
            }
        } else {
            for tempView in cell.contentView.subviews.reversed() {
                let tempY = CGRectGetMaxY(tempView.frame)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += cell.fw_maxYViewPadding
        return maxY
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
        configuration: @escaping (UITableViewHeaderFooterView) -> Void
    ) -> CGFloat {
        guard let key = key else {
            return fw_dynamicHeight(headerFooterViewClass: headerFooterViewClass, type: type, configuration: configuration, shouldCache: nil)
        }
        
        var viewHeight = fw_headerFooterHeightCache(type, for: key)
        if viewHeight != UITableView.automaticDimension {
            return viewHeight
        }
        var shouldCache = true
        viewHeight = fw_dynamicHeight(headerFooterViewClass: headerFooterViewClass, type: type, configuration: configuration, shouldCache: &shouldCache)
        if shouldCache {
            fw_setHeaderFooterHeightCache(viewHeight, type: type, for: key)
        }
        return viewHeight
    }
    
    private func fw_dynamicView(headerFooterViewClass: UITableViewHeaderFooterView.Type, identifier: String) -> UIView {
        let classIdentifier = NSStringFromClass(headerFooterViewClass).appending(identifier)
        var dict = fw_property(forName: "fw_dynamicHeaderFooterViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            fw_setProperty(dict, forName: "fw_dynamicHeaderFooterViews")
        }
        if let view = dict?[classIdentifier] as? UIView {
            return view
        }
        
        let headerFooterView = headerFooterViewClass.init(reuseIdentifier: nil)
        let view = UIView()
        view.addSubview(headerFooterView)
        dict?[classIdentifier] = view
        return view
    }
    
    private func fw_dynamicHeight(headerFooterViewClass: UITableViewHeaderFooterView.Type, type: HeaderFooterViewType, configuration: @escaping (UITableViewHeaderFooterView) -> Void, shouldCache: UnsafeMutablePointer<Bool>?) -> CGFloat {
        let view = fw_dynamicView(headerFooterViewClass: headerFooterViewClass, identifier: "\(type.rawValue)")
        var width = CGRectGetWidth(self.frame)
        if width <= 0 && self.superview != nil {
            // 获取 TableView 宽度
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
            width = CGRectGetWidth(self.frame)
        }
        if let shouldCache = shouldCache {
            shouldCache.pointee = width > 0
        }
        
        // 设置 Frame
        view.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        guard let headerFooterView = view.subviews.first as? UITableViewHeaderFooterView else { return .zero }
        headerFooterView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        
        // 让外面布局 UITableViewHeaderFooterView
        headerFooterView.prepareForReuse()
        configuration(headerFooterView)
        
        // 自动撑开方式
        if headerFooterView.fw_maxYViewExpanded {
            return headerFooterView.fw_layoutHeight(width: width)
        }
        
        // 刷新布局
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 获取需要的高度
        var maxY: CGFloat = 0
        let contentView = headerFooterView.contentView.subviews.count > 0 ? headerFooterView.contentView : headerFooterView
        if headerFooterView.fw_maxYViewFixed {
            if let maxYView = headerFooterView.fw_maxYView {
                maxY = CGRectGetMaxY(maxYView.frame)
            } else {
                var maxYView: UIView?
                for tempView in contentView.subviews.reversed() {
                    let tempY = CGRectGetMaxY(tempView.frame)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                headerFooterView.fw_maxYView = maxYView
            }
        } else {
            for tempView in contentView.subviews.reversed() {
                let tempY = CGRectGetMaxY(tempView.frame)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += headerFooterView.fw_maxYViewPadding
        return maxY
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
        let identifier = reuseIdentifier ?? NSStringFromClass(Self.classForCoder()).appending("FWDynamicLayoutReuseIdentifier")
        if collectionView.fw_propertyBool(forName: identifier) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Self
        }
        collectionView.register(Self.classForCoder(), forCellWithReuseIdentifier: identifier)
        collectionView.fw_setPropertyBool(true, forName: identifier)
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Self
    }

    /// 根据配置自动计算view大小，可固定宽度或高度，可指定key使用缓存，子类可重写
    public static func fw_size(
        collectionView: UICollectionView,
        width: CGFloat = 0,
        height: CGFloat = 0,
        cacheBy key: AnyHashable? = nil,
        configuration: @escaping (UICollectionViewCell) -> Void
    ) -> CGSize {
        return collectionView.fw_size(cellClass: self, width: width, height: height, cacheBy: key, configuration: configuration)
    }
    
}

// MARK: - UICollectionReusableView+DynamicLayout
@_spi(FW) extension UICollectionReusableView {
    
    /// 如果用来确定ReusableView所需尺寸的View是唯一的，请把此值设置为YES，可提升一定的性能
    public var fw_maxYViewFixed: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewFixed") }
    }

    /// 最大Y尺寸视图的底部内边距(横向滚动时为X)，可避免新创建View来撑开ReusableView，默认0
    public var fw_maxYViewPadding: CGFloat {
        get {
            if let number = fw_property(forName: "fw_maxYViewPadding") as? NSNumber {
                return number.doubleValue
            }
            return .zero
        }
        set {
            fw_setProperty(NSNumber(value: newValue), forName: "fw_maxYViewPadding")
        }
    }

    /// 最大Y视图是否撑开布局(横向滚动时为X)，需布局约束完整。默认NO，无需撑开布局；YES时padding不起作用
    public var fw_maxYViewExpanded: Bool {
        get { fw_propertyBool(forName: "fw_maxYViewExpanded") }
        set { fw_setPropertyBool(newValue, forName: "fw_maxYViewExpanded") }
    }
    
    fileprivate var fw_maxYView: UIView? {
        get { fw_property(forName: "fw_maxYView") as? UIView }
        set { fw_setProperty(newValue, forName: "fw_maxYView") }
    }
    
    /// 免注册alloc创建UICollectionReusableView，内部自动处理缓冲池，指定reuseIdentifier
    public static func fw_reusableView(
        collectionView: UICollectionView,
        kind: String,
        indexPath: IndexPath,
        reuseIdentifier: String? = nil
    ) -> Self {
        let identifier = reuseIdentifier ?? NSStringFromClass(Self.classForCoder()).appending("FWDynamicLayoutReuseIdentifier")
        let kindIdentifier = identifier + kind
        if collectionView.fw_propertyBool(forName: kindIdentifier) {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! Self
        }
        collectionView.register(Self.classForCoder(), forSupplementaryViewOfKind: kind, withReuseIdentifier: identifier)
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
        configuration: @escaping (UICollectionReusableView) -> Void
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
        configuration: @escaping (UICollectionViewCell) -> Void
    ) -> CGSize {
        guard let key = key else {
            return fw_dynamicSize(cellClass: cellClass, width: width, height: height, configuration: configuration, shouldCache: nil)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var cellSize = fw_cellSizeCache(for: cacheKey)
        if cellSize != UICollectionViewFlowLayout.automaticSize {
            return cellSize
        }
        var shouldCache = true
        cellSize = fw_dynamicSize(cellClass: cellClass, width: width, height: height, configuration: configuration, shouldCache: &shouldCache)
        if shouldCache {
            fw_setCellSizeCache(cellSize, for: cacheKey)
        }
        return cellSize
    }
    
    private func fw_dynamicView(cellClass: UICollectionViewCell.Type, identifier: String) -> UIView {
        let classIdentifier = NSStringFromClass(cellClass).appending(identifier)
        var dict = fw_property(forName: "fw_dynamicCellViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            fw_setProperty(dict, forName: "fw_dynamicCellViews")
        }
        if let view = dict?[classIdentifier] as? UIView {
            return view
        }
        
        let cell = cellClass.init()
        let view = UIView()
        view.addSubview(cell)
        dict?[classIdentifier] = view
        return view
    }
    
    private func fw_dynamicSize(cellClass: UICollectionViewCell.Type, width fixedWidth: CGFloat, height fixedHeight: CGFloat, configuration: @escaping (UICollectionViewCell) -> Void, shouldCache: UnsafeMutablePointer<Bool>?) -> CGSize {
        let view = fw_dynamicView(cellClass: cellClass, identifier: "\(fixedWidth)-\(fixedHeight)")
        var width = fixedWidth
        var height = fixedHeight
        if width <= 0 && height <= 0 {
            width = CGRectGetWidth(self.frame)
            if width <= 0 && self.superview != nil {
                // 获取 CollectionView 宽度
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
                width = CGRectGetWidth(self.frame)
            }
        }
        if let shouldCache = shouldCache {
            shouldCache.pointee = fixedHeight > 0 || width > 0
        }
        
        // 设置 Frame
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        guard let cell = view.subviews.first as? UICollectionViewCell else { return .zero }
        cell.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // 让外面布局 Cell
        cell.prepareForReuse()
        configuration(cell)
        
        // 自动撑开方式
        if cell.fw_maxYViewExpanded {
            if fixedHeight > 0 {
                width = cell.fw_layoutWidth(height: height)
            } else {
                height = cell.fw_layoutHeight(width: width)
            }
            return CGSize(width: width, height: height)
        }
        
        // 刷新布局
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 获取需要的高度
        var maxY: CGFloat = 0
        let maxYBlock: (UIView) -> CGFloat = { view in
            return fixedHeight > 0 ? CGRectGetMaxX(view.frame) : CGRectGetMaxY(view.frame)
        }
        if cell.fw_maxYViewFixed {
            if let maxYView = cell.fw_maxYView {
                maxY = maxYBlock(maxYView)
            } else {
                var maxYView: UIView?
                for tempView in cell.contentView.subviews.reversed() {
                    let tempY = maxYBlock(tempView)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                cell.fw_maxYView = maxYView
            }
        } else {
            for tempView in cell.contentView.subviews.reversed() {
                let tempY = maxYBlock(tempView)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += cell.fw_maxYViewPadding
        return fixedHeight > 0 ? CGSize(width: maxY, height: height) : CGSize(width: width, height: maxY)
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
        configuration: @escaping (UICollectionReusableView) -> Void
    ) -> CGSize {
        guard let key = key else {
            return fw_dynamicSize(reusableViewClass: reusableViewClass, width: width, height: height, kind: kind, configuration: configuration, shouldCache: nil)
        }
        
        var cacheKey = key
        if width > 0 || height > 0 {
            cacheKey = "\(cacheKey)-\(width)-\(height)"
        }
        var viewSize = fw_reusableViewSizeCache(kind, for: cacheKey)
        if viewSize != UICollectionViewFlowLayout.automaticSize {
            return viewSize
        }
        var shouldCache = true
        viewSize = fw_dynamicSize(reusableViewClass: reusableViewClass, width: width, height: height, kind: kind, configuration: configuration, shouldCache: &shouldCache)
        if shouldCache {
            fw_setReusableViewSizeCache(viewSize, kind: kind, for: cacheKey)
        }
        return viewSize
    }
    
    private func fw_dynamicView(reusableViewClass: UICollectionReusableView.Type, identifier: String) -> UIView {
        let classIdentifier = NSStringFromClass(reusableViewClass).appending(identifier)
        var dict = fw_property(forName: "fw_dynamicReusableViews") as? NSMutableDictionary
        if dict == nil {
            dict = NSMutableDictionary()
            fw_setProperty(dict, forName: "fw_dynamicReusableViews")
        }
        if let view = dict?[classIdentifier] as? UIView {
            return view
        }
        
        let reusableView = reusableViewClass.init()
        let view = UIView()
        view.addSubview(reusableView)
        dict?[classIdentifier] = view
        return view
    }
    
    private func fw_dynamicSize(reusableViewClass: UICollectionReusableView.Type, width fixedWidth: CGFloat, height fixedHeight: CGFloat, kind: String, configuration: @escaping (UICollectionReusableView) -> Void, shouldCache: UnsafeMutablePointer<Bool>?) -> CGSize {
        let view = fw_dynamicView(reusableViewClass: reusableViewClass, identifier: "\(kind)-\(fixedWidth)-\(fixedHeight)")
        var width = fixedWidth
        var height = fixedHeight
        if width <= 0 && height <= 0 {
            width = CGRectGetWidth(self.frame)
            if width <= 0 && self.superview != nil {
                // 获取 CollectionView 宽度
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
                width = CGRectGetWidth(self.frame)
            }
        }
        if let shouldCache = shouldCache {
            shouldCache.pointee = fixedHeight > 0 || width > 0
        }
        
        // 设置 Frame
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        guard let reusableView = view.subviews.first as? UICollectionReusableView else { return .zero }
        reusableView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        // 让外面布局 UICollectionReusableView
        reusableView.prepareForReuse()
        configuration(reusableView)
        
        // 自动撑开方式
        if reusableView.fw_maxYViewExpanded {
            if fixedHeight > 0 {
                width = reusableView.fw_layoutWidth(height: height)
            } else {
                height = reusableView.fw_layoutHeight(width: width)
            }
            return CGSize(width: width, height: height)
        }
        
        // 刷新布局
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // 获取需要的高度
        var maxY: CGFloat = 0
        let maxYBlock: (UIView) -> CGFloat = { view in
            return fixedHeight > 0 ? CGRectGetMaxX(view.frame) : CGRectGetMaxY(view.frame)
        }
        if reusableView.fw_maxYViewFixed {
            if let maxYView = reusableView.fw_maxYView {
                maxY = maxYBlock(maxYView)
            } else {
                var maxYView: UIView?
                for tempView in reusableView.subviews.reversed() {
                    let tempY = maxYBlock(tempView)
                    if tempY > maxY {
                        maxY = tempY
                        maxYView = tempView
                    }
                }
                reusableView.fw_maxYView = maxYView
            }
        } else {
            for tempView in reusableView.subviews.reversed() {
                let tempY = maxYBlock(tempView)
                if tempY > maxY {
                    maxY = tempY
                }
            }
        }
        maxY += reusableView.fw_maxYViewPadding
        return fixedHeight > 0 ? CGSize(width: maxY, height: height) : CGSize(width: width, height: maxY)
    }
    
}
