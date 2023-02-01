//
//  CollectionViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - CollectionViewControllerProtocol
/// 集合视图控制器协议，可覆写
@objc public protocol CollectionViewControllerProtocol: ViewControllerProtocol, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /// 集合视图，默认不显示滚动条
    var collectionView: UICollectionView { get }

    /// 集合数据，默认空数组，延迟加载
    var collectionData: NSMutableArray { get }

    /// 渲染集合视图内容布局，只调用一次
    func setupCollectionViewLayout() -> UICollectionViewLayout

    /// 渲染集合视图，setupSubviews之前调用，默认未实现
    @objc optional func setupCollectionView()

    /// 渲染集合视图布局，setupSubviews之前调用，默认铺满
    @objc optional func setupCollectionLayout()
    
}

extension CollectionViewControllerProtocol where Self: UIViewController {
    
    /// 集合视图，默认不显示滚动条
    public var collectionView: UICollectionView {
        if let result = fw.property(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = UICollectionView(frame: .zero, collectionViewLayout: setupCollectionViewLayout())
            result.showsVerticalScrollIndicator = false
            result.showsHorizontalScrollIndicator = false
            fw.setProperty(result, forName: "collectionView")
            return result
        }
    }
    
    /// 集合数据，默认空数组，延迟加载
    public var collectionData: NSMutableArray {
        if let result = fw.property(forName: "collectionData") as? NSMutableArray {
            return result
        } else {
            let result = NSMutableArray()
            fw.setProperty(result, forName: "collectionData")
            return result
        }
    }
    
    /// 渲染集合视图内容布局，只调用一次
    public func setupCollectionViewLayout() -> UICollectionViewLayout {
        let result = UICollectionViewFlowLayout()
        result.minimumLineSpacing = 0
        result.minimumInteritemSpacing = 0
        return result
    }

    /// 渲染集合视图布局，setupSubviews之前调用，默认铺满
    public func setupCollectionLayout() {
        collectionView.fw_pinEdges()
    }
    
}

// MARK: - ViewControllerManager+CollectionViewControllerProtocol
internal extension ViewControllerManager {
    
    @objc func collectionViewControllerViewDidLoad(_ viewController: UIViewController & CollectionViewControllerProtocol) {
        let collectionView = viewController.collectionView
        collectionView.dataSource = viewController
        collectionView.delegate = viewController
        viewController.view.addSubview(collectionView)
        
        hookCollectionViewController?(viewController)
        
        viewController.setupCollectionView?()
        viewController.setupCollectionLayout?()
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
    }
    
}
