//
//  UIView+FWLayoutChain.swift
//  FWFramework
//
//  Created by wuyong on 2019/6/29.
//  Copyright © 2019 wuyong.site. All rights reserved.
//

import Foundation

public class FWLayoutChain {
    weak var view: UIView? = nil
    
    @discardableResult
    public func top(_ inset: CGFloat = 0) -> FWLayoutChain {
        self.view?.fwPinEdge(toSuperview: .top, withInset: inset)
        return self
    }
    
    @discardableResult
    public func centerX() -> FWLayoutChain {
        self.view?.fwAlignAxis(toSuperview: .centerX)
        return self
    }
    
    @discardableResult
    public func centerX(toView view: UIView) -> FWLayoutChain {
        self.view?.fwAlignAxis(.centerX, toView: view)
        return self
    }
    
    @discardableResult
    public func size(_ size: CGSize) -> FWLayoutChain {
        self.view?.fwSetDimensions(to: size)
        return self
    }
}

extension UIView {
    private struct FWLayoutChainProperties {
        static var layoutChain: UInt8 = 0
    }
    
    public var fwLayoutChain: FWLayoutChain {
        var layoutChain = objc_getAssociatedObject(self, &FWLayoutChainProperties.layoutChain)
        if layoutChain == nil {
            let chain = FWLayoutChain()
            chain.view = self
            layoutChain = chain
            objc_setAssociatedObject(self, &FWLayoutChainProperties.layoutChain, layoutChain, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return layoutChain as! FWLayoutChain
    }
}
