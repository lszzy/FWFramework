//
//  RequestViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - RequestViewControllerProtocol
/// 通用请求视图控制器协议，可扩展重写
@MainActor public protocol RequestViewControllerProtocol {
    
    /// 请求数据完成句柄，回调数据是否追加完成
    typealias Completion = (_ request: HTTPRequestProtocol, _ finished: Bool) -> Void
    
    /// 自定义请求滚动视图，ViewControllerProtocol自动处理
    var requestScrollView: UIScrollView? { get }
    
    /// 渲染数据，请求成功时调用
    func setupData()
    
    /// 请求数据(含刷新)，用于进入或下拉刷新时请求
    func requestData()
    
    /// 追加数据，用于上拉追加时分页请求
    func loadingData()
    
    /// 开始数据请求，必须实现并调用completion句柄
    func startDataRequest(isRefreshing: Bool, completion: @escaping Completion)
    
    /// 显示或隐藏加载器，默认加载吐司
    func showRequestLoading(isShowing: Bool)
    
    /// 显示网络请求错误，默认显示空界面和提示吐司
    func showRequestError(_ request: HTTPRequestProtocol, isRefreshing: Bool)
    
}

extension RequestViewControllerProtocol where Self: UIViewController {
    
    /// 默认实现请求滚动视图，可自定义
    public var requestScrollView: UIScrollView? {
        get { fw.property(forName: #function) as? UIScrollView }
        set { fw.setPropertyWeak(newValue, forName: #function) }
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
        showRequestLoading(isShowing: true)
        startDataRequest(isRefreshing: true) { [weak self] request, finished in
            self?.showRequestLoading(isShowing: false)
            
            if request.error == nil {
                self?.fw.isDataLoaded = true
                self?.setupData()
                self?.requestScrollView?.fw.endRefreshing(finished: finished)
            } else {
                self?.requestScrollView?.fw.endRefreshing()
                self?.showRequestError(request, isRefreshing: true)
            }
        }
    }
    
    /// 默认实现追加数据
    public func loadingData() {
        startDataRequest(isRefreshing: false) { [weak self] request, finished in
            if request.error == nil {
                self?.setupData()
                self?.requestScrollView?.fw.endLoading(finished: finished)
            } else {
                self?.requestScrollView?.fw.endLoading()
                self?.showRequestError(request, isRefreshing: false)
            }
        }
    }
    
    /// 默认实现显示或隐藏加载器
    public func showRequestLoading(isShowing: Bool) {
        if isShowing {
            if !fw.isDataLoaded {
                if let scrollView = requestScrollView {
                    if !scrollView.fw.isRefreshing {
                        fw.showLoading()
                    }
                } else {
                    fw.showLoading()
                }
            }
        } else {
            fw.hideLoading()
        }
    }
    
    /// 默认实现显示网络请求错误
    public func showRequestError(_ request: HTTPRequestProtocol, isRefreshing: Bool) {
        if isRefreshing {
            if !fw.isDataLoaded {
                request.autoShowError = false
                fw.showEmptyView(error: request.error) { [weak self] _ in
                    self?.fw.hideEmptyView()
                    self?.requestData()
                }
            } else if !request.autoShowError {
                request.showError()
            }
        } else {
            if !request.autoShowError {
                request.showError()
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
