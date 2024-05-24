//
//  RequestViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - RequestViewControllerProtocol
/// 通用请求视图控制器协议，可扩展重写
public protocol RequestViewControllerProtocol {
    
    /// 请求数据完成句柄，回调数据是否追加完成
    typealias Completion = (_ request: HTTPRequestProtocol?, _ finished: Bool) -> Void
    
    /// 自定义请求滚动视图，ViewControllerProtocol自动处理
    var requestScrollView: UIScrollView? { get }
    
    /// 是否自动显示加载吐司，默认true
    var showsRequestLoading: Bool { get }
    
    /// 渲染数据，请求成功时调用
    func setupData()
    
    /// 请求数据(含刷新)，用于进入或下拉刷新时请求
    func requestData()
    
    /// 追加数据，用于上拉追加时分页请求
    func loadingData()
    
    /// 开始数据请求，必须实现并调用completion句柄
    func startDataRequest(isLoading: Bool, completion: @escaping Completion)
    
}

extension RequestViewControllerProtocol where Self: UIViewController {
    
    /// 默认实现请求滚动视图，可自定义
    public var requestScrollView: UIScrollView? {
        get { fw.property(forName: #function) as? UIScrollView }
        set { fw.setPropertyWeak(newValue, forName: #function) }
    }
    
    /// 是否自动显示加载吐司，默认true
    public var showsRequestLoading: Bool {
        return true
    }
    
    /// 默认实现渲染数据，显示并调用reloadData
    public func setupData() {
        if let scrollView = requestScrollView {
            if scrollView.isHidden { scrollView.isHidden = false }
        }
        if let tableView = requestScrollView as? UITableView {
            tableView.reloadData()
        } else if let collectionView = requestScrollView as? UICollectionView {
            collectionView.reloadData()
        }
    }
    
    /// 默认实现请求或刷新数据
    public func requestData() {
        if !fw.isDataLoaded, showsRequestLoading {
            if let scrollView = requestScrollView {
                if !scrollView.fw.isRefreshing {
                    fw.showLoading()
                }
            } else {
                fw.showLoading()
            }
        }
        
        startDataRequest(isLoading: false) { [weak self] request, finished in
            guard let self = self else { return }
            self.fw.hideLoading()
            
            if request?.error == nil {
                self.fw.isDataLoaded = true
                self.setupData()
                self.requestScrollView?.fw.endRefreshing(finished: finished)
            } else {
                self.requestScrollView?.fw.endRefreshing()
                if !self.fw.isDataLoaded {
                    request?.autoShowError = false
                    self.fw.showEmptyView(error: request?.error) { [weak self] _ in
                        self?.fw.hideEmptyView()
                        self?.requestData()
                    }
                } else if let request = request, !request.autoShowError {
                    request.showError()
                }
            }
        }
    }
    
    /// 默认实现追加数据
    public func loadingData() {
        startDataRequest(isLoading: true) { [weak self] request, finished in
            guard let self = self else { return }
            
            if request?.error == nil {
                self.setupData()
                self.requestScrollView?.fw.endLoading(finished: finished)
            } else {
                self.requestScrollView?.fw.endLoading()
                if let request = request, !request.autoShowError {
                    request.showError()
                }
            }
        }
    }
    
}

extension RequestViewControllerProtocol where Self: UIViewController & ScrollViewControllerProtocol {
    
    public var requestScrollView: UIScrollView? {
        scrollView
    }
    
}

extension RequestViewControllerProtocol where Self: UIViewController & TableDelegateControllerProtocol {
    
    public var requestScrollView: UIScrollView? {
        tableView
    }
    
}

extension RequestViewControllerProtocol where Self: UIViewController & CollectionDelegateControllerProtocol {
    
    public var requestScrollView: UIScrollView? {
        collectionView
    }
    
}
