//
//  ScrollViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

extension CollectionViewControllerProtocol where Self: UIViewController {
    /// 集合视图，默认不显示滚动条
    @nonobjc public var collectionView: UICollectionView {
        if let result = fw.property(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("collectionView"), withObject: self) as! UICollectionView
            fw.setProperty(result, forName: "collectionView")
            return result
        }
    }
    
    /// 集合数据，默认空数组，延迟加载
    @nonobjc public var collectionData: NSMutableArray {
        if let result = fw.property(forName: "collectionData") as? NSMutableArray {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("collectionData"), withObject: self) as! NSMutableArray
            fw.setProperty(result, forName: "collectionData")
            return result
        }
    }
}

extension ScrollViewControllerProtocol where Self: UIViewController {
    /// 滚动视图，默认不显示滚动条
    @nonobjc public var scrollView: UIScrollView {
        if let result = fw.property(forName: "scrollView") as? UIScrollView {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("scrollView"), withObject: self) as! UIScrollView
            fw.setProperty(result, forName: "scrollView")
            return result
        }
    }
    
    /// 内容容器视图，自动撑开，子视图需要添加到此视图上
    @nonobjc public var contentView: UIView {
        if let result = fw.property(forName: "contentView") as? UIView {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("contentView"), withObject: self) as! UIView
            fw.setProperty(result, forName: "contentView")
            return result
        }
    }
}

extension TableViewControllerProtocol where Self: UIViewController {
    /// 表格视图，默认不显示滚动条，Footer为空视图。Plain有悬停，Group无悬停
    @nonobjc public var tableView: UITableView {
        if let result = fw.property(forName: "tableView") as? UITableView {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("tableView"), withObject: self) as! UITableView
            fw.setProperty(result, forName: "tableView")
            return result
        }
    }
    
    /// 表格数据，默认空数组，延迟加载
    @nonobjc public var tableData: NSMutableArray {
        if let result = fw.property(forName: "tableData") as? NSMutableArray {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("tableData"), withObject: self) as! NSMutableArray
            fw.setProperty(result, forName: "tableData")
            return result
        }
    }
}

extension WebViewControllerProtocol where Self: UIViewController {
    /// 网页视图，默认显示滚动条，启用前进后退手势
    @nonobjc public var webView: WebView {
        if let result = fw.property(forName: "webView") as? WebView {
            return result
        } else {
            let result = ViewControllerManager.shared.performIntercepter(NSSelectorFromString("webView"), withObject: self) as! WebView
            fw.setProperty(result, forName: "webView")
            return result
        }
    }
    
    /// 左侧按钮组，依次为返回|关闭，支持UIBarButtonItem|UIImage|NSString|NSNumber等。可覆写，默认nil
    @nonobjc public var webItems: NSArray? {
        get {
            return ViewControllerManager.shared.performIntercepter(NSSelectorFromString("webItems"), withObject: self) as? NSArray
        }
        set {
            ViewControllerManager.shared.performIntercepter(NSSelectorFromString("setWebItems:"), withObject: self, parameter: newValue)
        }
    }
    
    /// 网页请求，设置后会自动加载，支持NSString|NSURL|NSURLRequest。默认nil
    @nonobjc public var webRequest: Any? {
        get {
            return ViewControllerManager.shared.performIntercepter(NSSelectorFromString("webRequest"), withObject: self)
        }
        set {
            ViewControllerManager.shared.performIntercepter(NSSelectorFromString("setWebRequest:"), withObject: self, parameter: newValue)
        }
    }
}
