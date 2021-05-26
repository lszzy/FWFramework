//
//  FWViewController.swift
//  FWFramework
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

extension FWCollectionViewController where Self: UIViewController {
    /// 集合视图，默认不显示滚动条
    @nonobjc public var collectionView: UICollectionView {
        if let result = fwProperty(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("collectionView"), withObject: self) as! UICollectionView
            fwSetProperty(result, forName: "collectionView")
            return result
        }
    }
    
    /// 集合数据，默认空数组，延迟加载
    @nonobjc public var collectionData: NSMutableArray {
        if let result = fwProperty(forName: "collectionData") as? NSMutableArray {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("collectionData"), withObject: self) as! NSMutableArray
            fwSetProperty(result, forName: "collectionData")
            return result
        }
    }
}

extension FWScrollViewController where Self: UIViewController {
    /// 滚动视图，默认不显示滚动条
    @nonobjc public var scrollView: UIScrollView {
        if let result = fwProperty(forName: "scrollView") as? UIScrollView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("scrollView"), withObject: self) as! UIScrollView
            fwSetProperty(result, forName: "scrollView")
            return result
        }
    }
    
    /// 内容容器视图，自动撑开，子视图需要添加到此视图上
    @nonobjc public var contentView: UIView {
        if let result = fwProperty(forName: "contentView") as? UIView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("contentView"), withObject: self) as! UIView
            fwSetProperty(result, forName: "contentView")
            return result
        }
    }
}

extension FWTableViewController where Self: UIViewController {
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    @nonobjc public var tableView: UITableView {
        if let result = fwProperty(forName: "tableView") as? UITableView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("tableView"), withObject: self) as! UITableView
            fwSetProperty(result, forName: "tableView")
            return result
        }
    }
    
    /// 表格数据，默认空数组，延迟加载
    @nonobjc public var tableData: NSMutableArray {
        if let result = fwProperty(forName: "tableData") as? NSMutableArray {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("tableData"), withObject: self) as! NSMutableArray
            fwSetProperty(result, forName: "tableData")
            return result
        }
    }
}

extension FWWebViewController where Self: UIViewController {
    /// 网页视图，默认显示滚动条，启用前进后退手势
    @nonobjc public var webView: FWWebView {
        if let result = fwProperty(forName: "webView") as? FWWebView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webView"), withObject: self) as! FWWebView
            fwSetProperty(result, forName: "webView")
            return result
        }
    }
    
    /// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
    @nonobjc public var webItems: NSArray? {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webItems"), withObject: self) as? NSArray
    }
    
    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    @nonobjc public var webRequest: Any? {
        get {
            return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webRequest"), withObject: self)
        }
        set {
            FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("setWebRequest:"), withObject: self, parameter: newValue)
        }
    }
}
