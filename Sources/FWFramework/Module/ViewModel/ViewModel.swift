//
//  ViewModel.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

import Foundation

/// ViewModel协议，被View持有(Controller和View都视为View层)，负责处理数据并通知View，兼容UIKit和SwiftUI使用
public protocol ViewModel: ObservableObject {}
