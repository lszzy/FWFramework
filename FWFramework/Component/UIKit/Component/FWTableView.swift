//
//  FWTableView.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/27.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

/// 便捷表格视图
@objcMembers open class FWTableView: UITableView, UITableViewDataSource, UITableViewDelegate {
    /// 表格数据，可选方式，必须按[section][row]二维数组格式
    open var tableData: [[Any]] = []
    
    /// 表格section数，默认自动计算tableData
    open var countForSection: (() -> Int)?
    /// 表格section头视图句柄，支持UIView或UITableViewHeaderFooterView.Type
    open var viewClassForHeader: ((Int) -> Any?)?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForHeader: FWHeaderFooterViewSectionBlock?
    /// 表格section头高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForHeader: ((Int) -> CGFloat)?
    /// 表格section尾视图句柄，支持UIView或UITableViewHeaderFooterView.Type
    open var viewClassForFooter: ((Int) -> Any?)?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    open var viewForFooter: FWHeaderFooterViewSectionBlock?
    /// 表格section尾高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    open var heightForFooter: ((Int) -> CGFloat)?
    
    /// 表格row数句柄，默认自动计算tableData
    open var countForRow: ((Int) -> Int)?
    /// 表格cell类句柄，style固定为default，默认UITableViewCell
    open var cellClassForRow: ((IndexPath) -> UITableViewCell.Type)?
    /// 表格cell配置句柄，参数为对应cellClass对象，默认设置fwViewModel为tableData对应数据
    open var cellForRow: FWCellIndexPathBlock?
    /// 表格cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    open var heightForRow: ((IndexPath) -> CGFloat)?
    /// 表格选中事件，默认nil
    open var didSelectRow: ((IndexPath) -> Void)?
    
    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setupView()
    }
    
    public init(frame: CGRect) {
        super.init(frame: frame, style: .plain)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        tableFooterView = UIView(frame: .zero)
        dataSource = self
        delegate = self
    }
    
    // MARK: - UITableView
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if let countBlock = countForSection {
            return countBlock()
        }
        
        return tableData.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let countBlock = countForRow {
            return countBlock(section)
        }
        
        return tableData.count > section ? tableData[section].count : 0
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clazz = cellClassForRow?(indexPath) ?? UITableViewCell.self
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
        
        let clazz = cellClassForRow?(indexPath) ?? UITableViewCell.self
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
        guard let header = viewClassForHeader?(section) else { return nil }
        
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
        
        guard let header = viewClassForHeader?(section) else { return 0 }
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
        guard let footer = viewClassForFooter?(section) else { return nil }
        
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
        
        guard let footer = viewClassForFooter?(section) else { return 0 }
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
