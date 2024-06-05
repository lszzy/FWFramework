//
//  ViewProtocol.swift
//  FWFramework
//
//  Created by wuyong on 2024/6/5.
//

import UIKit

// MARK: - ViewProtocol
/// 视图规范协议，需手工调用
///
/// 渲染数据规范示例：
/// 1. 无需外部数据时，实现 setupData() ，示例如下：
/// ```swift
/// func setupData() {
///     ...
/// }
/// ```
///
/// 2. 需外部数据时，实现：configure(...)，示例如下：
/// ```swift
/// func configure(model: Model) {
///     ...
/// }
/// ```
public protocol ViewProtocol {
    
    /// 初始化完成，一般init(frame:)调用，默认空实现
    func didInitialize()
    
    /// 初始化子视图，一般init(frame:)调用，默认空实现
    func setupSubviews()
    
    /// 初始化布局，一般init(frame:)调用，默认空实现
    func setupLayout()
    
}

extension ViewProtocol where Self: UIView {
    
    /// 初始化完成，一般init(frame:)调用，默认空实现
    public func didInitialize() {}
    
    /// 初始化子视图，一般init(frame:)调用，默认空实现
    public func setupSubviews() {}
    
    /// 初始化布局，一般init(frame:)调用，默认空实现
    public func setupLayout() {}
    
}
