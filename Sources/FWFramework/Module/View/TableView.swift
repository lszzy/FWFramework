//
//  TableView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - TableViewDelegate
/// 便捷表格视图代理
open class TableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    /// 表格section数
    open var countForSection: (() -> Int)?
    /// 表格section数，优先级低
    open var sectionCount: Int = 0
    /// 表格row数句柄
    open var countForRow: ((Int) -> Int)?
    /// 表格row数，优先级低
    open var rowCount: Int = 0
    
    /// 表格section头视图句柄，支持UIView或UITableViewHeaderFooterView，默认nil
    open var viewForHeader: ((Int) -> Any?)?
    /// 表格section头视图，支持UIView或UITableViewHeaderFooterView，默认nil，优先级低
    open var headerViewClass: Any?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var headerConfiguration: ((UITableViewHeaderFooterView, Int) -> Void)?
    /// 表格section头高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForHeader: ((Int) -> CGFloat)?
    /// 表格section头高度，默认nil，可设置为automaticDimension，优先级低
    open var headerHeight: CGFloat?
    
    /// 表格section尾视图句柄，支持UIView或UITableViewHeaderFooterView，默认nil
    open var viewForFooter: ((Int) -> Any?)?
    /// 表格section尾视图，支持UIView或UITableViewHeaderFooterView，默认nil，优先级低
    open var footerViewClass: Any?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var footerConfiguration: ((UITableViewHeaderFooterView, Int) -> Void)?
    /// 表格section尾高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForFooter: ((Int) -> CGFloat)?
    /// 表格section尾高度，默认nil，可设置为automaticDimension，优先级低
    open var footerHeight: CGFloat?
    
    /// 表格cell类句柄，style为default，支持cell或cellClass，默认nil
    open var cellForRow: ((IndexPath) -> Any?)?
    /// 表格cell类，支持cell或cellClass，默认nil，优先级低
    open var cellClass: Any?
    /// 表格cell配置句柄，参数为对应cellClass对象
    open var cellConfiguation: ((UITableViewCell, IndexPath) -> Void)?
    /// 表格cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var heightForRow: ((IndexPath) -> CGFloat)?
    /// 表格cell高度，默认nil，可设置为automaticDimension，优先级低
    open var rowHeight: CGFloat?
    
    /// 表格选中事件，默认nil
    open var didSelectRow: ((IndexPath) -> Void)?
    /// 表格删除标题句柄，不为空才能删除，默认nil不能删除
    open var titleForDelete: ((IndexPath) -> String?)?
    /// 表格删除标题，不为空才能删除，默认nil不能删除，优先级低
    open var deleteTitle: String?
    /// 表格删除事件，默认nil
    open var didDeleteRow: ((IndexPath) -> Void)?
    
    // MARK: - UITableView
    
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
        let rowCell = cellForRow?(indexPath) ?? cellClass
        if let cell = rowCell as? UITableViewCell {
            return cell
        }
        guard let clazz = rowCell as? UITableViewCell.Type else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
        let cell = clazz.fw_cell(tableView: tableView)
        cellConfiguation?(cell, indexPath)
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let heightBlock = heightForRow {
            return heightBlock(indexPath)
        }
        if let rowHeight = rowHeight {
            return rowHeight
        }
        
        let rowCell = cellForRow?(indexPath) ?? cellClass
        if let cell = rowCell as? UITableViewCell {
            return cell.frame.size.height
        }
        guard let clazz = rowCell as? UITableViewCell.Type else {
            return 0
        }
        
        return tableView.fw_height(cellClass: clazz, cacheBy: indexPath) { [weak self] (cell) in
            self?.cellConfiguation?(cell, indexPath)
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let viewClass = viewForHeader?(section) ?? headerViewClass
        guard let header = viewClass else { return nil }
        
        if let view = header as? UIView {
            return view
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
            let view = clazz.fw_headerFooterView(tableView: tableView)
            headerConfiguration?(view, section)
            return view
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let heightBlock = heightForHeader {
            return heightBlock(section)
        }
        if let headerHeight = headerHeight {
            return headerHeight
        }
        
        let viewClass = viewForHeader?(section) ?? headerViewClass
        guard let header = viewClass else { return 0 }
        
        if let view = header as? UIView {
            return view.frame.size.height
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            return tableView.fw_height(headerFooterViewClass: clazz, type: .header, cacheBy: section) { [weak self] (headerView) in
                self?.headerConfiguration?(headerView, section)
            }
        }
        return 0
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let viewClass = viewForFooter?(section) ?? footerViewClass
        guard let footer = viewClass else { return nil }
        
        if let view = footer as? UIView {
            return view
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            // 注意：此处必须使用.fw_创建，否则返回的对象类型不对
            let view = clazz.fw_headerFooterView(tableView: tableView)
            footerConfiguration?(view, section)
            return view
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let heightBlock = heightForFooter {
            return heightBlock(section)
        }
        if let footerHeight = footerHeight {
            return footerHeight
        }
        
        let viewClass = viewForFooter?(section) ?? footerViewClass
        guard let footer = viewClass else { return 0 }
        
        if let view = footer as? UIView {
            return view.frame.size.height
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            return tableView.fw_height(headerFooterViewClass: clazz, type: .footer, cacheBy: section) { [weak self] (footerView) in
                self?.footerConfiguration?(footerView, section)
            }
        }
        return 0
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath)
    }
    
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? true : false
    }
    
    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return titleForDelete?(indexPath) ?? deleteTitle
    }
    
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let title = titleForDelete?(indexPath) ?? deleteTitle
        return title != nil ? .delete : .none
    }
    
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            didDeleteRow?(indexPath)
        }
    }
}

@_spi(FW) extension UITableView {
    public var fw_delegate: TableViewDelegate {
        if let result = fw_property(forName: "fw_delegate") as? TableViewDelegate {
            return result
        } else {
            let result = TableViewDelegate()
            fw_setProperty(result, forName: "fw_delegate")
            dataSource = result
            delegate = result
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
