//
//  Icon.swift
//  FWFramework
//
//  Created by wuyong on 2022/8/22.
//

import CoreText
import UIKit

// MARK: - WrapperGlobal
extension WrapperGlobal {
    /// 快速创建图标对象
    ///
    /// - Parameters:
    ///   - named: 图标名称
    ///   - size: 图标大小
    /// - Returns: FWIcon对象
    public static func icon(_ named: String, _ size: CGFloat) -> Icon? {
        Icon.iconNamed(named, size: size)
    }

    /// 快速创建图标图像
    ///
    /// - Parameters:
    ///   - name: 图标名称
    ///   - size: 图片大小
    /// - Returns: UIImage对象
    public static func iconImage(_ name: String, _ size: CGFloat) -> UIImage? {
        Icon.iconImage(name, size: size)
    }
}

// MARK: - Icon
/// 字体图标抽象基类，子类需继承
///
/// [Foundation icons](https://zurb.com/playground/foundation-icon-fonts-3#allicons)
/// [FontAwesome](https://fontawesome.com/)
/// [ionicons](https://ionic.io/ionicons/)
/// [Octicons](https://primer.style/octicons/)
/// [Material](https://google.github.io/material-design-icons/#icons-for-ios)
///
/// [FontAwesomeKit](https://github.com/PrideChung/FontAwesomeKit)
open class Icon {
    private nonisolated(unsafe) static var iconMappers: [String: Icon.Type] = [:]

    /// 图标加载器，访问未注册图标时会尝试调用并注册，block返回值为register方法class参数
    public static let sharedLoader = Loader<String, Icon.Type>()

    /// 注册图标实现类，必须继承Icon，用于name快速查找，注意name不要重复
    open class func registerClass(_ iconClass: Icon.Type) {
        for (key, _) in iconClass.iconMapper() {
            iconMappers[key] = iconClass
        }
    }

    /// 指定名称和大小初始化图标对象
    open class func iconNamed(_ name: String, size: CGFloat) -> Icon? {
        var iconClass = iconMappers[name]
        if iconClass == nil {
            iconClass = sharedLoader.load(name)
            if let iconClass {
                registerClass(iconClass)
            }
        }
        guard let iconClass else { return nil }

        return iconClass.init(name: name, size: size)
    }

    /// 指定名称和大小初始化图标图像
    open class func iconImage(_ name: String, size: CGFloat) -> UIImage? {
        iconNamed(name, size: size)?.image
    }

    /// 安装图标字体文件，返回安装结果
    @discardableResult
    open class func installIconFont(_ fileURL: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return false }

        guard let dataProvider = CGDataProvider(url: fileURL as CFURL),
              let newFont = CGFont(dataProvider) else { return false }
        let result = CTFontManagerRegisterGraphicsFont(newFont, nil)
        return result
    }

    /// 自定义字体大小
    open var fontSize: CGFloat {
        get {
            iconFont.pointSize
        }
        set {
            addAttribute(.font, value: iconFont.withSize(newValue))
        }
    }

    /// 自定义背景色
    open var backgroundColor: UIColor? {
        get {
            attribute(.backgroundColor) as? UIColor
        }
        set {
            if let color = newValue {
                addAttribute(.backgroundColor, value: color)
            } else {
                removeAttribute(.backgroundColor)
            }
        }
    }

    /// 自定义前景色
    open var foregroundColor: UIColor? {
        get {
            attribute(.foregroundColor) as? UIColor
        }
        set {
            if let color = newValue {
                addAttribute(.foregroundColor, value: color)
            } else {
                removeAttribute(.foregroundColor)
            }
        }
    }

    /// 获取图标字符编码
    open var characterCode: String {
        mutableAttributedString.string
    }

    /// 获取图标名称
    open var iconName: String {
        var name: String?
        for (key, obj) in Self.iconMapper() {
            if obj == characterCode {
                name = key
                break
            }
        }
        return name ?? ""
    }

    /// 返回图标字体
    open var iconFont: UIFont {
        (attribute(.font) as? UIFont) ?? Self.iconFont(size: UIFont.systemFontSize)
    }

    /// 自定义图片偏移位置，仅创建Image时生效
    open var imageOffset: UIOffset = .zero

    /// 返回字体相同大小的图标Image
    open var image: UIImage? {
        let fontSize = fontSize
        return image(size: CGSize(width: fontSize, height: fontSize))
    }

    /// 生成属性字符串
    open var attributedString: NSAttributedString {
        mutableAttributedString.copy() as! NSAttributedString
    }

    private var mutableAttributedString: NSMutableAttributedString = .init()

    /// 根据字符编码和大小创建图标对象
    public init(code: String, size: CGFloat) {
        let font = Self.iconFont(size: size)
        self.mutableAttributedString = NSMutableAttributedString(string: code, attributes: [.font: font])
    }

    /// 根据图标名称和大小创建图标对象
    public required convenience init?(name: String, size: CGFloat) {
        guard let code = Self.iconMapper()[name] else { return nil }
        self.init(code: code, size: size)
    }

    /// 快速生成指定大小图标Image
    open func image(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        var attributedString = mutableAttributedString
        if let color = backgroundColor {
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            attributedString = mutableAttributedString.mutableCopy() as! NSMutableAttributedString
            attributedString.removeAttribute(.backgroundColor, range: NSMakeRange(0, attributedString.length))
        }

        let iconSize = attributedString.size()
        let xOffset = (size.width - iconSize.width) / 2.0 + imageOffset.horizontal
        let yOffset = (size.height - iconSize.height) / 2.0 + imageOffset.vertical
        let drawRect = CGRect(x: xOffset, y: yOffset, width: iconSize.width, height: iconSize.height)
        attributedString.draw(in: drawRect)

        let iconImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return iconImage
    }

    /// 设置图标属性，注意不要设置NSFontAttributeName为其他字体
    open func setAttributes(_ attrs: [NSAttributedString.Key: Any]) {
        var attributes = attrs
        if attributes[.font] == nil {
            attributes[.font] = iconFont
        }
        mutableAttributedString.setAttributes(attributes, range: NSMakeRange(0, mutableAttributedString.length))
    }

    /// 添加某个图标属性
    open func addAttribute(_ key: NSAttributedString.Key, value: Any) {
        mutableAttributedString.addAttribute(key, value: value, range: NSMakeRange(0, mutableAttributedString.length))
    }

    /// 批量添加属性
    open func addAttributes(_ attrs: [NSAttributedString.Key: Any]) {
        mutableAttributedString.addAttributes(attrs, range: NSMakeRange(0, mutableAttributedString.length))
    }

    /// 移除指定名称属性
    open func removeAttribute(_ key: NSAttributedString.Key) {
        mutableAttributedString.removeAttribute(key, range: NSMakeRange(0, mutableAttributedString.length))
    }

    /// 返回图标所有属性
    open func attributes() -> [NSAttributedString.Key: Any] {
        mutableAttributedString.attributes(at: 0, effectiveRange: nil)
    }

    /// 返回图标指定属性
    open func attribute(_ key: NSAttributedString.Key) -> Any? {
        mutableAttributedString.attribute(key, at: 0, effectiveRange: nil)
    }

    // MARK: - Override
    /// 所有图标名称=>编码映射字典，子类必须重写
    open class func iconMapper() -> [String: String] {
        [:]
    }

    /// 返回指定大小的图标字体，子类必须重写
    open class func iconFont(size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size)
    }
}
