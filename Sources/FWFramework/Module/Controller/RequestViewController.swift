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
    
    /// 请求数据完成回调句柄
    typealias Completion = (_ request: HTTPRequestProtocol?, _ finished: Bool) -> Void
    
    /// 自定义请求滚动视图，ViewControllerProtocol自动处理
    var requestScrollView: UIScrollView? { get }
    
    /// 渲染数据
    func setupData()
    
    /// 请求或刷新数据
    func requestData()
    
    /// 追加数据
    func loadingData()
    
    /// 请求或刷新数据原始方法
    func requestData(completion: @escaping Completion)
    
    /// 追加数据原始方法
    func loadingData(completion: @escaping Completion)
    
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
            if scrollView.isHidden {
                scrollView.isHidden = false
            }
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
        
        requestData { [weak self] request, finished in
            guard let self = self else { return }
            self.fw.hideLoading()
            self.requestScrollView?.fw.endRefreshing()
            
            if request?.error == nil {
                self.fw.isDataLoaded = true
                self.setupData()
                self.requestScrollView?.fw.loadingFinished = finished
            } else {
                if !self.fw.isDataLoaded {
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
        loadingData { [weak self] request, finished in
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
    }
    
    /// 默认实现请求或刷新数据原始方法
    public func requestData(completion: @escaping Completion) {
        completion(nil, true)
    }
    
    /// 默认实现追加数据原始方法
    public func loadingData(completion: @escaping Completion) {
        completion(nil, true)
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
