//
//  ViewModel.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/23.
//

#if canImport(SwiftUI)
import SwiftUI

/// ViewModel协议，被View持有(Controller和View都视为View层)，负责处理数据并通知View，兼容UIKit使用
/// 注意：iOS13系统使用时不能继承实现ObservableObject协议的ViewModel类，需直接实现ObservableObject协议，否则\@Published监听不会触发View刷新
///
/// \@State: 内部值传递，赋值时会触发View刷新
/// \@Binding: 外部引用传递，实现向外传递引用
/// \@ObservableObject: 可被订阅的对象，属性标记@Published时生效
/// \@ObservedObject: View订阅监听，收到通知时刷新View，不被View持有，随时可能被销毁，适合外部数据
/// \@EnvironmentObject: 全局环境对象，使用environmentObject方法绑定，View及其子层级可直接读取
/// \@StateObject: View引用对象，生命周期和View保持一致，刷新时数据会保持直到View被销毁
public protocol ViewModel: ObservableObject {}

#endif
