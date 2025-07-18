//
//  ViewPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit

// MARK: - Wrapper+UIView
@MainActor extension Wrapper where Base: UIView {
    /// 自定义视图插件，未设置时自动从插件池加载
    public var viewPlugin: ViewPlugin! {
        get {
            if let viewPlugin = property(forName: "viewPlugin") as? ViewPlugin {
                return viewPlugin
            } else if let viewPlugin = PluginManager.loadPlugin(ViewPlugin.self) {
                return viewPlugin
            }
            return ViewPluginImpl.shared
        }
        set {
            setProperty(newValue, forName: "viewPlugin")
        }
    }

    /// 统一进度视图工厂方法
    public func progressView(style: ProgressViewStyle = .default) -> UIView & ProgressViewPlugin {
        let plugin = viewPlugin ?? ViewPluginImpl.shared
        return plugin.progressView(style: style)
    }

    /// 统一指示器视图工厂方法
    public func indicatorView(style: IndicatorViewStyle = .default) -> UIView & IndicatorViewPlugin {
        let plugin = viewPlugin ?? ViewPluginImpl.shared
        return plugin.indicatorView(style: style)
    }

    /// 统一进度视图工厂方法
    public static func progressView(style: ProgressViewStyle = .default) -> UIView & ProgressViewPlugin {
        let plugin = PluginManager.loadPlugin(ViewPlugin.self) ?? ViewPluginImpl.shared
        return plugin.progressView(style: style)
    }

    /// 统一指示器视图工厂方法
    public static func indicatorView(style: IndicatorViewStyle = .default) -> UIView & IndicatorViewPlugin {
        let plugin = PluginManager.loadPlugin(ViewPlugin.self) ?? ViewPluginImpl.shared
        return plugin.indicatorView(style: style)
    }
}

// MARK: - Wrapper+UIActivityIndicatorView
@MainActor extension Wrapper where Base: UIActivityIndicatorView {
    /// 快速创建指示器，可指定颜色，默认白色
    public static func indicatorView(color: UIColor?) -> UIActivityIndicatorView {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = color ?? .white
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }
}

// MARK: - ProgressViewPlugin
/// 进度条视图样式枚举，可扩展
public struct ProgressViewStyle: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 默认进度条样式
    public static let `default`: ProgressViewStyle = .init(0)

    // MARK: - Style
    /// Toast样式
    public static let toast: ProgressViewStyle = .init(1)
    /// ImagePreview样式
    public static let imagePreview: ProgressViewStyle = .init(2)

    /// 全部样式，全局设置
    public static let all: ProgressViewStyle = .init(999)

    // MARK: - Config
    /// 自定义样式尺寸
    public static func setIndicatorSize(_ size: CGSize, for style: ProgressViewStyle) {
        FrameworkConfiguration.progressViewSizes[style.rawValue] = size
    }

    /// 自定义样式颜色
    public static func setIndicatorColor(_ color: UIColor?, for style: ProgressViewStyle) {
        FrameworkConfiguration.progressViewColors[style.rawValue] = color
    }

    /// 获取自定义样式尺寸，默认nil
    public var indicatorSize: CGSize? {
        if let indicatorSize = FrameworkConfiguration.progressViewSizes[rawValue] {
            return indicatorSize
        }

        return FrameworkConfiguration.progressViewSizes[ProgressViewStyle.all.rawValue]
    }

    /// 获取自定义样式颜色，默认nil
    public var indicatorColor: UIColor? {
        if let indicatorColor = FrameworkConfiguration.progressViewColors[rawValue] {
            return indicatorColor
        }

        return FrameworkConfiguration.progressViewColors[ProgressViewStyle.all.rawValue]
    }

    // MARK: - Lifecycle
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// 自定义进度条视图插件
@MainActor public protocol ProgressViewPlugin: AnyObject {
    /// 设置或获取进度条当前颜色
    var indicatorColor: UIColor? { get set }

    /// 设置或获取进度条大小
    var indicatorSize: CGSize { get set }

    /// 设置或获取进度条当前进度
    var progress: CGFloat { get set }

    /// 设置进度条当前进度，支持动画
    func setProgress(_ progress: CGFloat, animated: Bool)
}

// MARK: - IndicatorViewPlugin
/// 指示器视图样式枚举，可扩展
public struct IndicatorViewStyle: RawRepresentable, Equatable, Hashable, Sendable {
    public typealias RawValue = Int

    /// 默认指示器样式
    public static let `default`: IndicatorViewStyle = .init(0)

    // MARK: - Style
    /// Toast样式
    public static let toast: IndicatorViewStyle = .init(1)
    /// Refresh下拉刷新样式
    public static let refreshPulldown: IndicatorViewStyle = .init(2)
    /// Refresh上拉追加样式
    public static let refreshPullup: IndicatorViewStyle = .init(3)
    /// Empty样式
    public static let empty: IndicatorViewStyle = .init(4)
    /// Image样式
    public static let image: IndicatorViewStyle = .init(5)
    /// Image占位样式
    public static let imagePlaceholder: IndicatorViewStyle = .init(6)

    /// 全部样式，全局设置
    public static let all: IndicatorViewStyle = .init(999)

    // MARK: - Config
    /// 自定义样式尺寸，默认nil
    public static func setIndicatorSize(_ size: CGSize, for style: IndicatorViewStyle) {
        FrameworkConfiguration.indicatorViewSizes[style.rawValue] = size
    }

    /// 自定义样式颜色，默认nil
    public static func setIndicatorColor(_ color: UIColor?, for style: IndicatorViewStyle) {
        FrameworkConfiguration.indicatorViewColors[style.rawValue] = color
    }

    /// 获取自定义样式尺寸，默认nil
    public var indicatorSize: CGSize? {
        if let indicatorSize = FrameworkConfiguration.indicatorViewSizes[rawValue] {
            return indicatorSize
        }

        return FrameworkConfiguration.indicatorViewSizes[IndicatorViewStyle.all.rawValue]
    }

    /// 获取自定义样式颜色，默认nil
    public var indicatorColor: UIColor? {
        if let indicatorColor = FrameworkConfiguration.indicatorViewColors[rawValue] {
            return indicatorColor
        }

        return FrameworkConfiguration.indicatorViewColors[IndicatorViewStyle.all.rawValue]
    }

    // MARK: - Lifecycle
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// 自定义指示器视图协议
@MainActor public protocol IndicatorViewPlugin: AnyObject {
    /// 设置或获取指示器当前颜色
    var indicatorColor: UIColor? { get set }

    /// 设置或获取指示器大小
    var indicatorSize: CGSize { get set }

    /// 当前是否正在执行动画
    var isAnimating: Bool { get }

    /// 开始加载动画
    func startAnimating()

    /// 停止加载动画
    func stopAnimating()
}

// MARK: - ViewPlugin
/// 视图插件协议
@MainActor public protocol ViewPlugin: AnyObject {
    /// 进度视图工厂方法
    func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin

    /// 指示器视图工厂方法
    func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin
}

extension ViewPlugin {
    /// 默认实现，进度视图工厂方法
    public func progressView(style: ProgressViewStyle) -> UIView & ProgressViewPlugin {
        ViewPluginImpl.shared.progressView(style: style)
    }

    /// 默认实现，指示器视图工厂方法
    public func indicatorView(style: IndicatorViewStyle) -> UIView & IndicatorViewPlugin {
        ViewPluginImpl.shared.indicatorView(style: style)
    }
}

/// 系统指示器默认实现指示器视图协议
@objc extension UIActivityIndicatorView: IndicatorViewPlugin, ProgressViewPlugin {
    /// 设置或获取指示器颜色
    open var indicatorColor: UIColor? {
        get { color }
        set { color = newValue }
    }

    /// 设置或获取指示器大小，默认中{20,20}，大{37,37}
    open var indicatorSize: CGSize {
        get {
            bounds.size
        }
        set {
            var height = bounds.size.height
            if height <= 0 {
                height = sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).height
                if height <= 0 {
                    height = 20
                }
            }
            let scale = newValue.height / height
            transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    /// 指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:animated:
    open var progress: CGFloat {
        get { fw.propertyDouble(forName: "progress") }
        set { setProgress(newValue, animated: false) }
    }

    /// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
    open func setProgress(_ progress: CGFloat, animated: Bool) {
        fw.setPropertyDouble(progress, forName: "progress")
        if progress > 0 && progress < 1 {
            if !isAnimating {
                startAnimating()
            }
        } else {
            if isAnimating {
                stopAnimating()
            }
        }
    }
}

// MARK: - FrameworkConfiguration+ViewPlugin
extension FrameworkConfiguration {
    fileprivate static var progressViewSizes: [Int: CGSize] = [:]
    fileprivate static var progressViewColors: [Int: UIColor] = [:]
    fileprivate static var indicatorViewSizes: [Int: CGSize] = [:]
    fileprivate static var indicatorViewColors: [Int: UIColor] = [:]
}
