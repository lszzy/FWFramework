//
//  DrawerView.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

/// 抽屉拖拽视图事件代理
public protocol DrawerViewDelegate: AnyObject {
    
    /// 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
    func drawerView(_ drawerView: DrawerView, positionChanged position: CGFloat, finished: Bool)
    
}

/// 抽屉拖拽视图
open class DrawerView: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    /// 事件代理，默认nil
    open weak var delegate: DrawerViewDelegate?
    
    /// 拖拽方向，如向上拖动视图时为Up，向下为Down，向右为Right，向左为Left。默认向上
    open var direction: UISwipeGestureRecognizer.Direction = .up {
        didSet {
            if let view = self.view {
                self.position = isVertical ? view.frame.origin.y : view.frame.origin.x
            }
        }
    }
    
    /// 抽屉位置，至少两级，相对于view父视图的originY位置，自动从小到大排序
    open var positions: [CGFloat] {
        get {
            return _positions
        }
        set {
            if newValue.count < 2 { return }
            _positions = newValue.sorted(by: { $0 < $1 })
        }
    }
    private var _positions: [CGFloat] = []
    
    /// 回弹高度，拖拽小于该高度执行回弹，默认为0
    open var kickbackHeight: CGFloat = 0
    
    /// 是否启用拖拽，默认YES。其实就是设置手势的enabled
    open var enabled: Bool {
        get { return gestureRecognizer.isEnabled }
        set { gestureRecognizer.isEnabled = newValue }
    }
    
    /// 是否自动检测滚动视图，默认YES。如需手工指定，请禁用之
    open var autoDetected: Bool = true
    
    /// 指定滚动视图，自动处理与滚动视图pan手势在指定方向的冲突。先尝试设置delegate为自身，尝试失败请手工调用scrollViewDidScroll
    open weak var scrollView: UIScrollView? {
        didSet {
            if let drawerView = oldValue?.delegate as? DrawerView, drawerView == self {
                oldValue?.delegate = nil
            }
            if let scrollView = scrollView, scrollView.delegate == nil {
                scrollView.delegate = self
            }
        }
    }
    
    /// 抽屉视图，自动添加pan手势
    open private(set) weak var view: UIView?
    
    /// 抽屉拖拽手势，默认设置delegate为自身
    open private(set) lazy var gestureRecognizer: UIPanGestureRecognizer = {
        let result = UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(_:)))
        result.delegate = self
        return result
    }()
    
    /// 抽屉视图当前位置
    open private(set) var position: CGFloat = 0
    
    /// 抽屉视图打开位置
    open var openPosition: CGFloat {
        return (isReverse ? positions.first : positions.last) ?? .zero
    }
    
    /// 抽屉视图中间位置，建议单数时调用
    open var middlePosition: CGFloat {
        return position(at: positions.count / 2)
    }
    
    /// 抽屉视图关闭位置
    open var closePosition: CGFloat {
        return (isReverse ? positions.last : positions.first) ?? .zero
    }
    
    /// 抽屉视图位移回调，参数为相对view父视图的origin位置和是否拖拽完成的标记
    open var positionChanged: ((_ position: CGFloat, _ finished: Bool) -> Void)?
    
    /// 自定义动画句柄，动画必须调用animations和completion句柄
    open var animationBlock: ((_ animations: () -> Void, _ completion: (Bool) -> Void) -> Void)?
    
    /// 滚动视图过滤器，默认只处理可滚动视图的冲突。如需其它条件，可自定义此句柄
    open var scrollViewFilter: ((UIScrollView) -> Bool)?
    
    /// 自定义滚动视图允许滚动的位置，默认nil时仅openPosition可滚动
    open var scrollViewPositions: ((UIScrollView) -> [CGFloat])?
    
    /// 自定义滚动视图在各个位置的contentInset(从小到大，数量同positions)，默认nil时不处理。UITableView时也可使用tableFooterView等实现
    open var scrollViewInsets: ((UIScrollView) -> [UIEdgeInsets])?
    
    private var displayLink: CADisplayLink?
    private var panDisabled = false
    private var originPosition: CGFloat = .zero
    private var originOffset: CGPoint = .zero
    private var isOriginDraggable = false
    private var isOriginScrollable = false
    private var isOriginScrollView = false
    private var isOriginDirection = false
    
    private var isVertical: Bool {
        return direction == .up || direction == .down
    }
    
    private var isReverse: Bool {
        return direction == .up || direction == .left
    }
    
    private var scrollEdge: UIRectEdge {
        switch direction {
        case .up:
            return .top
        case .down:
            return .bottom
        case .left:
            return .left
        case .right:
            return .right
        default:
            return []
        }
    }
    
    // MARK: - Lifecycle
    /// 创建抽屉拖拽视图，view会强引用之。view为滚动视图时，详见scrollView属性
    public init(view: UIView) {
        super.init()
        self.view = view
        self.position = isVertical ? view.frame.origin.y : view.frame.origin.x
        
        if let scrollView = view as? UIScrollView {
            self.scrollView = scrollView
            if scrollView.delegate == nil {
                scrollView.delegate = self
            }
        }
        
        view.addGestureRecognizer(self.gestureRecognizer)
        view.fw_drawerView = self
    }
    
    // MARK: - Public
    /// 设置抽屉效果视图到指定位置，如果位置发生改变，会触发抽屉callback回调
    open func setPosition(_ position: CGFloat, animated: Bool = true) {
        
    }
    
    /// 获取抽屉视图指定索引位置(从小到大)，获取失败返回0
    open func position(at index: Int) -> CGFloat {
        return .zero
    }
    
    /// 判断当前抽屉效果视图是否在指定索引位置(从小到大)
    open func isPosition(at index: Int) -> Bool {
        return false
    }
    
    /// 设置抽屉效果视图到指定索引位置(从小到大)，如果位置发生改变，会触发抽屉callback回调
    open func setPosition(at index: Int, animated: Bool = true) {
        
    }
    
    /// 如果scrollView已自定义delegate，需在scrollViewDidScroll手工调用本方法
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    // MARK: - Private
    private func isDirection(_ gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        let swipeDirection = gestureRecognizer.fw_swipeDirection
        switch self.direction {
        case .up:
            return swipeDirection == .down
        case .down:
            return swipeDirection == .up
        case .left:
            return swipeDirection == .right
        case .right:
            return swipeDirection == .left
        default:
            return false
        }
    }
    
    private var nextPosition: CGFloat {
        var nextPosition: CGFloat = .zero
        if self.position > self.originPosition {
            for obj in self.positions {
                let maxKickback = (obj == self.positions.last) ? obj : obj + self.kickbackHeight
                if self.position <= maxKickback {
                    nextPosition = obj
                    break
                }
            }
        } else {
            for obj in self.positions.reversed() {
                let minKickback = (obj == self.positions.first) ? obj : obj - self.kickbackHeight
                if self.position >= minKickback {
                    nextPosition = obj
                    break
                }
            }
        }
        return nextPosition
    }
    
    private func canScroll(_ scrollView: UIScrollView) -> Bool {
        if let scrollViewFilter = self.scrollViewFilter { return scrollViewFilter(scrollView) }
        if !scrollView.fw_isViewVisible || !scrollView.isScrollEnabled { return false }
        if self.isVertical {
            if !scrollView.fw_canScrollVertical { return false }
        } else {
            if !scrollView.fw_canScrollHorizontal { return false }
        }
        return true
    }
    
    private func togglePosition(_ position: CGFloat) {
        guard let view = self.view else { return }
        view.frame = CGRect(
            x: isVertical ? view.frame.origin.x : position,
            y: isVertical ? position : view.frame.origin.y,
            width: view.frame.size.width,
            height: view.frame.size.height
        )
    }
    
    @objc private func gestureRecognizerAction(_ gestureRecognizer: UIPanGestureRecognizer) {
        
    }
    
}

/// 视图抽屉拖拽效果分类
@_spi(FW) extension UIView {
    
    /// 抽屉拖拽视图，绑定抽屉拖拽效果后才存在
    @objc(__fw_drawerView)
    public var fw_drawerView: DrawerView? {
        get {
            return fw_property(forName: "fw_drawerView") as? DrawerView
        }
        set {
            fw_setProperty(newValue, forName: "fw_drawerView")
        }
    }
    
    /**
     设置抽屉拖拽效果。如果view为滚动视图，自动处理与滚动视图pan手势冲突的问题
     
     @param direction 拖拽方向，如向上拖动视图时为Up，默认向上
     @param positions 抽屉位置，至少两级，相对于view父视图的originY位置
     @param kickbackHeight 回弹高度，拖拽小于该高度执行回弹
     @param positionChanged 抽屉视图位移回调，参数为相对父视图的origin位置和是否拖拽完成的标记
     @return 抽屉拖拽视图
     */
    @discardableResult
    public func fw_drawerView(_ direction: UISwipeGestureRecognizer.Direction, positions: [CGFloat], kickbackHeight: CGFloat, positionChanged: ((CGFloat, Bool) -> Void)? = nil) -> DrawerView {
        let drawerView = DrawerView(view: self)
        if direction.rawValue > 0 {
            drawerView.direction = direction
        }
        drawerView.positions = positions
        drawerView.kickbackHeight = kickbackHeight
        drawerView.positionChanged = positionChanged
        return drawerView
    }
    
}

/// 滚动视图纵向手势冲突无缝滑动分类，需允许同时识别多个手势
@_spi(FW) extension UIScrollView {
    
    /// 外部滚动视图是否位于顶部固定位置，在顶部时不能滚动
    public var fw_drawerSuperviewFixed: Bool {
        get { return fw_propertyBool(forName: "fw_drawerSuperviewFixed") }
        set { fw_setPropertyBool(newValue, forName: "fw_drawerSuperviewFixed") }
    }

    /// 外部滚动视图scrollViewDidScroll调用，参数为固定的位置
    public func fw_drawerSuperviewDidScroll(_ position: CGFloat) {
        if self.contentOffset.y >= position {
            self.fw_drawerSuperviewFixed = true
        }
        if self.fw_drawerSuperviewFixed {
            self.contentOffset = CGPoint(x: self.contentOffset.x, y: position)
        }
    }

    /// 内嵌滚动视图scrollViewDidScroll调用，参数为外部滚动视图
    public func fw_drawerSubviewDidScroll(_ superview: UIScrollView) {
        if self.contentOffset.y <= 0 {
            superview.fw_drawerSuperviewFixed = false
        }
        if !superview.fw_drawerSuperviewFixed {
            self.contentOffset = CGPoint(x: self.contentOffset.x, y: 0)
        }
    }
    
}
