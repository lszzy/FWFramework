//
//  UITableView+FWDelegate.swift
//  FWFramework
//
//  Created by wuyong on 2020/10/21.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

/// 便捷表格视图代理
@objcMembers open class FWTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    /// 表格数据，可选方式，必须按[section][row]二维数组格式
    open var tableData: [[Any]] = []
    
    /// 表格section数，默认自动计算tableData
    open var countForSection: (() -> Int)?
    /// 表格section数，默认0自动计算，优先级低
    open var sectionCount: Int = 0
    /// 表格row数句柄，默认自动计算tableData
    open var countForRow: ((Int) -> Int)?
    /// 表格row数，默认0自动计算，优先级低
    open var rowCount: Int = 0
    
    /// 表格section头视图句柄，支持UIView或UITableViewHeaderFooterView
    open var viewClassForHeader: ((Int) -> Any?)?
    /// 表格section头视图，默认nil，支持UIView或UITableViewHeaderFooterView，优先级低
    open var headerViewClass: Any?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForHeader: FWHeaderFooterViewSectionBlock?
    /// 表格section头高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForHeader: ((Int) -> CGFloat)?
    /// 表格section头高度，默认0自动计算，优先级低
    open var headerHeight: CGFloat = 0
    
    /// 表格section尾视图句柄，支持UIView或UITableViewHeaderFooterView
    open var viewClassForFooter: ((Int) -> Any?)?
    /// 表格section尾视图，默认nil，支持UIView或UITableViewHeaderFooterView，优先级低
    open var footerViewClass: Any?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForFooter: FWHeaderFooterViewSectionBlock?
    /// 表格section尾高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForFooter: ((Int) -> CGFloat)?
    /// 表格section尾高度，默认0自动计算，优先级低
    open var footerHeight: CGFloat = 0
    
    /// 表格cell类句柄，style为default，支持cell或cellClass，默认nil
    open var cellClassForRow: ((IndexPath) -> Any)?
    /// 表格cell类，支持cell或cellClass，默认UITableViewCell，优先级低
    open var cellClass: Any = UITableViewCell.self
    /// 表格cell配置句柄，参数为对应cellClass对象，默认设置fwViewModel为tableData对应数据
    open var cellForRow: FWCellIndexPathBlock?
    /// 表格cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var heightForRow: ((IndexPath) -> CGFloat)?
    /// 表格cell高度，默认0自动计算，优先级低
    open var rowHeight: CGFloat = 0
    
    /// 表格选中事件，默认nil
    open var didSelectRow: ((IndexPath) -> Void)?
    
    // MARK: - UITableView
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if let countBlock = countForSection {
            return countBlock()
        }
        if sectionCount > 0 {
            return sectionCount
        }
        
        return tableData.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let countBlock = countForRow {
            return countBlock(section)
        }
        if rowCount > 0 {
            return rowCount
        }
        
        return tableData.count > section ? tableData[section].count : 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowCell = cellClassForRow?(indexPath) ?? cellClass
        if let cell = rowCell as? UITableViewCell {
            return cell
        }
        
        let clazz = rowCell as? UITableViewCell.Type ?? UITableViewCell.self
        let cell = clazz.fwCell(with: tableView)
        if let cellBlock = cellForRow {
            cellBlock(cell, indexPath)
            return cell
        }
        
        var viewModel: Any?
        if let sectionData = tableData.count > indexPath.section ? tableData[indexPath.section] : nil,
           sectionData.count > indexPath.row {
            viewModel = sectionData[indexPath.row]
        }
        cell.fwViewModel = viewModel
        return cell
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let heightBlock = heightForRow {
            return heightBlock(indexPath)
        }
        if rowHeight > 0 {
            return rowHeight
        }
        
        let rowCell = cellClassForRow?(indexPath) ?? cellClass
        if let cell = rowCell as? UITableViewCell {
            return cell.frame.size.height
        }
        
        let clazz = rowCell as? UITableViewCell.Type ?? UITableViewCell.self
        if let cellBlock = cellForRow {
            return tableView.fwHeight(withCellClass: clazz, cacheBy: indexPath) { (cell) in
                cellBlock(cell, indexPath)
            }
        }
        
        var viewModel: Any?
        if let sectionData = tableData.count > indexPath.section ? tableData[indexPath.section] : nil,
           sectionData.count > indexPath.row {
            viewModel = sectionData[indexPath.row]
        }
        return tableView.fwHeight(withCellClass: clazz, cacheBy: indexPath) { (cell) in
            cell.fwViewModel = viewModel
        }
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let viewClass = viewClassForHeader?(section) ?? headerViewClass
        guard let header = viewClass else { return nil }
        
        if let view = header as? UIView {
            return view
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            let view = clazz.fwHeaderFooterView(with: tableView)
            let viewBlock = viewForHeader ?? { (header, section) in header.fwViewModel = nil }
            viewBlock(view, section)
            return view
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let heightBlock = heightForHeader {
            return heightBlock(section)
        }
        if headerHeight > 0 {
            return headerHeight
        }
        
        let viewClass = viewClassForHeader?(section) ?? headerViewClass
        guard let header = viewClass else { return 0 }
        
        if let view = header as? UIView {
            return view.frame.size.height
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            let viewBlock = viewForHeader ?? { (header, section) in header.fwViewModel = nil }
            return tableView.fwHeight(withHeaderFooterViewClass: clazz, type: .header, cacheBySection: section) { (headerView) in
                viewBlock(headerView, section)
            }
        }
        return 0
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let viewClass = viewClassForFooter?(section) ?? footerViewClass
        guard let footer = viewClass else { return nil }
        
        if let view = footer as? UIView {
            return view
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            let view = clazz.fwHeaderFooterView(with: tableView)
            let viewBlock = viewForFooter ?? { (footer, section) in footer.fwViewModel = nil }
            viewBlock(view, section)
            return view
        }
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let heightBlock = heightForFooter {
            return heightBlock(section)
        }
        if footerHeight > 0 {
            return footerHeight
        }
        
        let viewClass = viewClassForFooter?(section) ?? footerViewClass
        guard let footer = viewClass else { return 0 }
        
        if let view = footer as? UIView {
            return view.frame.size.height
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            let viewBlock = viewForFooter ?? { (footer, section) in footer.fwViewModel = nil }
            return tableView.fwHeight(withHeaderFooterViewClass: clazz, type: .footer, cacheBySection: section) { (footerView) in
                viewBlock(footerView, section)
            }
        }
        return 0
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath)
    }
}

@objc public extension UITableView {
    class func fwTableView() -> UITableView {
        return fwTableView(.plain)
    }
    
    class func fwTableView(_ style: UITableView.Style) -> UITableView {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.tableFooterView = UIView(frame: .zero)
        return tableView
    }
    
    func fwDelegate() -> FWTableViewDelegate {
        if let result = fwProperty(forName: "fwDelegate") as? FWTableViewDelegate {
            return result
        } else {
            let result = FWTableViewDelegate()
            fwSetProperty(result, forName: "fwDelegate")
            dataSource = result
            delegate = result
            return result
        }
    }
}
