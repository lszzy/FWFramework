import Foundation

/// MappedValue宏，仅支持class或struct
///
/// 使用方法：
/// 1. 标记class或struct为自动映射存储属性宏，使用方式：@MappedValueMacro
/// 2. 可自定义字段映射规则，使用方式：@MappedValue("name1", "name2")
/// 3. 以下划线开头或结尾的字段将自动忽略，也可代码忽略：@MappedValue(ignored: true)
@attached(memberAttribute)
public macro MappedValueMacro() = #externalMacro(module: "FWMacroMacros", type: "MappedValueMacro")
