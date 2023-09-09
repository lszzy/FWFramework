//
//  ViewPlugin.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import UIKit
#if FWMacroSPM
import FWObjC
#endif

// MARK: - ProgressViewPlugin
/// 进度条视图样式枚举，可扩展
public struct ProgressViewStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认进度条样式
    public static let `default`: ProgressViewStyle = .init(0)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

/// 进度条视图场景选项，可扩展
public struct ProgressViewScene: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认场景，默认白色
    public static let `default`: ProgressViewScene = .init(0)
    /// 全部场景，全局设置
    public static let all: ProgressViewScene = .init(999)
    
    // MARK: - Scene
    /// Toast场景，默认白色
    public static let toast: ProgressViewScene = .init(1)
    /// ImagePreview场景，默认白色
    public static let imagePreview: ProgressViewScene = .init(2)
    
    // MARK: - Config
    /// 配置场景尺寸，默认{37,37}
    public static func setIndicatorSize(_ size: CGSize, for scene: ProgressViewScene) {
        indicatorSizes[scene.rawValue] = size
    }
    
    /// 配置场景颜色，默认值见注释
    public static func setIndicatorColor(_ color: UIColor?, for scene: ProgressViewScene) {
        indicatorColors[scene.rawValue] = color
    }
    
    private static var indicatorSizes: [Int: CGSize] = [:]
    private static var indicatorColors: [Int: UIColor] = [:]
    
    /// 获取场景尺寸，默认{37,37}
    public var indicatorSize: CGSize {
        if let indicatorSize = Self.indicatorSizes[rawValue] ?? Self.indicatorSizes[ProgressViewScene.all.rawValue] {
            return indicatorSize
        }
        
        return CGSize(width: 37, height: 37)
    }
    
    /// 获取场景颜色，默认值见注释
    public var indicatorColor: UIColor? {
        if let indicatorColor = Self.indicatorColors[rawValue] ?? Self.indicatorColors[ProgressViewScene.all.rawValue] {
            return indicatorColor
        }
        
        return .white
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
@objc(__FWProgressViewPlugin)
public protocol ProgressViewPlugin {
    
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
public struct IndicatorViewStyle: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认指示器样式
    public static let `default`: IndicatorViewStyle = .init(0)
    
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init(_ rawValue: Int) {
        self.rawValue = rawValue
    }
    
}

/// 指示器视图场景选项，可扩展
public struct IndicatorViewScene: RawRepresentable, Equatable, Hashable {
    
    public typealias RawValue = Int
    
    /// 默认场景，默认白色
    public static let `default`: IndicatorViewScene = .init(0)
    /// 全部场景，全局设置
    public static let all: IndicatorViewScene = .init(999)
    
    // MARK: - Scene
    /// Toast场景，默认白色
    public static let toast: IndicatorViewScene = .init(1)
    /// Refresh下拉刷新场景，默认灰色
    public static let refreshPulldown: IndicatorViewScene = .init(2)
    /// Refresh上拉追加场景，默认灰色
    public static let refreshPullup: IndicatorViewScene = .init(3)
    /// Empty场景，默认灰色
    public static let empty: IndicatorViewScene = .init(4)
    /// Image场景，默认灰色
    public static let image: IndicatorViewScene = .init(5)
    /// Image占位场景，默认白色
    public static let imagePlaceholder: IndicatorViewScene = .init(6)
    
    // MARK: - Config
    /// 配置场景尺寸，默认{37,37}
    public static func setIndicatorSize(_ size: CGSize, for scene: IndicatorViewScene) {
        indicatorSizes[scene.rawValue] = size
    }
    
    /// 配置场景颜色，默认值见注释
    public static func setIndicatorColor(_ color: UIColor?, for scene: IndicatorViewScene) {
        indicatorColors[scene.rawValue] = color
    }
    
    private static var indicatorSizes: [Int: CGSize] = [:]
    private static var indicatorColors: [Int: UIColor] = [:]
    
    /// 获取场景尺寸，默认{37,37}
    public var indicatorSize: CGSize {
        if let indicatorSize = Self.indicatorSizes[rawValue] ?? Self.indicatorSizes[IndicatorViewScene.all.rawValue] {
            return indicatorSize
        }
        
        return CGSize(width: 37, height: 37)
    }
    
    /// 获取场景颜色，默认值见注释
    public var indicatorColor: UIColor? {
        if let indicatorColor = Self.indicatorColors[rawValue] ?? Self.indicatorColors[IndicatorViewScene.all.rawValue] {
            return indicatorColor
        }
        
        switch self {
        case .refreshPullup, .refreshPulldown, .empty, .image:
            return .gray
        default:
            return .white
        }
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
@objc(__FWIndicatorViewPlugin)
public protocol IndicatorViewPlugin {
    
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
public protocol ViewPlugin: AnyObject {
    
    /// 进度视图工厂方法
    func progressView(style: ProgressViewStyle, scene: ProgressViewScene) -> UIView & ProgressViewPlugin
    
    /// 指示器视图工厂方法
    func indicatorView(style: IndicatorViewStyle, scene: IndicatorViewScene) -> UIView & IndicatorViewPlugin
    
}

extension ViewPlugin {
    
    /// 默认实现，进度视图工厂方法
    public func progressView(style: ProgressViewStyle, scene: ProgressViewScene) -> UIView & ProgressViewPlugin {
        return ViewPluginImpl.shared.progressView(style: style, scene: scene)
    }
    
    /// 默认实现，指示器视图工厂方法
    public func indicatorView(style: IndicatorViewStyle, scene: IndicatorViewScene) -> UIView & IndicatorViewPlugin {
        return ViewPluginImpl.shared.indicatorView(style: style, scene: scene)
    }
    
}

// MARK: - UIView+ViewPlugin
@_spi(FW) extension UIView {
    
    /// 自定义视图插件，未设置时自动从插件池加载
    public var fw_viewPlugin: ViewPlugin! {
        get {
            if let viewPlugin = fw_property(forName: "fw_viewPlugin") as? ViewPlugin {
                return viewPlugin
            } else if let viewPlugin = PluginManager.loadPlugin(ViewPlugin.self) {
                return viewPlugin
            }
            return ViewPluginImpl.shared
        }
        set {
            fw_setProperty(newValue, forName: "fw_viewPlugin")
        }
    }

    /// 统一进度视图工厂方法
    public func fw_progressView(style: ProgressViewStyle = .default, scene: ProgressViewScene = .default) -> UIView & ProgressViewPlugin {
        let plugin = fw_viewPlugin ?? ViewPluginImpl.shared
        return plugin.progressView(style: style, scene: scene)
    }

    /// 统一指示器视图工厂方法
    public func fw_indicatorView(style: IndicatorViewStyle = .default, scene: IndicatorViewScene = .default) -> UIView & IndicatorViewPlugin {
        let plugin = fw_viewPlugin ?? ViewPluginImpl.shared
        return plugin.indicatorView(style: style, scene: scene)
    }
    
    /// 统一进度视图工厂方法
    public static func fw_progressView(style: ProgressViewStyle = .default, scene: ProgressViewScene = .default) -> UIView & ProgressViewPlugin {
        let plugin = PluginManager.loadPlugin(ViewPlugin.self) ?? ViewPluginImpl.shared
        return plugin.progressView(style: style, scene: scene)
    }

    /// 统一指示器视图工厂方法
    public static func fw_indicatorView(style: IndicatorViewStyle = .default, scene: IndicatorViewScene = .default) -> UIView & IndicatorViewPlugin {
        let plugin = PluginManager.loadPlugin(ViewPlugin.self) ?? ViewPluginImpl.shared
        return plugin.indicatorView(style: style, scene: scene)
    }
    
}

@_spi(FW) extension UIActivityIndicatorView {
    
    /// 快速创建指示器，可指定颜色，默认白色
    public static func fw_indicatorView(color: UIColor? = nil) -> UIActivityIndicatorView {
        var indicatorStyle: UIActivityIndicatorView.Style
        if #available(iOS 13.0, *) {
            indicatorStyle = .medium
        } else {
            indicatorStyle = .white
        }
        let indicatorView = UIActivityIndicatorView(style: indicatorStyle)
        indicatorView.color = color ?? .white
        indicatorView.hidesWhenStopped = true
        return indicatorView
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
            return bounds.size
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
        get { fw_propertyDouble(forName: "progress") }
        set { setProgress(newValue, animated: false) }
    }
    
    /// 设置指示器进度，大于0小于1时开始动画，其它值停止动画。同setProgress:
    open func setProgress(_ progress: CGFloat, animated: Bool) {
        fw_setPropertyDouble(progress, forName: "progress")
        if 0 < progress && progress < 1 {
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
