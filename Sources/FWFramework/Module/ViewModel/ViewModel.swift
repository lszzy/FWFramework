//
//  ViewModel.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation

/// 可监听ViewModel协议，被View持有(Controller和View都视为View层)，负责处理数据并通知View，兼容UIKit和SwiftUI使用
public protocol ObservableViewModel: ObservableObject {}

/// 已废弃，ViewModel协议，被View持有(Controller和View都视为View层)，负责处理数据并通知View，兼容UIKit和SwiftUI使用
@available(*, deprecated, renamed: "ObservableViewModel", message: "Use ObservableViewModel instead")
public typealias ViewModel = ObservableViewModel
