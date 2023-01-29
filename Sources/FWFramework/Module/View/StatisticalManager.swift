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

@_spi(FW) extension UIView {
    
    private class StatisticalTarget: NSObject {
        private(set) weak var view: UIView?
        
        init(view: UIView?) {
            super.init()
            self.view = view
        }
        
        @objc func statisticalExposureCalculate() {
            if let view = self.view, (view is UITableView || view is UICollectionView) {
                for subview in view.subviews {
                    subview.fw_updateStatisticalExposureState()
                }
            } else {
                self.view?.fw_updateStatisticalExposureState()
            }
        }
    }
    
    private enum StatisticalExposureState: Int {
        case none = 0
        case partly
        case fully
    }
    
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
        let triggerCount = self.fw_statisticalClickTotalCount(indexPath)
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
        
        if let tableView = self as? UITableView, let tableDelegate = tableView.delegate as? NSObject {
            NSObject.fw_swizzleMethod(
                tableDelegate,
                selector: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:)),
                identifier: "FWStatisticalManager",
                methodSignature: (@convention(c) (NSObject, Selector, UITableView, IndexPath) -> Void).self,
                swizzleSignature: (@convention(block) (NSObject, UITableView, IndexPath) -> Void).self
            ) { store in { selfObject, tableView, indexPath in
                store.original(selfObject, store.selector, tableView, indexPath)
                
                if !selfObject.fw_isSwizzleInstanceMethod(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)), identifier: "FWStatisticalManager") { return }
                if !tableView.fw_statisticalClickIsRegistered { return }
                let cell = tableView.cellForRow(at: indexPath)
                tableView.fw_statisticalTriggerClick(cell, indexPath: indexPath)
            }}
            return
        }
        
        if let collectionView = self as? UICollectionView, let collectionDelegate = collectionView.delegate as? NSObject {
            NSObject.fw_swizzleMethod(
                collectionDelegate,
                selector: #selector(UICollectionViewDelegate.collectionView(_:didSelectItemAt:)),
                identifier: "FWStatisticalManager",
                methodSignature: (@convention(c) (NSObject, Selector, UICollectionView, IndexPath) -> Void).self,
                swizzleSignature: (@convention(block) (NSObject, UICollectionView, IndexPath) -> Void).self
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
    
    private func fw_statisticalClickTotalCount(_ indexPath: IndexPath?) -> Int {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalClickTotalCount") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalClickTotalCount")
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
    public func fw_statisticalTriggerExposure(_ cell: UIView?, indexPath: IndexPath?, duration: TimeInterval = 0) {
        var object: StatisticalObject
        if let exposureObject = cell?.fw_statisticalExposure ?? self.fw_statisticalExposure {
            object = exposureObject
        } else {
            object = StatisticalObject()
        }
        if object.triggerIgnored { return }
        let triggerCount = self.fw_statisticalExposureTotalCount(indexPath)
        if triggerCount > 1 && object.triggerOnce { return }
        
        let totalDuration = self.fw_statisticalExposureTotalDuration(duration, indexPath: indexPath)
        object.__triggerExposure(self, indexPath: indexPath, triggerCount: triggerCount, duration: duration, totalDuration: totalDuration)
        
        if cell?.fw_statisticalExposureBlock != nil {
            cell?.fw_statisticalExposureBlock?(object)
        } else if self.fw_statisticalExposureBlock != nil {
            self.fw_statisticalExposureBlock?(object)
        }
        if cell?.fw_statisticalExposure != nil || self.fw_statisticalExposure != nil {
            StatisticalManager.shared.__handleEvent(object)
        }
    }
    
    /// 内部方法，启用统计功能
    @objc(__fw_enableStatistical)
    public static func fw_enableStatistical() {
        guard !fw_staticStatisticalEnabled else { return }
        fw_staticStatisticalEnabled = true
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.frame),
            methodSignature: (@convention(c) (UIView, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGRect) -> Void).self
        ) { store in { selfObject, frame in
            store.original(selfObject, store.selector, frame)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.isHidden),
            methodSignature: (@convention(c) (UIView, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, Bool) -> Void).self
        ) { store in { selfObject, hidden in
            store.original(selfObject, store.selector, hidden)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.alpha),
            methodSignature: (@convention(c) (UIView, Selector, CGFloat) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGFloat) -> Void).self
        ) { store in { selfObject, alpha in
            store.original(selfObject, store.selector, alpha)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(setter: UIView.bounds),
            methodSignature: (@convention(c) (UIView, Selector, CGRect) -> Void).self,
            swizzleSignature: (@convention(block) (UIView, CGRect) -> Void).self
        ) { store in { selfObject, bounds in
            store.original(selfObject, store.selector, bounds)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIView.self,
            selector: #selector(UIView.didMoveToWindow),
            methodSignature: (@convention(c) (UIView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UIView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UITableView.self,
            selector: #selector(UITableView.reloadData),
            methodSignature: (@convention(c) (UITableView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionView.self,
            selector: #selector(UICollectionView.reloadData),
            methodSignature: (@convention(c) (UICollectionView, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionView) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            selfObject.fw_statisticalExposureUpdate()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UITableViewCell.self,
            selector: #selector(UITableViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UITableViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UITableViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_statisticalClick != nil || selfObject.fw_statisticalClickBlock != nil {
                selfObject.fw_statisticalClickCellRegister()
            }
            if selfObject.fw_statisticalExposure != nil || selfObject.fw_statisticalExposureBlock != nil {
                selfObject.fw_statisticalExposureCellRegister()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UICollectionViewCell.self,
            selector: #selector(UICollectionViewCell.didMoveToSuperview),
            methodSignature: (@convention(c) (UICollectionViewCell, Selector) -> Void).self,
            swizzleSignature: (@convention(block) (UICollectionViewCell) -> Void).self
        ) { store in { selfObject in
            store.original(selfObject, store.selector)
            
            if selfObject.fw_statisticalClick != nil || selfObject.fw_statisticalClickBlock != nil {
                selfObject.fw_statisticalClickCellRegister()
            }
            if selfObject.fw_statisticalExposure != nil || selfObject.fw_statisticalExposureBlock != nil {
                selfObject.fw_statisticalExposureCellRegister()
            }
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidAppear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.fw_statisticalExposureDidAppear()
        }}
        
        NSObject.fw_swizzleInstanceMethod(
            UIViewController.self,
            selector: #selector(UIViewController.viewDidDisappear(_:)),
            methodSignature: (@convention(c) (UIViewController, Selector, Bool) -> Void).self,
            swizzleSignature: (@convention(block) (UIViewController, Bool) -> Void).self
        ) { store in { selfObject, animated in
            store.original(selfObject, store.selector, animated)
            selfObject.fw_statisticalExposureDidDisappear()
        }}
    }
    
    private static var fw_staticStatisticalEnabled = false
    
    private var fw_statisticalExposureIsRegistered: Bool {
        get { return fw_propertyBool(forName: "fw_statisticalExposureIsRegistered") }
        set { fw_setPropertyBool(newValue, forName: "fw_statisticalExposureIsRegistered") }
    }
    
    private var fw_statisticalExposureIsProxy: Bool {
        get { return fw_propertyBool(forName: "fw_statisticalExposureIsProxy") }
        set { fw_setPropertyBool(newValue, forName: "fw_statisticalExposureIsProxy") }
    }
    
    private var fw_statisticalExposureIsFully: Bool {
        get { return fw_propertyBool(forName: "fw_statisticalExposureIsFully") }
        set { fw_setPropertyBool(newValue, forName: "fw_statisticalExposureIsFully") }
    }
    
    private var fw_statisticalExposureIdentifier: String {
        get { return fw_property(forName: "fw_statisticalExposureIdentifier") as? String ?? "" }
        set { fw_setProperty(newValue, forName: "fw_statisticalExposureIdentifier") }
    }
    
    private func fw_statisticalExposureViewIdentifier() -> String {
        var indexPath: IndexPath?
        if let cell = self as? UITableViewCell {
            indexPath = cell.fw_indexPath
        } else if let cell = self as? UICollectionViewCell {
            indexPath = cell.fw_indexPath
        }
        
        let identifier = "\(indexPath?.section ?? -1)-\(indexPath?.row ?? -1)-\(self.fw_statisticalExposure?.name ?? "")-\(String.fw_safeString(self.fw_statisticalExposure?.object))"
        return identifier
    }
    
    @discardableResult
    private func fw_statisticalExposureCustom() -> Bool {
        if self.conforms(to: StatisticalDelegate.self),
           self.responds(to: #selector(StatisticalDelegate.statisticalExposure(callback:))) {
            (self as? StatisticalDelegate)?.statisticalExposure?(callback: { [weak self] cell, indexPath, duration in
                guard let this = self else { return }
                if this.fw_statisticalExposureIsFullyState(this.fw_statisticalExposureViewState()) {
                    this.fw_statisticalTriggerExposure(cell, indexPath: indexPath, duration: duration)
                }
            })
            return true
        }
        return false
    }
    
    private var fw_statisticalExposureState: StatisticalExposureState {
        get {
            let value = fw_propertyInt(forName: "fw_statisticalExposureState")
            return .init(rawValue: value) ?? .none
        }
        set {
            fw_setPropertyInt(newValue.rawValue, forName: "fw_statisticalExposureState")
        }
    }
    
    private func fw_statisticalExposureViewState() -> StatisticalExposureState {
        if !self.fw_isViewVisible {
            return .none
        }
        
        let viewController = self.fw_viewController
        if let viewController = viewController,
           viewController.view.window == nil || viewController.presentedViewController != nil {
            return .none
        }
        
        let targetView = viewController?.view ?? self.window
        var superview = self.superview
        var superviewHidden = false
        while superview != nil && superview != targetView {
            if !(superview?.fw_isViewVisible ?? false) {
                superviewHidden = true
                break
            }
            superview = superview?.superview
        }
        if superviewHidden {
            return .none
        }
        
        var viewRect = self.convert(self.bounds, to: targetView)
        viewRect = CGRect(x: floor(viewRect.origin.x), y: floor(viewRect.origin.y), width: floor(viewRect.size.width), height: floor(viewRect.size.height))
        let targetRect = targetView?.bounds ?? .zero
        var state: StatisticalExposureState = .none
        if !CGRectIsEmpty(viewRect) {
            if CGRectContainsRect(targetRect, viewRect) {
                state = .fully
            } else if CGRectIntersectsRect(targetRect, viewRect) {
                state = .partly
            }
        }
        if state == .none {
            return state
        }
        
        var shieldView: UIView?
        if self.fw_statisticalExposure?.shieldView != nil {
            shieldView = self.fw_statisticalExposure?.shieldView
        } else if self.fw_statisticalExposure?.shieldViewBlock != nil {
            shieldView = self.fw_statisticalExposure?.shieldViewBlock?()
        }
        guard let shieldView = shieldView, shieldView.fw_isViewVisible else {
            return state
        }
        let shieldRect = shieldView.convert(shieldView.bounds, to: targetView)
        if !CGRectIsEmpty(shieldRect) {
            if CGRectContainsRect(shieldRect, viewRect) {
                return .none
            } else if CGRectIntersectsRect(shieldRect, viewRect) {
                return .partly
            }
        }
        return state
    }
    
    private func fw_updateStatisticalExposureState() {
        let oldIdentifier = self.fw_statisticalExposureIdentifier
        let identifier = self.fw_statisticalExposureViewIdentifier()
        let identifierChanged = oldIdentifier.count > 0 && identifier != oldIdentifier
        if oldIdentifier.count < 1 || identifierChanged {
            self.fw_statisticalExposureIdentifier = identifier
            if oldIdentifier.count < 1 { self.fw_statisticalExposureCustom() }
        }
        
        let oldState = self.fw_statisticalExposureState
        let state = self.fw_statisticalExposureViewState()
        if state == oldState && !identifierChanged { return }
        self.fw_statisticalExposureState = state
        
        if self.fw_statisticalExposureIsFullyState(state),
           (!self.fw_statisticalExposureIsFully || identifierChanged) {
            self.fw_statisticalExposureIsFully = true
            if self.fw_statisticalExposureCustom() {
            } else if let cell = self as? UITableViewCell {
                cell.fw_tableView?.fw_statisticalTriggerExposure(self, indexPath: cell.fw_indexPath, duration: 0)
            } else if let cell = self as? UICollectionViewCell {
                cell.fw_collectionView?.fw_statisticalTriggerExposure(self, indexPath: cell.fw_indexPath, duration: 0)
            } else {
                self.fw_statisticalTriggerExposure(nil, indexPath: nil, duration: 0)
            }
        } else if state == .none || identifierChanged {
            self.fw_statisticalExposureIsFully = false
        }
    }
    
    private func fw_statisticalExposureRegister() {
        if self.fw_statisticalExposureIsRegistered { return }
        self.fw_statisticalExposureIsRegistered = true
        if self is UITableViewCell || self is UICollectionViewCell {
            self.fw_statisticalExposureCellRegister()
            return
        }
        
        if self.superview != nil {
            self.superview?.fw_statisticalExposureRegister()
        }
        
        if self.fw_statisticalExposure != nil ||
            self.fw_statisticalExposureBlock != nil ||
            self.fw_statisticalExposureIsProxy {
            NSObject.cancelPreviousPerformRequests(withTarget: self.fw_statisticalTarget, selector: #selector(StatisticalTarget.statisticalExposureCalculate), object: nil)
            self.fw_statisticalTarget.perform(#selector(StatisticalTarget.statisticalExposureCalculate), with: nil, afterDelay: 0, inModes: [StatisticalManager.shared.runLoopMode])
        }
    }
    
    private func fw_statisticalExposureCellRegister() {
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
        proxyView?.fw_statisticalExposureIsProxy = true
        proxyView?.fw_statisticalExposureRegister()
    }
    
    private func fw_statisticalExposureUpdate() {
        if !self.fw_statisticalExposureIsRegistered { return }
        
        if let viewController = self.fw_viewController,
           viewController.view.window == nil || viewController.presentedViewController != nil { return }
        
        self.fw_statisticalExposureRecursive()
    }
    
    private func fw_statisticalExposureRecursive() {
        if !self.fw_statisticalExposureIsRegistered { return }
        
        if self.fw_statisticalExposure != nil ||
            self.fw_statisticalExposureBlock != nil ||
            self.fw_statisticalExposureIsProxy {
            NSObject.cancelPreviousPerformRequests(withTarget: self.fw_statisticalTarget, selector: #selector(StatisticalTarget.statisticalExposureCalculate), object: nil)
            self.fw_statisticalTarget.perform(#selector(StatisticalTarget.statisticalExposureCalculate), with: nil, afterDelay: 0, inModes: [StatisticalManager.shared.runLoopMode])
        }
        
        for subview in self.subviews {
            subview.fw_statisticalExposureRecursive()
        }
    }
    
    private var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget(view: self)
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
    private func fw_statisticalExposureIsFullyState(_ state: StatisticalExposureState) -> Bool {
        var isFullState = (state == .fully) ? true : false
        if !isFullState && StatisticalManager.shared.exposurePartly {
            isFullState = (state == .partly) ? true : false
        }
        return isFullState
    }
    
    private func fw_statisticalExposureTotalCount(_ indexPath: IndexPath?) -> Int {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalExposureTotalCount") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalExposureTotalCount")
        }
        
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)" as NSString
        let triggerCount = ((triggerDict[triggerKey] as? NSNumber)?.intValue ?? 0) + 1
        triggerDict.setObject(NSNumber(value: triggerCount), forKey: triggerKey)
        return triggerCount
    }
    
    private func fw_statisticalExposureTotalDuration(_ duration: TimeInterval, indexPath: IndexPath?) -> TimeInterval {
        var triggerDict: NSMutableDictionary
        if let dict = fw_property(forName: "fw_statisticalExposureTotalDuration") as? NSMutableDictionary {
            triggerDict = dict
        } else {
            triggerDict = NSMutableDictionary()
            fw_setProperty(triggerDict, forName: "fw_statisticalExposureTotalDuration")
        }
        
        let triggerKey = "\(indexPath?.section ?? -1).\(indexPath?.row ?? -1)" as NSString
        let triggerDuration = ((triggerDict[triggerKey] as? NSNumber)?.doubleValue ?? 0) + duration
        triggerDict.setObject(NSNumber(value: triggerDuration), forKey: triggerKey)
        return triggerDuration
    }
    
}

@_spi(FW) extension UIViewController {
    
    private class StatisticalTarget: NSObject {
        var exposure: StatisticalObject?
        var exposureBlock: StatisticalBlock?
        var exposureTimestamp: TimeInterval = 0
        var exposureDuration: TimeInterval = 0
        var exposureTotalCount: Int = 0
        var exposureTotalDuration: TimeInterval = 0
        
        private(set) weak var viewController: UIViewController?
        
        init(viewController: UIViewController?) {
            super.init()
            self.viewController = viewController
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        func exposureRegister() {
            NotificationCenter.default.addObserver(self, selector: #selector(appResignActive), name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        
        @objc func appResignActive() {
            let beginTime = exposureTimestamp
            if beginTime > 0 {
                exposureTimestamp = 0
                exposureDuration += Date().timeIntervalSince1970 - beginTime
            }
        }
        
        @objc func appBecomeActive() {
            exposureTimestamp = Date().timeIntervalSince1970
        }
        
        func viewDidAppear() {
            // 忽略侧滑返回手势取消触发viewDidAppear的情况
            if exposureDuration > 0 { return }
            
            exposureTimestamp = Date().timeIntervalSince1970
            exposureDuration = 0
            triggerExposure(duration: 0)
        }
        
        func viewDidDisappear() {
            var duration = exposureDuration
            let beginTime = exposureTimestamp
            if beginTime > 0 {
                duration += Date().timeIntervalSince1970 - beginTime
            }
            exposureTimestamp = 0
            exposureDuration = 0
            triggerExposure(duration: duration)
        }
        
        func triggerExposure(duration: TimeInterval) {
            var object: StatisticalObject
            if let exposureObject = exposure {
                object = exposureObject
            } else {
                object = StatisticalObject()
            }
            if object.triggerIgnored { return }
            exposureTotalCount += 1
            if exposureTotalCount > 1 && object.triggerOnce { return }
            
            exposureTotalDuration += duration
            object.__triggerExposure(viewController, triggerCount: exposureTotalCount, duration: duration, totalDuration: exposureTotalDuration)
            
            if exposureBlock != nil {
                exposureBlock?(object)
            }
            if exposure != nil {
                StatisticalManager.shared.__handleEvent(object)
            }
        }
    }
    
    /// 绑定统计曝光事件，触发管理器
    public var fw_statisticalExposure: StatisticalObject? {
        get { return fw_statisticalTarget.exposure }
        set {
            fw_statisticalTarget.exposure = newValue
            if !fw_statisticalExposureEnabled {
                fw_statisticalExposureEnabled = true
                fw_statisticalTarget.exposureRegister()
            }
        }
    }

    /// 绑定统计曝光事件，仅触发回调
    public var fw_statisticalExposureBlock: StatisticalBlock? {
        get { return fw_statisticalTarget.exposureBlock }
        set {
            fw_statisticalTarget.exposureBlock = newValue
            if !fw_statisticalExposureEnabled {
                fw_statisticalExposureEnabled = true
                fw_statisticalTarget.exposureRegister()
            }
        }
    }

    /// 手工触发统计曝光事件，更新曝光次数和时长，duration为单次曝光时长(0表示开始)，可重复触发
    public func fw_statisticalTriggerExposure(duration: TimeInterval = 0) {
        fw_statisticalTarget.triggerExposure(duration: duration)
    }
    
    fileprivate func fw_statisticalExposureDidAppear() {
        if !self.fw_statisticalExposureEnabled { return }
        fw_statisticalTarget.viewDidAppear()
    }
    
    fileprivate func fw_statisticalExposureDidDisappear() {
        if !self.fw_statisticalExposureEnabled { return }
        fw_statisticalTarget.viewDidDisappear()
    }
    
    private var fw_statisticalExposureEnabled: Bool {
        get { return fw_propertyBool(forName: "fw_statisticalExposureEnabled") }
        set { fw_setPropertyBool(newValue, forName: "fw_statisticalExposureEnabled") }
    }
    
    private var fw_statisticalTarget: StatisticalTarget {
        if let target = fw_property(forName: "fw_statisticalTarget") as? StatisticalTarget {
            return target
        } else {
            let target = StatisticalTarget(viewController: self)
            fw_setProperty(target, forName: "fw_statisticalTarget")
            return target
        }
    }
    
}
