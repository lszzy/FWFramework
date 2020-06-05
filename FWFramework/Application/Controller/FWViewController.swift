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
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("collectionView"), withObject: self) as! UICollectionView
    }
    
    @nonobjc public var collectionData: NSMutableArray {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("collectionData"), withObject: self) as! NSMutableArray
    }
}

extension FWScrollViewController where Self: UIViewController {
    @nonobjc public var scrollView: UIScrollView {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("scrollView"), withObject: self) as! UIScrollView
    }
    
    @nonobjc public var contentView: UIView {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("contentView"), withObject: self) as! UIView
    }
}

extension FWTableViewController where Self: UIViewController {
    @nonobjc public var tableView: UITableView {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("tableView"), withObject: self) as! UITableView
    }
    
    @nonobjc public var tableData: NSMutableArray {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("tableData"), withObject: self) as! NSMutableArray
    }
}

extension FWWebViewController where Self: UIViewController {
    @nonobjc public var webView: WKWebView {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("webView"), withObject: self) as! WKWebView
    }
    
    @nonobjc public var progressView: UIProgressView {
        return FWViewControllerManager.sharedInstance.performIntercepter(NSSelectorFromString("progressView"), withObject: self) as! UIProgressView
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
