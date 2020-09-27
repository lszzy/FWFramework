//
//  FWTableView.swift
//  FWFramework
//
//  Created by wuyong on 2020/9/27.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import UIKit

/// 便捷表格视图
@objcMembers public class FWTableView: UIView, UITableViewDataSource, UITableViewDelegate {
    /// 表格视图
    public lazy var tableView: UITableView = {
        let tableView = UITableView(frame: bounds, style: style)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    /// 表格数据，可选方式，必须按[section][row]二维数组格式
    public var tableData: [[Any]] = []
    
    /// 表格头视图
    public var tableHeaderView: UIView? {
        get { return tableView.tableHeaderView }
        set { tableView.tableHeaderView = newValue }
    }
    /// 表格尾视图
    public var tableFooterView: UIView? {
        get { return tableView.tableFooterView }
        set { tableView.tableFooterView = newValue }
    }
    
    /// 表格section数，默认自动计算tableData
    public var numberOfSections: (() -> Int)?
    
    /// 表格section头视图句柄，支持UIView或UITableViewHeaderFooterView.Type
    public var viewClassForHeader: ((Int) -> Any?)?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    public var viewForHeader: FWHeaderFooterViewConfigurationBlock?
    /// 表格section头高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    public var heightForHeader: ((Int) -> CGFloat)?
    
    /// 表格section尾视图句柄，支持UIView或UITableViewHeaderFooterView.Type
    public var viewClassForFooter: ((Int) -> Any?)?
    /// 表格section头视图配置句柄，参数为headerClass对象，默认为nil
    public var viewForFooter: FWHeaderFooterViewConfigurationBlock?
    /// 表格section尾高度句柄，不指定时默认使用FWDynamicLayout自动计算并按section缓存
    public var heightForFooter: ((Int) -> CGFloat)?
    
    /// 表格row数句柄，默认自动计算tableData
    public var numberOfRows: ((Int) -> Int)?
    /// 表格cell类句柄，style固定为default，默认UITableViewCell
    public var cellClassForRow: ((IndexPath) -> UITableViewCell.Type)?
    /// 表格cell配置句柄，参数为对应cellClass对象，默认设置fwViewModel为tableData对应数据
    public var cellForRow: FWCellConfigurationBlock?
    /// 表格cell高度句柄，不指定时默认使用FWDynamicLayout自动计算并按indexPath缓存
    public var heightForRow: ((IndexPath) -> CGFloat)?
    
    private var style: UITableView.Style = .plain
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public init(style: UITableView.Style) {
        super.init(frame: .zero)
        self.style = style
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(tableView)
        tableView.fwPinEdgesToSuperview()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        tableView.reloadData()
    }
    
    public func reloadData() {
        tableView.reloadData()
    }
    
    // MARK: - UITableView
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        if let numberBlock = numberOfSections {
            return numberBlock()
        }
        
        return tableData.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberBlock = numberOfRows {
            return numberBlock(section)
        }
        
        return tableData.count > section ? tableData[section].count : 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let clazz = cellClassForRow?(indexPath) ?? UITableViewCell.self
        let cell = clazz.fwCell(with: tableView)
        if let cellBlock = cellForRow {
            cellBlock(cell)
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
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let heightBlock = heightForRow {
            return heightBlock(indexPath)
        }
        
        let clazz = cellClassForRow?(indexPath) ?? UITableViewCell.self
        if let cellBlock = cellForRow {
            return tableView.fwHeight(withCellClass: clazz, cacheBy: indexPath, configuration: cellBlock)
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
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = viewClassForHeader?(section) else { return nil }
        
        if let view = header as? UIView {
            return view
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            let view = clazz.fwHeaderFooterView(with: tableView)
            let viewBlock = viewForHeader ?? { (header) in header.fwViewModel = nil }
            viewBlock(view)
            return view
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let heightBlock = heightForHeader {
            return heightBlock(section)
        }
        
        guard let header = viewClassForHeader?(section) else { return 0 }
        if let view = header as? UIView {
            return view.frame.size.height
        }
        if let clazz = header as? UITableViewHeaderFooterView.Type {
            let viewBlock = viewForHeader ?? { (header) in header.fwViewModel = nil }
            return tableView.fwHeight(withHeaderFooterViewClass: clazz, type: .header, cacheBySection: section, configuration: viewBlock)
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = viewClassForFooter?(section) else { return nil }
        
        if let view = footer as? UIView {
            return view
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            let view = clazz.fwHeaderFooterView(with: tableView)
            let viewBlock = viewForFooter ?? { (header) in header.fwViewModel = nil }
            viewBlock(view)
            return view
        }
        return nil
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let heightBlock = heightForFooter {
            return heightBlock(section)
        }
        
        guard let footer = viewClassForFooter?(section) else { return 0 }
        if let view = footer as? UIView {
            return view.frame.size.height
        }
        if let clazz = footer as? UITableViewHeaderFooterView.Type {
            let viewBlock = viewForFooter ?? { (header) in header.fwViewModel = nil }
            return tableView.fwHeight(withHeaderFooterViewClass: clazz, type: .footer, cacheBySection: section, configuration: viewBlock)
        }
        return 0
    }
}
