//
//  ViewToolkit.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/18.
//

#if canImport(SwiftUI)
import SwiftUI
#if FWMacroSPM
@_spi(FW) import FWFramework
#endif

// MARK: - View+Toolkit
/// 线条形状，用于分割线、虚线等。自定义路径形状：Path { (path) in ... }
/// 常用分割线：Rectangle.foregroundColor替代Divider组件
public struct LineShape: Shape {
    public var axes: Axis.Set = .horizontal

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        if axes == .horizontal {
            path.addLine(to: CGPoint(x: rect.width, y: 0))
        } else {
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        }
        return path
    }
}

/// 不规则圆角形状
public struct RoundedCornerShape: Shape {
    public var radius: CGFloat = 0
    public var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

/// 视图移除性修改器
public struct RemovableModifier: ViewModifier {
    public let removable: Bool

    public init(removable: Bool) {
        self.removable = removable
    }

    public func body(content: Content) -> some View {
        Group {
            if !removable {
                content
            } else {
                EmptyView()
            }
        }
    }
}

/// 注意：iOS13系统View在dismiss时可能不会触发onDisappear，可在关闭按钮事件中处理
extension View {
    /// 设置不规则圆角效果
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }

    /// 同时设置边框和圆角
    public func border<S: ShapeStyle>(_ content: S, width lineWidth: CGFloat, cornerRadius: CGFloat) -> some View {
        self.cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                    .stroke(content, lineWidth: lineWidth)
            )
    }

    /// 切换视图移除性
    public func removable(_ removable: Bool) -> some View {
        modifier(RemovableModifier(removable: removable))
    }

    /// 切换视图隐藏性
    public func hidden(_ isHidden: Bool) -> some View {
        Group {
            if isHidden {
                hidden()
            } else {
                self
            }
        }
    }

    /// 切换视图可见性
    public func visible(_ isVisible: Bool = true) -> some View {
        opacity(isVisible ? 1 : 0)
    }

    /// 动态切换裁剪性
    public func clipped(_ value: Bool) -> some View {
        if value {
            return AnyView(clipped())
        } else {
            return AnyView(self)
        }
    }

    /// 执行闭包并返回新的视图
    public func then(_ body: (Self) -> AnyView) -> some View {
        body(self)
    }

    /// 条件成立时执行闭包并返回新的视图
    public func then<T: View>(_ condition: Bool, body: (Self) -> T) -> some View {
        if condition {
            return AnyView(body(self))
        } else {
            return AnyView(self)
        }
    }

    /// 值不为空时执行闭包并返回新的视图
    public func then<T: View, Value>(_ value: Value?, body: (Self, Value) -> T) -> some View {
        if let value {
            return AnyView(body(self, value))
        } else {
            return AnyView(self)
        }
    }

    /// 配置当前对象
    public func configure(_ body: (inout Self) -> Void) -> Self {
        var result = self
        body(&result)
        return result
    }

    /// 转换为AnyView
    public func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Color+Toolkit
extension Color {
    /// 从16进制创建Color
    /// - Parameters:
    ///   - hex: 十六进制值，格式0xFFFFFF
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ hex: Int, _ alpha: Double = 1) -> Color {
        Color(red: Double((hex & 0xFF0000) >> 16) / 255.0, green: Double((hex & 0xFF00) >> 8) / 255.0, blue: Double(hex & 0xFF) / 255.0, opacity: alpha)
    }

    /// 从RGB创建Color
    /// - Parameters:
    ///   - red: 红色值
    ///   - green: 绿色值
    ///   - blue: 蓝色值
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1) -> Color {
        Color(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, opacity: alpha)
    }

    /// 从十六进制字符串初始化，支持RGB、RGBA|ARGB，格式："20B2AA", "#FFFFFF"，失败时返回clear
    /// - Parameters:
    ///   - hexString: 十六进制字符串
    ///   - alpha: 透明度可选，默认1
    /// - Returns: Color
    public static func color(_ hexString: String, _ alpha: Double = 1) -> Color {
        Color(UIColor.fw.color(hexString: hexString, alpha: alpha))
    }

    /// 几乎透明的颜色，常用于clear不起作用的场景
    public static var almostClear: Color {
        Color.black.opacity(0.0001)
    }

    /// 获取透明度为1.0的RGB随机颜色
    public static var randomColor: Color {
        let red = arc4random() % 255
        let green = arc4random() % 255
        let blue = arc4random() % 255
        return Color(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, opacity: 1.0)
    }

    // MARK: - UIColor
    /// Color转换为UIColor，失败时返回clear
    /// - Returns: UIColor
    public func toUIColor() -> UIColor {
        if let cachedResult = Self.colorCaches[self] {
            return cachedResult
        } else {
            var result: UIColor
            if #available(iOS 14.0, *) {
                result = UIColor(self)
            } else {
                result = toUIColor1() ?? toUIColor2() ?? .clear
            }
            Self.colorCaches[self] = result
            return result
        }
    }

    private nonisolated(unsafe) static var colorCaches: [Color: UIColor] = [:]

    private func toUIColor1() -> UIColor? {
        switch self {
        case .clear:
            return UIColor.clear
        case .black:
            return UIColor.black
        case .white:
            return UIColor.white
        case .gray:
            return UIColor.systemGray
        case .red:
            return UIColor.systemRed
        case .green:
            return UIColor.systemGreen
        case .blue:
            return UIColor.systemBlue
        case .orange:
            return UIColor.systemOrange
        case .yellow:
            return UIColor.systemYellow
        case .pink:
            return UIColor.systemPink
        case .purple:
            return UIColor.systemPurple
        case .primary:
            return UIColor.label
        case .secondary:
            return UIColor.secondaryLabel
        default:
            return nil
        }
    }

    private func toUIColor2() -> UIColor? {
        let children = Mirror(reflecting: self).children
        let _provider = children.filter { $0.label == "provider" }.first
        guard let provider = _provider?.value else {
            return nil
        }

        let providerChildren = Mirror(reflecting: provider).children
        let _base = providerChildren.filter { $0.label == "base" }.first
        guard let base = _base?.value else {
            return nil
        }
        if let uiColor = base as? UIColor {
            return uiColor
        }

        if String(describing: type(of: base)) == "NamedColor" {
            let baseMirror = Mirror(reflecting: base)
            if let name = baseMirror.descendant("name") as? String {
                let bundle = baseMirror.descendant("bundle") as? Bundle
                if let color = UIColor(named: name, in: bundle, compatibleWith: nil) {
                    return color
                }
            }
        }

        if String(describing: type(of: base)) == "OpacityColor" {
            let baseOpacity = Mirror(reflecting: base)
            if let opacity = baseOpacity.descendant("opacity") as? Double,
               let colorBase = baseOpacity.descendant("base") as? Color {
                return colorBase.toUIColor().withAlphaComponent(CGFloat(opacity))
            }
        }

        var baseValue = ""
        dump(base, to: &baseValue)
        guard let firstLine = baseValue.split(separator: "\n").first,
              let hexString = firstLine.split(separator: " ")[1] as Substring? else {
            return nil
        }

        return UIColor.fw.color(hexString: hexString.trimmingCharacters(in: .newlines))
    }
}

// MARK: - Font+Toolkit
@MainActor extension Font {
    /// 全局自定义字体句柄，优先调用
    public nonisolated(unsafe) static var fontBlock: ((CGFloat, Font.Weight) -> Font?)?

    /// 返回系统Thin字体，自动等比例缩放
    public static func thinFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        font(size: size, weight: .thin, autoScale: autoScale)
    }

    /// 返回系统Light字体，自动等比例缩放
    public static func lightFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        font(size: size, weight: .light, autoScale: autoScale)
    }

    /// 返回系统Medium字体，自动等比例缩放
    public static func mediumFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        font(size: size, weight: .medium, autoScale: autoScale)
    }

    /// 返回系统Semibold字体，自动等比例缩放
    public static func semiboldFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        font(size: size, weight: .semibold, autoScale: autoScale)
    }

    /// 返回系统Bold字体，自动等比例缩放
    public static func boldFont(size: CGFloat, autoScale: Bool? = nil) -> Font {
        font(size: size, weight: .bold, autoScale: autoScale)
    }

    /// 创建指定尺寸和weight的系统字体，自动等比例缩放
    public static func font(size: CGFloat, weight: Font.Weight = .regular, autoScale: Bool? = nil) -> Font {
        var fontSize = size
        if (autoScale == nil && UIFont.fw.autoScaleFont) || autoScale == true {
            fontSize = UIFont.fw.autoScaleBlock?(size) ?? UIScreen.fw.relativeValue(size, flat: UIFont.fw.autoFlatFont)
        }

        return nonScaleFont(size: fontSize, weight: weight)
    }

    /// 创建指定尺寸和weight的不缩放系统字体
    public nonisolated static func nonScaleFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if let font = fontBlock?(size, weight) { return font }
        return .system(size: size, weight: weight)
    }

    /// 获取指定名称、字重、斜体字体的完整规范名称
    public nonisolated static func fontName(_ name: String, weight: Font.Weight, italic: Bool = false) -> String {
        var fontName = name
        if let weightSuffix = weightSuffixes[weight] {
            fontName += weightSuffix + (italic ? "Italic" : "")
        }
        return fontName
    }

    private nonisolated static let weightSuffixes: [Font.Weight: String] = [
        .ultraLight: "-Ultralight",
        .thin: "-Thin",
        .light: "-Light",
        .regular: "-Regular",
        .medium: "-Medium",
        .semibold: "-Semibold",
        .bold: "-Bold",
        .heavy: "-Heavy",
        .black: "-Black"
    ]
}

// MARK: - Divider+Toolkit
/// 修改分割线颜色使用background方法即可，示例：background(Color.gray)
extension Divider {
    /// 分割线默认尺寸配置，未自定义时1像素，仅影响Divider和Rectangle的dividerStyle方法
    public nonisolated(unsafe) static var defaultSize: CGFloat = 1.0 / UIScreen.fw.screenScale

    /// 分割线默认颜色，未自定义时为灰色，仅影响Divider和Rectangle的dividerStyle方法
    public nonisolated(unsafe) static var defaultColor: Color {
        defaultColorConfiguration?() ??
            Color(red: 222.0 / 255.0, green: 224.0 / 255.0, blue: 226.0 / 255.0)
    }

    /// 自定义分割线默认颜色配置句柄，默认nil
    public nonisolated(unsafe) static var defaultColorConfiguration: (() -> Color)?

    /// 自定义分割线尺寸，使用scale实现，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        scaleEffect(y: UIScreen.main.scale * (size ?? Divider.defaultSize))
            .frame(height: size ?? Divider.defaultSize)
            .background(color ?? Divider.defaultColor)
    }
}

/// 使用Rectangle实现分割线更灵活可控
extension Rectangle {
    /// 自定义线条样式，参数nil时为Divider默认配置
    public func dividerStyle(size: CGFloat? = nil, color: Color? = nil) -> some View {
        frame(height: size ?? Divider.defaultSize)
            .foregroundColor(color ?? Divider.defaultColor)
    }
}

// MARK: - Button+Toolkit
/// 透明度按钮样式，支持设置高亮和禁用时的透明度
public struct OpacityButtonStyle: ButtonStyle {
    public var disabled: Bool
    public var highlightedAlpha: CGFloat
    public var disabledAlpha: CGFloat

    public init(disabled: Bool = false, highlightedAlpha: CGFloat? = nil, disabledAlpha: CGFloat? = nil) {
        self.disabled = disabled
        self.highlightedAlpha = highlightedAlpha ?? UIButton.fw.highlightedAlpha
        self.disabledAlpha = disabledAlpha ?? UIButton.fw.disabledAlpha
    }

    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? highlightedAlpha : (disabled ? disabledAlpha : 1.0))
    }
}

extension View {
    /// 设置按钮高亮和禁用时的透明度，nil时使用默认
    public func opacityButtonStyle(
        disabled: Bool = false,
        highlightedAlpha: CGFloat? = nil,
        disabledAlpha: CGFloat? = nil
    ) -> some View {
        buttonStyle(OpacityButtonStyle(disabled: disabled, highlightedAlpha: highlightedAlpha, disabledAlpha: disabledAlpha))
            .disabled(disabled)
    }

    /// 包装到Button并指定点击事件
    public func wrappedButton(
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            self
        }
    }

    /// 包装到VStack，可指定内容(如Spacer)
    public func wrappedVStack<Content: View>(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        content: (() -> Content)? = nil
    ) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            self

            if let content {
                content()
            }
        }
    }

    /// 包装到HStack，可指定内容(如Spacer)
    public func wrappedHStack<Content: View>(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        content: (() -> Content)? = nil
    ) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            self

            if let content {
                content()
            }
        }
    }
}

// MARK: - EdgeInsets+Toolkit
extension EdgeInsets {
    /// 静态zero边距
    public static var zero: Self { .init() }

    /// 自定义指定边长度，默认为0
    public init(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        guard let length else { return }

        if edges.contains(.top) { top = length }
        if edges.contains(.leading) { leading = length }
        if edges.contains(.bottom) { bottom = length }
        if edges.contains(.trailing) { trailing = length }
    }
}

// MARK: - Binding+Toolkit
/// [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)
extension Binding {
    public func onSet(_ body: @escaping @Sendable (Value) -> Void) -> Self where Value: Sendable {
        .init(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0; body($0) }
        )
    }

    public func onChange(perform action: @escaping @Sendable (Value) -> Void) -> Self where Value: Equatable, Value: Sendable {
        .init(
            get: { self.wrappedValue },
            set: { newValue in
                let oldValue = self.wrappedValue
                self.wrappedValue = newValue

                if newValue != oldValue {
                    action(newValue)
                }
            }
        )
    }

    public func onChange(toggle value: Binding<Bool>) -> Self where Value: Equatable, Value: Sendable {
        return onChange { _ in
            value.wrappedValue.toggle()
        }
    }

    public func withDefaultValue<T>(_ defaultValue: T) -> Binding<T> where Value == T?, T: Sendable {
        .init(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

#endif
