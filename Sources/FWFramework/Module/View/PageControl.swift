//
//  PageControl.swift
//  FWFramework
//
//  Created by wuyong on 2023/3/29.
//

import UIKit

// MARK: - PageControl
/// 分页控件事件代理
public protocol PageControlDelegate: NSObjectProtocol {
    
    /// 选中指定页回调方法
    func pageControl(_ pageControl: PageControl, didSelectPage page: Int)
    
}

/// 分页控件
///
/// [TAPageControl](https://github.com/TanguyAladenise/TAPageControl)
open class PageControl: UIControl {
    
    /// 点视图类
    open var dotViewClass: AnyClass? = DotView.self
    
    /// 点视图句柄
    open var customDotView: ((UIView) -> Void)?
    
    /// 点图片
    open var dotImage: UIImage?
    
    /// 当前点图片
    open var currentDotImage: UIImage?
    
    /// 点大小
    open var dotSize: CGSize = CGSize(width: 8, height: 8)
    
    /// 点颜色
    open var dotColor: UIColor?
    
    /// 当前点颜色
    open var currentDotColor: UIColor?
    
    /// 点间距
    open var spacingBetweenDots: CGFloat = 8
    
    /// 事件代理
    open weak var delegate: PageControlDelegate?
    
    /// 总页数，默认0
    open var numberOfPages: Int = 0
    
    /// 当前页数，默认0
    open var currentPage: Int = 0
    
    /// 单页时是否隐藏，默认false
    open var hidesForSinglePage: Bool = false
    
    /// 是否resize保持居中，默认true
    open var shouldResizeFromCenter: Bool = true
    
    private var dots: [UIView] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view = touches.first?.view, view != self else { return }
        if let index = dots.firstIndex(of: view) {
            delegate?.pageControl(self, didSelectPage: index)
        }
    }
    
    open override func sizeToFit() {
        updateFrame(true)
    }
    
    /// 计算指定页数时的显示尺寸
    open func sizeForNumberOfPages(_ pageCount: Int) -> CGSize {
        return CGSize(width: (dotSize.width + spacingBetweenDots) * CGFloat(pageCount) - spacingBetweenDots, height: dotSize.height)
    }
    
    private func updateDots() {
        guard numberOfPages > 0 else { return }
        
        
    }
    
    private func updateFrame(_ overrideExistingFrame: Bool) {
        
    }
    
}

// MARK: - DotView
/// 点视图协议
public protocol DotViewProtocol {
    
    /// 选中状态改变方法
    func changeActivityState(_ active: Bool)
    
}

/// 自带点视图
open class DotView: UIView, DotViewProtocol {
    
    open var dotColor: UIColor = .white.withAlphaComponent(0.5)
    
    open var currentDotColor: UIColor = .white
    
    open var isAnimated = false
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        didInitialize()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        didInitialize()
    }
    
    fileprivate func didInitialize() {
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.masksToBounds = true
        backgroundColor = dotColor
    }
    
    open func changeActivityState(_ active: Bool) {
        if !isAnimated {
            backgroundColor = active ? currentDotColor : dotColor
        } else {
            if active {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -20, options: .curveLinear, animations: {
                    self.backgroundColor = self.currentDotColor
                    self.transform = .init(scaleX: 1.4, y: 1.4)
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear, animations: {
                    self.backgroundColor = self.dotColor
                    self.transform = .identity
                }, completion: nil)
            }
        }
    }
    
}

/// 自带边框点视图
open class BorderDotView: DotView {
    
    open override var dotColor: UIColor {
        didSet {
            backgroundColor = dotColor
        }
    }
    
    open override var currentDotColor: UIColor {
        didSet {
            layer.borderColor = currentDotColor.cgColor
        }
    }
    
    override func didInitialize() {
        dotColor = .clear
        currentDotColor = .white
        layer.cornerRadius = min(frame.width, frame.height) / 2.0
        layer.borderWidth = 2
        layer.masksToBounds = true
        backgroundColor = dotColor
        layer.borderColor = currentDotColor.cgColor
    }
    
}
