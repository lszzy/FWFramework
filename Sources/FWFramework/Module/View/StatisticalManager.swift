//
//  StatisticalManager.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

@_spi(FW) @objc extension UIView {
    
    /// 绑定统计点击事件，触发管理器。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
    public var fw_statisticalClick: StatisticalObject? {
        get {
            return fw_property(forName: "fw_statisticalClick") as? StatisticalObject
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalClick")
            self.fw_statisticalClickRegister()
        }
    }

    /// 绑定统计点击事件，仅触发回调。view为添加的Tap手势(需先添加手势)，control为TouchUpInside|ValueChanged，tableView|collectionView为Select(需先设置delegate)
    public var fw_statisticalClickBlock: StatisticalBlock? {
        get {
            return fw_property(forName: "fw_statisticalClickBlock") as? StatisticalBlock
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_statisticalClickBlock")
            self.fw_statisticalClickRegister()
        }
    }

    /// 手工触发统计点击事件，更新点击次数，列表可指定cell和位置，可重复触发
    public func fw_statisticalTriggerClick(_ cell: UIView?, indexPath: IndexPath?) {
        var object: StatisticalObject
        if let clickObject = cell?.fw_statisticalClick ?? self.fw_statisticalClick {
            object = clickObject
        } else {
            object = StatisticalObject()
        }
        if object.triggerIgnored { return }
        let triggerCount = self.fw_statisticalClickCount(indexPath)
        if triggerCount > 1 && object.triggerOnce { return }
        
        object.__triggerClick(self, indexPath: indexPath, triggerCount: triggerCount)
        
        if cell?.fw_statisticalClickBlock != nil {
            cell?.fw_statisticalClickBlock?(object)
        } else if self.fw_statisticalClickBlock != nil {
            self.fw_statisticalClickBlock?(object)
        }
        if cell?.fw_statisticalClick != nil || self.fw_statisticalClick != nil {
            StatisticalManager.shared.__handleEvent(object)
        }
    }
    
    private var fw_statisticalClickIsRegistered: Bool {
        get { return fw_propertyBool(forName: "fw_statisticalClickIsRegistered") }
        set { fw_setPropertyBool(newValue, forName: "fw_statisticalClickIsRegistered") }
    }
    
    private func fw_statisticalClickRegister() {
        if self.fw_statisticalClickIsRegistered { return }
        self.fw_statisticalClickIsRegistered = true
        if self is UITableViewCell || self is UICollectionViewCell {
            self.fw_statisticalClickCellRegister()
            return
        }
        
        if self.conforms(to: StatisticalDelegate.self),
           self.responds(to: #selector(StatisticalDelegate.statisticalClick(callback:))) {
            (self as? StatisticalDelegate)?.statisticalClick?(callback: { [weak self] cell, indexPath in
                self?.fw_statisticalTriggerClick(cell, indexPath: indexPath)
            })
            return
        }
        
        if let tableView = self as? UITableView {
            NSObject.fw_swizzleMethod(
                tableView.delegate,
                selector: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
                identifier: "FWStatisticalManager",
                methodSignature: (@convention(c) (AnyObject, Selector, UITableView, IndexPath) -> Void).self,
                swizzleSignature: (@convention(block) (AnyObject, UITableView, IndexPath) -> Void).self
            ) { store in { selfObject, tableView, indexPath in
                store.original(selfObject, store.selector, tableView, indexPath)
                
                if !selfObject.fw_isSwizzleInstanceMethod(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)), identifier: "FWStatisticalManager") { return }
                if !tableView.fw_statisticalClickIsRegistered { return }
                let cell = tableView.cellForRow(at: indexPath)
                tableView.fw_statisticalTriggerClick(cell, indexPath: indexPath)
            }}
            return
        }
        
        if let collectionView = self as? UICollectionView {
            NSObject.fw_swizzleMethod(
                collectionView.delegate,
                selector: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
                identifier: "FWStatisticalManager",
                methodSignature: (@convention(c) (AnyObject, Selector, UICollectionView, IndexPath) -> Void).self,
                swizzleSignature: (@convention(block) (AnyObject, UICollectionView, IndexPath) -> Void).self
            ) { store in { selfObject, collectionView, indexPath in
                store.original(selfObject, store.selector, collectionView, indexPath)
                
                if !selfObject.fw_isSwizzleInstanceMethod(#selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)), identifier: "FWStatisticalManager") { return }
                if !collectionView.fw_statisticalClickIsRegistered { return }
                let cell = collectionView.cellForItem(at: indexPath)
                collectionView.fw_statisticalTriggerClick(cell, indexPath: indexPath)
            }}
            return
        }
        
        if let control = self as? UIControl {
            var controlEvents = UIControl.Event.touchUpInside
            if self is UIDatePicker ||
                self is UIPageControl ||
                self is UISegmentedControl ||
                self is UISlider ||
                self is UIStepper ||
                self is UISwitch ||
                self is UITextField {
                controlEvents = .valueChanged
            }
            control.fw_addBlock({ sender in
                (sender as? UIControl)?.fw_statisticalTriggerClick(nil, indexPath: nil)
            }, for: controlEvents)
            return
        }
        
        if let gestureRecognizers = self.gestureRecognizers {
            for gesture in gestureRecognizers {
                if let tapGesture = gesture as? UITapGestureRecognizer {
                    tapGesture.fw_addBlock { sender in
                        (sender as? UIGestureRecognizer)?.view?.fw_statisticalTriggerClick(nil, indexPath: nil)
                    }
                }
            }
        }
    }
    
    private func fw_statisticalClickCellRegister() {
        if self.superview == nil { return }
        var proxyView: UIView?
        if self.conforms(to: StatisticalDelegate.self),
           self.responds(to: #selector(StatisticalDelegate.statisticalCellProxyView)) {
            proxyView = (self as? StatisticalDelegate)?.statisticalCellProxyView?()
        } else {
            if let cell = self as? UITableViewCell {
                proxyView = cell.fw_tableView
            } else if let cell = self as? UICollectionViewCell {
                proxyView = cell.fw_collectionView
            }
        }
        proxyView?.fw_statisticalClickRegister()
    }
    
    private func fw_statisticalClickCount(_ indexPath: IndexPath?) -> Int {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalClickCount") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalClickCount")
        }
        
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)" as NSString
        let triggerCount = ((triggerDict[triggerKey] as? NSNumber)?.intValue ?? 0) + 1
        triggerDict.setObject(NSNumber(value: triggerCount), forKey: triggerKey)
        return triggerCount
    }
    
    /// 绑定统计曝光事件，触发管理器。如果对象发生变化(indexPath|name|object)，也会触发
    public var fw_statisticalExposure: StatisticalObject? {
        get {
            return fw_property(forName: "fw_statisticalExposure") as? StatisticalObject
        }
        set {
            fw_setProperty(newValue, forName: "fw_statisticalExposure")
            self.fw_statisticalExposureRegister()
        }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var fw_statisticalExposureBlock: StatisticalBlock? {
        get {
            return fw_property(forName: "fw_statisticalExposureBlock") as? StatisticalBlock
        }
        set {
            fw_setPropertyCopy(newValue, forName: "fw_statisticalExposureBlock")
            self.fw_statisticalExposureRegister()
        }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，列表可指定cell和位置，duration为单次曝光时长(0表示开始)，可重复触发
    public func fw_statisticalTriggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval) {
        var object: StatisticalObject
        if let exposureObject = cell?.fw_statisticalExposure ?? self.fw_statisticalExposure {
            object = exposureObject
        } else {
            object = StatisticalObject()
        }
        if object.triggerIgnored { return }
        let triggerCount = self.fw_statisticalExposureCount(indexPath)
        if triggerCount > 1 && object.triggerOnce { return }
        
        object.__triggerExposure(self, indexPath: indexPath, triggerCount: triggerCount, duration: duration, totalDuration: self.fw_statisticalExposureDuration(duration, indexPath: indexPath))
        
        if cell?.fw_statisticalExposureBlock != nil {
            cell?.fw_statisticalExposureBlock?(object)
        } else if self.fw_statisticalExposureBlock != nil {
            self.fw_statisticalExposureBlock?(object)
        }
        if cell?.fw_statisticalExposure != nil || self.fw_statisticalExposure != nil {
            StatisticalManager.shared.__handleEvent(object)
        }
    }
    
    private func fw_statisticalExposureRegister() {
        
    }
    
    private func fw_statisticalExposureCount(_ indexPath: IndexPath?) -> Int {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalExposureCount") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalExposureCount")
        }
        
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)" as NSString
        let triggerCount = ((triggerDict[triggerKey] as? NSNumber)?.intValue ?? 0) + 1
        triggerDict.setObject(NSNumber(value: triggerCount), forKey: triggerKey)
        return triggerCount
    }
    
    private func fw_statisticalExposureDuration(_ duration: TimeInterval, indexPath: IndexPath?) -> TimeInterval {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalExposureDuration") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalExposureDuration")
        }
        
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)" as NSString
        let triggerDuration = ((triggerDict[triggerKey] as? NSNumber)?.doubleValue ?? 0) + duration
        triggerDict.setObject(NSNumber(value: triggerDuration), forKey: triggerKey)
        return triggerDuration
    }
    
}
