//
//  TableViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - TableDelegateControllerProtocol
/// 表格代理控制器协议，数据源和事件代理为tableDelegate，可覆写
public protocol TableDelegateControllerProtocol: ViewControllerProtocol, UITableViewDelegate {
    
    /// 关联表格数据元素类型，默认Any
    associatedtype TableElement = Any
    
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    var tableView: UITableView { get }
    
    /// 表格代理，同表格tableDelegate，延迟加载
    var tableDelegate: TableViewDelegate { get }

    /// 表格数据，默认空数组，延迟加载
    var tableData: [TableElement] { get set }

    /// 渲染表格视图样式，默认Plain
    func setupTableStyle() -> UITableView.Style

    /// 渲染表格视图，setupSubviews之前调用，默认空实现
    func setupTableView()

    /// 渲染表格视图布局，setupSubviews之前调用，默认铺满
    func setupTableLayout()
    
}

// MARK: - TableViewControllerProtocol
/// 表格视图控制器协议，数据源和事件代理为控制器，可覆写
public protocol TableViewControllerProtocol: TableDelegateControllerProtocol, UITableViewDataSource {}

// MARK: - UIViewController+TableViewControllerProtocol
extension TableDelegateControllerProtocol where Self: UIViewController {
    
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    public var tableView: UITableView {
        if let result = fw_property(forName: "tableView") as? UITableView {
            return result
        } else {
            let result = UITableView.fw_tableView(setupTableStyle())
            fw_setProperty(result, forName: "tableView")
            return result
        }
    }
    
    /// 表格代理，同表格tableDelegate，延迟加载
    public var tableDelegate: TableViewDelegate {
        return tableView.fw_tableDelegate
    }
    
    /// 表格数据，默认空数组，延迟加载
    public var tableData: [TableElement] {
        get { return fw_property(forName: "tableData") as? [TableElement] ?? [] }
        set { fw_setProperty(newValue, forName: "tableData") }
    }
    
    /// 渲染表格视图样式，默认Plain
    public func setupTableStyle() -> UITableView.Style {
        return .plain
    }
    
    /// 渲染表格视图，setupSubviews之前调用，默认空实现
    public func setupTableView() {}
    
    /// 渲染表格视图布局，setupSubviews之前调用，默认铺满
    public func setupTableLayout() {
        tableView.fw_pinEdges()
    }
    
}

// MARK: - ViewControllerManager+TableViewControllerProtocol
internal extension ViewControllerManager {
    
    func tableViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? any UIViewController & TableDelegateControllerProtocol else { return }
        
        let tableView = viewController.tableView
        if let viewController = viewController as? any UIViewController & TableViewControllerProtocol {
            tableView.dataSource = viewController
            tableView.delegate = viewController
        } else {
            viewController.tableDelegate.delegate = viewController
            tableView.dataSource = viewController.tableDelegate
            tableView.delegate = viewController.tableDelegate
        }
        viewController.view.addSubview(tableView)
        
        hookTableViewController?(viewController)
        
        viewController.setupTableView()
        viewController.setupTableLayout()
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }
    
}