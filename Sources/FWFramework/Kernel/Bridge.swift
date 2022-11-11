//
//  Bridge.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/20.
//

import Foundation

@objc extension UITableView {
    @objc(fw_delegate)
    public var __fw_delegate: TableViewDelegate {
        return fw.delegate
    }
    
    @objc(fw_tableView)
    public static func __fw_tableView() -> UITableView {
        return fw.tableView()
    }
    
    @objc(fw_tableView:)
    public static func __fw_tableView(_ style: UITableView.Style) -> UITableView {
        return fw.tableView(style)
    }
}

@objc extension UICollectionView {
    @objc(fw_delegate)
    public var __fw_delegate: CollectionViewDelegate {
        return fw.delegate
    }
    
    @objc(fw_collectionView)
    public static func __fw_collectionView() -> UICollectionView {
        return fw.collectionView()
    }
    
    @objc(fw_collectionView:)
    public static func __fw_collectionView(_ collectionViewLayout: UICollectionViewLayout) -> UICollectionView {
        return fw.collectionView(collectionViewLayout)
    }
}

/// 视图显示骨架屏扩展
@objc extension UIView {
    
    /// 显示骨架屏，指定布局代理
    @objc(fw_showSkeletonWithDelegate:)
    open func __fw_showSkeleton(delegate: SkeletonViewDelegate?) {
        fw.showSkeleton(delegate: delegate)
    }
    
    /// 显示骨架屏，指定布局句柄
    @objc(fw_showSkeletonWithBlock:)
    open func __fw_showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        fw.showSkeleton(block: block)
    }
    
    /// 显示骨架屏，默认布局代理为self
    @objc(fw_showSkeleton)
    open func __fw_showSkeleton() {
        fw.showSkeleton()
    }
    
    /// 隐藏骨架屏
    @objc(fw_hideSkeleton)
    open func __fw_hideSkeleton() {
        fw.hideSkeleton()
    }
    
    /// 是否正在显示骨架屏
    @objc(fw_hasSkeleton)
    open var __fw_hasSkeleton: Bool {
        return fw.hasSkeleton
    }
}

/// 控制器显示骨架屏扩展
@objc extension UIViewController {
    /// 显示view骨架屏，指定布局代理
    @objc(fw_showSkeletonWithDelegate:)
    open func __fw_showSkeleton(delegate: SkeletonViewDelegate?) {
        fw.showSkeleton(delegate: delegate)
    }
    
    /// 显示view骨架屏，指定布局句柄
    @objc(fw_showSkeletonWithBlock:)
    open func __fw_showSkeleton(block: ((SkeletonLayout) -> Void)?) {
        fw.showSkeleton(block: block)
    }
    
    /// 显示view骨架屏，默认布局代理为self
    @objc(fw_showSkeleton)
    open func __fw_showSkeleton() {
        fw.showSkeleton()
    }
    
    /// 隐藏view骨架屏
    @objc(fw_hideSkeleton)
    open func __fw_hideSkeleton() {
        fw.hideSkeleton()
    }
    
    /// 是否正在显示view骨架屏
    @objc(fw_hasSkeleton)
    open var __fw_hasSkeleton: Bool {
        return fw.hasSkeleton
    }
}

@objc extension UIDevice {
    
    /// 获取或设置设备UUID，自动keychain持久化。默认获取IDFV(未使用IDFA，避免额外权限)，失败则随机生成一个
    @objc(fw_deviceUUID)
    public static var __fw_deviceUUID: String {
        get { fw.deviceUUID }
        set { fw.deviceUUID = newValue }
    }
    
}
