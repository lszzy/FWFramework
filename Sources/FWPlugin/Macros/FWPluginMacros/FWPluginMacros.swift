import Foundation
#if FWMacroSPM
import FWFramework
#endif

// MARK: - FWPluginMacros
/// MappedValue宏，仅支持class或struct
///
/// 使用方法：
/// 1. 标记class或struct为自动映射存储属性宏，使用方式：@MappedValueMacro
/// 2. 可自定义字段映射规则，使用方式：@MappedValue("name1", "name2")
/// 3. 以下划线开头或结尾的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
@attached(memberAttribute)
public macro MappedValueMacro() = #externalMacro(module: "FWMacroMacros", type: "MappedValueMacro")

/// 通用PropertyWrapper宏，仅支持class或struct
///
/// 使用方法：
/// 1. 标记class或struct为属性包装器宏，使用方式：@PropertyWrapperMacro("MappedValue")
/// 2. 如果字段不包含该属性包装器且不以下划线开头或结尾，将自动添加属性包装器
@attached(memberAttribute)
public macro PropertyWrapperMacro(_ name: StaticString...) = #externalMacro(module: "FWMacroMacros", type: "PropertyWrapperMacro")

/// 继承SmartCodable宏，仅支持class
///
/// 使用方法：
/// 1. 标记class为属性包装器宏，使用方式：@SmartSubclass
@attached(member, names: named(init(from:)), named(encode(to:)), named(CodingKeys), named(init))
public macro SmartSubclass() = #externalMacro(module: "FWMacroMacros", type: "SmartSubclassMacro")

// MARK: - Autoloader+Macros
#if FWPluginMacros
@objc extension Autoloader {
    static func loadPlugin_Macros() {}
}
#endif
