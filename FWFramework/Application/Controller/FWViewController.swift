//
//  FWViewController.swift
//  FWFramework
//
//  Created by wuyong on 2020/6/5.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

import Foundation

extension FWCollectionViewController where Self: UIViewController {
    @nonobjc public var collectionView: UICollectionView {
        if let result = fwProperty(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("collectionView"), withObject: self) as! UICollectionView
            fwSetProperty(result, forName: "collectionView")
            return result
        }
    }
    
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
    @nonobjc public var scrollView: UIScrollView {
        if let result = fwProperty(forName: "scrollView") as? UIScrollView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("scrollView"), withObject: self) as! UIScrollView
            fwSetProperty(result, forName: "scrollView")
            return result
        }
    }
    
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
    @nonobjc public var tableView: UITableView {
        if let result = fwProperty(forName: "tableView") as? UITableView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("tableView"), withObject: self) as! UITableView
            fwSetProperty(result, forName: "tableView")
            return result
        }
    }
    
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
    @nonobjc public var webView: WKWebView {
        if let result = fwProperty(forName: "webView") as? WKWebView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webView"), withObject: self) as! WKWebView
            fwSetProperty(result, forName: "webView")
            return result
        }
    }
    
    @nonobjc public var progressView: UIProgressView {
        if let result = fwProperty(forName: "progressView") as? UIProgressView {
            return result
        } else {
            let result = FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("progressView"), withObject: self) as! UIProgressView
            fwSetProperty(result, forName: "progressView")
            return result
        }
    }
    
    @nonobjc public var webItems: NSArray? {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webItems"), withObject: self) as? NSArray
    }
    
    @nonobjc public var webRequest: Any? {
        get {
            return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webRequest"), withObject: self)
        }
        set {
            FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("setWebRequest:"), withObject: self, parameter: newValue)
        }
    }
}
