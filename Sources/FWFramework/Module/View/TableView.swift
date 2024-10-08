//
//  TableView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - Wrapper+UITableView
@MainActor extension Wrapper where Base: UITableView {
    /// 表格代理，延迟加载
    public var tableDelegate: TableViewDelegate {
        get {
            if let result = property(forName: "tableDelegate") as? TableViewDelegate {
                return result
            } else {
                let result = TableViewDelegate()
                setProperty(result, forName: "tableDelegate")
                return result
            }
        }
        set {
            setProperty(newValue, forName: "tableDelegate")
        }
    }

    /// 快速创建tableView，可配置钩子句柄
    public static func tableView(_ style: UITableView.Style = .plain) -> Base {
        let tableView = Base(frame: .zero, style: style)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableViewConfiguration?(tableView)
        return tableView
    }

    /// 配置创建tableView钩子句柄，默认nil
    public static var tableViewConfiguration: ((Base) -> Void)? {
        get { NSObject.fw.getAssociatedObject(Base.self, key: #function) as? (Base) -> Void }
        set { NSObject.fw.setAssociatedObject(Base.self, key: #function, value: newValue, policy: .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}

// MARK: - TableViewDelegate
/// 常用表格视图数据源和事件代理，可继承
@MainActor open class TableViewDelegate: DelegateProxy<UITableViewDelegate>, UITableViewDelegate, UITableViewDataSource {
    /// 表格section数
    open var numberOfSections: (() -> Int)?
    /// 表格section数，默认1，优先级低
    open var sectionCount: Int = 1
    /// 表格row数句柄
    open var numberOfRows: ((Int) -> Int)?
    /// 表格row数，优先级低
    open var rowCount: Int = 0

    /// 表格section头视图句柄，高度未指定时automaticDimension，默认nil
    open var viewForHeader: ((UITableView, Int) -> UIView?)?
    /// 表格section头视图类句柄，搭配headerConfiguration使用，默认nil
    open var viewClassForHeader: ((UITableView, Int) -> UITableViewHeaderFooterView.Type?)?
    /// 表格section头视图类，搭配headerConfiguration使用，默认nil，优先级低
    open var headerViewClass: UITableViewHeaderFooterView.Type?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var headerConfiguration: ((UITableViewHeaderFooterView, Int) -> Void)?
    /// 表格section头高度句柄，不指定时默认使用DynamicLayout自动计算并按section缓存
    open var heightForHeader: ((UITableView, Int) -> CGFloat)?
    /// 表格section头高度，默认nil，可设置为automaticDimension，优先级低
    open var headerHeight: CGFloat?

    /// 表格section尾视图句柄，高度未指定时automaticDimension，默认nil
    open var viewForFooter: ((UITableView, Int) -> UIView?)?
    /// 表格section尾视图类句柄，搭配footerConfiguration使用，默认nil
    open var viewClassForFooter: ((UITableView, Int) -> UITableViewHeaderFooterView.Type?)?
    /// 表格section尾视图，搭配footerConfiguration使用，默认nil，优先级低
    open var footerViewClass: UITableViewHeaderFooterView.Type?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var footerConfiguration: ((UITableViewHeaderFooterView, Int) -> Void)?
    /// 表格section尾高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForFooter: ((UITableView, Int) -> CGFloat)?
    /// 表格section尾高度，默认nil，可设置为automaticDimension，优先级低
    open var footerHeight: CGFloat?

    /// 表格cell视图句柄，高度未指定时automaticDimension，默认nil
    open var cellForRow: ((UITableView, IndexPath) -> UITableViewCell?)?
    /// 表格cell视图类句柄，搭配cellConfiguation使用，默认nil
    open var cellClassForRow: ((UITableView, IndexPath) -> UITableViewCell.Type?)?
    /// 表格cell视图类，搭配cellConfiguation使用，默认nil时为UITableViewCell.Type，优先级低
    open var cellClass: UITableViewCell.Type?
    /// 表格cell配置句柄，参数为对应cellClass对象
    open var cellConfiguation: ((UITableViewCell, IndexPath) -> Void)?
    /// 表格cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var heightForRow: ((UITableView, IndexPath) -> CGFloat)?
    /// 表格cell高度，默认nil，可设置为automaticDimension，优先级低
    open var rowHeight: CGFloat?

    /// 是否启用默认高度缓存，优先级低于cacheKey句柄，默认false
    open var heightCacheEnabled = false
    /// 表格cell自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForRow: ((IndexPath) -> AnyHashable?)?
    /// 表格section头自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForHeader: ((Int) -> AnyHashable?)?
    /// 表格section尾自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForFooter: ((Int) -> AnyHashable?)?

    /// 表格选中事件，默认nil
    open var didSelectRow: ((UITableView, IndexPath) -> Void)?
    /// 表格删除标题句柄，不为空才能删除，默认nil不能删除
    open var titleForDelete: ((IndexPath) -> String?)?
    /// 表格删除标题，不为空才能删除，默认nil不能删除，优先级低
    open var deleteTitle: String?
    /// 表格删除事件，默认nil
    open var didDeleteRow: ((UITableView, IndexPath) -> Void)?
    /// 表格cell即将显示句柄，默认nil
    open var willDisplayCell: ((UITableViewCell, IndexPath) -> Void)?
    /// 表格cell即将停止显示，默认nil
    open var didEndDisplayingCell: ((UITableViewCell, IndexPath) -> Void)?

    /// 表格滚动句柄，默认nil
    open var didScroll: ((UIScrollView) -> Void)?
    /// 表格即将开始拖动句柄，默认nil
    open var willBeginDragging: ((UIScrollView) -> Void)?
    /// 表格即将停止拖动句柄，默认nil
    open var willEndDragging: ((UIScrollView, CGPoint, UnsafeMutablePointer<CGPoint>) -> Void)?
    /// 表格已经停止拖动句柄，默认nil
    open var didEndDragging: ((UIScrollView, Bool) -> Void)?
    /// 表格已经停止减速句柄，默认nil
    open var didEndDecelerating: ((UIScrollView) -> Void)?
    /// 表格已经停止滚动动画句柄，默认nil
    open var didEndScrollingAnimation: ((UIScrollView) -> Void)?

    // MARK: - Lifecycle
    /// 初始化并绑定tableView
    public convenience init(tableView: UITableView) {
        self.init()
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - UITableViewDataSource
    open func numberOfSections(in tableView: UITableView) -> Int {
        let dataSource = delegate as? UITableViewDataSource
        if let sectionCount = dataSource?.numberOfSections?(in: tableView) {
            return sectionCount
        }

        if let countBlock = numberOfSections {
            return countBlock()
        }
        return sectionCount
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dataSource = delegate as? UITableViewDataSource
        if let rowCount = dataSource?.tableView(tableView, numberOfRowsInSection: section) {
            return rowCount
        }

        if let countBlock = numberOfRows {
            return countBlock(section)
        }
        return rowCount
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataSource = delegate as? UITableViewDataSource
        if let cell = dataSource?.tableView(tableView, cellForRowAt: indexPath) {
            return cell
        }

        if let cell = cellForRow?(tableView, indexPath) {
            return cell
        }
        let cellClass = cellClassForRow?(tableView, indexPath) ?? (cellClass ?? UITableViewCell.self)
        // 注意：此处必须使用tableView.fw.cell创建，否则返回的对象类型不对
        let cell = tableView.fw.cell(of: cellClass)
        cellConfiguation?(cell, indexPath)
        return cell
    }

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let dataSource = delegate as? UITableViewDataSource
        if let canEdit = dataSource?.tableView?(tableView, canEditRowAt: indexPath) {
            return canEdit
        }

        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? true : false
    }

    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let dataSource = delegate as? UITableViewDataSource
        if dataSource?.tableView?(tableView, commit: editingStyle, forRowAt: indexPath) != nil {
            return
        }

        if editingStyle == .delete {
            didDeleteRow?(tableView, indexPath)
        }
    }

    // MARK: - UITableViewDelegate
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rowHeight = delegate?.tableView?(tableView, heightForRowAt: indexPath) {
            return rowHeight
        }

        if let heightBlock = heightForRow {
            return heightBlock(tableView, indexPath)
        }
        if let rowHeight {
            return rowHeight
        }

        if cellForRow != nil || cellConfiguation == nil {
            return UITableView.automaticDimension
        }
        let cellClass = cellClassForRow?(tableView, indexPath) ?? (cellClass ?? UITableViewCell.self)
        let cacheKey = cacheKeyForRow?(indexPath) ?? (heightCacheEnabled ? indexPath : nil)
        return tableView.fw.height(cellClass: cellClass, cacheBy: cacheKey) { [weak self] cell in
            self?.cellConfiguation?(cell, indexPath)
        }
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if delegate?.responds(to: #selector(UITableViewDelegate.tableView(_:viewForHeaderInSection:))) ?? false {
            return delegate?.tableView?(tableView, viewForHeaderInSection: section)
        }

        if viewForHeader != nil {
            return viewForHeader?(tableView, section)
        }
        let viewClass = viewClassForHeader?(tableView, section) ?? headerViewClass
        guard let viewClass else { return nil }

        // 注意：此处必须使用tableView.fw.headerFooterView创建，否则返回的对象类型不对
        let view = tableView.fw.headerFooterView(of: viewClass)
        headerConfiguration?(view, section)
        return view
    }

    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let headerHeight = delegate?.tableView?(tableView, heightForHeaderInSection: section) {
            return headerHeight
        }

        if let heightBlock = heightForHeader {
            return heightBlock(tableView, section)
        }
        if let headerHeight {
            return headerHeight
        }

        if viewForHeader != nil {
            return UITableView.automaticDimension
        }
        let viewClass = viewClassForHeader?(tableView, section) ?? headerViewClass
        guard let viewClass else { return 0 }
        if headerConfiguration == nil {
            return UITableView.automaticDimension
        }

        let cacheKey = cacheKeyForHeader?(section) ?? (heightCacheEnabled ? section : nil)
        return tableView.fw.height(headerFooterViewClass: viewClass, type: .header, cacheBy: cacheKey) { [weak self] headerView in
            self?.headerConfiguration?(headerView, section)
        }
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if delegate?.responds(to: #selector(UITableViewDelegate.tableView(_:viewForFooterInSection:))) ?? false {
            return delegate?.tableView?(tableView, viewForFooterInSection: section)
        }

        if viewForFooter != nil {
            return viewForFooter?(tableView, section)
        }
        let viewClass = viewClassForFooter?(tableView, section) ?? footerViewClass
        guard let viewClass else { return nil }

        // 注意：此处必须使用tableView.fw.headerFooterView创建，否则返回的对象类型不对
        let view = tableView.fw.headerFooterView(of: viewClass)
        footerConfiguration?(view, section)
        return view
    }

    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let footerHeight = delegate?.tableView?(tableView, heightForFooterInSection: section) {
            return footerHeight
        }

        if let heightBlock = heightForFooter {
            return heightBlock(tableView, section)
        }
        if let footerHeight {
            return footerHeight
        }

        if viewForFooter != nil {
            return UITableView.automaticDimension
        }
        let viewClass = viewClassForFooter?(tableView, section) ?? footerViewClass
        guard let viewClass else { return 0 }
        if footerConfiguration == nil {
            return UITableView.automaticDimension
        }

        let cacheKey = cacheKeyForFooter?(section) ?? (heightCacheEnabled ? section : nil)
        return tableView.fw.height(headerFooterViewClass: viewClass, type: .footer, cacheBy: cacheKey) { [weak self] footerView in
            self?.footerConfiguration?(footerView, section)
        }
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if delegate?.tableView?(tableView, didSelectRowAt: indexPath) != nil {
            return
        }

        didSelectRow?(tableView, indexPath)
    }

    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if delegate?.responds(to: #selector(UITableViewDelegate.tableView(_:titleForDeleteConfirmationButtonForRowAt:))) ?? false {
            return delegate?.tableView?(tableView, titleForDeleteConfirmationButtonForRowAt: indexPath)
        }

        return titleForDelete?(indexPath) ?? deleteTitle
    }

    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if let editingStyle = delegate?.tableView?(tableView, editingStyleForRowAt: indexPath) {
            return editingStyle
        }

        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? .delete : .none
    }

    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if delegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath) != nil {
            return
        }

        willDisplayCell?(cell, indexPath)
    }

    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if delegate?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath) != nil {
            return
        }

        didEndDisplayingCell?(cell, indexPath)
    }

    // MARK: - UIScrollViewDelegate
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidScroll?(scrollView) != nil {
            return
        }

        didScroll?(scrollView)
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if delegate?.scrollViewWillBeginDragging?(scrollView) != nil {
            return
        }

        willBeginDragging?(scrollView)
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) != nil {
            return
        }

        willEndDragging?(scrollView, velocity, targetContentOffset)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate) != nil {
            return
        }

        didEndDragging?(scrollView, decelerate)
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndDecelerating?(scrollView) != nil {
            return
        }

        didEndDecelerating?(scrollView)
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if delegate?.scrollViewDidEndScrollingAnimation?(scrollView) != nil {
            return
        }

        didEndScrollingAnimation?(scrollView)
    }
}
