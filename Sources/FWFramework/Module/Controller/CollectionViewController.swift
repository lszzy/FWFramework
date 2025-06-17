//
//  CollectionViewController.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit

// MARK: - CollectionDelegateControllerProtocol
/// 集合代理控制器协议，数据源和事件代理为collectionDelegate，可覆写
@MainActor public protocol CollectionDelegateControllerProtocol: ViewControllerProtocol, UICollectionViewDelegate {
    /// 关联表格数据元素类型，默认Any
    associatedtype CollectionElement = Any

    /// 集合视图，默认不显示滚动条
    var collectionView: UICollectionView { get }

    /// 集合代理，同集合collectionDelegate，延迟加载
    var collectionDelegate: CollectionViewDelegate { get }

    /// 集合数据，默认空数组，延迟加载
    var collectionData: [CollectionElement] { get set }

    /// 渲染集合视图内容布局，只调用一次
    func setupCollectionViewLayout() -> UICollectionViewLayout

    /// 渲染集合视图，setupSubviews之前调用，默认空实现
    func setupCollectionView()

    /// 渲染集合视图布局，setupSubviews之前调用，默认铺满
    func setupCollectionLayout()
}

// MARK: - CollectionViewControllerProtocol
/// 集合视图控制器协议，数据源和事件代理为控制器，可覆写
@MainActor public protocol CollectionViewControllerProtocol: CollectionDelegateControllerProtocol, UICollectionViewDataSource {}

// MARK: - UIViewController+CollectionViewControllerProtocol
extension CollectionDelegateControllerProtocol where Self: UIViewController {
    /// 集合视图，默认不显示滚动条
    public var collectionView: UICollectionView {
        if let result = fw.property(forName: "collectionView") as? UICollectionView {
            return result
        } else {
            let result = UICollectionView.fw.collectionView(setupCollectionViewLayout())
            fw.setProperty(result, forName: "collectionView")
            return result
        }
    }

    /// 集合代理，同集合collectionDelegate，延迟加载
    public var collectionDelegate: CollectionViewDelegate {
        collectionView.fw.collectionDelegate
    }

    /// 集合数据，默认空数组，延迟加载
    public var collectionData: [CollectionElement] {
        get { fw.property(forName: "collectionData") as? [CollectionElement] ?? [] }
        set { fw.setProperty(newValue, forName: "collectionData") }
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
        collectionView.fw.pinEdges(autoScale: false)
    }
}

// MARK: - ViewControllerManager+CollectionViewControllerProtocol
extension ViewControllerManager {
    @MainActor func collectionViewControllerViewDidLoad(_ viewController: UIViewController) {
        guard let viewController = viewController as? any UIViewController & CollectionDelegateControllerProtocol else { return }

        let collectionView = viewController.collectionView
        if let viewController = viewController as? any UIViewController & CollectionViewControllerProtocol {
            collectionView.dataSource = viewController
            collectionView.delegate = viewController
        } else {
            viewController.collectionDelegate.delegate = viewController
            collectionView.dataSource = viewController.collectionDelegate
            collectionView.delegate = viewController.collectionDelegate
        }
        if let popupController = viewController as? PopupViewControllerProtocol {
            popupController.popupView.addSubview(collectionView)
        } else {
            viewController.view.addSubview(collectionView)
        }

        hookCollectionViewController?(viewController)

        viewController.setupCollectionView()
        viewController.setupCollectionLayout()
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
    }
}
