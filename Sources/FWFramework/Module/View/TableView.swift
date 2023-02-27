//
//  TableView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - TableViewDelegate
/// 便捷表格视图数据源和事件代理，注意仅代理UITableViewDelegate
open class TableViewDelegate: DelegateProxy<UITableViewDelegate>, UITableViewDelegate, UITableViewDataSource {
    /// 表格section数
    open var countForSection: (() -> Int)?
    /// 表格section数，默认1，优先级低
    open var sectionCount: Int = 1
    /// 表格row数句柄
    open var countForRow: ((Int) -> Int)?
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
    /// 表格section头自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForHeader: ((Int) -> AnyHashable?)?
    
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
    /// 表格section尾自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForFooter: ((Int) -> AnyHashable?)?
    
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
    /// 表格cell自定义高度缓存key句柄，默认nil，优先级高
    open var cacheKeyForRow: ((IndexPath) -> AnyHashable?)?
    
    /// 是否启用默认高度缓存，优先级低于cacheKey句柄，默认false
    open var heightCacheEnabled = false
    /// 表格选中事件，默认nil
    open var didSelectRow: ((IndexPath) -> Void)?
    /// 表格删除标题句柄，不为空才能删除，默认nil不能删除
    open var titleForDelete: ((IndexPath) -> String?)?
    /// 表格删除标题，不为空才能删除，默认nil不能删除，优先级低
    open var deleteTitle: String?
    /// 表格删除事件，默认nil
    open var didDeleteRow: ((IndexPath) -> Void)?
    
    // MARK: - Lifecycle
    /// 初始化并绑定tableView
    public convenience init(tableView: UITableView) {
        self.init()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    // MARK: - UITableViewDataSource
    open func numberOfSections(in tableView: UITableView) -> Int {
        if let countBlock = countForSection {
            return countBlock()
        }
        return sectionCount
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let countBlock = countForRow {
            return countBlock(section)
        }
        return rowCount
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = cellForRow?(tableView, indexPath) {
            return cell
        }
        let cellClass = cellClassForRow?(tableView, indexPath) ?? (cellClass ?? UITableViewCell.self)
        // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
        let cell = cellClass.fw_cell(tableView: tableView)
        cellConfiguation?(cell, indexPath)
        return cell
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? true : false
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            didDeleteRow?(indexPath)
        }
    }
    
    // MARK: - UITableViewDelegate
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let heightBlock = heightForRow {
            return heightBlock(tableView, indexPath)
        }
        if let rowHeight = rowHeight {
            return rowHeight
        }
        
        if cellForRow != nil {
            return UITableView.automaticDimension
        }
        let cellClass = cellClassForRow?(tableView, indexPath) ?? (cellClass ?? UITableViewCell.self)
        let cacheKey = cacheKeyForRow?(indexPath) ?? (heightCacheEnabled ? indexPath : nil)
        return tableView.fw_height(cellClass: cellClass, cacheBy: cacheKey) { [weak self] (cell) in
            self?.cellConfiguation?(cell, indexPath)
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewForHeader != nil {
            return viewForHeader?(tableView, section)
        }
        let viewClass = viewClassForHeader?(tableView, section) ?? headerViewClass
        guard let viewClass = viewClass else { return nil }
        
        // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
        let view = viewClass.fw_headerFooterView(tableView: tableView)
        headerConfiguration?(view, section)
        return view
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let heightBlock = heightForHeader {
            return heightBlock(tableView, section)
        }
        if let headerHeight = headerHeight {
            return headerHeight
        }
        
        if viewForHeader != nil {
            return UITableView.automaticDimension
        }
        let viewClass = viewClassForHeader?(tableView, section) ?? headerViewClass
        guard let viewClass = viewClass else { return 0 }
        
        let cacheKey = cacheKeyForHeader?(section) ?? (heightCacheEnabled ? section : nil)
        return tableView.fw_height(headerFooterViewClass: viewClass, type: .header, cacheBy: cacheKey) { [weak self] (headerView) in
            self?.headerConfiguration?(headerView, section)
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewForFooter != nil {
            return viewForFooter?(tableView, section)
        }
        let viewClass = viewClassForFooter?(tableView, section) ?? footerViewClass
        guard let viewClass = viewClass else { return nil }
        
        // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
        let view = viewClass.fw_headerFooterView(tableView: tableView)
        footerConfiguration?(view, section)
        return view
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let heightBlock = heightForFooter {
            return heightBlock(tableView, section)
        }
        if let footerHeight = footerHeight {
            return footerHeight
        }
        
        if viewForFooter != nil {
            return UITableView.automaticDimension
        }
        let viewClass = viewClassForFooter?(tableView, section) ?? footerViewClass
        guard let viewClass = viewClass else { return 0 }
        
        let cacheKey = cacheKeyForFooter?(section) ?? (heightCacheEnabled ? section : nil)
        return tableView.fw_height(headerFooterViewClass: viewClass, type: .footer, cacheBy: cacheKey) { [weak self] (footerView) in
            self?.footerConfiguration?(footerView, section)
        }
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath)
    }
    
    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return titleForDelete?(indexPath) ?? deleteTitle
    }
    
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? .delete : .none
    }
}

@_spi(FW) extension UITableView {
    public var fw_tableDelegate: TableViewDelegate {
        if let result = fw_property(forName: "fw_tableDelegate") as? TableViewDelegate {
            return result
        } else {
            let result = TableViewDelegate(tableView: self)
            fw_setProperty(result, forName: "fw_tableDelegate")
            return result
        }
    }
    
    public static func fw_tableView() -> Self {
        return fw_tableView(.plain)
    }
    
    public static func fw_tableView(_ style: UITableView.Style) -> Self {
        let tableView = Self(frame: .zero, style: style)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.tableFooterView = UIView(frame: .zero)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        return tableView
    }
}
