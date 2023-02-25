//
//  CollectionViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - CollectionViewControllerProtocol
/// 集合视图控制器协议，可覆写
public protocol CollectionViewControllerProtocol: ViewControllerProtocol, UICollectionViewDataSource, UICollectionViewDelegate {
    
    /// 关联表格数据元素类型，默认Any
    associatedtype CollectionElement = Any
    
    /// 集合视图，默认不显示滚动条
    var collectionView: UICollectionView { get }

    /// 集合数据，默认空数组，延迟加载
    var collectionData: [CollectionElement] { get set }

    /// 渲染集合视图内容布局，只调用一次
    func setupCollectionViewLayout() -> UICollectionViewLayout

    /// 渲染集合视图，setupSubviews之前调用，默认空实现
    func setupCollectionView()

    /// 渲染集合视图布局，setupSubviews之前调用，默认铺满
    func setupCollectionLayout()
    
}

extension CollectionViewControllerProtocol where Self: UIViewController {
    
    /// 集合视图，默认不显示滚动条
    public var collectionView: UICollectionView {
        if let result = fw_property(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = UICollectionView(frame: .zero, collectionViewLayout: setupCollectionViewLayout())
            result.showsVerticalScrollIndicator = false
            result.showsHorizontalScrollIndicator = false
            fw_setProperty(result, forName: "collectionView")
            return result
        }
    }
    
    /// 集合视图代理，调用时自动生效
    public var collectionDelegate: CollectionViewDelegate {
        return collectionView.fw_delegate
    }
    
    /// 集合数据，默认空数组，延迟加载
    public var collectionData: [CollectionElement] {
        get { return fw_property(forName: "collectionData") as? [CollectionElement] ?? [] }
        set { fw_setProperty(newValue, forName: "collectionData") }
    }
    
    /// 渲染集合视图内容布局，只调用一次
    public func setupCollectionViewLayout() -> UICollectionViewLayout {
        let result = UICollectionViewFlowLayout()
        result.minimumLineSpacing = 0
        result.minimumInteritemSpacing = 0
        return result
    }
    
    /// 渲染集合视图，setupSubviews之前调用，默认空实现
    public func setupCollectionView() {}

    /// 渲染集合视图布局，setupSubviews之前调用，默认铺满
    public func setupCollectionLayout() {
        collectionView.fw_pinEdges()
    }
    
}

// MARK: - ViewControllerManager+CollectionViewControllerProtocol
internal extension ViewControllerManager {
    
    func collectionViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? any UIViewController & CollectionViewControllerProtocol else { return }
        
        let collectionView = viewController.collectionView
        collectionView.dataSource = viewController
        collectionView.delegate = viewController
        viewController.view.addSubview(collectionView)
        
        hookCollectionViewController?(viewController)
        
        viewController.setupCollectionView()
        viewController.setupCollectionLayout()
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
    }
    
}
