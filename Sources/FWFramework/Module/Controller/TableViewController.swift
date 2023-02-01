//
//  TableViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - TableViewControllerProtocol
/// 表格视图控制器协议，可覆写
@objc public protocol TableViewControllerProtocol: ViewControllerProtocol, UITableViewDataSource, UITableViewDelegate {
    
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    var tableView: UITableView { get }

    /// 表格数据，默认空数组，延迟加载
    var tableData: NSMutableArray { get }

    /// 渲染表格视图样式，默认Plain
    func setupTableStyle() -> UITableView.Style

    /// 渲染表格视图，setupSubviews之前调用，默认未实现
    @objc optional func setupTableView()

    /// 渲染表格视图布局，setupSubviews之前调用，默认铺满
    @objc optional func setupTableLayout()
    
}

extension TableViewControllerProtocol where Self: UIViewController {
    
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    public var tableView: UITableView {
        if let result = fw.property(forName: "tableView") as? UITableView {
            return result
        } else {
            let result = UITableView(frame: .zero, style: setupTableStyle())
            result.showsVerticalScrollIndicator = false
            result.showsHorizontalScrollIndicator = false
            result.tableFooterView = UIView(frame: .zero)
            if #available(iOS 15.0, *) {
                result.sectionHeaderTopPadding = 0
            }
            fw.setProperty(result, forName: "tableView")
            return result
        }
    }
    
    /// 表格数据，默认空数组，延迟加载
    public var tableData: NSMutableArray {
        if let result = fw.property(forName: "tableData") as? NSMutableArray {
            return result
        } else {
            let result = NSMutableArray()
            fw.setProperty(result, forName: "tableData")
            return result
        }
    }
    
    /// 渲染表格视图样式，默认Plain
    public func setupTableStyle() -> UITableView.Style {
        return .plain
    }
    
    /// 渲染表格视图布局，setupSubviews之前调用，默认铺满
    public func setupTableLayout() {
        tableView.fw_pinEdges()
    }
    
}

// MARK: - ViewControllerManager+TableViewControllerProtocol
internal extension ViewControllerManager {
    
    @objc func tableViewControllerViewDidLoad(_ viewController: UIViewController & TableViewControllerProtocol) {
        let tableView = viewController.tableView
        tableView.dataSource = viewController
        tableView.delegate = viewController
        viewController.view.addSubview(tableView)
        
        hookTableViewController?(viewController)
        
        viewController.setupTableView?()
        viewController.setupTableLayout?()
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }
    
}
