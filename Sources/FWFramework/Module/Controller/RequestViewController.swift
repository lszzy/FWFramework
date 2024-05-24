//
//  RequestViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - RequestViewControllerProtocol
/// 通用请求视图控制器协议，可覆写
public protocol RequestViewControllerProtocol {
    
    /// 自定义请求滚动视图，ViewControllerProtocol自动处理
    var requestScrollView: UIScrollView? { get }
    
    /// 渲染数据，请求成功时调用
    func setupData()
    
    /// 请求数据(含刷新)，用于进入或下拉刷新时请求
    func requestData()
    
    /// 追加数据，用于上拉追加时分页请求
    func loadingData()
    
    /// 开始数据请求，回调数据是否追加完成，必须实现并调用completion句柄
    func startDataRequest(isLoading: Bool, completion: @escaping (Bool) -> Void) -> HTTPRequestProtocol?
    
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
        if !fw.isDataLoaded {
            if let scrollView = requestScrollView {
                if !scrollView.fw.isRefreshing {
                    fw.showLoading()
                }
            } else {
                fw.showLoading()
            }
        }
        
        var request: HTTPRequestProtocol?
        request = startDataRequest(isLoading: false) { [weak self] finished in
            guard let self = self else { return }
            self.fw.hideLoading()
            self.requestScrollView?.fw.endRefreshing()
            
            if request?.error == nil {
                self.fw.isDataLoaded = true
                self.setupData()
                self.requestScrollView?.fw.loadingFinished = finished
            } else {
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
        if let request = request as? HTTPRequest {
            request.autoShowLoading = false
        }
    }
    
    /// 默认实现追加数据
    public func loadingData() {
        var request: HTTPRequestProtocol?
        request = startDataRequest(isLoading: true) { [weak self] finished in
            guard let self = self else { return }
            self.requestScrollView?.fw.endLoading()
            
            if request?.error == nil {
                self.setupData()
                self.requestScrollView?.fw.loadingFinished = finished
            } else {
                if let request = request, !request.autoShowError {
                    request.showError()
                }
            }
        }
        if let request = request as? HTTPRequest {
            request.autoShowLoading = false
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
