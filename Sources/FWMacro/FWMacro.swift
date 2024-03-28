import Foundation

@attached(memberAttribute)
public macro MappedValueMacro() = #externalMacro(module: "FWMacroMacros", type: "MappedValueMacro")
